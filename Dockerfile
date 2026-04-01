FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Unminimize the image
RUN yes | unminimize

# Install common packages
RUN apt-get update && apt-get install -y \
    git \
    curl \
    fish \
    vim \
    sudo \
    gosu \
    tmux \
    ripgrep \
    ca-certificates \
    locales \
    pipx \
    && rm -rf /var/lib/apt/lists/*

# Generate locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Install latest n (Node version manager) and latest Node/npm
RUN curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n -o /usr/local/bin/n \
    && chmod +x /usr/local/bin/n \
    && n lts \
    && rm -f /usr/local/bin/n \
    && npm install -g npm@latest n@latest

# Install GitHub Copilot CLI
RUN npm install -g @github/copilot \
    && chmod -R a+rx /usr/local/lib/node_modules /usr/local/bin

# Install telegram-send via pipx (system-wide)
RUN PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install telegram-send

# Copy default config files
COPY .tmux.conf /etc/skel/.tmux.conf

# Create copilot hooks template
RUN mkdir -p /etc/skel/.copilot/hooks
COPY hooks/tg.json /etc/skel/.copilot/hooks/tg.json

# Copy notification script
COPY copilot-tg-notify.py /usr/local/bin/copilot-tg-notify
RUN chmod +x /usr/local/bin/copilot-tg-notify

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["fish"]
