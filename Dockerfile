FROM ubuntu:22.04 AS ubuntu_gcc

ARG GCC_VERSION='9.2-2019.12'

RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y \
        xz-utils \
        curl


WORKDIR /usr/local/src
RUN curl -O -L https://developer.arm.com/-/media/Files/downloads/gnu-a/$GCC_VERSION/binrel/gcc-arm-$GCC_VERSION-x86_64-aarch64-none-linux-gnu.tar.xz
RUN tar -xf ./gcc-arm-$GCC_VERSION-x86_64-aarch64-none-linux-gnu.tar.xz
RUN cp -r gcc-arm-$GCC_VERSION-x86_64-aarch64-none-linux-gnu/* /usr/

RUN rm -rf /usr/local/src

RUN aarch64-none-linux-gnu-gcc --version

RUN ln /usr/bin/aarch64-none-linux-gnu-gcc /usr/bin/aarch64-linux-gnu-gcc

ENV CC=aarch64-linux-gnu-gcc

####################################################################################################

FROM ubuntu_gcc AS lib_builder

RUN apt-get install -y build-essential make

####################################################################################################

FROM lib_builder AS openssl_builder

ARG OPENSSL_VERSION='3.0.0'
ARG TARGET_OPENSSL_DIR='/usr'

WORKDIR /usr/local/src
RUN curl https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz | tar xz
RUN mv openssl-$OPENSSL_VERSION openssl
WORKDIR ./openssl
RUN ./Configure linux-aarch64 shared --openssldir=$TARGET_OPENSSL_DIR
RUN make

####################################################################################################

FROM lib_builder AS zlib_builder

ARG ZLIB_VERSION='1.2.13'

WORKDIR /usr/local/src
RUN curl https://zlib.net/zlib-$ZLIB_VERSION.tar.gz | tar xz
RUN mv zlib-$ZLIB_VERSION zlib
WORKDIR ./zlib
RUN ./configure
RUN make

####################################################################################################

FROM ubuntu_gcc

ARG RUST_VERSION='1.69.0'

RUN apt-get install -y make libfindbin-libs-perl binutils build-essential

# Install OpenSSL
COPY --from=openssl_builder /usr/local/src/ /usr/local/src/
WORKDIR /usr/local/src/openssl
RUN make install

# Install zlib
COPY --from=zlib_builder /usr/local/src/ /usr/local/src/
WORKDIR /usr/local/src/zlib
RUN make install

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain $RUST_VERSION --target aarch64-unknown-linux-gnu

# Cleanup
RUN apt-get remove -y make libfindbin-libs-perl binutils curl
RUN rm -rf /usr/local/src/*

ENV OPENSSL_DIR=/usr/local
WORKDIR /root
