# ifm = []
# ifm.append([0 for _ in range(36)])
# ifm.append([0 for _ in range(36)])
# for _ in range(32):
#     ifm.append([0, 0] + [i for i in range(32)] + [0, 0])
# ifm.append([0 for _ in range(36)])
# ifm.append([0 for _ in range(36)])

# filter = []
# for _ in range(5):
#     filter.append([i+1 for i in range(5)])

# def conv(i, j):
#     sum = 0
#     for fi in range(5):
#         for fj in range(5):
#             sum += ifm[i + fi][j + fj] * filter[fi][fj]
#     return sum

# for i in range(32):
#     row = []
#     for j in range(32):
#         row.append(conv(i, j) % 256)
#     print(row)

import random

random.seed(114514)

image = [[random.randint(-50, 50) for _ in range(32)] for _ in range(32)]
filter = [[[random.randint(-50, 50) for _ in range(5)] for _ in range(5)] for _ in range(32)]

with open("image.txt", "w") as f:
    for row in image:
        f.write(" ".join(map(str, row)) + "\n")

# Note that the indices of the filter have been reorganized here
# outer: row of filters    inner: index of filters
with open("filter.txt", "w") as f:
    for oc_batch in range(4):
        for r in range(5):
            for oc in range(8):
                f.write(" ".join(str(filter[oc_batch * 8 + oc][r][c]) for c in range(5)) + "\n")

def conv(i, j, oc):
    sum = 0
    for fi in range(5):
        for fj in range(5):
            if 0 <= i + fi - 2 < 32 and 0 <= j + fj - 2 < 32:
                sum += image[i + fi - 2][j + fj - 2] * filter[oc][fi][fj]
    return sum

def quantize_relu(x):
    return min(max(0, x) >> 9, 127)

with open("expected_output.txt", "w") as f:
    for oc in range(32):
        for i in range(32):
            for j in range(32):
                f.write(str(quantize_relu(conv(i, j, oc))) + "\n")

print("------------------------------------------------------")
print(f"Input feature map")
print("------------------------------------------------------")
print()
for i in range(32):
    for j in range(32):
        print(image[i][j], end='\t')
    print()
print()

for i in range(32):
    print("------------------------------------------------------")
    print(f"Filter for output channel {i}:")
    print("------------------------------------------------------")
    print()
    for fi in range(5):
        for fj in range(5):
            print(filter[i][fi][fj], end='\t')
        print()
    print()

for oc in range(32):
    print("------------------------------------------------------")
    print(f"Output feature map for output channel {oc}:")
    print("------------------------------------------------------")
    print()
    for i in range(32):
        for j in range(32):
            print(quantize_relu(conv(i, j, oc)), end='\t')
        print()
    print()