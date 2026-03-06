FROM jenkins/jenkins:lts-jdk17

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    docker.io \
    gcc \
    g++ \
    gcovr \
    libgtest-dev \
    make \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl

WORKDIR /workspace
