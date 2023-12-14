FROM ubuntu:22.04 AS gcc_downloader
ARG GCC_VERSION='9.2-2019.12'

RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y \
        xz-utils \
        curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/src
RUN curl -O -L https://developer.arm.com/-/media/Files/downloads/gnu-a/$GCC_VERSION/binrel/gcc-arm-$GCC_VERSION-x86_64-aarch64-none-linux-gnu.tar.xz \
    && tar -xf ./gcc-arm-$GCC_VERSION-x86_64-aarch64-none-linux-gnu.tar.xz \
    && mv gcc-arm-$GCC_VERSION-x86_64-aarch64-none-linux-gnu/ /output

####################################################################################################

FROM ubuntu:22.04 AS ubuntu_gcc

RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y curl build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=gcc_downloader /output/ /usr/

RUN ln -s /usr/bin/aarch64-none-linux-gnu-gcc /usr/bin/aarch64-linux-gnu-gcc

ENV CC=aarch64-linux-gnu-gcc

RUN aarch64-linux-gnu-gcc --version

####################################################################################################

FROM ubuntu_gcc AS lib_builder

RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y make libfindbin-libs-perl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

####################################################################################################

FROM lib_builder AS openssl_builder

ARG OPENSSL_VERSION='3.0.0'
ARG TARGET_OPENSSL_DIR='/usr'

WORKDIR /usr/local/src
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz | tar xz
WORKDIR /usr/local/src/openssl-$OPENSSL_VERSION
RUN ./Configure linux-aarch64 shared --openssldir=$TARGET_OPENSSL_DIR --prefix=/output \
    && make \
    && make install

####################################################################################################

FROM lib_builder AS zlib_builder

ARG ZLIB_VERSION='1.3'

WORKDIR /usr/local/src
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl https://zlib.net/zlib-$ZLIB_VERSION.tar.gz | tar xz
WORKDIR /usr/local/src/zlib-$ZLIB_VERSION
RUN ./configure \
    && make \
    && make install prefix=/output

####################################################################################################

FROM ubuntu_gcc

ARG RUST_VERSION='1.69.0'

# Install OpenSSL
COPY --from=openssl_builder /output/ /usr/local/
ENV OPENSSL_DIR=/usr/local

# Install zlib
COPY --from=zlib_builder /output/ /usr/local/

# Install Rust
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain $RUST_VERSION --target aarch64-unknown-linux-gnu
ENV PATH="/root/.cargo/bin:${PATH}"
ENV CARGO_HOME="/root/.cargo"
ENV RUSTUP_HOME="/root/.rustup"

WORKDIR /usr/local/src
ENTRYPOINT ["cargo"]
CMD ["build", "--target=aarch64-unknown-linux-gnu", "--config=target.aarch64-unknown-linux-gnu.linker=\"aarch64-linux-gnu-gcc\""]
