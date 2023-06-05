# Docker image for cross compiling Rust with OpenSSL to aarch64

This docker image can be used to cross compile Rust programs with a OpenSSL dependency to `aarch64-unknown-linux-gnu`.

## Usage

```
docker run \
    --rm \
    -v .:/usr/src \
    -w /usr/src \
    -v ~/.cargo/registry:/root/.cargo/registry \
    ghcr.io/kws-electronic/aarch64-openssl-rs \
    /root/.cargo/bin/cargo build --target=aarch64-unknown-linux-gnu --config target.aarch64-unknown-linux-gnu.linker=\"aarch64-linux-gnu-gcc\"
```

## Configuration

There are a couple of docker build-time variables available to configure the build. These can be passed to the `docker build` command using the `--build-arg <varname>=<value>` flag.

| Name                 | Default Value | Description                                                                                  |
| :------------------- | :------------ | :------------------------------------------------------------------------------------------- |
| `GCC_VERSION`        | `9.2-2019.12` | GCC version to download from developer.arm.com                                               |
| `RUST_VERSION`       | `1.69.0`      | Rust version to install                                                                      |
| `ZLIB_VERSION`       | `1.2.13`      | ZLib version to install                                                                      |
| `OPENSSL_VERSION`    | `3.0.0`       | OpenSSL version to install                                                                   |
| `TARGET_OPENSSL_DIR` | `/usr`        | OpenSSL directory on target machine (will be passed as `--openssldir` to `./Configure` call) |
