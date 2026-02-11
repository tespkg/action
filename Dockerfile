# 1. Inherit from official latest image (Includes Docker CLI, Git, Jq)
FROM ghcr.io/actions/actions-runner:latest

# 2. Switch to root to install dependencies
USER root

# 3. Install missing build tools
# build-essential: Includes make, gcc, g++
# python3: Required for some npm install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3-minimal \
    python3-pip \
    python3-venv \
    git-lfs \
    wget \
    ca-certificates \
    && git lfs install \
    && wget https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 -O /usr/bin/yq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

    
# 4. Switch back to runner user (Mandatory)
USER runner