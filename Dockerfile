FROM debian:trixie-slim

ARG COMMIT_SHA

LABEL org.opencontainers.image.authors="rpfilomeno"
LABEL org.opencontainers.image.url="https://github.com/rpfilomeno/warp-socks5"
LABEL COMMIT_SHA=${COMMIT_SHA}
# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Add Cloudflare's GPG key and repository
RUN curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list

# Install Cloudflare WARP
RUN apt-get update && \
    apt-get install -y cloudflare-warp && \
    rm -rf /var/lib/apt/lists/*

    

RUN curl -LO https://github.com/ginuerzh/gost/releases/download/v2.12.0/gost_2.12.0_linux_amd64v3.tar.gz && \
    tar -xzf gost_2.12.0_linux_amd64v3.tar.gz -C /usr/bin/ gost && \
    chmod +x /usr/bin/gost && \
    rm -rf gost_2.12.0_linux_amd64v3.tar.gz

# Create startup script
COPY entrypoint.sh /entrypoint.sh
# Create health check script
COPY health-check.sh /health-check.sh

RUN chmod +x /health-check.sh && \
    chmod +x /entrypoint.sh


ENV GOST_ARGS="-L :1080"

# Run the startup script
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
  CMD /health-check.sh

ENTRYPOINT ["/entrypoint.sh"]