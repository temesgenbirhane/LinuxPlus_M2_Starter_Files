FROM ubuntu:22.04
LABEL description="Linux+ M2 Deployment Environment"
LABEL course="CompTIA Linux+ XK0-006 FastForward"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisites
# These packages are pre-installed so your script can focus on configuration,
# not on bootstrapping the environment
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    vim \
    nano \
    cron \
    ufw \
    logrotate \
    systemd \
    systemd-sysv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create the working directory where your script will live
WORKDIR /opt/deploy
# deploy.sh is provided via volume mount — no COPY needed
# Students edit on the host; changes appear immediately at /opt/deploy/deploy.sh

# Default command: interactive bash shell
# Your script is at /opt/deploy/deploy.sh — run it with: bash deploy.sh
CMD ["/bin/bash"]