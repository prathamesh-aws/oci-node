# Use the official Jenkins LTS image as the base
FROM jenkins/jenkins:lts

# Switch to root user to install additional tools
USER root

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Add Docker’s official GPG key and repository
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list

# Install Docker CLI (and optionally Docker Engine)
RUN apt-get update && apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    && rm -rf /var/lib/apt/lists/*

# Optional: Add Jenkins user to the Docker group (if Docker daemon is present)
RUN usermod -aG docker jenkins

# Install Node.js & npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest

# Verify installations
RUN node -v && npm -v

# Switch back to the Jenkins user
USER jenkins

# Expose Jenkins default port
EXPOSE 8080
