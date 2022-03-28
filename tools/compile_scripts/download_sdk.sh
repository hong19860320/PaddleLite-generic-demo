#!/bin/bash
set -e

readlinkf() {
  perl -MCwd -e 'print Cwd::abs_path shift' "$1";
}

root_dir=$(readlinkf $(pwd)/../../)

sdk_dir=$root_dir/sdk

if [ ! -d sdk_dir ]; then
  rm -rf $sdk_dir
  mkdir $sdk_dir
fi

# amlogic_npu
amlogic_npu_sdk_dir=$sdk_dir/amlogic_npu
# cambricon_mlu
cambricon_mlu_sdk_dir=$sdk_dir/cambricon_mlu
# huawei_ascend_npu
huawei_ascend_npu_sdk_dir=$sdk_dir/huawei_ascend_npu
# huawei_kirin_npu
huawei_kirin_npu_sdk_dir=$sdk_dir/huawei_kirin_npu
# imagination_nna
imagination_nna_sdk_dir=$sdk_dir/imagination_nna
# intel_openvino
intel_openvino_sdk_dir=$sdk_dir/intel_openvino
# mediatek_apu
mediatek_apu_sdk_dir=$sdk_dir/mediatek_apu
# rockchip_npu
rockchip_npu_sdk_dir=$sdk_dir/rockchip_npu

download_amlogic_npu_sdk() {
    local os=$1
    local arch=$2
    mkdir -p $amlogic_npu_sdk_dir/$os/$arch
    cd $amlogic_npu_sdk_dir/$os/$arch
    if [ "$os" = "android" ]; then 
        wget http://paddlelite-demo.bj.bcebos.com/devices/amlogic/android/amlnpu_ddk.tar.gz
        tar -zxvf amlnpu_ddk.tar.gz
    elif [ "$os" = "linux" ]; then
        wget http://paddlelite-demo.bj.bcebos.com/devices/amlogic/linux/amlnpu_ddk.tar.gz
        tar -zxvf amlnpu_ddk.tar.gz
    else
      echo "download_amlogic_npu_sdk is not supported for $os."
    fi
    cd -
    echo "download amlogic npu sdk succeed!"
}

download_cambricon_mlu_sdk() {
    local os=$1
    local arch=$2
    mkdir -p $cambricon_mlu_sdk_dir/$os/$arch
    cd $cambricon_mlu_sdk_dir/$os/$arch
    if [ "$os" = "linux" ]; then 
        if [ "$arch" = "x86" ]; then 
            wget http://paddlelite-demo.bj.bcebos.com/devices/cambricon_mlu/cambricon_mlu_sdk.tar.gz
            tar -zxvf cambricon_mlu_sdk.tar.gz
        else 
            echo "download_cambricon_mlu_sdk is not supported for $os/$arch."
        fi
    else
      echo "download_cambricon_mlu_sdk is not supported for $os."
    fi
    cd -
    echo "download cambricon mlu npu sdk succeed!"
}

download_huawei_kirin_npu_sdk() {
    local os=$1
    local arch=$2
    mkdir -p $huawei_kirin_npu_sdk_dir/$os/$arch
    cd $huawei_kirin_npu_sdk_dir/$os/$arch
    if [ "$os" = "android" ]; then 
        if [ "$arch" = "armv8" ] || [ "$arch" = "armv7" ]; then 
            wget http://paddlelite-demo.bj.bcebos.com/devices/huawei/kirin/hiai_ddk_lib_510.tar.gz
            tar -xvf hiai_ddk_lib_510.tar.gz
        else 
            echo "download_huawei_kirin_npu_sdk is not supported for $os/$arch."
        fi
    else
      echo "download_huawei_kirin_npu_sdk is not supported for $os."
    fi
    cd -
    echo "download huawei kirin npu sdk succeed!"
}

download_huawei_ascend_npu_sdk() {
    local os=$1
    local arch=$2
    mkdir -p $huawei_ascend_npu_sdk_dir/$os/$arch
    cd $huawei_ascend_npu_sdk_dir/$os/$arch
    if [ "$os" = "linux" ]; then 
        if [ "$arch" = "x86" ]; then 
            wget http://paddlelite-demo.bj.bcebos.com/devices/huawei/ascend/intel_x86/3.3.0.alpha001.tar.gz
            tar -zxvf 3.3.0.alpha001.tar.gz
            wget http://paddlelite-demo.bj.bcebos.com/devices/huawei/ascend/intel_x86/5.1.RC1.alpha001.tar.gz
            tar -zxvf 5.1.RC1.alpha001.tar.gz
        elif [ "$arch" = "armv8" ]; then 
            wget http://paddlelite-demo.bj.bcebos.com/devices/huawei/ascend/kunpeng920_arm/5.0.4.alpha002.tar.gz
            tar -zxvf 5.0.4.alpha002.tar.gz
        else 
            echo "download_huawei_ascend_npu_sdk is not supported for $os/$arch."
        fi
    else
      echo "download_huawei_ascend_npu_sdk is not supported for $os."
    fi
    cd -
    echo "download huawei ascend npu sdk succeed!"
}

download_imagination_nna_sdk() {
    local os=$1
    local arch=$2
    mkdir -p $imagination_nna_sdk_dir/$os/$arch
    cd $imagination_nna_sdk_dir/$os/$arch
    if [ "$os" = "linux" ]; then 
        if [ "$arch" = "armv8" ]; then 
            curl -L http://paddlelite-demo.bj.bcebos.com/devices/imagination/imagination_nna_sdk.tar.gz -o - | tar -zx
        else 
            echo "download_imagination_nna_sdk is not supported for $os/$arch."
        fi
    else
      echo "download_imagination_nna_sdk is not supported for $os."
    fi
    cd -
    echo "download imagination nna sdk succeed!"
}

download_rockchip_npu_sdk() {
    local os=$1
    local arch=$2
    mkdir -p $rockchip_npu_sdk_dir/$os/$arch
    cd $rockchip_npu_sdk_dir/$os/$arch
    if [ "$os" = "linux" ]; then 
        if [ "$arch" = "armv8" ] || [ "$arch" = "armv7hf" ]; then 
            git clone http://github.com/airockchip/rknpu_ddk.git
        else 
            echo "download_rockchip_npu_sdk is not supported for $os/$arch."
        fi
    else
      echo "download_rockchip_npu_sdk is not supported for $os."
    fi
    cd -
    echo "download rockchip npu sdk succeed!"
}

download_mediatek_apu_sdk() {
    local os=$1
    local arch=$2
    mkdir -p $mediatek_apu_sdk_dir/$os/$arch
    cd $mediatek_apu_sdk_dir/$os/$arch
    if [ "$os" = "android" ]; then 
        if [ "$arch" = "armv7" ]; then 
            wget http://paddlelite-demo.bj.bcebos.com/devices/mediatek/apu_ddk.tar.gz
            tar -xvf apu_ddk.tar.gz
        else 
            echo "download_mediatek_apu_sdk is not supported for $os/$arch."
        fi
    else
      echo "download_mediatek_apu_sdk is not supported for $os."
    fi
    cd -
    echo "download mediatek apu sdk succeed!"
}

download_intel_openvino_sdk() {
    local os=$1
    local arch=$2
    mkdir -p $intel_openvino_sdk_dir/$os/$arch
    cd $intel_openvino_sdk_dir/$os/$arch
    if [ "$os" = "linux" ]; then 
        if [ "$arch" = "x86" ]; then 
            wget http://paddlelite-demo.bj.bcebos.com/devices/intel/openvino_2022.1.0.643.tar.gz
            tar -zxvf openvino_2022.1.0.643.tar.gz
        else 
            echo "download_intel_openvino_sdk is not supported for $os/$arch."
        fi
    else
      echo "download_intel_openvino_sdk is not supported for $os."
    fi   
    cd -
    echo "download intel openvino sdk succeed!"
}

echo "1/8 "
download_amlogic_npu_sdk linux armv8
download_amlogic_npu_sdk android armv7
echo "2/8 "
download_cambricon_mlu_sdk linux x86
echo "3/8 "
download_huawei_kirin_npu_sdk android armv8
download_huawei_kirin_npu_sdk android armv7
echo "4/8 "
download_imagination_nna_sdk linux armv8
echo "5/8 "
download_rockchip_npu_sdk linux armv8
download_rockchip_npu_sdk linux armv7hf
echo "6/8 "
download_mediatek_apu_sdk android armv7
echo "7/8 "
download_intel_openvino_sdk linux x86
echo "8/8"
download_huawei_ascend_npu_sdk linux x86
download_huawei_ascend_npu_sdk linux armv8
echo "all done."