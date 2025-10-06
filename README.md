# Cloudflare WARP SOCKS5 Proxy

A Docker container running Cloudflare WARP as a SOCKS5 proxy, allowing other containers and applications to route their traffic through Cloudflare's network.

[![Docker Pulls](https://img.shields.io/docker/pulls/rpfilomeno/warp)](https://hub.docker.com/r/rpfilomeno/warp)

``bash
docker run -d \
    --name warp-proxy \
    --restart unless-stopped \
    --cap-add=NET_ADMIN \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --sysctl net.ipv4.conf.all.src_valid_mark=1 \
    -p 1080:1080 \
    -v "$(pwd)/warp-data":/var/lib/cloudflare-warp \
    /warp
``

## Features

- 🚀 Easy setup with Docker Compose
- 🔒 Secure traffic routing through Cloudflare WARP
- 🌐 SOCKS5 proxy on port 1080
- 💾 Persistent WARP configuration
- ❤️ Health checks included
- 🔄 Automatic restart on failure

## Prerequisites

- Docker
- Docker Compose
- Host system with IPv6 support (or ability to disable IPv6 requirement)

## Quick Start

1. **Clone or create the files:**
   ```bash
   # Create directory
   mkdir warp-proxy && cd warp-proxy
   
   # Copy the Dockerfile and docker-compose.yml to this directory
   ```

2. **Start the proxy:**
   ```bash
   docker-compose up -d
   ```

3. **Check the logs:**
   ```bash
   docker-compose logs -f warp-socks5
   ```

4. **Verify WARP is connected:**
   ```bash
   docker-compose exec warp-socks5 warp-cli status
   ```

5. **Test the proxy:**
   ```bash
   curl -x socks5h://localhost:1080 https://www.cloudflare.com/cdn-cgi/trace
   ```

## Using the Proxy with Other Containers

### Method 1: Environment Variables (Recommended)

Add these environment variables to your container:

```yaml
services:
  your-app:
    image: your-image
    environment:
      - ALL_PROXY=socks5h://warp-socks5:1080
      - HTTPS_PROXY=socks5h://warp-socks5:1080
      - HTTP_PROXY=socks5h://warp-socks5:1080
      - NO_PROXY=localhost,127.0.0.1,.local,.internal
    depends_on:
      warp-socks5:
        condition: service_healthy
```

**Test from your container:**
```bash
docker-compose exec your-app curl https://www.cloudflare.com/cdn-cgi/trace
```

### Method 2: Shared Network Stack

Share the WARP container's network:

```yaml
services:
  your-app:
    image: your-image
    network_mode: "service:warp-socks5"
    # Use localhost:1080 as the proxy address
```

**Note:** You cannot expose ports when using `network_mode`.

### Method 3: From Host Machine

Access the proxy from your host:

```bash
# Using curl
curl -x socks5h://localhost:1080 https://example.com

# Using wget
wget -e use_proxy=yes -e socks_proxy=localhost:1080 https://example.com

# Configure system-wide (Linux/macOS)
export ALL_PROXY=socks5h://localhost:1080
```

### Method 4: Application-Specific Configuration

**Python (requests):**
```python
proxies = {
    'http': 'socks5h://warp-socks5:1080',
    'https': 'socks5h://warp-socks5:1080'
}
response = requests.get('https://example.com', proxies=proxies)
```

**Node.js:**
```javascript
const SocksProxyAgent = require('socks-proxy-agent');
const agent = new SocksProxyAgent('socks5h://warp-socks5:1080');
fetch('https://example.com', { agent });
```

**Go:**
```go
proxyURL, _ := url.Parse("socks5://warp-socks5:1080")
transport := &http.Transport{Proxy: http.ProxyURL(proxyURL)}
client := &http.Client{Transport: transport}
```

## Management Commands

### Start the proxy
```bash
docker-compose up -d
```

### Stop the proxy
```bash
docker-compose down
```

### Restart the proxy
```bash
docker-compose restart warp-socks5
```

### View logs
```bash
docker-compose logs -f warp-socks5
```

### Check WARP status
```bash
docker-compose exec warp-socks5 warp-cli status
```

### Check WARP settings
```bash
docker-compose exec warp-socks5 warp-cli settings
```

### Disconnect/Reconnect WARP
```bash
docker-compose exec warp-socks5 warp-cli disconnect
docker-compose exec warp-socks5 warp-cli connect
```

### Remove everything (including volumes)
```bash
docker-compose down -v
```

## Troubleshooting

### Container fails to start

**Check Docker logs:**
```bash
docker-compose logs warp-socks5
```

**Verify IPv6 is enabled:**
```bash
docker run --rm --sysctl net.ipv6.conf.all.disable_ipv6=0 alpine cat /proc/sys/net/ipv6/conf/all/disable_ipv6
```

### WARP won't connect

**Re-register WARP:**
```bash
docker-compose exec warp-socks5 warp-cli disconnect
docker-compose exec warp-socks5 warp-cli delete
docker-compose exec warp-socks5 warp-cli register
docker-compose exec warp-socks5 warp-cli connect
```

### Proxy not working

**Test connectivity:**
```bash
# From host
curl -v -x socks5h://localhost:1080 https://www.cloudflare.com/cdn-cgi/trace

# From another container
docker-compose exec your-app curl -v -x socks5h://warp-socks5:1080 https://www.cloudflare.com/cdn-cgi/trace
```

**Check if WARP is connected:**
```bash
docker-compose exec warp-socks5 warp-cli status
# Should show: Status update: Connected
```

### Permission issues

Ensure the container has `NET_ADMIN` capability:
```yaml
cap_add:
  - NET_ADMIN
```

## Configuration

### Change proxy port

Modify the `docker-compose.yml`:
```yaml
ports:
  - "2080:2080"  # Change host port
```

And update the startup script in `Dockerfile` to set the new port:
```bash
warp-cli --accept-tos set-proxy-port 2080
```

### Use WARP+ license

```bash
docker-compose exec warp-socks5 warp-cli set-license YOUR-LICENSE-KEY
```

## Security Considerations

- The proxy is exposed on `0.0.0.0:1080` by default. Consider using firewall rules or binding to `127.0.0.1:1080` if not needed on the network.
- WARP encrypts traffic between your container and Cloudflare's network.
- DNS queries are also routed through WARP when using `socks5h://` protocol.

## Performance

- WARP adds minimal latency (typically 10-30ms)
- Bandwidth depends on your connection and Cloudflare's network
- Multiple containers can share the same WARP proxy

## License

This project uses Cloudflare WARP client. Please review Cloudflare's terms of service.

## Contributing

Feel free to open issues or submit pull requests for improvements.

## Resources

- [Cloudflare WARP Documentation](https://developers.cloudflare.com/warp-client/)
- [Docker Documentation](https://docs.docker.com/)
- [SOCKS5 Protocol](https://en.wikipedia.org/wiki/SOCKS)

---

**Note:** This is not an official Cloudflare product. Use at your own discretion.