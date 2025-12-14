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

image = [[random.randint(0, 255) for _ in range(32)] for _ in range(32)]
filter = [[[random.randint(0, 15) for _ in range(5)] for _ in range(5)] for _ in range(8)]

with open("image.txt", "w") as f:
    for row in image:
        f.write(" ".join(map(str, row)) + "\n")

# Note that the indices of the filter have been reorganized here
# outer: row of filters    inner: index of filters
with open("filter.txt", "w") as f:
    for r in range(5):
        for oc in range(8):
            f.write(" ".join(str(filter[oc][r][c]) for c in range(5)) + "\n")

def conv(i, j, oc):
    sum = 0
    for fi in range(5):
        for fj in range(5):
            if 0 <= i + fi - 2 < 32 and 0 <= j + fj - 2 < 32:
                sum += image[i + fi - 2][j + fj - 2] * filter[oc][fi][fj]
    return sum

for oc in range(8):
    for i in range(32):
        row = []
        for j in range(32):
            row.append(conv(i, j, oc) % 256)
        print(row)
    print()