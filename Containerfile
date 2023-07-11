FROM lukemathwalker/cargo-chef:latest-rust-1 as chef
WORKDIR app

FROM chef AS planner
COPY . .
RUN cargo chef prepare  --recipe-path recipe.json


FROM chef AS builder

COPY --from=planner /app/recipe.json recipe.json

RUN apt-get update && \
    apt-get install -y musl musl-dev musl-tools && \
    rm -rf /var/lib/apt/lists/*

RUN rustup target add x86_64-unknown-linux-musl
# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --target x86_64-unknown-linux-musl --release --recipe-path recipe.json

# Build application
COPY . .

RUN cargo build --release --target x86_64-unknown-linux-musl -j 1
RUN ls -l /app/target/x86_64-unknown-linux-musl/release

FROM scratch

# We need to install libsqlite3-0 >= 3.35 to have support for DROP COLUMN, stable is 3.34.1
# @see https://stackoverflow.com/a/5987838
# RUN apt-get update && \
#     apt-get install -y libcurl4 && \
#     rm -rf /var/lib/apt/lists/*


COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/hello /app/hello

WORKDIR /app
VOLUME /config

CMD ["./hello"]


