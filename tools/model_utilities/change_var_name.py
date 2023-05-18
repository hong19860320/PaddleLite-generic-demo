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

SRC_MODEL_DIR = "./simple_model"
DST_MODEL_DIR = "./output_model"
MODEL_FILE = "model.pdmodel"
PARAMS_FILE = "model.pdiparams"

#MODEL_FILE = ""
#PARAMS_FILE = ""


def main(argv=None):
    place = paddle.CPUPlace()
    exe = paddle.static.Executor(place=place)
    if len(MODEL_FILE) == 0 and len(PARAMS_FILE) == 0:
        [program, feed_target_names,
         fetch_targets] = fluid.io.load_inference_model(SRC_MODEL_DIR, exe)
    else:
        [program, feed_target_names,
         fetch_targets] = fluid.io.load_inference_model(
             SRC_MODEL_DIR,
             exe,
             model_filename=MODEL_FILE,
             params_filename=PARAMS_FILE)
    exe.run(paddle.static.default_startup_program())
    print('--- feed_target_names ---')
    print(feed_target_names)
    print('--- fetch_targets ---')
    print(fetch_targets)
    try:
        os.makedirs(DST_MODEL_DIR)
    except OSError as e:
        if e.errno != 17:
            raise
    # Specify a named variable
    old_name = "batch_norm_0.tmp_3"
    new_name = "custom_var_name"
    main_block = program.block(0)
    old_var = main_block.var(old_name)
    new_var = main_block.create_var(
        name=new_name,
        shape=old_var.shape,
        dtype=old_var.dtype,
        type=old_var.type,
        persistable=False,
        stop_gradient=False)
    for i in range(len(main_block.ops)):
        op_desc = main_block.ops[i].desc
        op_type = op_desc.type()
        found = False
        for arg_name in op_desc.inputs():
            in_names = op_desc.input(arg_name)
            for j in range(len(in_names)):
                if in_names[j] == old_name:
                    print("Found in inputs of op %s!" % op_type)
                    found = True
                    in_names[j] = new_name
                    op_desc.set_input(arg_name, in_names)
                    break
            if found:
                break
        found = False
        for arg_name in op_desc.outputs():
            out_names = op_desc.output(arg_name)
            for j in range(len(out_names)):
                if out_names[j] == old_name:
                    print("Found in outputs of op %s!" % op_type)
                    found = True
                    out_names[j] = new_name
                    op_desc.set_output(arg_name, out_names)
                    break
            if found:
                break
        if found:
            break
    for i in range(len(feed_target_names)):
        if feed_target_names[i] == old_name:
            print("Found in feed target names!")
            feed_target_names[i] = new_name
            break
    for i in range(len(fetch_targets)):
        if fetch_targets[i].name == old_name:
            print("Found in fetch targets!")
            fetch_targets[i] = new_var
            break
    if len(MODEL_FILE) == 0 and len(PARAMS_FILE) == 0:
        fluid.io.save_inference_model(
            DST_MODEL_DIR,
            feed_target_names,
            fetch_targets,
            exe,
            main_program=program)
    else:
        fluid.io.save_inference_model(
            DST_MODEL_DIR,
            feed_target_names,
            fetch_targets,
            exe,
            main_program=program,
            model_filename=MODEL_FILE,
            params_filename=PARAMS_FILE)
    print("Done.")


if __name__ == '__main__':
    main()
