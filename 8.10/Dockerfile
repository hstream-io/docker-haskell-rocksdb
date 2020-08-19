FROM haskell:8.10.2-buster

RUN apt-get update && \
    apt-get install -y --no-install-recommends git libgflags-dev libsnappy-dev zlib1g-dev libbz2-dev liblz4-dev libzstd-dev && \
    rm -rf /var/lib/apt/lists/*

ARG ROCKSDB_VERSION=v6.10.2
ARG BUILD_JOBS=4

RUN git clone https://github.com/facebook/rocksdb.git /tmp/rocksdb && \
    cd /tmp/rocksdb && git checkout $ROCKSDB_VERSION && \
    make -j$BUILD_JOBS shared_lib && make install-shared

RUN yes Y | apt-get remove --purge git libgflags-dev libsnappy-dev zlib1g-dev libbz2-dev liblz4-dev libzstd-dev && \
    rm -rf /tmp/rocksdb

CMD ["ghci"]
