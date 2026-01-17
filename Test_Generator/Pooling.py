import numpy as np
import os

np.random.seed(114514)

img_size = input("Enter image size (e.g., 5 for 5x5): ")
ic = input("Enter number of input channels (e.g., 64): ")
out_size = input("Enter output feature map size (e.g., 5 for 5x5): ")
oc = ic
kernel_size = input("Enter kernel size (e.g., 3 for 3x3): ")
stride = input("Enter stride (e.g., 1): ")
padding = 0
pooling_type = int(input("Enter pooling type (0 for MAX, 1 for AVG): "))

IFM_H, IFM_W, IFM_C = int(img_size), int(img_size), int(ic)
OFM_H, OFM_W, OFM_C = int(out_size), int(out_size), int(oc)
K_H, K_W = int(kernel_size), int(kernel_size)
STRIDE = int(stride)
PAD = int(padding)

os.makedirs('Test_Generator/data', exist_ok=True)

with open('Test_Generator/data/config.txt', 'w') as f:
    f.write(f'{IFM_H} {IFM_C//16} {OFM_H} {OFM_C//16} {K_H} {STRIDE} {PAD}\n')
    f.write(f'{pooling_type}\n')

ifm = np.random.randint(-50, 50, size=(IFM_C, IFM_H, IFM_W)).astype(np.int8)

ofm = np.zeros((OFM_C, OFM_H, OFM_W), dtype=np.int32)

print("Computing Golden Model...")
for oc in range(OFM_C):
    for oh in range(OFM_H):
        for ow in range(OFM_W):
            val = 0
            # Spatial loop
            for kh in range(K_H):
                for kw in range(K_W):
                    # Input coords
                    ih = oh * STRIDE + kh
                    iw = ow * STRIDE + kw
                    val = int(ifm[oc, ih, iw])
                    if pooling_type == 0:
                        ofm[oc, oh, ow] = max(ofm[oc, oh, ow], val)
                    else:
                        # division leaved to post-processing (Q)
                        ofm[oc, oh, ow] += val

# Transpose to (H, W, C)
ifm_transposed = ifm.transpose(1, 2, 0)
# Flatten
ifm_u8 = ifm_transposed.flatten().astype(np.uint8)
np.savetxt('Test_Generator/data/ifm.txt', ifm_u8, fmt='%02x')

# Transpose to (H, W, C)
ofm_transposed = ofm.transpose(1, 2, 0)
# Flatten
ofm_flat = ofm_transposed.flatten()
# Use a custom format for 32-bit signed integers
with open('Test_Generator/data/golden.txt', 'w') as f:
    for val in ofm_flat:
        # Handle negative numbers for 32-bit hex
        val = int(val)
        val_u32 = val & 0xFFFFFFFF
        f.write(f'{val_u32:08x}\n')

print("Data generation complete.")
