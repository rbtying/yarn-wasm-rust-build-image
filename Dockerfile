FROM node:lts-slim as base
RUN apt-get update && apt-get -y install curl build-essential binaryen libssl-dev pkg-config
# Install Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup target add wasm32-unknown-unknown
# Install wasm-pack -- newer version than v0.10.1 currently released on crates.io
RUN cargo install wasm-pack --git https://github.com/rustwasm/wasm-pack --rev ae10c23cc14b79ed37a7be222daf5fd851b9cd0d
ENV WASM_PACK_PATH="/root/.cargo/bin/wasm-pack"
RUN yarn global add rimraf webpack webpack-cli
# Install cargo-chef
RUN cargo install cargo-chef
