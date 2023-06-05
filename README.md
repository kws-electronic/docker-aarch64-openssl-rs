# Docker image for cross compiling Rust with OpenSSL to aarch64

This docker image can be used to cross compile Rust programs with a OpenSSL dependency to `aarch64-unknown-linux-gnu`.

## Usage

You can either use the [public docker image](https://github.com/kws-electronic/docker-aarch64-openssl-rs/pkgs/container/aarch64-openssl-rs) (`ghcr.io/kws-electronic/aarch64-openssl-rs`) or build the image with the provided Dockerfile yourself, if you need other versions of OpenSSL, GCC, zlib or Rust than specified [in the table below](#configuration).

When running the image, `cargo` is the default entry point, so if you just want to use `cargo`, you only need to pass the cargo-command (i.e. `build`) and options. The working directory is `/usr/local/src`, therefore you need to bind a volume from you rust project to that directory.

### Building a Rust project via `cargo build`
The default command in the docker container already specifies the target (`aarch64-unknown-linux-gnu`) and the linker (`aarch64-linux-gnu-gcc`), therefore if you just want to build without passing any extra options, you can do it like this:
```sh
docker run --rm -v .:/usr/local/src ghcr.io/kws-electronic/aarch64-openssl-rs
```
_(This example assumes that your working directory is located in your Rust project. `--rm` is theoretically not needed, but ensures the container is removed once done)_

### Passing extra options to `cargo build`
If you need to pass options to `cargo build` (other than target and linker). You need make sure that you set the correct build target (`aarch64-unknown-linux-gnu`) and configured the correct linker  (`aarch64-linux-gnu-gcc`). This can be done by either placing a `config.toml` in the `.cargo` directory in your rust project or passing both options as flags to `cargo build`.
```toml
# File .cargo/config.toml
[build]
target="aarch64-unknown-linux-gnu"

[target.aarch64-unknown-linux-gnu]
linker = "aarch64-linux-gnu-gcc"
```
or
```sh
# flags to pass to cargo build
--target=aarch64-unknown-linux-gnu --config=target.aarch64-unknown-linux-gnu.linker=\"aarch64-linux-gnu-gcc\"
```

Therefore actually running `cargo build` in the container (i.e. with the `--release` flag) would look something like this:
```sh
# When .cargo/config.toml includes target and linker
docker run --rm -v .:/usr/local/src ghcr.io/kws-electronic/aarch64-openssl-rs build --release

# Passing target and linker as flags
docker run --rm -v .:/usr/local/src ghcr.io/kws-electronic/aarch64-openssl-rs build --release --target=aarch64-unknown-linux-gnu --config=target.aarch64-unknown-linux-gnu.linker=\"aarch64-linux-gnu-gcc\"
```
_(This example assumes that your working directory is located in your Rust project. `--rm` is theoretically not needed, but ensures the container is removed once done)_

### Using your local crates.io cache
To speed up the build process you can map your local crates.io cache into the container, by specifying an extra volume when executing `docker run`:

```sh
docker run -v ~/.cargo/registry:/root/.cargo/registry [...]
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
