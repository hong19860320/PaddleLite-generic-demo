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

import cv2
import numpy as np
from array import array

if __name__ == "__main__":
    src_img_file_path = '../assets/images/dog.jpg'
    raw_rgb_file_path = '../assets/images/dog.raw'
    dst_width = 416
    dst_height = 416
    # Decode image and resize it to the target size
    src_image = cv2.imread(src_img_file_path)
    resized_image = cv2.resize(
        src_image, (dst_height, dst_width),
        fx=0,
        fy=0,
        interpolation=cv2.INTER_CUBIC)
    rgb_image = cv2.cvtColor(resized_image, cv2.COLOR_BGR2RGB)
    # Convert to float and dump to file
    rgb_image = rgb_image[:, :, :].astype('float32') / 255.0
    with open(raw_rgb_file_path, "wb") as f:
        rgb_image.tofile(f)
