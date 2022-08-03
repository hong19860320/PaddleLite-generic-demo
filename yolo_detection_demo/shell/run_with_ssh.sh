#!/bin/bash
MODEL_NAME=yolov3_mobilenet_v1_270e_coco_fp32_608
#MODEL_NAME=yolov3_darknet53_270e_coco_fp32_608
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

DEMO_NAME=yolo_detection_demo
MODEL_TYPE=1 # 1 combined paddle fluid model
LABEL_NAME=coco-labels-2014_2017.txt
IMAGE_NAME=dog.raw
RESULT_NAME=dog.bin
WORK_SPACE="/var/tmp/test"
FILE_TRANSFER_COMMAND=$FILE_TRANSFER_COMMAND
if [ -z "$FILE_TRANSFER_COMMAND" ]; then
  FILE_TRANSFER_COMMAND=scp # Only supports scp and lftp, use 'sudo apt-get install lftp' to install lftp, default is scp
fi

# For TARGET_OS=android, TARGET_ABI should be arm64-v8a or armeabi-v7a.
# For TARGET_OS=linux, TARGET_ABI should be arm64, armhf or amd64.
# Kirin810/820/985/990/9000/9000E: TARGET_OS=android and TARGET_ABI=arm64-v8a
# MT8168/8175, Kirin810/820/985/990/9000/9000E: TARGET_OS=android and TARGET_ABI=armeabi-v7a
# RK1808EVB, TB-RK1808S0: TARGET_OS=linux and TARGET_ABI=arm64
# RK1806EVB, RV1109/1126 EVB: TARGET_OS=linux and TARGET_ABI=armhf
# Intel-x86+CambriconMLU: TARGET_OS=linux and TARGET_ABI=amd64
TARGET_OS=linux
if [ -n "$2" ]; then
  TARGET_OS=$2
fi

if [ "$TARGET_OS" == "android" ]; then
  WORK_SPACE=/data/local/tmp/test
fi

TARGET_ABI=arm64
if [ -n "$3" ]; then
  TARGET_ABI=$3
fi

# RK1808EVB, TB-RK1808S0, RK1806EVB, RV1109/1126 EVB: NNADAPTER_DEVICE_NAMES=rockchip_npu
# MT8168/8175: NNADAPTER_DEVICE_NAMES=mediatek_apu
# Kirin810/820/985/990/9000/9000E: NNADAPTER_DEVICE_NAMES=huawei_kirin_npu
# Ascend310: NNADAPTER_DEVICE_NAMES=huawei_ascend_npu
# CambriconMLU: NNADAPTER_DEVICE_NAMES=cambricon_mlu
# CPU only: NNADAPTER_DEVICE_NAMES=cpu
NNADAPTER_DEVICE_NAMES="cpu"
if [ -n "$4" ]; then
  NNADAPTER_DEVICE_NAMES="$4"
fi
NNADAPTER_DEVICE_NAMES_LIST=(${NNADAPTER_DEVICE_NAMES//,/ })
NNADAPTER_DEVICE_NAMES_TEXT=${NNADAPTER_DEVICE_NAMES//,/_}

SSH_DEVICE_IP_ADDR="192.168.180.8"
if [ -n "$5" ]; then
  SSH_DEVICE_IP_ADDR="$5"
fi

SSH_DEVICE_SSH_PORT="22"
if [ -n "$6" ]; then
  SSH_DEVICE_SSH_PORT="$6"
fi

SSH_DEVICE_USR_ID="toybrick"
if [ -n "$7" ]; then
  SSH_DEVICE_USR_ID="$7"
fi

SSH_DEVICE_USR_PWD="toybrick"
if [ -n "$8" ]; then
  SSH_DEVICE_USR_PWD="$8"
fi

if [ -n "$9" ] && [ "$9" != "null" ]; then
  NNADAPTER_CONTEXT_PROPERTIES="$9"
fi

NNADAPTER_MODEL_CACHE_DIR="null"
if [ -n "${10}" ]; then
  NNADAPTER_MODEL_CACHE_DIR="${10}"
fi

NNADAPTER_MODEL_CACHE_TOKEN="null"
if [ -n "${11}" ]; then
  NNADAPTER_MODEL_CACHE_TOKEN="${11}"
fi

#NNADAPTER_SUBGRAPH_PARTITION_CONFIG_PATH="null"
NNADAPTER_SUBGRAPH_PARTITION_CONFIG_PATH="./$MODEL_NAME/${NNADAPTER_DEVICE_NAMES_TEXT}_subgraph_partition_config_file.txt"

EXPORT_ENVIRONMENT_VARIABLES="export GLOG_v=5; export SUBGRAPH_ONLINE_MODE=true;"
if [[ "$NNADAPTER_DEVICE_NAMES" =~ "rockchip_npu" ]]; then
  EXPORT_ENVIRONMENT_VARIABLES="${EXPORT_ENVIRONMENT_VARIABLES}export RKNPU_LOGLEVEL=5; export RKNN_LOG_LEVEL=5; ulimit -c unlimited;"
  sshpass -p $SSH_DEVICE_USR_PWD ssh -v -o ConnectTimeout=60 -o StrictHostKeyChecking=no -p $SSH_DEVICE_SSH_PORT $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR "echo userspace > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"
  sshpass -p $SSH_DEVICE_USR_PWD ssh -v -o ConnectTimeout=60 -o StrictHostKeyChecking=no -p $SSH_DEVICE_SSH_PORT $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR "echo $(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq) > /sys/devices/system/cpu/cpufreq/policy0/scaling_setspeed"
fi

if [[ "$NNADAPTER_DEVICE_NAMES" =~ "amlogic_npu" ]]; then
  sshpass -p $SSH_DEVICE_USR_PWD ssh -v -o ConnectTimeout=60 -o StrictHostKeyChecking=no -p $SSH_DEVICE_SSH_PORT $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR "echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"
fi

if [[ "$NNADAPTER_DEVICE_NAMES" =~ "imagination_nna" ]]; then
  sshpass -p $SSH_DEVICE_USR_PWD ssh -v -o ConnectTimeout=60 -o StrictHostKeyChecking=no -p $SSH_DEVICE_SSH_PORT $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR "echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"
  sshpass -p $SSH_DEVICE_USR_PWD ssh -v -o ConnectTimeout=60 -o StrictHostKeyChecking=no -p $SSH_DEVICE_SSH_PORT $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR "echo performance > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor"
fi

EXPORT_ENVIRONMENT_VARIABLES="${EXPORT_ENVIRONMENT_VARIABLES}export LD_LIBRARY_PATH=."
for NNADAPTER_DEVICE_NAME in ${NNADAPTER_DEVICE_NAMES_LIST[@]}
do
  EXPORT_ENVIRONMENT_VARIABLES="$EXPORT_ENVIRONMENT_VARIABLES:./$NNADAPTER_DEVICE_NAME"
done
EXPORT_ENVIRONMENT_VARIABLES="$EXPORT_ENVIRONMENT_VARIABLES:./cpu:\$LD_LIBRARY_PATH;"

if [[ "$NNADAPTER_DEVICE_NAMES" =~ "huawei_ascend_npu" ]]; then
  HUAWEI_ASCEND_TOOLKIT_HOME="/usr/local/Ascend/ascend-toolkit/latest"
  if [ "$TARGET_OS" == "linux" ]; then
    if [[ "$TARGET_ABI" != "arm64" && "$TARGET_ABI" != "amd64" ]]; then
      echo "Unknown OS $TARGET_OS, only supports 'arm64' or 'amd64' for Huawei Ascend NPU."
      exit -1
    fi
  else
    echo "Unknown OS $TARGET_OS, only supports 'linux' for Huawei Ascend NPU."
    exit -1
  fi
  if [[ ! "$NNADAPTER_CONTEXT_PROPERTIES" =~ "HUAWEI_ASCEND_NPU_SELECTED_DEVICE_IDS" ]]; then
    NNADAPTER_CONTEXT_PROPERTIES="HUAWEI_ASCEND_NPU_SELECTED_DEVICE_IDS=0;${NNADAPTER_CONTEXT_PROPERTIES}"
  fi
  # ASCEND_GLOBAL_LOG_LEVEL=0 for DEBUG, 3 for ERROR
  EXPORT_ENVIRONMENT_VARIABLES="${EXPORT_ENVIRONMENT_VARIABLES}export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/Ascend/driver/lib64/driver:/usr/local/Ascend/driver/lib64:/usr/local/Ascend/driver/lib64/stub:$HUAWEI_ASCEND_TOOLKIT_HOME/acllib/lib64:$HUAWEI_ASCEND_TOOLKIT_HOME/atc/lib64:$HUAWEI_ASCEND_TOOLKIT_HOME/opp/op_proto/built-in; export PYTHONPATH=$PYTHONPATH:$HUAWEI_ASCEND_TOOLKIT_HOME/fwkacllib/python/site-packages:$HUAWEI_ASCEND_TOOLKIT_HOME/acllib/python/site-packages:$HUAWEI_ASCEND_TOOLKIT_HOME/toolkit/python/site-packages:$HUAWEI_ASCEND_TOOLKIT_HOME/atc/python/site-packages:$HUAWEI_ASCEND_TOOLKIT_HOME/pyACL/python/site-packages/acl; export PATH=\$PATH:$HUAWEI_ASCEND_TOOLKIT_HOME/atc/ccec_compiler/bin:${HUAWEI_ASCEND_TOOLKIT_HOME}/acllib/bin:$HUAWEI_ASCEND_TOOLKIT_HOME/atc/bin; export ASCEND_AICPU_PATH=$HUAWEI_ASCEND_TOOLKIT_HOME; export ASCEND_OPP_PATH=$HUAWEI_ASCEND_TOOLKIT_HOME/opp; export TOOLCHAIN_HOME=$HUAWEI_ASCEND_TOOLKIT_HOME/toolkit; export ASCEND_GLOBAL_EVENT_ENABLE=0; export ASCEND_SLOG_PRINT_TO_STDOUT=1; export ASCEND_GLOBAL_LOG_LEVEL=3;"
fi

if [[ "$NNADAPTER_DEVICE_NAMES" =~ "kunlunxin_xtcl" ]]; then
  EXPORT_ENVIRONMENT_VARIABLES="${EXPORT_ENVIRONMENT_VARIABLES}export XTCL_AUTO_ALLOC_L3=1; export XTCL_CONV_USE_FP16=1; export XTCL_QUANTIZE_WEIGHT=1; export XTCL_L3_SIZE=16777216;"
fi

if [[ "$NNADAPTER_DEVICE_NAMES" =~ "cambricon_mlu" ]]; then
  EXPORT_ENVIRONMENT_VARIABLES="${EXPORT_ENVIRONMENT_VARIABLES}export LD_LIBRARY_PATH=/usr/local/neuware/lib64:\$LD_LIBRARY_PATH;"
fi

if [[ "$NNADAPTER_DEVICE_NAMES" =~ "intel_openvino" ]]; then
  if [[ ! "$NNADAPTER_CONTEXT_PROPERTIES" =~ "INTEL_OPENVINO_SELECT_DEVICE_NAMES" ]]; then
    NNADAPTER_CONTEXT_PROPERTIES="INTEL_OPENVINO_SELECT_DEVICE_NAMES=CPU;${NNADAPTER_CONTEXT_PROPERTIES}"
  fi
fi

if [[ "$NNADAPTER_DEVICE_NAMES" =~ "qualcomm_qnn" ]]; then
  EXPORT_ENVIRONMENT_VARIABLES="${EXPORT_ENVIRONMENT_VARIABLES}export ADSP_LIBRARY_PATH=$WORK_SPACE/qualcomm_qnn/hexagon-v68/lib/unsigned;"
  EXPORT_ENVIRONMENT_VARIABLES="${EXPORT_ENVIRONMENT_VARIABLES}export PATH=/ifs/bin:/ifs/usr/bin:/ifs/usr/sbin:/ifs/sbin:/mnt/bin:/mnt/usr/bin:/mnt/usr/sbin:/mnt/sbin:/mnt/scripts:\$PATH;"
  if [[ ! "$NNADAPTER_CONTEXT_PROPERTIES" =~ "QUALCOMM_QNN_DEVICE" ]]; then
    NNADAPTER_CONTEXT_PROPERTIES="QUALCOMM_QNN_DEVICE=HTP;${NNADAPTER_CONTEXT_PROPERTIES}"
  fi
fi

if [ -z "$NNADAPTER_CONTEXT_PROPERTIES" ]; then
  NNADAPTER_CONTEXT_PROPERTIES="null"
fi

BUILD_DIR=build.${TARGET_OS}.${TARGET_ABI}

if [ "$FILE_TRANSFER_COMMAND" == "lftp" ]; then
  set -e
  lftp -e "rm -rf $WORK_SPACE; bye" -u $SSH_DEVICE_USR_ID,$SSH_DEVICE_USR_PWD $SSH_DEVICE_IP_ADDR
  lftp -e "mkdir -p $WORK_SPACE; bye" -u $SSH_DEVICE_USR_ID,$SSH_DEVICE_USR_PWD $SSH_DEVICE_IP_ADDR
  lftp -e "cd $WORK_SPACE; mput ../../libs/PaddleLite/$TARGET_OS/$TARGET_ABI/lib/libpaddle_*.so; bye" -u $SSH_DEVICE_USR_ID,$SSH_DEVICE_USR_PWD $SSH_DEVICE_IP_ADDR
  for NNADAPTER_DEVICE_NAME in ${NNADAPTER_DEVICE_NAMES_LIST[@]}
  do
    lftp -e "cd $WORK_SPACE; mirror -R ../../libs/PaddleLite/$TARGET_OS/$TARGET_ABI/lib/$NNADAPTER_DEVICE_NAME; bye" -u $SSH_DEVICE_USR_ID,$SSH_DEVICE_USR_PWD $SSH_DEVICE_IP_ADDR
  done
  lftp -e "cd $WORK_SPACE; mirror -R ../../libs/PaddleLite/$TARGET_OS/$TARGET_ABI/lib/cpu; bye" -u $SSH_DEVICE_USR_ID,$SSH_DEVICE_USR_PWD $SSH_DEVICE_IP_ADDR
  lftp -e "cd $WORK_SPACE; mirror -R ../assets/models/$MODEL_NAME; bye" -u $SSH_DEVICE_USR_ID,$SSH_DEVICE_USR_PWD $SSH_DEVICE_IP_ADDR
  set +e
  lftp -e "cd $WORK_SPACE; put ../assets/models/$MODEL_NAME.nb; bye" -u $SSH_DEVICE_USR_ID,$SSH_DEVICE_USR_PWD $SSH_DEVICE_IP_ADDR
  if [ "$NNADAPTER_MODEL_CACHE_DIR" != "null" ]; then
    lftp -e "set xfer:clobber on; cd $WORK_SPACE; mirror -R ../assets/models/$NNADAPTER_MODEL_CACHE_DIR; bye" -u $SSH_DEVICE_USR_ID,$SSH_DEVICE_USR_PWD $SSH_DEVICE_IP_ADDR
    lftp -e "mkdir -p $WORK_SPACE/$NNADAPTER_MODEL_CACHE_DIR; bye" -u $SSH_DEVICE_USR_ID,$SSH_DEVICE_USR_PWD $SSH_DEVICE_IP_ADDR
  fi
  set -e
  lftp -e "cd $WORK_SPACE; mput ../assets/labels/*; bye" -u $SSH_DEVICE_USR_ID,$SSH_DEVICE_USR_PWD $SSH_DEVICE_IP_ADDR
  lftp -e "cd $WORK_SPACE; mput ../assets/images/*; bye" -u $SSH_DEVICE_USR_ID,$SSH_DEVICE_USR_PWD $SSH_DEVICE_IP_ADDR
  lftp -e "cd $WORK_SPACE; put $BUILD_DIR/$DEMO_NAME; bye" -u $SSH_DEVICE_USR_ID,$SSH_DEVICE_USR_PWD $SSH_DEVICE_IP_ADDR
  sshpass -p $SSH_DEVICE_USR_PWD ssh -v -o ConnectTimeout=60 -o StrictHostKeyChecking=no -p $SSH_DEVICE_SSH_PORT $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR "cd $WORK_SPACE; ${EXPORT_ENVIRONMENT_VARIABLES} chmod +x ./$DEMO_NAME; ./$DEMO_NAME ./$MODEL_NAME $MODEL_TYPE ./$LABEL_NAME ./$IMAGE_NAME ./$RESULT_NAME $NNADAPTER_DEVICE_NAMES \"$NNADAPTER_CONTEXT_PROPERTIES\" $NNADAPTER_MODEL_CACHE_DIR $NNADAPTER_MODEL_CACHE_TOKEN $NNADAPTER_SUBGRAPH_PARTITION_CONFIG_PATH"
  #sshpass -p $SSH_DEVICE_USR_PWD ssh -v -o ConnectTimeout=60 -o StrictHostKeyChecking=no -p $SSH_DEVICE_SSH_PORT $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR "cd $WORK_SPACE; ${EXPORT_ENVIRONMENT_VARIABLES} chmod +x ./$DEMO_NAME; ./$DEMO_NAME ./$MODEL_NAME $MODEL_TYPE ./$LABEL_NAME ./$IMAGE_NAME ./$RESULT_NAME $NNADAPTER_DEVICE_NAMES \"$NNADAPTER_CONTEXT_PROPERTIES\" $NNADAPTER_MODEL_CACHE_DIR $NNADAPTER_MODEL_CACHE_TOKEN $NNADAPTER_SUBGRAPH_PARTITION_CONFIG_PATH >${NNADAPTER_DEVICE_NAMES_TEXT}.log 2>&1"
  #lftp -e "set xfer:clobber on; cd $WORK_SPACE; get ${NNADAPTER_DEVICE_NAMES_TEXT}.log; bye" -u $SSH_DEVICE_USR_ID,$SSH_DEVICE_USR_PWD $SSH_DEVICE_IP_ADDR
  lftp -e "set xfer:clobber on; cd $WORK_SPACE; get ${MODEL_NAME}.nb -o ../assets/models/; bye" -u $SSH_DEVICE_USR_ID,$SSH_DEVICE_USR_PWD $SSH_DEVICE_IP_ADDR
  lftp -e "set xfer:clobber on; cd $WORK_SPACE; get ${RESULT_NAME} -o ../assets/results/; bye" -u $SSH_DEVICE_USR_ID,$SSH_DEVICE_USR_PWD $SSH_DEVICE_IP_ADDR
  if [ "$NNADAPTER_MODEL_CACHE_DIR" != "null" ]; then
    lftp -e "set xfer:clobber on; cd $WORK_SPACE; mirror $NNADAPTER_MODEL_CACHE_DIR ../assets/models/; bye" -u $SSH_DEVICE_USR_ID,$SSH_DEVICE_USR_PWD $SSH_DEVICE_IP_ADDR
  fi
else
  set -e
  sshpass -p $SSH_DEVICE_USR_PWD ssh -v -o ConnectTimeout=60 -o StrictHostKeyChecking=no -p $SSH_DEVICE_SSH_PORT $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR "rm -rf $WORK_SPACE"
  sshpass -p $SSH_DEVICE_USR_PWD ssh -v -o ConnectTimeout=60 -o StrictHostKeyChecking=no -p $SSH_DEVICE_SSH_PORT $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR "mkdir -p $WORK_SPACE"
  sshpass -p $SSH_DEVICE_USR_PWD scp -v -r -o ConnectTimeout=60 -o StrictHostKeyChecking=no -P $SSH_DEVICE_SSH_PORT ../../libs/PaddleLite/$TARGET_OS/$TARGET_ABI/lib/libpaddle_*.so $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR:$WORK_SPACE
  for NNADAPTER_DEVICE_NAME in ${NNADAPTER_DEVICE_NAMES_LIST[@]}
  do
    sshpass -p $SSH_DEVICE_USR_PWD scp -v -r -o ConnectTimeout=60 -o StrictHostKeyChecking=no -P $SSH_DEVICE_SSH_PORT ../../libs/PaddleLite/$TARGET_OS/$TARGET_ABI/lib/$NNADAPTER_DEVICE_NAME $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR:$WORK_SPACE
  done
  sshpass -p $SSH_DEVICE_USR_PWD scp -v -r -o ConnectTimeout=60 -o StrictHostKeyChecking=no -P $SSH_DEVICE_SSH_PORT ../../libs/PaddleLite/$TARGET_OS/$TARGET_ABI/lib/cpu $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR:$WORK_SPACE
  sshpass -p $SSH_DEVICE_USR_PWD scp -v -r -o ConnectTimeout=60 -o StrictHostKeyChecking=no -P $SSH_DEVICE_SSH_PORT ../assets/models/${MODEL_NAME} $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR:$WORK_SPACE
  set +e
  sshpass -p $SSH_DEVICE_USR_PWD scp -v -r -o ConnectTimeout=60 -o StrictHostKeyChecking=no -P $SSH_DEVICE_SSH_PORT ../assets/models/${MODEL_NAME}.nb $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR:$WORK_SPACE
  if [ "$NNADAPTER_MODEL_CACHE_DIR" != "null" ]; then
    sshpass -p $SSH_DEVICE_USR_PWD scp -v -r -o ConnectTimeout=60 -o StrictHostKeyChecking=no -P $SSH_DEVICE_SSH_PORT ../assets/models/$NNADAPTER_MODEL_CACHE_DIR $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR:$WORK_SPACE
    sshpass -p $SSH_DEVICE_USR_PWD ssh -v -o ConnectTimeout=60 -o StrictHostKeyChecking=no -p $SSH_DEVICE_SSH_PORT $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR "mkdir -p $WORK_SPACE/$NNADAPTER_MODEL_CACHE_DIR"
  fi
  set -e
  sshpass -p $SSH_DEVICE_USR_PWD scp -v -r -o ConnectTimeout=60 -o StrictHostKeyChecking=no -P $SSH_DEVICE_SSH_PORT ../assets/labels/* $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR:$WORK_SPACE
  sshpass -p $SSH_DEVICE_USR_PWD scp -v -r -o ConnectTimeout=60 -o StrictHostKeyChecking=no -P $SSH_DEVICE_SSH_PORT ../assets/images/* $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR:$WORK_SPACE
  sshpass -p $SSH_DEVICE_USR_PWD scp -v -o ConnectTimeout=60 -o StrictHostKeyChecking=no -P $SSH_DEVICE_SSH_PORT $BUILD_DIR/$DEMO_NAME $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR:$WORK_SPACE
  sshpass -p $SSH_DEVICE_USR_PWD ssh -v -o ConnectTimeout=60 -o StrictHostKeyChecking=no -p $SSH_DEVICE_SSH_PORT $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR "cd $WORK_SPACE; ${EXPORT_ENVIRONMENT_VARIABLES} chmod +x ./$DEMO_NAME; ./$DEMO_NAME ./$MODEL_NAME $MODEL_TYPE ./$LABEL_NAME ./$IMAGE_NAME ./$RESULT_NAME $NNADAPTER_DEVICE_NAMES \"$NNADAPTER_CONTEXT_PROPERTIES\" $NNADAPTER_MODEL_CACHE_DIR $NNADAPTER_MODEL_CACHE_TOKEN $NNADAPTER_SUBGRAPH_PARTITION_CONFIG_PATH"
  #sshpass -p $SSH_DEVICE_USR_PWD ssh -v -o ConnectTimeout=60 -o StrictHostKeyChecking=no -p $SSH_DEVICE_SSH_PORT $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR "cd $WORK_SPACE; ${EXPORT_ENVIRONMENT_VARIABLES} chmod +x ./$DEMO_NAME; ./$DEMO_NAME ./$MODEL_NAME $MODEL_TYPE ./$LABEL_NAME ./$IMAGE_NAME ./$RESULT_NAME $NNADAPTER_DEVICE_NAMES \"$NNADAPTER_CONTEXT_PROPERTIES\" $NNADAPTER_MODEL_CACHE_DIR $NNADAPTER_MODEL_CACHE_TOKEN $NNADAPTER_SUBGRAPH_PARTITION_CONFIG_PATH >${NNADAPTER_DEVICE_NAMES_TEXT}.log 2>&1"
  #sshpass -p $SSH_DEVICE_USR_PWD scp -v -o ConnectTimeout=60 -o StrictHostKeyChecking=no -P $SSH_DEVICE_SSH_PORT $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR:$WORK_SPACE/${NNADAPTER_DEVICE_NAMES_TEXT}.log .
  sshpass -p $SSH_DEVICE_USR_PWD scp -v -o ConnectTimeout=60 -o StrictHostKeyChecking=no -P $SSH_DEVICE_SSH_PORT $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR:$WORK_SPACE/${MODEL_NAME}.nb ../assets/models/
  sshpass -p $SSH_DEVICE_USR_PWD scp -v -o ConnectTimeout=60 -o StrictHostKeyChecking=no -P $SSH_DEVICE_SSH_PORT $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR:$WORK_SPACE/${RESULT_NAME} ../assets/results/
  if [ "$NNADAPTER_MODEL_CACHE_DIR" != "null" ]; then
    sshpass -p $SSH_DEVICE_USR_PWD scp -v -r -o ConnectTimeout=60 -o StrictHostKeyChecking=no -P $SSH_DEVICE_SSH_PORT $SSH_DEVICE_USR_ID@$SSH_DEVICE_IP_ADDR:$WORK_SPACE/$NNADAPTER_MODEL_CACHE_DIR ../assets/models/
  fi
fi
