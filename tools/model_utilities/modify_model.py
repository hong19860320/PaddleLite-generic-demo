# Copyright (c) 2022 PaddlePaddle Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import numpy as np
import paddle
import paddle.fluid as fluid
from paddle.fluid import core

paddle.enable_static()

src_model_dir = "./simple_model"
dst_model_dir = "./output_model"
model_file = "model.pdmodel"
params_file = "model.pdiparams"

#model_file = ""
#params_file = ""


def main(argv=None):
    place = paddle.CPUPlace()
    exe = paddle.static.Executor(place=place)
    if len(model_file) == 0 and len(params_file) == 0:
        [program, feed_target_names,
         fetch_targets] = fluid.io.load_inference_model(src_model_dir, exe)
    else:
        [program, feed_target_names,
         fetch_targets] = fluid.io.load_inference_model(
             src_model_dir,
             exe,
             model_filename=model_file,
             params_filename=params_file)
    print('--- origin feed_target_names ---')
    print(feed_target_names)
    print('--- origin fetch_targets ---')
    print(fetch_targets)
    try:
        os.makedirs(dst_model_dir)
    except OSError as e:
        if e.errno != 17:
            raise
    # Update the attributes of the specified op, which is uniquely determined by the op type and the output variable name.
    main_block = program.block(0)
    for i in range(len(main_block.ops)):
        op_desc = main_block.ops[i].desc
        if op_desc.type() == "batch_norm":
            out_name = op_desc.output("Y")[0]
            if out_name == "batch_norm_0.tmp_2":
                op_desc._set_attr('momentum', 0.1)
    print('--- new feed_target_names ---')
    print(feed_target_names)
    print('--- new fetch_targets ---')
    print(fetch_targets)
    if len(model_file) == 0 and len(params_file) == 0:
        fluid.io.save_inference_model(dst_model_dir, feed_target_names,
                                      fetch_targets, exe, program)
    else:
        fluid.io.save_inference_model(
            dst_model_dir,
            feed_target_names,
            fetch_targets,
            exe,
            program,
            model_filename=model_file,
            params_filename=params_file)


if __name__ == '__main__':
    main()
