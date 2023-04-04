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

SRC_MODEL_DIR = "./input_model"
DST_MODEL_DIR = "./output_model"
MODEL_FILE = "model.pdmodel"
PARAMS_FILE = "model.pdiparams"

#MODEL_FILE = ""
#PARAMS_FILE = ""


def convert_paddle_dtype_numpy_dtype(paddle_dtype):
    if paddle_dtype == core.VarDesc.VarType.FP32:
        return np.float32
    elif paddle_dtype == core.VarDesc.VarType.FP64:
        return np.float64
    elif paddle_dtype == core.VarDesc.VarType.FP16:
        return np.float16
    elif paddle_dtype == core.VarDesc.VarType.INT32:
        return np.int32
    elif paddle_dtype == core.VarDesc.VarType.INT16:
        return np.int16
    elif paddle_dtype == core.VarDesc.VarType.INT64:
        return np.int64
    elif paddle_dtype == core.VarDesc.VarType.BOOL:
        return np.bool_
    elif paddle_dtype == core.VarDesc.VarType.BF16:
        return np.uint16
    elif paddle_dtype == core.VarDesc.VarType.UINT8:
        return np.uint8
    elif paddle_dtype == core.VarDesc.VarType.INT8:
        return np.int8
    elif paddle_dtype == core.VarDesc.VarType.COMPLEX64:
        return np.complex64
    elif paddle_dtype == core.VarDesc.VarType.COMPLEX128:
        return np.complex128
    else:
        raise ValueError("Not supported paddle dtype %s" % paddle_dtype)


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
    print('--- origin feed_target_names ---')
    print(feed_target_names)
    print('--- origin fetch_targets ---')
    print(fetch_targets)
    try:
        os.makedirs(DST_MODEL_DIR)
    except OSError as e:
        if e.errno != 17:
            raise
    # Fold fill_constant op to a persistable variable
    scope = fluid.global_scope()
    main_block = program.block(0)
    for i in range(len(main_block.ops)):
        op_desc = main_block.ops[i].desc
        op_type = op_desc.type()
        if op_type == 'fill_constant':
            output_name = op_desc.output("Out")[0]
            print("Found %s!" % output_name)
            output_var = main_block.var(output_name)
            fill_value = op_desc.attr("value")
            numpy_dtype = convert_paddle_dtype_numpy_dtype(output_var.dtype)
            print(fill_value)
            print(numpy_dtype)
            scope.var(output_name).get_tensor().set(np.full(
                output_var.shape, fill_value, dtype=numpy_dtype),
                                                    place)
            output_var.desc.set_persistable(True)
            dummy_output_name = output_name + "_dummy"
            dummy_output_var = main_block.create_var(
                name=dummy_output_name,
                shape=output_var.shape,
                dtype=output_var.dtype,
                type=output_var.type,
                persistable=False,
                stop_gradient=False)
            op_desc.set_output("Out", [dummy_output_name])

    print('--- new feed_target_names ---')
    print(feed_target_names)
    print('--- new fetch_targets ---')
    print(fetch_targets)
    if len(MODEL_FILE) == 0 and len(PARAMS_FILE) == 0:
        fluid.io.save_inference_model(DST_MODEL_DIR, feed_target_names,
                                      fetch_targets, exe, program)
    else:
        fluid.io.save_inference_model(
            DST_MODEL_DIR,
            feed_target_names,
            fetch_targets,
            exe,
            program,
            model_filename=MODEL_FILE,
            params_filename=PARAMS_FILE)
    print("Done.")


if __name__ == '__main__':
    main()
