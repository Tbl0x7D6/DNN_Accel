ifm = []
ifm.append([1 + i % 2 for i in range(36)])
ifm.append([i + 1 for i in range(36)])
ifm.append([1 for i in range(36)])
ifm.append([7 - (i % 7) for i in range(36)])
# 1, 2, 1, 2, 1, 2, 1, 2, 1, ...
# 1, 2, 3, 4, 5, 6, 7, 8, 9, ...
# 1, 1, 1, 1, 1, 1, 1, 1, 1, ...
# 7, 6, 5, 4, 3, 2, 1, 7, 6, ...

filter = [
    [1, 2, 3],
    [1, 1, 1],
    [3, 2, 1]
]

def conv(x, y):
    sum = 0
    for i in range(3):
        for j in range(3):
            sum += ifm[x + i][y + j] * filter[i][j]
    return sum

for y in range(34):
    print(conv(0, y), end=' ')
print()
for y in range(34):
    print(conv(1, y), end=' ')
print()




ifm = []
ifm.append([i % 2 for i in range(36)])
ifm.append([i % 3 for i in range(36)])
ifm.append([i % 4 for i in range(36)])
ifm.append([i % 5 for i in range(36)])

filter = [
    [1, 0, 1],
    [1, 0, 1],
    [1, 0, 1]
]

def conv(x, y):
    sum = 0
    for i in range(3):
        for j in range(3):
            sum += ifm[x + i][y + j] * filter[i][j]
    return sum

for y in range(34):
    print(conv(0, y), end=' ')
print()
for y in range(34):
    print(conv(1, y), end=' ')
print()