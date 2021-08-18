# AppleNeuralHash2ONNX

Convert Apple NeuralHash model for [CSAM Detection](https://www.apple.com/child-safety/pdf/CSAM_Detection_Technical_Summary.pdf) to [ONNX](https://github.com/onnx/onnx).

## Intro

Apple NeuralHash is a [perceptual hashing](https://en.wikipedia.org/wiki/Perceptual_hashing) method for images based on neural networks. It can tolerate image resize and compression. The steps of hashing is as the following:
1. Convert image to RGB.
2. Resize image to `360x360`.
3. Normalize RGB values to `[-1, 1]` range.
4. Perform inference on the NeuralHash model.
5. Calculate dot product of a `96x128` matrix with the resulting vector of 128 floats.
6. Apply [binary step](https://en.wikipedia.org/wiki/Heaviside_step_function) to the resulting 96 float vector.
7. Convert the vector of 1.0 and 0.0 to bits, resulting in 96-bit binary data.

In this project, we convert Apple's NeuralHash model to ONNX format. A demo script for testing the model is also included.

## Prerequisite

### OS

Both macOS and Linux will work. In the following sections Debian is used for Linux example.

### LZFSE decoder

- macOS: Install by running `brew install lzfse`.
- Linux: Build and install from [lzfse](https://github.com/lzfse/lzfse) source.

### Python

Python 3.6 and above should work. Install the following dependencies:
```bash
pip install onnx coremltools
```

## Conversion Guide

### Step 1: Get NeuralHash model

You will need 4 files from a recent macOS or iOS build:
- neuralhash_128x96_seed1.dat
- NeuralHashv3b-current.espresso.net
- NeuralHashv3b-current.espresso.shape
- NeuralHashv3b-current.espresso.weights

**Option 1: From macOS or jailbroken iOS device (Recommended)**

If you have a recent version of macOS (11.4+) or jailbroken iOS (14.7+) installed, simply grab these files from `/System/Library/Frameworks/Vision.framework/Resources/` (on macOS) or `/System/Library/Frameworks/Vision.framework/` (on iOS).

<details>
  <summary>Option 2: From iOS IPSW (click to reveal)</summary>

1. Download any `.ipsw` of a recent iOS build (14.7+) from [ipsw.me](https://ipsw.me/).
2. Unpack the file:
```bash
cd /path/to/ipsw/file
mkdir unpacked_ipsw
cd unpacked_ipsw
unzip ../*.ipsw
```
3. Locate system image:
```bash
ls -lh
```
What you need is the largest `.dmg` file, for example `018-63036-003.dmg`.

4. Mount system image. On macOS simply open the file in Finder. On Linux run the following commands:
```bash
# Build and install apfs-fuse
sudo apt install fuse libfuse3-dev bzip2 libbz2-dev cmake g++ git libattr1-dev zlib1g-dev
git clone https://github.com/sgan81/apfs-fuse.git
cd apfs-fuse
git submodule init
git submodule update
mkdir build
cd build
cmake ..
make
sudo make install
sudo ln -s /bin/fusermount /bin/fusermount3
# Mount image
mkdir rootfs
apfs-fuse 018-63036-003.dmg rootfs
```
Required files are under `/System/Library/Frameworks/Vision.framework/` in mounted path.

</details>

Put them under the same directory:
```bash
mkdir NeuralHash
cd NeuralHash
cp /System/Library/Frameworks/Vision.framework/Resources/NeuralHashv3b-current.espresso.* .
cp /System/Library/Frameworks/Vision.framework/Resources/neuralhash_128x96_seed1.dat .
```

### Step 2: Decode model structure and shapes

Normally compiled Core ML models store structure in `model.espresso.net` and shapes in `model.espresso.shape`, both in JSON. It's the same for NeuralHash model but compressed with [LZFSE](https://en.wikipedia.org/wiki/LZFSE).

```bash
dd if=NeuralHashv3b-current.espresso.net bs=4 skip=7 | lzfse -decode -o model.espresso.net
dd if=NeuralHashv3b-current.espresso.shape bs=4 skip=7 | lzfse -decode -o model.espresso.shape
cp NeuralHashv3b-current.espresso.weights model.espresso.weights
```

### Step 3: Convert model to ONNX

```bash
cd ..
git clone https://github.com/AsuharietYgvar/TNN.git
cd TNN
python3 tools/onnx2tnn/onnx-coreml/coreml2onnx.py ../NeuralHash
```

The resulting model is `NeuralHash/model.onnx`.

## Usage

### Inspect model

[Netron](https://github.com/lutzroeder/netron) is a perfect tool for this purpose.

### Calculate neural hash with [onnxruntime](https://github.com/microsoft/onnxruntime)

1. Install required libraries:
```bash
pip install onnxruntime pillow
```
2. Run `nnhash.py` on an image:
```bash
python3 nnhash.py /path/to/model.onnx /path/to/neuralhash_128x96_seed1.dat image.jpg
```

Example output:
```
ab14febaa837b6c1484c35e6
```

**Note:** Neural hash generated here might be a few bits off from one generated on an iOS device. This is expected since different iOS devices generate slightly different hashes anyway. The reason is that neural networks are based on floating-point calculations. The accuracy is highly dependent on the hardware. For smaller networks it won't make any difference. But NeuralHash has 200+ layers, resulting in significant cumulative errors.

|Device|Hash|
|---|---|
|iPad Pro 10.5-inch|`2b186faa6b36ffcc4c4635e1`|
|M1 Mac|`2b5c6faa6bb7bdcc4c4731a1`|
|iOS Simulator|`2b5c6faa6bb6bdcc4c4731a1`|
|ONNX Runtime|`2b5c6faa6bb6bdcc4c4735a1`|

## Credits

- [nhcalc](https://github.com/KhaosT/nhcalc) for uncovering NeuralHash private API.
- [TNN](https://github.com/Tencent/TNN) for compiled Core ML to ONNX script.
