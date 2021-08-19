#!/bin/bash

mkdir rootfs
apfs-fuse `ls -S unpacked_ipsw/*.dmg | head -1` rootfs

mkdir neural_hash
cd neural_hash
cp ../rootfs/root/System/Library/Frameworks/Vision.framework/neuralhash_128x96_seed1.dat .
cp ../rootfs/root/System/Library/Frameworks/Vision.framework/NeuralHashv3b-current.espresso.* .
dd if=NeuralHashv3b-current.espresso.net bs=4 skip=7 | LD_LIBRARY_PATH=/usr/local/lib lzfse -decode -o model.espresso.net
dd if=NeuralHashv3b-current.espresso.shape bs=4 skip=7 | LD_LIBRARY_PATH=/usr/local/lib lzfse -decode -o model.espresso.shape
cp NeuralHashv3b-current.espresso.weights model.espresso.weights
cd ..

git clone https://github.com/AsuharietYgvar/TNN.git
cd TNN
python3 tools/onnx2tnn/onnx-coreml/coreml2onnx.py ../neural_hash
