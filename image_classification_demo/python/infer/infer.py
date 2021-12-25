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

add_arg('model_dir', str, '../../assets/models/mobilenet_v1_fp32_224', 'The directory of target paddle inference model')
add_arg('model_type', str, '0', '0: non-combined 1: combined')
add_arg('label_path', str, '../../assets/labels/synset_words.txt', 'The path of label file')
add_arg('image_path', str, '../../assets/images/tabby_cat.jpg', 'The path of test image file')

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
    c = 3
    w = 224
    h = 224
    with open(ARGS.label_path, "r") as f:
      label_list = f.readlines()
    image_mean = [0.485, 0.456, 0.406]
    image_std = [0.229, 0.224, 0.225]
    image_data = cv2.imread(ARGS.image_path)
    image_data = cv2.resize(image_data, (h, w), fx=0, fy=0, interpolation=cv2.INTER_CUBIC)
    image_data = cv2.cvtColor(image_data, cv2.COLOR_BGR2RGB)
    image_data = image_data.transpose((2, 0, 1)) / 255.0
    image_data = (image_data - np.array(image_mean).reshape((3, 1, 1))) / np.array(image_std).reshape((3, 1, 1))
    image_data = image_data.reshape([1, 3, 224, 224]).astype('float32')
    # Set input tensors, run inference and get output tensors
    image_tensor = fluid.core.LoDTensor()
    image_tensor.set(image_data, place)
    [output_tensor] = exe.run(program=program, feed={"image": image_tensor}, fetch_list=fetch_list, return_numpy=False)
    # Postprocess
    output_data = np.array(output_tensor).flatten()
    class_id = np.argmax(output_data)
    class_name = label_list[class_id]
    score = output_data[class_id]
    print('Top1: %s score: %f' % (class_name, score))

if __name__ == '__main__':
    main()
