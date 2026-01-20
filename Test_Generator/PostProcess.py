import numpy as np
import os

os.system("python Test_Generator/Conv.py")
print()

img_size = 0
oc = 0
Q = input("Enter quantization factor (e.g., 9): ")

# relu and quantization
with open('Test_Generator/data/config.txt', 'r') as f:
    config = f.readline().strip().split()
    img_size = int(config[2])
    oc = int(config[3]) * 16

with open('Test_Generator/data/config.txt', 'a') as f:
    f.write(f'{Q}\n')

ofm = np.zeros(dtype = np.int32, shape=(img_size * img_size * oc))

# ReLU and Quantization
with open('Test_Generator/data/golden.txt', 'r') as f:
    for i in range(img_size * img_size * oc):
        value = int(f.readline().strip(), 16)
        if value & 0x80000000:
            value -= 0x100000000
        value = value >> int(Q)
        if value < 0:
            ofm[i] = 0
        elif value > 127:
            ofm[i] = 127
        else:
            ofm[i] = value

# Save activated data as hexadecimal
with open('Test_Generator/data/golden_activated.txt', 'w') as f:
    for value in ofm.flatten():
        f.write(f"{value:02x}\n")
