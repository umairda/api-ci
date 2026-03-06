FROM gcc:13 AS builder
WORKDIR /app
COPY . .
RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake \
    libgtest-dev \
    && rm -rf /var/lib/apt/lists/*
RUN make all

# Keep runtime toolchain-compatible with the builder's libstdc++.
FROM gcc:13
WORKDIR /app
COPY --from=builder /app/build/health_api /app/health_api
EXPOSE 8080
CMD ["/app/health_api"]
