FROM python:latest

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
  fuse \
  libfuse3-dev \
  bzip2 \
  libbz2-dev \
  cmake \
  g++ \
  git \
  libattr1-dev \
  zlib1g-dev \
  unzip \
  && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/sgan81/apfs-fuse.git \
  && cd apfs-fuse \
  && git submodule init \
  && git submodule update \
  && mkdir build && cd build \
  && cmake .. && make && make install \
  && ln -s /bin/fusermount /bin/fusermount3 \
  && cd ..

RUN git clone https://github.com/lzfse/lzfse.git \
  && cd lzfse \
  && mkdir build && cd build \
  && cmake .. && make install \
  && cd ..

WORKDIR /workdir

ARG IPSW_FILE

COPY ${IPSW_FILE} .

RUN mkdir unpacked_ipsw \
  && cd unpacked_ipsw \
  && unzip ../${IPSW_FILE} \
  && cd ..

COPY script.sh .
COPY nnhash.py .

RUN chmod 744 script.sh

RUN pip install onnx onnxruntime pillow
