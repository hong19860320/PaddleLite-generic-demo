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

add_arg('model_dir', str, '../../assets/models/conv_bn_relu_224_fp32', 'The directory of target paddle inference model')
add_arg('model_type', str, '0', '0: non-combined 1: combined')

# parser
ARGS = parser.parse_args()
print_arguments(ARGS)

def main(argv=None):
    # Load paddle inference model
    print('Loading paddle inference model...')
    place = fluid.CPUPlace()
    exe = fluid.Executor(place)
    [program, feed, fetch_list] = fluid.io.load_inference_model(ARGS.model_dir, exe)
    print('--- feed ---')
    print(feed)
    print('--- fetch_list ---')
    print(fetch_list)
    image_data = np.ones([1, 3, 224, 224]).astype('float32')
    image_tensor = fluid.core.LoDTensor()
    image_tensor.set(image_data, place)
    [output_tensor] = exe.run(program=program, feed={"image": image_tensor}, fetch_list=fetch_list, return_numpy=False)
    output_data = np.array(output_tensor).flatten()
    print(output_tensor)

if __name__ == '__main__':
    main()
