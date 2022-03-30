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
#if defined(__ARM_NEON) || defined(__ARM_NEON__)
#include <arm_neon.h>
#endif
#include <math.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>
#include <algorithm>
#include <fstream>
#include <limits>
#include <sstream>
#include <vector>

int WARMUP_COUNT = 1;
int REPEAT_COUNT = 5;
const int CPU_THREAD_NUM = 1;
const paddle::lite_api::PowerMode CPU_POWER_MODE =
    paddle::lite_api::PowerMode::LITE_POWER_NO_BIND;
const std::vector<int64_t> INPUT_SHAPE = {1, 3, 608, 608};
const std::vector<float> INPUT_MEAN = {0.485f, 0.456f, 0.406f};
const std::vector<float> INPUT_STD = {0.229f, 0.224f, 0.225f};

const float SCORE_THRESHOLD = 0.5f;

struct RESULT {
  std::string class_name;
  float score;
  float x0;
  float y0;
  float x1;
  float y1;
};

inline int64_t get_current_us() {
  struct timeval time;
  gettimeofday(&time, NULL);
  return 1000000LL * (int64_t)time.tv_sec + (int64_t)time.tv_usec;
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

std::vector<std::string> load_labels(const std::string &path) {
  std::ifstream file;
  std::vector<std::string> labels;
  file.open(path);
  while (file) {
    std::string line;
    std::getline(file, line);
    labels.push_back(line);
  }
  file.clear();
  file.close();
  return labels;
}

void preprocess(const float *input_image,
                const std::vector<float> &input_mean,
                const std::vector<float> &input_std,
                int input_width,
                int input_height,
                float *input_data) {
  // NHWC->NCHW
  int image_size = input_height * input_width;
  float *input_data_c0 = input_data;
  float *input_data_c1 = input_data + image_size;
  float *input_data_c2 = input_data + image_size * 2;
  int i = 0;
#if defined(__ARM_NEON) || defined(__ARM_NEON__)
  float32x4_t vmean0 = vdupq_n_f32(input_mean[0]);
  float32x4_t vmean1 = vdupq_n_f32(input_mean[1]);
  float32x4_t vmean2 = vdupq_n_f32(input_mean[2]);
  float32x4_t vscale0 = vdupq_n_f32(1.0f / input_std[0]);
  float32x4_t vscale1 = vdupq_n_f32(1.0f / input_std[1]);
  float32x4_t vscale2 = vdupq_n_f32(1.0f / input_std[2]);
  for (; i < image_size - 3; i += 4) {
    float32x4x3_t vin3 = vld3q_f32(input_image);
    float32x4_t vsub0 = vsubq_f32(vin3.val[0], vmean0);
    float32x4_t vsub1 = vsubq_f32(vin3.val[1], vmean1);
    float32x4_t vsub2 = vsubq_f32(vin3.val[2], vmean2);
    float32x4_t vs0 = vmulq_f32(vsub0, vscale0);
    float32x4_t vs1 = vmulq_f32(vsub1, vscale1);
    float32x4_t vs2 = vmulq_f32(vsub2, vscale2);
    vst1q_f32(input_data_c0, vs0);
    vst1q_f32(input_data_c1, vs1);
    vst1q_f32(input_data_c2, vs2);
    input_image += 12;
    input_data_c0 += 4;
    input_data_c1 += 4;
    input_data_c2 += 4;
  }
#endif
  for (; i < image_size; i++) {
    *(input_data_c0++) = (*(input_image++) - input_mean[0]) / input_std[0];
    *(input_data_c1++) = (*(input_image++) - input_mean[1]) / input_std[1];
    *(input_data_c2++) = (*(input_image++) - input_mean[2]) / input_std[2];
  }
}

std::vector<RESULT> postprocess(const float *output_data,
                                int64_t output_size,
                                int input_width,
                                int input_height,
                                const std::vector<std::string> &word_labels) {
  std::vector<RESULT> results;
  for (int64_t i = 0; i < output_size; i += 6) {
    // Class id
    auto class_id = static_cast<int>(round(output_data[i]));
    // Confidence score
    auto score = output_data[i + 1];
    if (score < SCORE_THRESHOLD) continue;
    RESULT object;
    object.class_name = class_id >= 0 && class_id < word_labels.size()
                            ? word_labels[class_id]
                            : "Unknow";
    object.score = score;
    object.x0 = output_data[i + 2];
    object.y0 = output_data[i + 3];
    object.x1 = output_data[i + 4];
    object.y1 = output_data[i + 5];
    results.push_back(object);
  }
  return results;
}

void process(const float *image_data,
             std::vector<float> *output_result,
             const std::vector<std::string> &word_labels,
             std::shared_ptr<paddle::lite_api::PaddlePredictor> predictor) {
  // Preprocess image and fill the data of input tensor
  int input_width = INPUT_SHAPE[3];
  int input_height = INPUT_SHAPE[2];
  // im_shape tensor
  auto image_shape_tensor = predictor->GetInput(0);
  image_shape_tensor->Resize({1, 2});
  auto image_shape_data = image_shape_tensor->mutable_data<float>();
  image_shape_data[0] = input_width;
  image_shape_data[1] = input_height;
  // image tensor
  auto input_tensor = predictor->GetInput(1);
  input_tensor->Resize(INPUT_SHAPE);
  auto input_data = input_tensor->mutable_data<float>();
  // scale_factor tensor
  auto scale_factor_tensor = predictor->GetInput(2);
  scale_factor_tensor->Resize({1, 2});
  auto scale_factor_data = scale_factor_tensor->mutable_data<float>();
  scale_factor_data[0] = 1.0f;
  scale_factor_data[1] = 1.0f;
  double preprocess_start_time = get_current_us();
  preprocess(
      image_data, INPUT_MEAN, INPUT_STD, input_width, input_height, input_data);
  double preprocess_end_time = get_current_us();
  double preprocess_time =
      (preprocess_end_time - preprocess_start_time) / 1000.0f;

  // Start to run inference
  // Warm up to skip the first inference and get more stable time, remove it in
  // actual products
  for (int i = 0; i < WARMUP_COUNT; i++) {
    predictor->Run();
  }
  // Repeat to obtain the average time, set REPEAT_COUNT=1 in actual products
  double prediction_time;
  double max_time_cost = 0.0f;
  double min_time_cost = std::numeric_limits<float>::max();
  double total_time_cost = 0.0f;
  for (int i = 0; i < REPEAT_COUNT; i++) {
    auto start = get_current_us();
    predictor->Run();
    auto end = get_current_us();
    double cur_time_cost = (end - start) / 1000.0f;
    if (cur_time_cost > max_time_cost) {
      max_time_cost = cur_time_cost;
    }
    if (cur_time_cost < min_time_cost) {
      min_time_cost = cur_time_cost;
    }
    total_time_cost += cur_time_cost;
    prediction_time = total_time_cost / REPEAT_COUNT;
    printf("iter %d cost: %f ms\n", i, cur_time_cost);
  }
  printf("warmup: %d repeat: %d, average: %f ms, max: %f ms, min: %f ms\n",
         WARMUP_COUNT,
         REPEAT_COUNT,
         prediction_time,
         max_time_cost,
         min_time_cost);

  // Get the data of output tensor and postprocess to output detected objects
  auto output_tensor = predictor->GetOutput(0);
  const float *output_data = output_tensor->data<float>();
  int64_t output_size = 1;
  for (auto dim : output_tensor->shape()) {
    output_size *= dim;
  }
  output_result->resize(output_size);
  memcpy(output_result->data(), &output_data, output_size * sizeof(float));
  double postprocess_start_time = get_current_us();
  std::vector<RESULT> results = postprocess(
      output_data, output_size, input_width, input_height, word_labels);
  double postprocess_end_time = get_current_us();
  double postprocess_time =
      (postprocess_end_time - postprocess_start_time) / 1000.0f;
  printf("results: %d\n", results.size());
  for (int i = 0; i < results.size(); i++) {
    printf("[%d] %s - %f %f,%f,%f,%f\n",
           i,
           results[i].class_name.c_str(),
           results[i].score,
           results[i].x0,
           results[i].y0,
           results[i].x1,
           results[i].y1);
  }

  printf("Preprocess time: %f ms\n", preprocess_time);
  printf("Prediction time: %f ms\n", prediction_time);
  printf("Postprocess time: %f ms\n\n", postprocess_time);
}

int main(int argc, char **argv) {
  if (argc < 11) {
    printf(
        "Usage: \n"
        "./yolo_detection_demo model_path mode_type label_path image_path "
        "result_path nnadapter_device_names nnadapter_context_properties "
        "nnadapter_model_cache_dir nnadapter_model_cache_token "
        "nnadapter_subgraph_partition_config_path");
    return -1;
  }
  std::string model_dir = argv[1];
  int model_type = atoi(argv[2]);
  std::string label_path = argv[3];
  std::string image_path = argv[4];
  std::string result_path = argv[5];
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

  // Load Labels
  std::vector<std::string> word_labels = load_labels(label_path);

  // Load raw image data from file
  std::ifstream image_file(
      image_path,
      std::ios::in | std::ios::binary);  // Raw RGB image with float data type
  if (!image_file) {
    printf("Failed to load image file %s\n", image_path.c_str());
    return -1;
  }
  size_t image_size =
      INPUT_SHAPE[0] * INPUT_SHAPE[1] * INPUT_SHAPE[2] * INPUT_SHAPE[3];
  std::vector<float> image_data(image_size);
  image_file.read(reinterpret_cast<char *>(image_data.data()),
                  image_size * sizeof(float));
  image_file.close();

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
#elif defined(__x86_64__)
  valid_places.push_back(
      paddle::lite_api::Place{TARGET(kX86), PRECISION(kInt8)});
  valid_places.push_back(
      paddle::lite_api::Place{TARGET(kX86), PRECISION(kFloat)});
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
    predictor =
        paddle::lite_api::CreatePaddlePredictor<paddle::lite_api::MobileConfig>(
            mobile_config);
    std::vector<float> result_data;
    process(image_data.data(), &result_data, word_labels, predictor);
    std::ofstream result_file(
        result_path,
        std::ios::out | std::ios::binary);  // dump the output tensor to file
    result_file.write(reinterpret_cast<char *>(result_data.data()),
                      result_data.size() * sizeof(float));
    result_file.close();
  } catch (std::exception e) {
    printf("An internal error occurred in PaddleLite(mobile config).\n");
    return -1;
  }
  return 0;
}
