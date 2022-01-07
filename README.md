# PaddleLite-generic-demo
Paddle Lite classic demo for AI accelerators

## Demo 1. Image classification demo based on MobileNet, ResNet etc.
```
cd image_classification_demo/shell
```
### Huawei Kirin NPU
- Huawei P40pro 5G
  ```
  ./run_with_adb.sh mobilenet_v1_fp32_224 android arm64-v8a huawei_kirin_npu UQG0220A15000356
  ./run_with_adb.sh resnet50_fp32_224 android arm64-v8a huawei_kirin_npu UQG0220A15000356
  ```
### MediaTek APU
- MediaTek MT8618 Tablet
  ```
  ./run_with_adb.sh mobilenet_v1_int8_224_per_layer android armeabi-v7a mediatek_apu 0123456789ABCDEF
  ./run_with_adb.sh mobilenet_v1_int8_224_per_channel android armeabi-v7a mediatek_apu 0123456789ABCDEF
  ./run_with_adb.sh resnet50_int8_224_per_layer android armeabi-v7a mediatek_apu 0123456789ABCDEF
  ```
### Rockchip NPU
- RK1808EVB
  ```
  ./run_with_adb.sh mobilenet_v1_int8_224_per_layer linux arm64 rockchip_npu a133d8abb26137b2
  ./run_with_adb.sh resnet50_int8_224_per_layer linux arm64 rockchip_npu a133d8abb26137b2
  ```
- Toybirck TB-RK1808S0
  ```
  ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer linux arm64 rockchip_npu 192.168.180.8 22 toybrick toybrick
  ./run_with_ssh.sh resnet50_int8_224_per_layer linux arm64 rockchip_npu 192.168.180.8 22 toybrick toybrick
  ```
- RV1109
  ```
  ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer linux armhf rockchip_npu 192.168.100.13 22 root rockchip
  ./run_with_ssh.sh resnet50_int8_224_per_layer linux armhf rockchip_npu 192.168.100.13 22 root rockchip
  ```
### Amlogic NPU
- Amlogic A311D
  ```
  ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer linux arm64 amlogic_npu 192.168.100.244 22 root 123456
  ./run_with_ssh.sh resnet50_int8_224_per_layer linux arm64 amlogic_npu 192.168.100.244 22 root 123456
  ```
### Imagination NNA
- ROC1
  ```
  ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer linux arm64 imagination_nna 192.168.100.10 22 img imgroc1
  ```
### Huawei Ascend NPU
- Intel CPU + Huawei Atlas 300C(3010)
  ```
  ./run_with_ssh.sh mobilenet_v1_fp32_224 linux amd64 huawei_ascend_npu localhost 9022 root root
  ./run_with_ssh.sh resnet50_fp32_224 linux amd64 huawei_ascend_npu localhost 9022 root root
  ```
- Kunpeng 920 + Huawei Atlas 300C(3000)
  ```
  ./run_with_ssh.sh mobilenet_v1_fp32_224 linux arm64 huawei_ascend_npu localhost 9022 root root
  ./run_with_ssh.sh resnet50_fp32_224 linux arm64 huawei_ascend_npu localhost 9022 root root
  ```
### Rockchip NPU and Amlogic NPU with TIM-VX
- Khadas VIM3 on ARMLinux
  ```
  ./run_with_ssh.sh mobilenet_v1_int8_224_per_layer linux arm64 verisilicon_timvx 192.168.100.30 22 khadas khadas
  ./run_with_ssh.sh mobilenet_v1_fp32_224 linux arm64 verisilicon_timvx 192.168.100.30 22 khadas khadas
  ./run_with_ssh.sh resnet50_int8_224_per_layer linux arm64 verisilicon_timvx 192.168.100.30 22 khadas khadas
  ./run_with_ssh.sh resnet50_fp32_224 linux arm64 verisilicon_timvx 192.168.100.30 22 khadas khadas
  ```
### Kunlunxin XPU with XTCL
- Intel CPU + Kunlunxin K100
  ```
  ./run_with_ssh.sh mobilenet_v1_fp32_224 linux amd64 kunlunxin_xtcl localhost 9023 root root
  ./run_with_ssh.sh resnet50_fp32_224 linux amd64 kunlunxin_xtcl localhost 9023 root root
  ```
- ARM CPU + Kunlunxin K100
  ```
  ./run_with_ssh.sh resnet50_fp32_224 linux arm64 kunlunxin_xtcl localhost 9023 root root
  ./run_with_ssh.sh mobilenet_v1_fp32_224 linux arm64 kunlunxin_xtcl localhost 9023 root root
  ```
### Cambricon MLU
- Intel CPU + Cambricon MLU 370
  ```
  ./run_with_ssh.sh mobilenet_v1_fp32_224 linux amd64 cambricon_mlu localhost 9031 root root
  ./run_with_ssh.sh resnet50_fp32_224 linux amd64 cambricon_mlu localhost 9031 root root
  ```

## Demo 2. Object detection demo based on SSD
```
cd ssd_detection_demo/shell
```
### Huawei Kirin NPU
- Huawei P40pro 5G
  ```
  ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_fp32_300 android arm64-v8a huawei_kirin_npu UQG0220A15000356
  ```
### MediaTek APU
- MediaTek MT8618 Tablet
  ```
  ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer android armeabi-v7a mediatek_apu 0123456789ABCDEF
  ```
### Rockchip NPU
- RK1808EVB
  ```
  ./run_with_adb.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux arm64 rockchip_npu a133d8abb26137b2
  ```
- Toybirck TB-RK1808S0
  ```
  ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux arm64 rockchip_npu 192.168.180.8 22 toybrick toybrick
  ```
- RV1109
  ```
  ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux armhf rockchip_npu 192.168.100.13 22 root rockchip
  ```
### Amlogic NPU
- Amlogic A311D
  ```
  ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux arm64 amlogic_npu 192.168.100.244 22 root 123456
  ```
### Imagination NNA
- ROC1
  ```
  ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux arm64 imagination_nna 192.168.100.10 22 img imgroc1
  ```
### Huawei Ascend NPU
- Intel CPU + Huawei Atlas 300C(3010)
  ```
  ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 linux amd64 huawei_ascend_npu localhost 9022 root root
  ```
- Kunpeng 920 + Huawei Atlas 300C(3000)
  ```
  ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 linux arm64 huawei_ascend_npu localhost 9022 root root
  ```
### Rockchip NPU and Amlogic NPU with TIM-VX
- Khadas VIM3 on ARMLinux
  ```
  ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_int8_300_per_layer linux arm64 verisilicon_timvx 192.168.100.30 22 khadas khadas
  ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 linux arm64 verisilicon_timvx 192.168.100.30 22 khadas khadas
  ```
### Kunlunxin XPU with XTCL
- Intel CPU + Kunlunxin K100
  ```
  ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 linux amd64 kunlunxin_xtcl localhost 9023 root root
  ```
- ARM CPU + Kunlunxin K100
  ```
  ./run_with_ssh.sh ssd_mobilenet_v1_relu_voc_fp32_300 linux arm64 kunlunxin_xtcl localhost 9023 root root
  ```

## Demo 3. Object detection demo based on YOLO
```
cd yolo_detection_demo/shell
```
### Huawei Ascend NPU
- Intel CPU + Huawei Atlas 300C(3010)
  ```
  ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 linux amd64 huawei_ascend_npu localhost 9022 root root
  ```
- Kunpeng 920 + Huawei Atlas 300C(3000)
  ```
  ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 linux arm64 huawei_ascend_npu localhost 9022 root root
  ```
### Kunlunxin XPU with XTCL
- Intel CPU + Kunlunxin K100
  ```
  ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 linux amd64 kunlunxin_xtcl localhost 9023 root root
  ```
- ARM CPU + Kunlunxin K100
  ```
  ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 linux arm64 kunlunxin_xtcl localhost 9023 root root
  ```
### Cambricon MLU
- Intel CPU + Cambricon MLU 370
  ```
  ./run_with_ssh.sh yolov3_mobilenet_v1_270e_coco_fp32_608 linux amd64 cambricon_mlu localhost 9031 root root
  ```

## Demo 4. Model test for benchmark or hardware adaptation based on Paddle Lite + NNAdapter
```
cd model_test/shell
```
### Huawei Kirin NPU
- Huawei P40pro 5G
  ```
  ./run_with_adb.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 android arm64-v8a huawei_kirin_npu UQG0220A15000356
  ```
### MediaTek APU
- MediaTek MT8618 Tablet
  ```
  ./run_with_adb.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 android armeabi-v7a mediatek_apu 0123456789ABCDEF
  ./run_with_adb.sh conv_bn_relu_224_int8_per_channel 0 1,3,224,224 float32 float32 android armeabi-v7a mediatek_apu 0123456789ABCDEF
  ```
### Rockchip NPU
- RK1808EVB
  ```
  ./run_with_adb.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux arm64 rockchip_npu a133d8abb26137b2
  ```
- Toybirck TB-RK1808S0
  ```
  ./run_with_ssh.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux arm64 rockchip_npu 192.168.180.8 22 toybrick toybrick
  ```
- RV1109
  ```
  ./run_with_ssh.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux armhf rockchip_npu 192.168.100.13 22 root rockchip
  ```
### Amlogic NPU
- Amlogic A311D
  ```
  ./run_with_ssh.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux arm64 amlogic_npu 192.168.100.244 22 root 123456
  ```
### Imagination NNA
- ROC1
  ```
  ./run_with_ssh.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux arm64 imagination_nna 192.168.100.10 22 img imgroc1
  ```
### Huawei Ascend NPU
- Intel CPU + Huawei Atlas 300C(3010)
  ```
  ./run_with_ssh.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 linux amd64 huawei_ascend_npu localhost 9022 root root
  ```
- Kunpeng 920 + Huawei Atlas 300C(3000)
  ```
  ./run_with_ssh.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 linux arm64 huawei_ascend_npu localhost 9022 root root
  ```
### Rockchip NPU and Amlogic NPU with TIM-VX
- Khadas VIM3 on ARMLinux
  ```
  ./run_with_ssh.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 linux arm64 verisilicon_timvx 192.168.100.30 22 khadas khadas
  ./run_with_ssh.sh conv_add_144_192_int8_per_layer 0 1,3,192,144 float32 float32 linux arm64 verisilicon_timvx 192.168.100.30 22 khadas khadas
  ```
### Kunlunxin XPU with XTCL
- Intel CPU + Kunlunxin K100
  ```
  ./run_with_ssh.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 linux amd64 kunlunxin_xtcl localhost 9023 root root
  ```
- ARM CPU + Kunlunxin K100
  ```
  ./run_with_ssh.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 linux arm64 kunlunxin_xtcl localhost 9023 root root
  ```
### Cambricon MLU
- Intel CPU + Cambricon MLU 370
  ```
  ./run_with_ssh.sh conv_bn_relu_224_fp32 0 1,3,224,224 float32 float32 linux amd64 cambricon_mlu localhost 9031 root root
  ```
