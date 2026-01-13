import numpy as np
import os

def read_conv_weight(layer, input_channel, output_channel, kernel_size):
    conv_data = []
    filepath = f'Test_Generator/data/parameters/conv{layer}.dat'
    with open(filepath, "rb") as f:
        for oc in range(output_channel):
            oc_data = []
            for ic in range(input_channel):
                ic_data = []
                for k1 in range(kernel_size):
                    k1_data = []
                    for k2 in range(kernel_size):
                        byte = f.read(1)
                        k1_data.append(int.from_bytes(byte, signed=True))
                    ic_data.append(k1_data)
                oc_data.append(ic_data)
            conv_data.append(oc_data)
    return conv_data

def read_fc_weight(input_size, output_size):
    fc_data_reshaped = []
    filepath = f'Test_Generator/data/parameters/fc.dat'
    with open(filepath, "rb") as f:
        for o in range(output_size):
            o_data = []
            for i in range(input_size):
                byte = f.read(1)
                o_data.append(int.from_bytes(byte, signed=True))
            fc_data_reshaped.append(o_data)
    return fc_data_reshaped

def pad_to_multiple(value, multiple=16):
    return ((value + multiple - 1) // multiple) * multiple

def conv2d(data, weight, stride, padding, relu = False):
    output_channel = len(weight)
    input_channel = len(weight[0])
    kernel_size = len(weight[0][0])
    image_height = len(data[0])
    image_width = len(data[0][0])
    output_height = (image_height - kernel_size + 2*padding)//stride + 1
    output_width = (image_width - kernel_size + 2*padding)//stride + 1
    # 使用int64避免溢出
    data_out = [[[0 for _ in range(output_width)] for _ in range(output_height)] for _ in range(output_channel)]
    for oc in range(output_channel):
        for ic in range(input_channel):
            for oh in range(output_height):
                for ow in range(output_width):
                    for kh in range(kernel_size):
                        for kw in range(kernel_size):
                            ih = oh*stride + kh - padding
                            iw = ow*stride + kw - padding
                            if ih >= 0 and ih < image_height and iw >= 0 and iw < image_width:
                                # 显式转换为int64防止溢出
                                data_out[oc][oh][ow] += int(data[ic][ih][iw]) * int(weight[oc][ic][kh][kw])
    if relu:
        for oc in range(output_channel):
            for oh in range(output_height):
                for ow in range(output_width):
                    if data_out[oc][oh][ow] < 0:
                        data_out[oc][oh][ow] = 0
    return data_out

def max_pool2d(data, kernel_size, stride):
    input_channel = len(data)
    input_height = len(data[0])
    input_width = len(data[0][0])
    output_height = (input_height - kernel_size)//stride + 1
    output_width = (input_width - kernel_size)//stride + 1
    data_out = [[[0 for _ in range(output_width)] for _ in range(output_height)] for _ in range(input_channel)]
    for c in range(input_channel):
        for oh in range(output_height):
            for ow in range(output_width):
                max_val = -1e9
                for kh in range(kernel_size):
                    for kw in range(kernel_size):
                        ih = oh*stride + kh
                        iw = ow*stride + kw
                        if data[c][ih][iw] > max_val:
                            max_val = data[c][ih][iw]
                data_out[c][oh][ow] = max_val
    return data_out

def avg_pool2d(data, kernel_size, stride):
    input_channel = len(data)
    input_height = len(data[0])
    input_width = len(data[0][0])
    output_height = (input_height - kernel_size)//stride + 1
    output_width = (input_width - kernel_size)//stride + 1
    data_out = [[[0 for _ in range(output_width)] for _ in range(output_height)] for _ in range(input_channel)]
    for c in range(input_channel):
        for oh in range(output_height):
            for ow in range(output_width):
                sum_val = 0
                for kh in range(kernel_size):
                    for kw in range(kernel_size):
                        ih = oh*stride + kh
                        iw = ow*stride + kw
                        sum_val += data[c][ih][iw]
                data_out[c][oh][ow] = sum_val / (kernel_size * kernel_size)
    return data_out

def linear(data, weight):
    output_size = len(weight)
    input_size = len(weight[0])
    data_out = [0 for _ in range(output_size)]
    for o in range(output_size):
        for i in range(input_size):
            # 显式转换为int64防止溢出
            data_out[o] += int(data[i]) * int(weight[o][i])
    return data_out

def clamp(value, min_value, max_value):
    if value < min_value:
        return min_value
    elif value > max_value:
        return max_value
    else:
        return value

def quantize_and_clamp(data, Q, relu=False):
    """量化：右移Q位，可选ReLU，然后clamp到[-127, 127]"""
    quantized = []
    for c in range(len(data)):
        c_data = []
        for h in range(len(data[0])):
            h_data = []
            for w in range(len(data[0][0])):
                val = data[c][h][w] >> Q  # 右移Q位
                if relu and val < 0:
                    val = 0
                val = clamp(val, -127, 127)
                h_data.append(val)
            c_data.append(h_data)
        quantized.append(c_data)
    return quantized

def quantize_and_clamp_1d(data, Q, relu=False):
    """量化1D数据：右移Q位，可选ReLU，然后clamp到[-127, 127]"""
    quantized = []
    for val in data:
        val = int(val) >> Q
        if relu and val < 0:
            val = 0
        val = clamp(val, -127, 127)
        quantized.append(val)
    return quantized

def write_weights_to_file():
    """生成weights.txt，包含所有层的权重数据（填充到16的整数倍）"""
    # 层配置（输入channel填充到16的整数倍）
    conv_configs = [
        {'layer': 1, 'ic': 16, 'oc': 32, 'k': 5},  # 原始ic=1，填充到16
        {'layer': 2, 'ic': 32, 'oc': 64, 'k': 3},
        {'layer': 3, 'ic': 64, 'oc': 64, 'k': 3},
        {'layer': 4, 'ic': 64, 'oc': 128, 'k': 3},
    ]
    
    all_weights = []
    
    # 处理conv层
    for cfg in conv_configs:
        layer, ic, oc, k = cfg['layer'], cfg['ic'], cfg['oc'], cfg['k']
        ic_padded = pad_to_multiple(ic, 16)
        oc_padded = pad_to_multiple(oc, 16)
        
        # 读取原始权重（conv1只有1个输入channel，需要填充到16）
        original_ic = 1 if layer == 1 else ic
        weights = read_conv_weight(layer, original_ic, oc, k)
        
        # 如果是conv1，需要手动填充权重到16个input channel
        if layer == 1:
            # weights shape: [oc][1][k][k], 需要扩展到 [oc][16][k][k]
            weights_padded = []
            for oc_idx in range(oc):
                oc_data = []
                for ic_idx in range(16):
                    if ic_idx == 0:
                        # 第一个channel使用原始权重
                        oc_data.append(weights[oc_idx][0])
                    else:
                        # 其他channel填充0
                        oc_data.append([[0 for _ in range(k)] for _ in range(k)])
                weights_padded.append(oc_data)
            weights = weights_padded
        
        # 按照 (kh, kw, ic, oc) 的顺序组织
        for kh in range(k):
            for kw in range(k):
                for ic_idx in range(ic_padded):
                    for oc_idx in range(oc_padded):
                        if ic_idx < ic and oc_idx < oc:
                            # 原始权重：weights[oc][ic][kh][kw]
                            w_val = weights[oc_idx][ic_idx][kh][kw]
                        else:
                            # 填充0
                            w_val = 0
                        
                        # 每个权重是8bit，转换为uint8
                        w_uint8 = np.int8(w_val).view(np.uint8)
                        all_weights.append(w_uint8)
    
    # 处理FC层（视为1x1卷积，128->10，填充到128->16）
    fc_ic = 128
    fc_oc = 10
    fc_ic_padded = pad_to_multiple(fc_ic, 16)
    fc_oc_padded = pad_to_multiple(fc_oc, 16)
    
    fc_weights = read_fc_weight(fc_ic, fc_oc)
    
    # FC作为1x1卷积，kh=1, kw=1
    for kh in range(1):
        for kw in range(1):
            for ic_idx in range(fc_ic_padded):
                for oc_idx in range(fc_oc_padded):
                    if ic_idx < fc_ic and oc_idx < fc_oc:
                        w_val = fc_weights[oc_idx][ic_idx]
                    else:
                        w_val = 0
                    
                    w_uint8 = np.int8(w_val).view(np.uint8)
                    all_weights.append(w_uint8)
    
    # 写入文件
    os.makedirs('Test_Generator/data', exist_ok=True)
    with open('Test_Generator/data/weights.txt', 'w') as f:
        for w in all_weights:
            f.write(f'{w:02x}\n')
    
    print(f"Total weights written: {len(all_weights)}")
    
    # 验证数据量（考虑填充）
    # conv1: ic=1->16, oc=32, k=5x5  -> 5*5*16*32 = 12800
    # conv2: ic=32, oc=64, k=3x3     -> 3*3*32*64 = 18432
    # conv3: ic=64, oc=64, k=3x3     -> 3*3*64*64 = 36864
    # conv4: ic=64, oc=128, k=3x3    -> 3*3*64*128 = 73728
    # fc: ic=128, oc=10->16, k=1x1   -> 1*1*128*16 = 2048
    # 但用户说的是16*8=128bit的数据单元，可能每个数据是16个8bit权重打包
    # 重新理解：可能每16个input channel和每16个output channel作为一组
    # conv1: (1->16)*(32/16=2)*5*5 = 16*2*25 = 800
    # conv2: (32/16=2)*(64/16=4)*3*3 = 2*4*9 = 72... 不对
    
    # 按用户说明：每个数据是16*8=128bit = 16个8bit权重
    # conv1: 800个数据 = 800*16 = 12800个8bit权重 = 16*32*5*5
    # conv2: 1152个数据 = 18432个权重 = 32*64*3*3
    # conv3: 2304个数据 = 36864个权重 = 64*64*3*3  
    # conv4: 4608个数据 = 73728个权重 = 64*128*3*3
    
    expected_weights = [
        ('conv1', 16, 32, 5, 12800, 800),
        ('conv2', 32, 64, 3, 18432, 1152),
        ('conv3', 64, 64, 3, 36864, 2304),
        ('conv4', 64, 128, 3, 73728, 4608),
        ('fc', 128, 16, 1, 2048, 128)
    ]
    
    offset = 0
    for name, ic_p, oc_p, k, expected_8bit, expected_128bit in expected_weights:
        actual = ic_p * oc_p * k * k
        print(f"{name}: {ic_p}*{oc_p}*{k}*{k} = {actual} weights (8bit), {actual//16} data units (128bit), expected {expected_128bit} units")
        offset += actual
    
    print(f"Total offset: {offset}")

def generate_input_image():
    """生成随机输入图像 (16, 32, 32)，第一个channel有数据，其余15个channel填充0"""
    np.random.seed(int(input("Enter a seed for random input image generation: ")))
    ifm = np.zeros((16, 32, 32), dtype=np.int8)
    # 只有第一个channel有随机数据
    ifm[0] = np.random.randint(-50, 50, size=(32, 32)).astype(np.int8)
    
    # 保存为 (H, W, C) 格式，flatten后写入
    ifm_transposed = ifm.transpose(1, 2, 0)  # (32, 32, 16)
    ifm_u8 = ifm_transposed.flatten().astype(np.uint8)
    
    os.makedirs('Test_Generator/data', exist_ok=True)
    np.savetxt('Test_Generator/data/ifm.txt', ifm_u8, fmt='%02x')
    
    # 保存原始图片，只有第一个channel，格式为(H, W)，没有C
    # 只有第一个channel有数据，所以直接保存ifm[0]
    ifm_original = ifm[0].astype(np.uint8)
    np.savetxt('Test_Generator/data/ifm_original.txt', ifm_original.flatten(), fmt='%02x')
    
    return ifm

def save_golden_output(data, filename):
    """保存golden输出，数据组织为(H, W, C)"""
    # data shape: (C, H, W)
    data_transposed = data.transpose(1, 2, 0)  # (H, W, C)
    data_flat = data_transposed.flatten()
    
    with open(filename, 'w') as f:
        for val in data_flat:
            val = int(val)
            val_u32 = val & 0xFFFFFFFF
            f.write(f'{val_u32:08x}\n')

def save_golden_output_1d(data, filename):
    """保存1D golden输出"""
    with open(filename, 'w') as f:
        for val in data:
            val = int(val)
            val_u32 = val & 0xFFFFFFFF
            f.write(f'{val_u32:08x}\n')

def main():
    """主函数：生成所有测试数据"""
    print("=== Generating Test Data ===")
    
    # 1. 生成权重文件
    print("\n1. Writing weights to weights.txt...")
    write_weights_to_file()
    
    # 2. 生成输入图像
    print("\n2. Generating input image...")
    ifm = generate_input_image()
    print(f"Input shape: {ifm.shape}")
    
    # 3. 逐层计算golden输出
    print("\n3. Computing golden outputs...")
    
    # Conv1: (16, 32, 32) -> (32, 32, 32), stride=1, padding=2, kernel=5
    print("Computing Conv1...")
    # 读取权重并填充到16个input channel
    conv1_weights_orig = read_conv_weight(1, 1, 32, 5)
    conv1_weights = []
    for oc in range(32):
        oc_data = []
        for ic in range(16):
            if ic == 0:
                oc_data.append(conv1_weights_orig[oc][0])
            else:
                oc_data.append([[0 for _ in range(5)] for _ in range(5)])
        conv1_weights.append(oc_data)
    
    conv1_out = conv2d(ifm, conv1_weights, stride=1, padding=2, relu=False)
    # 量化：Q=9, ReLU=True
    conv1_out = quantize_and_clamp(conv1_out, Q=9, relu=True)
    save_golden_output(np.array(conv1_out), 'Test_Generator/data/golden_1.txt')
    print(f"Conv1 output shape: ({len(conv1_out)}, {len(conv1_out[0])}, {len(conv1_out[0][0])})")
    
    # MaxPool after Conv1: (32, 32, 32) -> (32, 16, 16), kernel=2, stride=2
    print("Computing MaxPool after Conv1...")
    pool1_out = max_pool2d(conv1_out, kernel_size=2, stride=2)
    save_golden_output(np.array(pool1_out), 'Test_Generator/data/golden_pool1.txt')
    print(f"Pool1 output shape: ({len(pool1_out)}, {len(pool1_out[0])}, {len(pool1_out[0][0])})")
    
    # Conv2: (32, 16, 16) -> (64, 16, 16), stride=1, padding=1, kernel=3
    print("Computing Conv2...")
    conv2_weights = read_conv_weight(2, 32, 64, 3)
    conv2_out = conv2d(pool1_out, conv2_weights, stride=1, padding=1, relu=False)
    # 量化：Q=8, ReLU=True
    conv2_out = quantize_and_clamp(conv2_out, Q=8, relu=True)
    save_golden_output(np.array(conv2_out), 'Test_Generator/data/golden_2.txt')
    print(f"Conv2 output shape: ({len(conv2_out)}, {len(conv2_out[0])}, {len(conv2_out[0][0])})")
    
    # Conv3: (64, 16, 16) -> (64, 8, 8), stride=2, padding=1, kernel=3
    print("Computing Conv3...")
    conv3_weights = read_conv_weight(3, 64, 64, 3)
    conv3_out = conv2d(conv2_out, conv3_weights, stride=2, padding=1, relu=False)
    # 量化：Q=8, ReLU=True
    conv3_out = quantize_and_clamp(conv3_out, Q=8, relu=True)
    save_golden_output(np.array(conv3_out), 'Test_Generator/data/golden_3.txt')
    print(f"Conv3 output shape: ({len(conv3_out)}, {len(conv3_out[0])}, {len(conv3_out[0][0])})")
    
    # Conv4: (64, 8, 8) -> (128, 4, 4), stride=2, padding=1, kernel=3
    print("Computing Conv4...")
    conv4_weights = read_conv_weight(4, 64, 128, 3)
    conv4_out = conv2d(conv3_out, conv4_weights, stride=2, padding=1, relu=False)
    # 量化：Q=8, ReLU=True
    conv4_out = quantize_and_clamp(conv4_out, Q=8, relu=True)
    save_golden_output(np.array(conv4_out), 'Test_Generator/data/golden_4.txt')
    print(f"Conv4 output shape: ({len(conv4_out)}, {len(conv4_out[0])}, {len(conv4_out[0][0])})")
    
    # AvgPool after Conv4: (128, 4, 4) -> (128, 1, 1)
    print("Computing AvgPool after Conv4...")
    pool4_out = avg_pool2d(conv4_out, kernel_size=4, stride=1)
    save_golden_output(np.array(pool4_out), 'Test_Generator/data/golden_pool4.txt')
    print(f"Pool4 output shape: ({len(pool4_out)}, {len(pool4_out[0])}, {len(pool4_out[0][0])})")

    pool4_flat = [pool4_out[c][0][0] for c in range(128)]
    
    # FC: (128,) -> (10,), 视为1x1卷积，输出填充到16
    print("Computing FC...")
    fc_weights = read_fc_weight(128, 10)
    fc_out = linear(pool4_flat, fc_weights)
    # 量化：Q=6, ReLU=False
    fc_out = quantize_and_clamp_1d(fc_out, Q=6, relu=False)
    # 填充输出到16个channel
    fc_out_padded = fc_out + [0] * (16 - len(fc_out))
    save_golden_output_1d(fc_out_padded, 'Test_Generator/data/golden_5.txt')
    print(f"FC output shape: ({len(fc_out_padded)},) (10 valid + 6 padding)")
    
    print("\n=== Data Generation Complete ===")
    print("Generated files:")
    print("  - Test_Generator/data/weights.txt")
    print("  - Test_Generator/data/ifm.txt")
    print("  - Test_Generator/data/golden_1.txt (Conv1)")
    print("  - Test_Generator/data/golden_pool1.txt (MaxPool)")
    print("  - Test_Generator/data/golden_2.txt (Conv2)")
    print("  - Test_Generator/data/golden_3.txt (Conv3)")
    print("  - Test_Generator/data/golden_4.txt (Conv4)")
    print("  - Test_Generator/data/golden_pool4.txt (AvgPool)")
    print("  - Test_Generator/data/golden_5.txt (FC)")

if __name__ == "__main__":
    main()
