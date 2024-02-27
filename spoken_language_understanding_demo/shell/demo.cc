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
#include <libgen.h>
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
#include "fast_tokenizer/pretokenizers/pretokenizer.h"
#include "fast_tokenizer/tokenizers/ernie_fast_tokenizer.h"
#include "fast_tokenizer/utils/utf8.h"
#include "nlohmann/json.hpp"

using namespace paddlenlp;                        // NOLINT
using namespace fast_tokenizer::tokenizers_impl;  // NOLINT

int WARMUP_COUNT = 1;
int REPEAT_COUNT = 5;
const int CPU_THREAD_NUM = 1;
const paddle::lite_api::PowerMode CPU_POWER_MODE =
    paddle::lite_api::PowerMode::LITE_POWER_NO_BIND;

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

int64_t shape_production(std::vector<int64_t> shape) {
  int64_t s = 1;
  for (int64_t dim : shape) {
    s *= dim;
  }
  return s;
}

bool add_tokens_to_tokenizer(const std::string &path,
                             ErnieFastTokenizer *tokenizer) {
  std::ifstream fin(path);
  nlohmann::json j;
  fin >> j;
  using VOCAB_ITEM = std::pair<std::string, uint32_t>;
  std::vector<VOCAB_ITEM> vocab_list;
  for (nlohmann::json::iterator it = j.begin(); it != j.end(); ++it) {
    vocab_list.emplace_back(it.key(), it.value());
  }
  std::sort(vocab_list.begin(),
            vocab_list.end(),
            [](const VOCAB_ITEM &a, const VOCAB_ITEM &b) {
              return a.second < b.second;
            });
  std::vector<fast_tokenizer::core::AddedToken> added_tokens;
  int increase_idx = 0;
  for (auto &&vocab_item : vocab_list) {
    if (vocab_item.second != tokenizer->GetVocabSize() + increase_idx) {
      printf(
          "Non-consecutive added token '%s' found. Should have index %zu "
          "but has index %u in saved vocabulary.\n",
          vocab_item.first.c_str(),
          tokenizer->GetVocabSize(),
          vocab_item.second);
      return false;
    }
    added_tokens.emplace_back(vocab_item.first);
    ++increase_idx;
  }
  std::ostringstream oss;
  oss << "Try to add the following tokens to tokenizer vocab. AddedTokens = [";
  for (int i = 0; i < added_tokens.size(); ++i) {
    auto &&token = added_tokens[i];
    oss << token.GetContent();
    if (i < added_tokens.size() - 1) {
      oss << ", ";
    }
  }
  oss << "]";
  printf("%s\n", oss.str().c_str());
  tokenizer->AddTokens(added_tokens);
  return true;
}

typedef struct {
  int max_length;
  std::string vocab_path;
  std::string added_tokens_path;
  std::vector<std::string> intent_label_list;
  std::vector<std::string> slot_label_list;
} CONFIG;

std::vector<std::string> load_label(const std::string &path) {
  std::vector<char> buffer;
  if (!read_file(path, &buffer, false)) {
    printf("Failed to load the label file %s\n", path.c_str());
    exit(-1);
  }
  std::string content(buffer.begin(), buffer.end());
  auto lines = split_string<std::string>(content, '\n');
  if (lines.empty()) {
    printf("The label file %s should not be empty!\n", path.c_str());
    exit(-1);
  }
  return lines;
}

CONFIG load_config(const std::string &path) {
  CONFIG config;
  std::vector<char> buffer;
  if (!read_file(path, &buffer, false)) {
    printf("Failed to load the config file %s\n", path.c_str());
    exit(-1);
  }
  std::string dir = ".";
  auto pos = path.find_last_of("/");
  if (pos != std::string::npos) {
    dir = path.substr(0, pos);
  }
  printf("dir: %s\n", dir.c_str());
  std::string content(buffer.begin(), buffer.end());
  auto lines = split_string<std::string>(content, '\n');
  std::map<std::string, std::string> values;
  for (auto &line : lines) {
    auto value = split_string<std::string>(line, ':');
    if (value.size() != 2) {
      printf("Format error at '%s', it should be '<key>:<value>'.\n",
             line.c_str());
      exit(-1);
    }
    values[value[0]] = value[1];
  }
  // max_length
  if (!values.count("max_length")) {
    printf("Missing the key 'max_length'!\n");
    exit(-1);
  }
  config.max_length = atoi(values["max_length"].c_str());
  if (config.max_length <= 0) {
    printf("The key 'max_length' should > 0, but receive %d!\n",
           config.max_length);
    exit(-1);
  }
  printf("max_length: %d\n", config.max_length);
  // vocab_path
  if (!values.count("vocab_path")) {
    printf("Missing the key 'vocab_path'!\n");
    exit(-1);
  }
  std::string vocab_path = values["vocab_path"];
  if (vocab_path.empty()) {
    printf("The key 'vocab_path' should not empty !\n");
    exit(-1);
  }
  config.vocab_path = dir + "/" + vocab_path;
  printf("vocab_path: %s\n", config.vocab_path.c_str());
  // added_tokens_path(optional)
  if (values.count("added_tokens_path")) {
    std::string added_tokens_path = values["added_tokens_path"];
    if (!added_tokens_path.empty()) {
      config.added_tokens_path = dir + "/" + added_tokens_path;
    }
  }
  printf("added_tokens_path: %s\n", config.added_tokens_path.c_str());
  // intent_label_path(optional)
  if (values.count("intent_label_path")) {
    std::string intent_label_path = values["intent_label_path"];
    if (!intent_label_path.empty()) {
      config.intent_label_list = load_label(dir + "/" + intent_label_path);
    }
  }
  printf("intent_label_list size: %ld\n", config.intent_label_list.size());
  // slot_label_path(optional)
  if (values.count("slot_label_path")) {
    std::string slot_label_path = values["slot_label_path"];
    if (!slot_label_path.empty()) {
      config.slot_label_list = load_label(dir + "/" + slot_label_path);
    }
  }
  printf("slot_label_list size: %ld\n", config.slot_label_list.size());
  return config;
}

std::vector<std::string> load_dataset(const std::string &path) {
  std::vector<char> buffer;
  if (!read_file(path, &buffer, false)) {
    printf("Failed to load the dataset list file %s\n", path.c_str());
    exit(-1);
  }
  std::string content(buffer.begin(), buffer.end());
  auto lines = split_string<std::string>(content, '\n');
  if (lines.empty()) {
    printf("The dataset list file %s should not be empty!\n", path.c_str());
    exit(-1);
  }
  return lines;
}

std::vector<std::string> load_sequences(const std::string &path) {
  std::vector<char> buffer;
  if (!read_file(path, &buffer, false)) {
    printf("Failed to load the label file %s\n", path.c_str());
    exit(-1);
  }
  std::string content(buffer.begin(), buffer.end());
  auto lines = split_string<std::string>(content, '\n');
  if (lines.empty()) {
    printf("The sequence file %s should not be empty!\n", path.c_str());
    exit(-1);
  }
  return lines;
}

struct IntentDetAndSlotFillResult {
  struct IntentDetResult {
    std::string intent_label;
    float intent_confidence;
  } intent_result;
  struct SlotFillResult {
    std::string slot_label;
    std::string entity;
    std::pair<int, int> pos;
  };
  std::vector<SlotFillResult> slot_result;
};

void process(std::shared_ptr<paddle::lite_api::PaddlePredictor> predictor,
             const std::string &config_path,
             const std::string &dataset_dir) {
  // Parse the config file to extract the model info
  auto config = load_config(config_path);
  // Load dataset list
  auto dataset = load_dataset(dataset_dir + "/list.txt");
  // Initialize fast tokenizer
  FILE *fp = fopen(config.vocab_path.c_str(), "r");
  if (!fp) {
    printf("Failed to open vocab file %s.\n", config.vocab_path.c_str());
    exit(-1);
  }
  fclose(fp);
  if (!config.added_tokens_path.empty()) {
    fp = fopen(config.added_tokens_path.c_str(), "r");
    if (!fp) {
      printf("Failed to open added tokens file %s.\n",
             config.added_tokens_path.c_str());
      exit(-1);
    }
    fclose(fp);
  } else {
    printf("No added_tokens have been added to tokenizer.\n");
  }
  ErnieFastTokenizer tokenizer(config.vocab_path);
  add_tokens_to_tokenizer(config.added_tokens_path, &tokenizer);
  uint32_t max_length = config.max_length;
  tokenizer.EnableTruncMethod(
      max_length,
      0,
      fast_tokenizer::core::Direction::RIGHT,
      fast_tokenizer::core::TruncStrategy::LONGEST_FIRST);
  tokenizer.EnablePadMethod(fast_tokenizer::core::Direction::RIGHT,
                            0,
                            0,
                            "[PAD]",
                            &max_length,
                            nullptr);
  // Prepare for inference and warmup
  auto input_ids_tensor = predictor->GetInput(0);
  input_ids_tensor->Resize({1, config.max_length});
  auto input_ids_data = input_ids_tensor->mutable_data<int32_t>();
  memset(input_ids_data, 0, sizeof(int32_t) * config.max_length);
  predictor->Run();  // Warmup
  // Traverse the list of the dataset and run inference on each sample
  double cur_costs[3];
  double total_costs[3] = {0, 0, 0};
  double max_costs[3] = {0, 0, 0};
  double min_costs[3] = {std::numeric_limits<float>::max(),
                         std::numeric_limits<float>::max(),
                         std::numeric_limits<float>::max()};
  int iter_count = 0;
  auto sample_count = dataset.size();
  for (size_t i = 0; i < sample_count; i++) {
    auto sample_name = dataset[i];
    printf(
        "[%ld/%ld] Processing %s\n", i + 1, sample_count, sample_name.c_str());
    auto input_path = dataset_dir + "/inputs/" + sample_name;
    auto output_path = dataset_dir + "/outputs/" + sample_name;
    // Check if input and output is accessable
    if (access(input_path.c_str(), R_OK) != 0) {
      printf("%s not found or readable!\n", input_path.c_str());
      exit(-1);
    }
    auto sequences = load_sequences(input_path);
    auto sequence_count = sequences.size();
    for (size_t j = 0; j < sequence_count; j++) {
      printf("[%ld/%ld] %s\n", j + 1, sequence_count, sequences[j].c_str());
      // Preprocess
      double start = get_current_us();
      // Use tokenizer to decode text to IDs
      std::vector<std::string> texts;
      texts.push_back(sequences[j]);
      std::vector<fast_tokenizer::core::Encoding> encodings;
      tokenizer.EncodeBatchStrings(texts, &encodings);
      auto &&ids = encodings[0].GetIds();
      printf("ids: ");
      memset(input_ids_data, 0, sizeof(int32_t) * max_length);
      for (size_t k = 0; k < ids.size() && k < max_length; k++) {
        printf("%d ", ids[k]);
        input_ids_data[k] = ids[k];
      }
      printf("\n");
      double end = get_current_us();
      cur_costs[0] = (end - start) / 1000.0f;
      // Inference
      start = get_current_us();
      predictor->Run();
      end = get_current_us();
      cur_costs[1] = (end - start) / 1000.0f;
      // Postprocess
      start = get_current_us();
      IntentDetAndSlotFillResult result;
      // Intent cls
      auto intent_tensor = predictor->GetOutput(0);
      auto intent_data = intent_tensor->data<float>();
      auto intent_size = shape_production(intent_tensor->shape());
      if (intent_size > 0) {
        auto max_value = intent_data[0];
        auto max_index = 0;
        for (size_t k = 1; k < intent_size; k++) {
          auto cur_value = intent_data[k];
          if (max_value < cur_value) {
            max_value = cur_value;
            max_index = k;
          }
        }
        result.intent_result.intent_label =
            max_index >= 0 && max_index < config.intent_label_list.size()
                ? config.intent_label_list[max_index]
                : "Unknown";
        result.intent_result.intent_confidence = max_value;
      }
      // Slot cls
      auto slot_tensor = predictor->GetOutput(1);
      auto slot_data = slot_tensor->data<float>();
      auto slot_size = shape_production(slot_tensor->shape());
      // if (slot_size > 0) {
      // }
      printf("intent: %s - %f\n",
             result.intent_result.intent_label.c_str(),
             result.intent_result.intent_confidence);
      end = get_current_us();
      cur_costs[2] = (end - start) / 1000.0f;
      // Statisics
      for (size_t j = 0; j < 3; j++) {
        total_costs[j] += cur_costs[j];
        if (cur_costs[j] > max_costs[j]) {
          max_costs[j] = cur_costs[j];
        }
        if (cur_costs[j] < min_costs[j]) {
          min_costs[j] = cur_costs[j];
        }
      }
      printf(
          "[%d] Preprocess time: %f ms Prediction time: %f ms Postprocess "
          "time: "
          "%f ms\n",
          iter_count,
          cur_costs[0],
          cur_costs[1],
          cur_costs[2]);
      iter_count++;
    }
  }
  printf("Preprocess time: avg %f ms, max %f ms, min %f ms\n",
         total_costs[0] / iter_count,
         max_costs[0],
         min_costs[0]);
  printf("Prediction time: avg %f ms, max %f ms, min %f ms\n",
         total_costs[1] / iter_count,
         max_costs[1],
         min_costs[1]);
  printf("Postprocess time: avg %f ms, max %f ms, min %f ms\n",
         total_costs[2] / iter_count,
         max_costs[2],
         min_costs[2]);
  printf("Done.\n");
}

int main(int argc, char **argv) {
  if (argc < 10) {
    printf(
        "Usage: \n"
        "./demo model_dir config_path dataset_dir nnadapter_device_names "
        "nnadapter_context_properties nnadapter_model_cache_dir "
        "nnadapter_model_cache_token "
        "nnadapter_subgraph_partition_config_path "
        "nnadapter_mixed_precision_quantization_config_path");
    return -1;
  }
  std::string model_dir = argv[1];
  std::string config_path = argv[2];
  std::string dataset_dir = argv[3];
  std::vector<std::string> nnadapter_device_names =
      split_string<std::string>(argv[4], ',');
  if (nnadapter_device_names.empty()) {
    printf("No device specified.");
    return -1;
  }
  std::string nnadapter_context_properties =
      strcmp(argv[5], "null") == 0 ? "" : argv[5];
  std::string nnadapter_model_cache_dir =
      strcmp(argv[6], "null") == 0 ? "" : argv[6];
  std::string nnadapter_model_cache_token =
      strcmp(argv[7], "null") == 0 ? "" : argv[7];
  std::string nnadapter_subgraph_partition_config_path =
      strcmp(argv[8], "null") == 0 ? "" : argv[8];
  std::string nnadapter_mixed_precision_quantization_config_path =
      strcmp(argv[9], "null") == 0 ? "" : argv[9];

  std::shared_ptr<paddle::lite_api::PaddlePredictor> predictor = nullptr;
#ifdef USE_FULL_API
  // Run inference by using full api with CxxConfig
  paddle::lite_api::CxxConfig cxx_config;
  cxx_config.set_model_dir(model_dir);
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
  // Set the subgraph partition configuration file
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
          "Failed to load the subgraph partition configuration file "
          "%s\n",
          nnadapter_subgraph_partition_config_path.c_str());
    }
  }
  // Set the mixed precision quantization configuration file
  if (!nnadapter_mixed_precision_quantization_config_path.empty()) {
    std::vector<char> nnadapter_mixed_precision_quantization_config_buffer;
    if (read_file(nnadapter_mixed_precision_quantization_config_path,
                  &nnadapter_mixed_precision_quantization_config_buffer,
                  false)) {
      if (!nnadapter_mixed_precision_quantization_config_buffer.empty()) {
        std::string nnadapter_mixed_precision_quantization_config_string(
            nnadapter_mixed_precision_quantization_config_buffer.data(),
            nnadapter_mixed_precision_quantization_config_buffer.size());
        cxx_config.set_nnadapter_mixed_precision_quantization_config_buffer(
            nnadapter_mixed_precision_quantization_config_string);
      }
    } else {
      printf(
          "Failed to load the mixed precision quantization configuration file "
          "%s\n",
          nnadapter_mixed_precision_quantization_config_path.c_str());
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
    process(predictor, config_path, dataset_dir);
  } catch (std::exception e) {
    printf("An internal error occurred in PaddleLite(mobile config).\n");
    return -1;
  }
  return 0;
}
