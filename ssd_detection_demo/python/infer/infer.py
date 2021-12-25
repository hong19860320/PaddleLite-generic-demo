import os
import time
import cv2
import argparse
import functools
import numpy as np
import paddle
import paddle.fluid as fluid
from paddle.fluid import core

from utility import add_arguments
from utility import print_arguments

paddle.enable_static()

np.random.seed(10)
parser = argparse.ArgumentParser(description=__doc__)
add_arg = functools.partial(add_arguments, argparser=parser)

add_arg('model_dir', str, '../../assets/models/ssd_mobilenet_v1_relu_voc_fp32_300', 'The directory of target paddle inference model')
add_arg('model_type', str, '0', '0: non-combined 1: combined')
add_arg('label_path', str, '../../assets/labels/pascalvoc_label_list', 'The path of label file')
add_arg('image_path', str, '../../assets/images/dog.jpg', 'The path of test image file')
add_arg('result_path', str, '../../assets/results/dog.jpg', 'The path of result image file')

# parser
ARGS = parser.parse_args()
print_arguments(ARGS)

def main(argv=None):
    # Load paddle inference model
    print('Loading paddle inference model...')
    place = fluid.CPUPlace()
    exe = fluid.Executor(place)
    if ARGS.model_type == '1':
      [program, feed, fetch_list] = fluid.io.load_inference_model(ARGS.model_dir, exe, model_filename="model", params_filename="params")
    else:
      [program, feed, fetch_list] = fluid.io.load_inference_model(ARGS.model_dir, exe)
    print('--- feed ---')
    print(feed)
    print('--- fetch_list ---')
    print(fetch_list)
    # Load image and preprocess
    w = 300
    h = 300
    score_threshold = 0.5
    image_mean = [0.485, 0.456, 0.406]
    image_std = [0.229, 0.224, 0.225]
    origin_image = cv2.imread(ARGS.image_path)
    resized_image = cv2.resize(origin_image, (h, w), fx=0, fy=0, interpolation=cv2.INTER_CUBIC)
    image_data = cv2.cvtColor(resized_image, cv2.COLOR_BGR2RGB)
    image_data = image_data.transpose((2, 0, 1)) / 255.0
    image_data = (image_data - np.array(image_mean).reshape((3, 1, 1))) / np.array(image_std).reshape((3, 1, 1))
    image_data = image_data.reshape([1, 3, h, w]).astype('float32')
    # Set input tensors, run inference and get output tensors
    image_tensor = fluid.core.LoDTensor()
    image_tensor.set(image_data, place)
    output_tensors = exe.run(program=program, feed={"image": image_tensor}, fetch_list=fetch_list, return_numpy=False)
    # Postprocess
    bbox = np.array(output_tensors[0])
    print(bbox)
    num = bbox.shape[0]
    print(num)
    for i in range(num) :
        class_id = bbox[i][0]
        score = bbox[i][1]
        if score > score_threshold:
            x0 = bbox[i][2]
            y0 = bbox[i][3]
            x1 = bbox[i][4]
            y1 = bbox[i][5]
            print("[%d] class_id=%f score=%f bbox=[%f,%f,%f,%f]" %(i, class_id, score, x0, y0, x1, y1))
            x0 = max(int(x0 * origin_image.shape[1]), 0)
            y0 = max(int(y0 * origin_image.shape[0]), 0)
            x1 = min(int(x1 * origin_image.shape[1]), origin_image.shape[1])
            y1 = min(int(y1 * origin_image.shape[0]), origin_image.shape[0])
            cv2.rectangle(origin_image, (x0, y0), (x1, y1),  (0, 255, 0), 4)
    cv2.imwrite(ARGS.result_path, origin_image)

if __name__ == '__main__':
    main()
