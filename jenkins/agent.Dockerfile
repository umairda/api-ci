FROM docker:27-cli AS docker_cli

FROM jenkins/inbound-agent:latest-jdk21

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gcc \
    g++ \
    gcovr \
    libgtest-dev \
    make \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*
COPY --from=docker_cli /usr/local/bin/docker /usr/local/bin/docker
RUN curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl

USER jenkins
WORKDIR /home/jenkins/agent
