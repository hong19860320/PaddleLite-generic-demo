#!/bin/bash
MODEL_NAME=ssd_mobilenet_v1_relu_voc_fp32_300
#MODEL_NAME=ssd_mobilenet_v1_relu_voc_int8_300_per_layer
if [ -n "$1" ]; then
  MODEL_NAME=$1
fi

if [ ! -d "../assets/models/$MODEL_NAME" ];then
  MODEL_URL="http://paddlelite-demo.bj.bcebos.com/devices/generic/models/${MODEL_NAME}.tar.gz"
  echo "Model $MODEL_NAME not found! Try to download it from $MODEL_URL ..."
  curl $MODEL_URL -o -| tar -xz -C ../assets/models
  if [[ $? -ne 0 ]]; then
    echo "Model $MODEL_NAME download failed!"
    exit 1
  fi
fi

MODEL_TYPE=0 # 1 combined paddle fluid model
#SUBGRAPH_PARTITION_CONFIG_FILE=subgraph_partition_config_file.txt
LABEL_NAME=pascalvoc_label_list
IMAGE_NAME=dog.raw
RESULT_NAME=dog.bin
WORK_SPACE=/data/local/tmp/test

# For TARGET_OS=android, TARGET_ABI should be arm64-v8a or armeabi-v7a.
# For TARGET_OS=linux, TARGET_ABI should be arm64, armhf or amd64.
# Kirin810/820/985/990/9000/9000E: TARGET_OS=android and TARGET_ABI=arm64-v8a
# MT8168/8175, Kirin810/820/985/990/9000/9000E: TARGET_OS=android and TARGET_ABI=armeabi-v7a
# RK1808EVB, TB-RK1808S0, Kunpeng-920+Ascend310: TARGET_OS=linux and TARGET_ABI=arm64
# RK1806EVB, RV1109/1126 EVB: TARGET_OS=linux and TARGET_ABI=armhf 
# Intel-x86+Ascend310: TARGET_OS=linux and TARGET_ABI=amd64
TARGET_OS=android
if [ -n "$2" ]; then
  TARGET_OS=$2
fi

if [ "$TARGET_OS" == "linux" ]; then
  WORK_SPACE=~/test
fi

TARGET_ABI=arm64-v8a
if [ -n "$3" ]; then
  TARGET_ABI=$3
fi

# RK1808EVB, TB-RK1808S0, RK1806EVB, RV1109/1126 EVB: NNADAPTER_DEVICE_NAMES=rockchip_npu
# MT8168/8175: NNADAPTER_DEVICE_NAMES=mediatek_apu
# Kirin810/820/985/990/9000/9000E: NNADAPTER_DEVICE_NAMES=huawei_kirin_npu
# CPU only: NNADAPTER_DEVICE_NAMES=cpu
NNADAPTER_DEVICE_NAMES="cpu"
if [ -n "$4" ]; then
  NNADAPTER_DEVICE_NAMES="$4"
fi
NNADAPTER_DEVICE_NAMES_LIST=(${NNADAPTER_DEVICE_NAMES//,/ })
NNADAPTER_DEVICE_NAMES_TEXT=${NNADAPTER_DEVICE_NAMES//,/_}

ADB_DEVICE_NAME=
if [ -n "$5" ]; then
  ADB_DEVICE_NAME="-s $5"
fi

NNADAPTER_CONTEXT_PROPERTIES="null"
if [ -n "$6" ]; then
  NNADAPTER_CONTEXT_PROPERTIES="$6"
fi

NNADAPTER_MODEL_CACHE_DIR="null"
#NNADAPTER_MODEL_CACHE_DIR="$WORK_SPACE"
if [ -n "$7" ]; then
  NNADAPTER_MODEL_CACHE_DIR="$7"
fi

NNADAPTER_MODEL_CACHE_TOKEN="null"
if [ -n "$8" ]; then
  NNADAPTER_MODEL_CACHE_TOKEN="$8"
fi

NNADAPTER_SUBGRAPH_PARTITION_CONFIG_PATH="null"
if [ -n "$SUBGRAPH_PARTITION_CONFIG_FILE" ]; then
  NNADAPTER_SUBGRAPH_PARTITION_CONFIG_PATH="./$MODEL_NAME/${NNADAPTER_DEVICE_NAMES_TEXT}_${SUBGRAPH_PARTITION_CONFIG_FILE}"
fi

EXPORT_ENVIRONMENT_VARIABLES="export GLOG_v=5; export SUBGRAPH_ONLINE_MODE=true"
if [[ "$NNADAPTER_DEVICE_NAMES" =~ "rockchip_npu" ]]; then
  EXPORT_ENVIRONMENT_VARIABLES="$EXPORT_ENVIRONMENT_VARIABLES; export RKNPU_LOGLEVEL=5; export RKNN_LOG_LEVEL=5; ulimit -c unlimited"
  adb $ADB_DEVICE_NAME shell "echo userspace > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"
  adb $ADB_DEVICE_NAME shell "echo $(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq) > /sys/devices/system/cpu/cpufreq/policy0/scaling_setspeed"
fi

EXPORT_ENVIRONMENT_VARIABLES="$EXPORT_ENVIRONMENT_VARIABLES; export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:.:./cpu"
for NNADAPTER_DEVICE_NAME in ${NNADAPTER_DEVICE_NAMES_LIST[@]}
do
  EXPORT_ENVIRONMENT_VARIABLES="$EXPORT_ENVIRONMENT_VARIABLES:./$NNADAPTER_DEVICE_NAME"
done

BUILD_DIR=build.${TARGET_OS}.${TARGET_ABI}

# Please install adb, and DON'T run this in the docker.
set -e
adb $ADB_DEVICE_NAME shell "rm -rf $WORK_SPACE"
adb $ADB_DEVICE_NAME shell "mkdir -p $WORK_SPACE"
adb $ADB_DEVICE_NAME push ../../libs/PaddleLite/$TARGET_OS/$TARGET_ABI/lib/libpaddle_*.so $WORK_SPACE
for NNADAPTER_DEVICE_NAME in ${NNADAPTER_DEVICE_NAMES_LIST[@]}
do
  adb $ADB_DEVICE_NAME push ../../libs/PaddleLite/$TARGET_OS/$TARGET_ABI/lib/$NNADAPTER_DEVICE_NAME/. $WORK_SPACE
done
adb $ADB_DEVICE_NAME push ../../libs/PaddleLite/$TARGET_OS/$TARGET_ABI/lib/cpu/* $WORK_SPACE
adb $ADB_DEVICE_NAME push ../assets/models/$MODEL_NAME $WORK_SPACE
set +e
adb $ADB_DEVICE_NAME push ../assets/models/${MODEL_NAME}.nb $WORK_SPACE
adb $ADB_DEVICE_NAME push ../assets/models/*.nnc $WORK_SPACE
set -e
adb $ADB_DEVICE_NAME push ../assets/labels/. $WORK_SPACE
adb $ADB_DEVICE_NAME push ../assets/images/. $WORK_SPACE
adb $ADB_DEVICE_NAME push $BUILD_DIR/ssd_detection_demo $WORK_SPACE
adb $ADB_DEVICE_NAME shell "cd $WORK_SPACE; $EXPORT_ENVIRONMENT_VARIABLES; ./ssd_detection_demo ./$MODEL_NAME $MODEL_TYPE ./$LABEL_NAME ./$IMAGE_NAME ./$RESULT_NAME $NNADAPTER_DEVICE_NAMES \"$NNADAPTER_CONTEXT_PROPERTIES\" $NNADAPTER_MODEL_CACHE_DIR $NNADAPTER_MODEL_CACHE_TOKEN $NNADAPTER_SUBGRAPH_PARTITION_CONFIG_PATH"
#adb $ADB_DEVICE_NAME shell "cd $WORK_SPACE; $EXPORT_ENVIRONMENT_VARIABLES; ./ssd_detection_demo ./$MODEL_NAME $MODEL_TYPE ./$LABEL_NAME ./$IMAGE_NAME ./$RESULT_NAME $NNADAPTER_DEVICE_NAMES \"$NNADAPTER_CONTEXT_PROPERTIES\" $NNADAPTER_MODEL_CACHE_DIR $NNADAPTER_MODEL_CACHE_TOKEN $NNADAPTER_SUBGRAPH_PARTITION_CONFIG_PATH >${NNADAPTER_DEVICE_NAMES_TEXT}.log 2>&1"
#adb $ADB_DEVICE_NAME pull $WORK_SPACE/${NNADAPTER_DEVICE_NAMES_TEXT}.log .
adb $ADB_DEVICE_NAME pull $WORK_SPACE/${MODEL_NAME}.nb ../assets/models/
adb $ADB_DEVICE_NAME pull $WORK_SPACE/$RESULT_NAME ../assets/results/
