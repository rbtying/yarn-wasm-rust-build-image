ARG PLATFORM=$BUILDPLATFORM

FROM --platform=$PLATFORM messense/rust-musl-cross:x86_64-musl as amd64
RUN git clone https://github.com/rustwasm/wasm-pack
RUN cd wasm-pack && cargo build --release --target=x86_64-unknown-linux-musl
RUN cp /home/rust/src/wasm-pack/target/x86_64-unknown-linux-musl/release/wasm-pack /
RUN cargo install cargo-chef --target=x86_64-unknown-linux-musl
RUN cp /root/.cargo/bin/cargo-chef /

FROM --platform=$PLATFORM messense/rust-musl-cross:aarch64-musl as arm64
RUN git clone https://github.com/rustwasm/wasm-pack
RUN cd wasm-pack && cargo build --release --target=aarch64-unknown-linux-musl
RUN cp /home/rust/src/wasm-pack/target/aarch64-unknown-linux-musl/release/wasm-pack /
RUN cargo install cargo-chef --target=aarch64-unknown-linux-musl
RUN cp /root/.cargo/bin/cargo-chef /

FROM node:lts-slim as base
RUN apt-get update && apt-get -y install curl build-essential binaryen libssl-dev pkg-config
# Install Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y
ENV PATH="/root/.cargo/bin:${PATH}"
ARG TARGETPLATFORM
RUN echo $TARGETPLATFORM
RUN case "$TARGETPLATFORM" in \
  "linux/arm64") echo "aarch64-unknown-linux-musl" > /rust_target.txt ;; \
  "linux/amd64") echo "x86_64-unknown-linux-musl" > /rust_target.txt ;; \
  *) exit 1 ;; \
esac
RUN rustup target add wasm32-unknown-unknown $(cat /rust_target.txt)
COPY --from=amd64 /wasm-pack /wasm-pack.x86_64
COPY --from=arm64 /wasm-pack /wasm-pack.aarch64
RUN case "$TARGETPLATFORM" in \
  "linux/arm64") ln /wasm-pack.aarch64 /wasm-pack ;; \
  "linux/amd64") ln /wasm-pack.x86_64 /wasm-pack ;; \
  *) exit 1 ;; \
esac
ENV WASM_PACK_PATH="/wasm-pack"
RUN yarn global add rimraf webpack webpack-cli
COPY --from=amd64 /cargo-chef /cargo-chef.x86_64
COPY --from=arm64 /cargo-chef /cargo-chef.aarch64
RUN case "$TARGETPLATFORM" in \
  "linux/arm64") ln /cargo-chef.aarch64 /cargo-chef ;; \
  "linux/amd64") ln /cargo-chef.x86_64 /cargo-chef ;; \
  *) exit 1 ;; \
esac
ENV PATH=$PATH:/
