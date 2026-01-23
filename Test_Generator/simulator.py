def read_conv_weight(layer, input_channel, output_channel, kernel_size):
    conv_data = []
    with open (f'parameters/conv{layer}.dat', "rb") as f:
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
    with open (f'parameters/fc.dat', "rb") as f:
        for o in range(output_size):
            o_data = []
            for i in range(input_size):
                byte = f.read(1)
                o_data.append(int.from_bytes(byte, signed=True))
            fc_data_reshaped.append(o_data)
    return fc_data_reshaped

def conv2d(data, weight, stride, padding, relu = False):
    output_channel = len(weight)
    input_channel = len(weight[0])
    kernel_size = len(weight[0][0])
    image_height = len(data[0])
    image_width = len(data[0][0])
    output_height = (image_height - kernel_size + 2*padding)//stride + 1
    output_width = (image_width - kernel_size + 2*padding)//stride + 1
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
                                data_out[oc][oh][ow] += data[ic][ih][iw] * weight[oc][ic][kh][kw]
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

def avg_pool2d(data, output_size):
    input_channel = len(data)
    input_height = len(data[0])
    input_width = len(data[0][0])
    data_out = [[0 for _ in range(output_size)] for _ in range(input_channel)]
    for c in range(input_channel):
        for oh in range(output_size):
            for ow in range(output_size):
                sum_val = 0
                for ih in range(input_height):
                    for iw in range(input_width):
                        sum_val += data[c][ih][iw]
                data_out[c][oh] = sum_val / (input_height * input_width)
    return data_out

def linear(data, weight):
    output_size = len(weight)
    input_size = len(weight[0])
    data_out = [0 for _ in range(output_size)]
    for o in range(output_size):
        for i in range(input_size):
            data_out[o] += data[i] * weight[o][i]
    return data_out

def clamp(value, min_value, max_value):
    if value < min_value:
        return min_value
    elif value > max_value:
        return max_value
    else:
        return value

def test_conv(set, layer, input_channel, output_channel, kernel_size, stride, padding, input_height, input_width, Q):
    Q_in, Q_out, Q_w = Q
    factor = 2 ** (Q_in + Q_w - Q_out)
    input_data = [[[0 for _ in range(input_width)] for _ in range(input_height)] for _ in range(input_channel)]
    with open(f'im{set}/conv{layer}.input.dat', "rb") as f:
        for c in range(input_channel):
            for h in range(input_height):
                for w in range(input_width):
                    byte = f.read(1)
                    input_data[c][h][w] = int.from_bytes(byte, signed=True)
    # compute the output
    output_data = conv2d(input_data, read_conv_weight(layer, input_channel, output_channel, kernel_size), stride, padding)
    # compare with golden output
    with open(f'im{set}/conv{layer}.output.dat', "rb") as f:
        for c in range(output_channel):
            for h in range(len(output_data[0])):
                for w in range(len(output_data[0][0])):
                    byte = f.read(1)
                    golden = int.from_bytes(byte, signed=True)
                    result = clamp(output_data[c][h][w] // factor, -127, 127)
                    if result != golden:
                        print(f"Mismatch at conv{layer} output channel {c}, height {h}, width {w}: got {result}, expected {golden}")
                        return False
    return True

def test_linear(set, input_size=128, output_size=10, Q=[5, 5, 6]):
    Q_in, Q_out, Q_w = Q
    factor = 2 ** (Q_in + Q_w - Q_out)
    input_data = [0 for _ in range(input_size)]
    with open(f'im{set}/fc.input.dat', "rb") as f:
        for i in range(input_size):
            byte = f.read(1)
            input_data[i] = int.from_bytes(byte, signed=True)
    # compute the output
    output_data = linear(input_data, read_fc_weight(input_size, output_size))
    # compare with golden output
    with open(f'im{set}/fc.output.dat', "rb") as f:
        for o in range(output_size):
            byte = f.read(1)
            golden = int.from_bytes(byte, signed=True)
            result = clamp(output_data[o] // factor, -127, 127)
            if result != golden:
                print(f"Mismatch at fc output {o}: got {result}, expected {golden}")
                return False
    return True

def main():
    conv_Q = [[7, 5, 7], [5, 5, 8], [5, 5, 8], [5, 5, 8]]
    conv_in_channel = [1, 32, 64, 64]
    conv_out_channel = [32, 64, 64, 128]
    kernel_sizes = [5, 3, 3, 3]
    heights = [32, 16, 16, 8]
    widths = [32, 16, 16, 8]
    strides = [1, 1, 2, 2]
    paddings = [2, 1, 1, 1]
    fc_Q = [5, 5, 6]
    for s in range(8):
        for layer in range(4):
            if test_conv(s+1, layer+1, conv_in_channel[layer], conv_out_channel[layer], kernel_sizes[layer], strides[layer], paddings[layer], heights[layer], widths[layer], conv_Q[layer]):
                print(f"im{s+1} conv{layer+1} passed")
    for s in range(8):
        if test_linear(s+1, input_size=128, output_size=10, Q=fc_Q):
            print(f"im{s+1} fc passed")

if __name__ == "__main__":
    main()
