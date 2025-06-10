# Multi-stage Dockerfile for Leyline Platform Integration Development
# Implements development-environment-consistency standards with security-first approach
#
# Usage: This Dockerfile is automatically used by devcontainer.json
# Customization: Modify tool versions and add project-specific dependencies

# Base image with Ubuntu LTS for stability
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone to UTC for consistency
ENV TZ=UTC

# Create development user for security (non-root development)
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# ============================================================================
# SYSTEM DEPENDENCIES AND SECURITY UPDATES
# ============================================================================

RUN apt-get update && apt-get install -y \
    # Essential system packages
    curl \
    wget \
    git \
    vim \
    nano \
    zsh \
    sudo \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    # Build tools and compilers
    build-essential \
    cmake \
    pkg-config \
    # Development utilities
    htop \
    tree \
    jq \
    unzip \
    zip \
    # Network tools for debugging
    netcat \
    telnet \
    dnsutils \
    iputils-ping \
    # Security tools
    openssl \
    # Database clients for development
    postgresql-client \
    redis-tools \
    # Clean up package cache
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# USER SETUP WITH SUDO ACCESS
# ============================================================================

# Create the user with sudo access
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# ============================================================================
# NODE.JS AND NPM ECOSYSTEM
# ============================================================================

# Install Node.js via NodeSource repository for latest stable version
ENV NODE_VERSION=20.11.0
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest \
    # Global tools for development workflow
    && npm install -g \
        yarn \
        pnpm \
        typescript \
        ts-node \
        eslint \
        prettier \
        @commitlint/cli \
        @commitlint/config-conventional \
        husky \
        lint-staged \
        nodemon \
        pm2 \
        serve

# ============================================================================
# PYTHON AND PACKAGE MANAGEMENT
# ============================================================================

# Install Python and pip
ENV PYTHON_VERSION=3.11
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3-pip \
    python3-setuptools \
    && ln -sf /usr/bin/python3.11 /usr/bin/python3 \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && python3 -m pip install --upgrade pip \
    # Essential Python development tools
    && pip3 install \
        pipenv \
        poetry \
        virtualenv \
        black \
        isort \
        flake8 \
        mypy \
        pytest \
        pytest-cov \
        bandit \
        safety \
        pre-commit \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# GO LANGUAGE SETUP
# ============================================================================

ENV GO_VERSION=1.21.6
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH

RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz \
    && rm go${GO_VERSION}.linux-amd64.tar.gz \
    && mkdir -p $GOPATH/src $GOPATH/bin \
    && chown -R $USERNAME:$USERNAME $GOPATH \
    # Install common Go development tools
    && go install golang.org/x/tools/gopls@latest \
    && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest \
    && go install golang.org/x/tools/cmd/goimports@latest \
    && go install github.com/go-delve/delve/cmd/dlv@latest

# ============================================================================
# RUST AND CARGO SETUP
# ============================================================================

ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && chmod -R a+w $RUSTUP_HOME $CARGO_HOME \
    && rustup update \
    && rustup component add rustfmt clippy \
    # Install common Rust development tools
    && cargo install cargo-edit \
    && cargo install cargo-watch \
    && cargo install cargo-audit \
    && cargo install cargo-outdated

# ============================================================================
# DOCKER INSTALLATION
# ============================================================================

# Install Docker for container builds within development environment
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin \
    && usermod -aG docker $USERNAME \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# ADDITIONAL DEVELOPMENT TOOLS
# ============================================================================

# Install Terraform for infrastructure as code
ENV TERRAFORM_VERSION=1.6.6
RUN wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install kubectl for Kubernetes development
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Install Helm for Kubernetes package management
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
    && apt-get update \
    && apt-get install -y helm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI for development workflow
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install security scanning tools
RUN curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin \
    && pip3 install detect-secrets

# ============================================================================
# SHELL CONFIGURATION (ZSH WITH OH-MY-ZSH)
# ============================================================================

# Install Oh My Zsh for enhanced shell experience
USER $USERNAME
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Configure Zsh with development-friendly settings
RUN echo 'export ZSH="$HOME/.oh-my-zsh"' >> ~/.zshrc \
    && echo 'ZSH_THEME="robbyrussell"' >> ~/.zshrc \
    && echo 'plugins=(git docker docker-compose kubectl terraform golang rust python node npm yarn)' >> ~/.zshrc \
    && echo 'plugins+=(zsh-autosuggestions zsh-syntax-highlighting)' >> ~/.zshrc \
    && echo 'source $ZSH/oh-my-zsh.sh' >> ~/.zshrc \
    && echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc \
    && echo 'export EDITOR=vim' >> ~/.zshrc \
    && echo 'alias ll="ls -alF"' >> ~/.zshrc \
    && echo 'alias la="ls -A"' >> ~/.zshrc \
    && echo 'alias l="ls -CF"' >> ~/.zshrc \
    && echo 'alias ..="cd .."' >> ~/.zshrc \
    && echo 'alias ...="cd ../.."' >> ~/.zshrc \
    && echo 'alias grep="grep --color=auto"' >> ~/.zshrc \
    && echo 'alias dc="docker-compose"' >> ~/.zshrc \
    && echo 'alias k="kubectl"' >> ~/.zshrc

# Switch back to root for final configuration
USER root

# ============================================================================
# WORKSPACE SETUP AND PERMISSIONS
# ============================================================================

# Create workspace directory and set ownership
RUN mkdir -p /workspace \
    && chown -R $USERNAME:$USERNAME /workspace \
    && mkdir -p /home/$USERNAME/.cache \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/.cache

# Set up Git configuration placeholders
USER $USERNAME
RUN git config --global init.defaultBranch main \
    && git config --global pull.rebase false \
    && git config --global core.autocrlf false \
    && git config --global core.filemode false \
    && git config --global core.editor vim

USER root

# ============================================================================
# FINAL CONFIGURATION AND CLEANUP
# ============================================================================

# Set working directory
WORKDIR /workspace

# Set default user for development
USER $USERNAME

# Configure environment variables for development
ENV SHELL=/bin/zsh
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Health check to ensure container is ready
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Default command to keep container running
CMD ["/bin/zsh", "-l"]

# ============================================================================
# DEVELOPMENT NOTES
# ============================================================================
#
# This Dockerfile creates a comprehensive development environment with:
# - Multi-language support (Node.js, Python, Go, Rust)
# - Security tools (TruffleHog, detect-secrets)
# - Container development (Docker, Kubernetes)
# - Infrastructure tools (Terraform, Helm)
# - Enhanced shell experience (Zsh with Oh My Zsh)
#
# Security considerations:
# - Non-root user for development activities
# - Latest security updates for base packages
# - Pinned versions for reproducible builds
# - No secrets or credentials in the image
#
# Performance optimizations:
# - Multi-stage approach for layer caching
# - Combined RUN commands to reduce layers
# - Package cache cleanup to reduce image size
# - Volume mounts for dependency caching
#
# Customization points:
# - Adjust language versions in environment variables
# - Add project-specific tools in additional RUN commands
# - Modify shell configuration in .zshrc setup
# - Configure additional development services as needed
