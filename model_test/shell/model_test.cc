// Copyright (c) 2019 PaddlePaddle Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <paddle_api.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>
#include <algorithm>
#include <cmath>
#include <fstream>
#include <iostream>
#include <limits>
#include <sstream>
#include <vector>

int WARMUP_COUNT = 1;
int REPEAT_COUNT = 1;
const int CPU_THREAD_NUM = 1;
const paddle::lite_api::PowerMode CPU_POWER_MODE =
    paddle::lite_api::PowerMode::LITE_POWER_NO_BIND;

inline double get_current_us() {
  struct timeval time;
  gettimeofday(&time, NULL);
  return 1e+6 * time.tv_sec + time.tv_usec;
}

template <typename T>
void get_value_from_sstream(std::stringstream *ss, T *value) {
  (*ss) >> (*value);
}

template <>
void get_value_from_sstream<std::string>(std::stringstream *ss,
                                         std::string *value) {
  *value = ss->str();
}

template <typename T>
std::vector<T> split_string(const std::string &str, char sep) {
  std::stringstream ss;
  std::vector<T> values;
  T value;
  values.clear();
  for (auto c : str) {
    if (c != sep) {
      ss << c;
    } else {
      get_value_from_sstream<T>(&ss, &value);
      values.push_back(std::move(value));
      ss.str({});
      ss.clear();
    }
  }
  if (!ss.str().empty()) {
    get_value_from_sstream<T>(&ss, &value);
    values.push_back(std::move(value));
    ss.str({});
    ss.clear();
  }
  return values;
}

bool read_file(const std::string &filename,
               std::vector<char> *contents,
               bool binary = true) {
  FILE *fp = fopen(filename.c_str(), binary ? "rb" : "r");
  if (!fp) return false;
  fseek(fp, 0, SEEK_END);
  size_t size = ftell(fp);
  fseek(fp, 0, SEEK_SET);
  contents->clear();
  contents->resize(size);
  size_t offset = 0;
  char *ptr = reinterpret_cast<char *>(&(contents->at(0)));
  while (offset < size) {
    size_t already_read = fread(ptr, 1, size - offset, fp);
    offset += already_read;
    ptr += already_read;
  }
  fclose(fp);
  return true;
}

bool write_file(const std::string &filename,
                const std::vector<char> &contents,
                bool binary = true) {
  FILE *fp = fopen(filename.c_str(), binary ? "wb" : "w");
  if (!fp) return false;
  size_t size = contents.size();
  size_t offset = 0;
  const char *ptr = reinterpret_cast<const char *>(&(contents.at(0)));
  while (offset < size) {
    size_t already_written = fwrite(ptr, 1, size - offset, fp);
    offset += already_written;
    ptr += already_written;
  }
  fclose(fp);
  return true;
}

// The helper functions for loading and running model from command line and
// verifying output data
std::vector<std::string> parse_types(std::string text) {
  std::vector<std::string> types;
  while (!text.empty()) {
    size_t index = text.find_first_of(":");
    std::string type = text.substr(0, index);
    std::cout << type << std::endl;
    types.push_back(type);
    if (index == std::string::npos) {
      break;
    } else {
      text = text.substr(index + 1);
    }
  }
  return types;
}

std::vector<std::vector<int64_t>> parse_shapes(std::string text) {
  std::vector<std::vector<int64_t>> shapes;
  while (!text.empty()) {
    size_t index = text.find_first_of(":");
    std::string slice = text.substr(0, index);
    std::vector<int64_t> shape;
    while (!slice.empty()) {
      size_t index = slice.find_first_of(",");
      int d = atoi(slice.substr(0, index).c_str());
      std::cout << d << std::endl;
      shape.push_back(d);
      if (index == std::string::npos) {
        break;
      } else {
        slice = slice.substr(index + 1);
      }
    }
    shapes.push_back(shape);
    if (index == std::string::npos) {
      break;
    } else {
      text = text.substr(index + 1);
    }
  }
  return shapes;
}

int64_t shape_production(std::vector<int64_t> shape) {
  int64_t s = 1;
  for (int64_t dim : shape) {
    s *= dim;
  }
  return s;
}

void fill_input_tensors(
    const std::shared_ptr<paddle::lite_api::PaddlePredictor> &predictor,
    const std::vector<std::vector<int64_t>> &input_tensor_shapes,
    const std::vector<std::string> &input_tensor_types,
    const float value) {
#define FILL_TENSOR_WITH_TYPE(type)                            \
  auto input_tensor_data = input_tensor->mutable_data<type>(); \
  for (int j = 0; j < input_tensor_size; j++) {                \
    input_tensor_data[j] = static_cast<type>(value);           \
  }
  for (int i = 0; i < input_tensor_shapes.size(); i++) {
    auto input_tensor = predictor->GetInput(i);
    input_tensor->Resize(input_tensor_shapes[i]);
    auto input_tensor_size = shape_production(input_tensor->shape());
    if (input_tensor_types[i] == "float32") {
      FILL_TENSOR_WITH_TYPE(float)
    } else if (input_tensor_types[i] == "int32") {
      FILL_TENSOR_WITH_TYPE(int32_t)
    } else if (input_tensor_types[i] == "int64") {
      FILL_TENSOR_WITH_TYPE(int64_t)
    } else {
      printf(
          "Unsupported input data type '%s', only 'float32', 'int32', 'int64' "
          "are supported!\n",
          input_tensor_types[i].c_str());
      exit(-1);
    }
  }
#undef FILL_TENSOR_WITH_TYPE
}

const int MAX_DISPLAY_OUTPUT_TENSOR_SIZE = 10000;
void print_output_tensors(
    const std::shared_ptr<paddle::lite_api::PaddlePredictor> &predictor,
    const std::vector<std::string> &output_tensor_types) {
#define PRINT_TENSOR_WITH_TYPE(type)                                     \
  auto output_tensor_data = output_tensor->data<type>();                 \
  for (size_t j = 0;                                                     \
       j < output_tensor_size && j < MAX_DISPLAY_OUTPUT_TENSOR_SIZE;     \
       j++) {                                                            \
    std::cout << "[" << j << "] " << output_tensor_data[j] << std::endl; \
  }
  for (int i = 0; i < output_tensor_types.size(); i++) {
    auto output_tensor = predictor->GetOutput(i);
    auto output_tensor_size = shape_production(output_tensor->shape());
    if (output_tensor_types[i] == "float32") {
      PRINT_TENSOR_WITH_TYPE(float)
    } else if (output_tensor_types[i] == "int32") {
      PRINT_TENSOR_WITH_TYPE(int32_t)
    } else if (output_tensor_types[i] == "int64") {
      PRINT_TENSOR_WITH_TYPE(int64_t)
    } else {
      printf(
          "Unsupported input data type '%s', only 'float32', 'int32', 'int64' "
          "are supported!\n",
          output_tensor_types[i].c_str());
      exit(-1);
    }
  }
#undef PRINT_TENSOR_WITH_TYPE
}

void check_output_tensors(
    const std::shared_ptr<paddle::lite_api::PaddlePredictor> &tar_predictor,
    const std::shared_ptr<paddle::lite_api::PaddlePredictor> &ref_predictor,
    const std::vector<std::string> &output_tensor_type) {
#define CHECK_TENSOR_WITH_TYPE(type)                                          \
  auto tar_output_tensor_data = tar_output_tensor->data<type>();              \
  auto ref_output_tensor_data = ref_output_tensor->data<type>();              \
  for (size_t j = 0; j < ref_output_tensor_size; j++) {                       \
    auto abs_diff =                                                           \
        std::fabs(tar_output_tensor_data[j] - ref_output_tensor_data[j]);     \
    auto rel_diff = abs_diff / (std::fabs(ref_output_tensor_data[j]) + 1e-6); \
    if (rel_diff < 0.01f) continue;                                           \
    std::cout << "val: " << tar_output_tensor_data[j]                         \
              << " ref: " << ref_output_tensor_data[j]                        \
              << " abs_diff: " << abs_diff << " rel_diff: " << rel_diff       \
              << std::endl;                                                   \
  }
  for (int i = 0; i < output_tensor_type.size(); i++) {
    auto tar_output_tensor = tar_predictor->GetOutput(i);
    auto ref_output_tensor = ref_predictor->GetOutput(i);
    auto tar_output_tensor_size = shape_production(tar_output_tensor->shape());
    auto ref_output_tensor_size = shape_production(ref_output_tensor->shape());
    if (tar_output_tensor_size != ref_output_tensor_size) {
      std::cout << "The size of output tensor[" << i << "] does not match."
                << std::endl;
      exit(-1);
    }
    if (output_tensor_type[i] == "float32") {
      CHECK_TENSOR_WITH_TYPE(float)
    } else if (output_tensor_type[i] == "int32") {
      CHECK_TENSOR_WITH_TYPE(int32_t)
    } else if (output_tensor_type[i] == "int64") {
      CHECK_TENSOR_WITH_TYPE(int64_t)
    }
  }
#undef CHECK_TENSOR_WITH_TYPE
}

int main(int argc, char **argv) {
  if (argc < 11) {
    printf(
        "Usage: \n./model_test model_dir model_type input_tensor_shape "
        "input_tensor_type output_tensor_type nnadapter_device_names "
        "nnadapter_context_properties nnadapter_model_cache_dir "
        "nnadapter_model_cache_token "
        "nnadapter_subgraph_partition_config_path\n");
    return -1;
  }

  std::string model_dir = argv[1];
  int model_type = atoi(argv[2]);
  // Parsing the shape of input tensors from strings, supported formats:
  // "1,3,224,224" and "1,3,224,224:1,80"
  auto input_tensor_shapes = parse_shapes(argv[3]);
  // Parsing the data type of input and output tensors from strings, supported
  // formats: "float32" and "float32:int64:int8"
  auto input_tensor_types = parse_types(argv[4]);
  auto output_tensor_types = parse_types(argv[5]);
  std::vector<std::string> nnadapter_device_names =
      split_string<std::string>(argv[6], ',');
  if (nnadapter_device_names.empty()) {
    printf("No device specified.");
    return -1;
  }
  std::string nnadapter_context_properties =
      strcmp(argv[7], "null") == 0 ? "" : argv[7];
  std::string nnadapter_model_cache_dir =
      strcmp(argv[8], "null") == 0 ? "" : argv[8];
  std::string nnadapter_model_cache_token =
      strcmp(argv[9], "null") == 0 ? "" : argv[9];
  std::string nnadapter_subgraph_partition_config_path =
      strcmp(argv[10], "null") == 0 ? "" : argv[10];

  std::shared_ptr<paddle::lite_api::PaddlePredictor> predictor = nullptr;
#ifdef USE_FULL_API
  // Run inference by using full api with CxxConfig
  paddle::lite_api::CxxConfig cxx_config;
  if (model_type) {  // combined model
    cxx_config.set_model_file(model_dir + "/model");
    cxx_config.set_param_file(model_dir + "/params");
  } else {
    cxx_config.set_model_dir(model_dir);
  }
  cxx_config.set_threads(CPU_THREAD_NUM);
  cxx_config.set_power_mode(CPU_POWER_MODE);
  std::vector<paddle::lite_api::Place> valid_places;
  if (std::find(nnadapter_device_names.begin(),
                nnadapter_device_names.end(),
                "cpu") == nnadapter_device_names.end()) {
    valid_places.push_back(
        paddle::lite_api::Place{TARGET(kNNAdapter), PRECISION(kInt8)});
    valid_places.push_back(
        paddle::lite_api::Place{TARGET(kNNAdapter), PRECISION(kFloat)});
  }
#if defined(__arm__) || defined(__aarch64__)
  valid_places.push_back(
      paddle::lite_api::Place{TARGET(kARM), PRECISION(kInt8)});
  valid_places.push_back(
      paddle::lite_api::Place{TARGET(kARM), PRECISION(kFloat)});
  valid_places.push_back(
      paddle::lite_api::Place{TARGET(kARM), PRECISION(kInt32)});
#elif defined(__x86_64__)
  valid_places.push_back(
      paddle::lite_api::Place{TARGET(kX86), PRECISION(kInt8)});
  valid_places.push_back(
      paddle::lite_api::Place{TARGET(kX86), PRECISION(kFloat)});
  valid_places.push_back(
      paddle::lite_api::Place{TARGET(kX86), PRECISION(kInt32)});
#endif
  cxx_config.set_valid_places(valid_places);
  cxx_config.set_nnadapter_device_names(nnadapter_device_names);
  cxx_config.set_nnadapter_context_properties(nnadapter_context_properties);
  cxx_config.set_nnadapter_model_cache_dir(nnadapter_model_cache_dir);
  // Set the subgraph custom partition configuration file
  if (!nnadapter_subgraph_partition_config_path.empty()) {
    std::vector<char> nnadapter_subgraph_partition_config_buffer;
    if (read_file(nnadapter_subgraph_partition_config_path,
                  &nnadapter_subgraph_partition_config_buffer,
                  false)) {
      if (!nnadapter_subgraph_partition_config_buffer.empty()) {
        std::string nnadapter_subgraph_partition_config_string(
            nnadapter_subgraph_partition_config_buffer.data(),
            nnadapter_subgraph_partition_config_buffer.size());
        cxx_config.set_nnadapter_subgraph_partition_config_buffer(
            nnadapter_subgraph_partition_config_string);
      }
    } else {
      printf(
          "Failed to load the subgraph custom partition configuration file "
          "%s\n",
          nnadapter_subgraph_partition_config_path.c_str());
    }
  }
  try {
    predictor = paddle::lite_api::CreatePaddlePredictor(cxx_config);
    predictor->SaveOptimizedModel(
        model_dir, paddle::lite_api::LiteModelType::kNaiveBuffer);
  } catch (std::exception e) {
    printf("An internal error occurred in PaddleLite(cxx config).\n");
    return -1;
  }
#endif

  // Run inference by using light api with MobileConfig
  paddle::lite_api::MobileConfig mobile_config;
  mobile_config.set_model_from_file(model_dir + ".nb");
  mobile_config.set_threads(CPU_THREAD_NUM);
  mobile_config.set_power_mode(CPU_POWER_MODE);
  mobile_config.set_nnadapter_device_names(nnadapter_device_names);
  mobile_config.set_nnadapter_context_properties(nnadapter_context_properties);
  // Set the model cache buffer and directory
  mobile_config.set_nnadapter_model_cache_dir(nnadapter_model_cache_dir);
  if (!nnadapter_model_cache_token.empty() &&
      !nnadapter_model_cache_dir.empty()) {
    std::vector<char> nnadapter_model_cache_buffer;
    std::string nnadapter_model_cache_path =
        nnadapter_model_cache_dir + "/" + nnadapter_model_cache_token + ".nnc";
    if (!read_file(
            nnadapter_model_cache_path, &nnadapter_model_cache_buffer, true)) {
      printf("Failed to load the cache model file %s\n",
             nnadapter_model_cache_path.c_str());
    }
    if (!nnadapter_model_cache_buffer.empty()) {
      mobile_config.set_nnadapter_model_cache_buffers(
          nnadapter_model_cache_token, nnadapter_model_cache_buffer);
    }
  }
  try {
    predictor = paddle::lite_api::CreatePaddlePredictor(mobile_config);
    for (int i = 0; i < WARMUP_COUNT; i++) {
      fill_input_tensors(predictor, input_tensor_shapes, input_tensor_types, 1);
      predictor->Run();
    }
    double cost = 0.0f;
    for (int i = 0; i < REPEAT_COUNT; i++) {
      fill_input_tensors(predictor, input_tensor_shapes, input_tensor_types, 1);
      auto start = get_current_us();
      predictor->Run();
      auto duration = (get_current_us() - start) / 1000.0f;
      cost += duration;
      std::cout << "iter" << i << " " << duration << " ms" << std::endl;
    }
    std::cout << "warmup count: " << WARMUP_COUNT
              << ", repeat count: " << REPEAT_COUNT << ", spend "
              << cost / REPEAT_COUNT << " ms in average." << std::endl;
    print_output_tensors(predictor, output_tensor_types);
  } catch (std::exception e) {
    printf("An internal error occurred in PaddleLite(mobile config).\n");
    return -1;
  }
  return 0;
}
