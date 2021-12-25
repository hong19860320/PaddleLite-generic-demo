import cv2
import numpy as np
from array import array

if __name__ == "__main__":
    src_img_file_path = '../assets/images/tabby_cat.jpg'
    raw_rgb_file_path = '../assets/images/tabby_cat.raw'
    dst_width = 224
    dst_height = 224
    # Decode image and resize it to the target size
    src_image = cv2.imread(src_img_file_path)
    resized_image = cv2.resize(
        src_image, (dst_height, dst_width), fx=0, fy=0, interpolation=cv2.INTER_CUBIC)
    rgb_image = cv2.cvtColor(resized_image, cv2.COLOR_BGR2RGB)
    # Convert to float and dump to file
    rgb_image = rgb_image[:, :, :].astype('float32') / 255.0
    with open(raw_rgb_file_path, "wb") as f:
        rgb_image.tofile(f)
