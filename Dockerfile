FROM debian:trixie-slim

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

# Create startup script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Start warp-svc daemon in background\n\
warp-svc &\n\
sleep 2\n\
\n\
# Register and connect to WARP\n\
warp-cli --accept-tos register || true\n\
sleep 1\n\
\n\
# Set proxy mode to SOCKS5 on port 1080\n\
warp-cli --accept-tos set-mode proxy\n\
warp-cli --accept-tos set-proxy-port 1080\n\
sleep 1\n\
\n\
# Connect to WARP\n\
warp-cli --accept-tos connect\n\
sleep 2\n\
\n\
echo "Cloudflare WARP SOCKS5 proxy is running on port 1080"\n\
\n\
# Keep container running and monitor warp-svc\n\
tail -f /dev/null' > /start.sh && \
    chmod +x /start.sh

# Expose SOCKS5 proxy port
EXPOSE 1080

# Run the startup script
CMD ["/start.sh"]