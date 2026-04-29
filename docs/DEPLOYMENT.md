# Deployment Guide

## Overview

This guide covers deploying the AI-Based Timetable Generation System in various environments, from local development to production servers.

---

## 1. Local Deployment (Development)

### Prerequisites

- SWI-Prolog 8.x or higher
- Modern web browser

### Steps

```bash
# Clone or extract the project
cd ai-timetable-generation

# Start the server
# Windows
"C:\Program Files\swipl\bin\swipl.exe" main.pl

# macOS/Linux
swipl main.pl
```

The server starts on `http://localhost:8080` by default.

---

## 2. Environment Configuration

All settings live in `config.pl`. Edit before starting the server.

### Key Settings

```prolog
server_port(8080).           % Change if 8080 is in use
log_level(info).             % debug | info | warning | error
max_search_nodes(10000).     % Increase for larger problems
search_timeout(120).         % Seconds before CSP timeout
request_timeout(300).        % Max API request duration
enable_persistence(false).   % Set true to persist data to disk
database_file('data/timetable_db.pl').  % Persistence file path
```

### Production Recommendations

```prolog
log_level(warning).          % Reduce log noise
max_search_nodes(50000).     % Allow deeper search
debug_mode(false).           % Disable debug output
enable_persistence(true).    % Persist data across restarts
```

---

## 3. Linux Server Deployment

### Install SWI-Prolog

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y swi-prolog

# CentOS/RHEL
sudo yum install -y pl

# Verify
swipl --version
```

### Run as a Background Service (systemd)

Create `/etc/systemd/system/timetable.service`:

```ini
[Unit]
Description=AI Timetable Generation System
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/ai-timetable
ExecStart=/usr/bin/swipl main.pl
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable timetable
sudo systemctl start timetable
sudo systemctl status timetable
```

View logs:

```bash
sudo journalctl -u timetable -f
```

### Run as Background Process (without systemd)

```bash
nohup swipl main.pl > logs/server.log 2>&1 &
echo $! > logs/server.pid

# Stop
kill $(cat logs/server.pid)
```

---

## 4. Windows Server Deployment

### Run as a Windows Service

Using NSSM (Non-Sucking Service Manager):

```powershell
# Download NSSM from https://nssm.cc/
# Install the service
nssm install TimetableServer "C:\Program Files\swipl\bin\swipl.exe" "C:\ai-timetable\main.pl"
nssm set TimetableServer AppDirectory "C:\ai-timetable"
nssm start TimetableServer
```

### Run in Background (PowerShell)

```powershell
Start-Process -FilePath "C:\Program Files\swipl\bin\swipl.exe" `
  -ArgumentList "main.pl" `
  -WorkingDirectory "C:\ai-timetable" `
  -WindowStyle Hidden `
  -RedirectStandardOutput "logs\server.log"
```

---

## 5. Docker Deployment (Optional)

### Dockerfile

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y swi-prolog && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

EXPOSE 8080

CMD ["swipl", "main.pl"]
```

### Build and Run

```bash
docker build -t ai-timetable .
docker run -d -p 8080:8080 --name timetable ai-timetable

# View logs
docker logs -f timetable

# Stop
docker stop timetable
```

### Docker Compose (with persistent data)

```yaml
version: '3.8'
services:
  timetable:
    build: .
    ports:
      - "8080:8080"
    volumes:
      - ./data:/app/data
    restart: unless-stopped
    environment:
      - LOG_LEVEL=info
```

```bash
docker-compose up -d
```

---

## 6. Reverse Proxy with Nginx (Optional)

To serve the app on port 80/443 with a domain name:

```nginx
server {
    listen 80;
    server_name timetable.example.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 300s;
    }
}
```

Enable HTTPS with Certbot:

```bash
sudo certbot --nginx -d timetable.example.com
```

---

## 7. Security Considerations

- **No authentication**: The system has no built-in user auth. Deploy behind a VPN or add Nginx basic auth for restricted access.
- **CORS**: Enabled by default for development. In production, restrict origins in `api_server.pl` if needed.
- **Input validation**: All API inputs are validated and sanitized. Do not expose the Prolog REPL directly.
- **Port exposure**: Only expose port 8080 (or your configured port) through the firewall. Use a reverse proxy for public-facing deployments.
- **Data persistence**: If `enable_persistence(true)`, ensure the `data/` directory is not web-accessible.

Firewall example (UFW):

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (if using Nginx)
sudo ufw allow 443/tcp   # HTTPS (if using Nginx)
sudo ufw deny 8080/tcp   # Block direct access to Prolog server
sudo ufw enable
```

---

## 8. Backup and Recovery

### Backup

If persistence is enabled, back up the database file:

```bash
# Linux cron job (daily backup)
0 2 * * * cp /opt/ai-timetable/data/timetable_db.pl /backups/timetable_db_$(date +%Y%m%d).pl
```

### Recovery

```bash
# Restore from backup
cp /backups/timetable_db_20240101.pl /opt/ai-timetable/data/timetable_db.pl
sudo systemctl restart timetable
```

Without persistence, data is in-memory only and is lost on restart. Re-submit resources via the API or web interface after each restart.

---

## 9. Monitoring and Logging

### Log Levels

Set in `config.pl`:

| Level | Use Case |
|-------|----------|
| `debug` | Development, verbose output |
| `info` | Normal operation (default) |
| `warning` | Production, reduced noise |
| `error` | Minimal logging |

### Health Check

```bash
curl http://localhost:8080/api/timetable
# Returns 200 with empty timetable if server is healthy
```

### Monitor with a Simple Script

```bash
#!/bin/bash
# health_check.sh
if ! curl -sf http://localhost:8080/api/timetable > /dev/null; then
    echo "Server down, restarting..."
    systemctl restart timetable
fi
```

Add to cron (check every 5 minutes):

```bash
*/5 * * * * /opt/ai-timetable/health_check.sh
```

---

## 10. Changing the Port

1. Edit `config.pl`:
   ```prolog
   server_port(9090).
   ```
2. Restart the server.
3. Update any rever
se proxy configuration to point to the new port.

---

## 11. Troubleshooting Deployment Issues

**Port already in use**
```bash
# Linux: find what's using port 8080
lsof -i :8080
# Windows
netstat -ano | findstr :8080
```

**SWI-Prolog not found**
```bash
which swipl          # Linux/macOS
where swipl          # Windows
```
If not found, add the SWI-Prolog `bin` directory to your `PATH`.

**Server starts but frontend not loading**
- Confirm `frontend_path('frontend')` in `config.pl` points to the correct directory.
- Check that `frontend/index.html` exists.

**High memory usage on large problems**
- Reduce `max_search_nodes` in `config.pl`.
- Restart the server to clear in-memory state.

**Slow generation**
- Increase `max_search_nodes` and `search_timeout` for larger datasets.
- Reduce the number of sessions (fewer classes or subjects).
- Check logs for backtracking counts — high backtracking indicates constraint conflicts in the dataset.
