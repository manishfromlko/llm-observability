# Langfuse + LiteLLM Docker Compose Setup

A minimal, clean Docker Compose setup for running Langfuse and LiteLLM with callback-based logging integration.

## Directory Structure

```
.
├── langfuse/               # Langfuse tracing and observability
│   ├── docker-compose.yml
│   ├── .env.example
│   └── README.md
├── litellm/                # LiteLLM proxy with Langfuse callbacks
│   ├── docker-compose.yml
│   ├── litellm_config.yaml
│   ├── prometheus.yml
│   ├── .env.example
│   └── README.md
├── start.sh                # Automated setup script
├── stop.sh                 # Service management script
├── .gitignore
└── README.md
```

## Prerequisites

Before getting started, ensure you have:

- **Docker**: Version 20.10 or later
- **Docker Compose**: Version 2.0 or later
- **OpenAI API Key**: Required for LiteLLM to proxy requests to OpenAI models
- **Git**: For cloning this repository

### System Requirements

- **RAM**: At least 4GB available
- **Disk Space**: At least 5GB free space for Docker images and data
- **Ports**: Ensure ports 3000, 3030, 4000, 5432, 5442, 6379, 8123, 9090, 9091 are available

## Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd llm-infra
   ```

2. **Make scripts executable**:
   ```bash
   chmod +x start.sh stop.sh
   ```

3. **Add your OpenAI API key**:
   ```bash
   # Edit the LiteLLM environment file
   nano litellm/.env.example
   
   # Add your OpenAI API key:
   OPENAI_API_KEY=your-openai-api-key-here
   ```

## Quick Start

### Automated Setup (Recommended)

Run the automated setup script that handles everything:

```bash
./start.sh
```

This script will:
1. Generate secure API keys for Langfuse
2. Configure headless initialization for Langfuse (creates org, project, user, and API keys automatically)
3. Start Langfuse services and wait for them to be healthy
4. Configure LiteLLM with the generated Langfuse credentials
5. Start LiteLLM services

### Manual Setup (Alternative)

If you prefer manual setup:

#### 1. Start Langfuse

```bash
cd langfuse
cp .env.example .env
# Update .env with your desired configuration
docker-compose up -d
```

Wait for Langfuse to be healthy (check: `http://localhost:3000`)

#### 2. Start LiteLLM

```bash
cd ../litellm
cp .env.example .env
# Update .env with your API keys and Langfuse credentials
docker-compose up -d
```

## Services

### Langfuse Services
- **langfuse-web**: Main web interface (port 3000)
- **langfuse-worker**: Background worker service (port 3030)
- **postgres**: PostgreSQL database (port 5432, localhost only)
- **clickhouse**: ClickHouse analytics database (port 8123, localhost only)
- **minio**: S3-compatible storage (port 9090)
- **redis**: Redis cache (port 6379, localhost only)

### LiteLLM Services
- **litellm**: LiteLLM proxy server (port 4000)
- **db**: PostgreSQL database for LiteLLM (port 5442)
- **prometheus**: Metrics collection (port 9090, conflicts with MinIO - adjust if needed)

## Access Points

After running `./start.sh`:

- **Langfuse UI**: http://localhost:3000
  - Admin Email: `admin@example.com`
  - Admin Password: `admin123`
- **LiteLLM API**: http://localhost:4000
- **Langfuse API Keys**: Automatically generated and configured

## API Keys

The setup script generates secure API keys automatically. You can find them in the output or check the `.env` files:

- `LANGFUSE_PUBLIC_KEY`: Public API key for Langfuse
- `LANGFUSE_SECRET_KEY`: Secret API key for Langfuse

## Usage

Once both services are running, all requests to LiteLLM will be automatically traced in Langfuse.

Example request to LiteLLM:

```bash
curl -X POST http://localhost:4000/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{
    "model": "gpt-4o-mini",
    "messages": [{"role": "user", "content": "Hello, world!"}]
  }'
```

Check Langfuse at http://localhost:3000 to see the traces.

## Testing the Setup

### 1. Test LiteLLM API

Make a test request to LiteLLM:

```bash
curl -X POST http://localhost:4000/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{
    "model": "gpt-4o-mini",
    "messages": [{"role": "user", "content": "Hello, world!"}]
  }'
```

Expected response:
```json
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "gpt-4o-mini",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "Hello! How can I help you today?"
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 13,
    "completion_tokens": 8,
    "total_tokens": 21
  }
}
```

### 2. Verify Tracing in Langfuse

1. Open http://localhost:3000 in your browser
2. Log in with:
   - Email: `admin@example.com`
   - Password: `admin123`
3. Navigate to the "Traces" section
4. You should see the test request you just made

### 3. Check Service Health

```bash
# Check all running containers
docker ps

# Check Langfuse health
curl http://localhost:3000

# Check LiteLLM health
curl http://localhost:4000/health/liveliness
```

## Stopping Services

### Using the Stop Script (Recommended)

```bash
# Stop all services
./stop.sh

# Stop all services and remove all data (including databases)
./stop.sh -v
```

### Manual Stop

```bash
# Stop all services
docker-compose -f langfuse/docker-compose.yml -f litellm/docker-compose.yml down

# Stop and remove volumes (deletes all data)
docker-compose -f langfuse/docker-compose.yml -f litellm/docker-compose.yml down -v
```

## Production Considerations

### Security

- **Change default passwords**: Update admin credentials in Langfuse
- **Use environment-specific configs**: Don't use `.env.example` files in production
- **Secure API keys**: Store secrets in a proper secret management system
- **Network isolation**: Configure proper firewall rules and network segmentation

### Performance

- **Resource allocation**: Increase Docker resource limits for production workloads
- **Database tuning**: Configure PostgreSQL and ClickHouse for your scale
- **Monitoring**: Set up proper monitoring and alerting for all services
- **Backup strategy**: Implement regular backups for databases and persistent data

### Configuration Changes

For production deployment:

1. **Langfuse**:
   - Set `LANGFUSE_INIT_ORG_NAME`, `LANGFUSE_INIT_PROJECT_NAME` appropriately
   - Configure external database URLs
   - Set up proper authentication and authorization

2. **LiteLLM**:
   - Configure multiple LLM providers
   - Set up rate limiting and cost tracking
   - Configure proper logging and monitoring

3. **Infrastructure**:
   - Use managed databases (RDS, Cloud SQL, etc.)
   - Set up load balancers and reverse proxies
   - Configure SSL/TLS certificates
   - Implement auto-scaling

### Port Conflicts

If you encounter port conflicts:

- **Port 9090**: Both MinIO (Langfuse) and Prometheus (LiteLLM) use this port
  - Solution: Change Prometheus port in `litellm/docker-compose.yml`
- **Database ports**: Ensure 5432 and 5442 are available
- **Redis port**: Ensure 6379 is available

## Troubleshooting

### Common Issues

1. **Services won't start**:
   - Check Docker and Docker Compose versions
   - Ensure ports are available: `netstat -tulpn | grep :3000`
   - Check disk space: `df -h`

2. **Langfuse not accessible**:
   - Wait for services to fully start (can take 2-3 minutes)
   - Check logs: `docker-compose -f langfuse/docker-compose.yml logs`

3. **LiteLLM API errors**:
   - Verify OpenAI API key is set correctly
   - Check LiteLLM logs: `docker-compose -f litellm/docker-compose.yml logs`

4. **Tracing not appearing in Langfuse**:
   - Verify Langfuse credentials in LiteLLM config
   - Check network connectivity between containers
   - Ensure Langfuse is healthy before starting LiteLLM

### Logs

```bash
# View all logs
docker-compose -f langfuse/docker-compose.yml -f litellm/docker-compose.yml logs

# View specific service logs
docker-compose -f langfuse/docker-compose.yml logs langfuse-web
docker-compose -f litellm/docker-compose.yml logs litellm

# Follow logs in real-time
docker-compose -f langfuse/docker-compose.yml logs -f
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

See LICENSE file for details.

## Configuration

### Environment Variables

#### Langfuse (.env)
- `NEXTAUTH_SECRET`: Secret for NextAuth authentication
- `ENCRYPTION_KEY`: Key for encrypting sensitive data
- `DATABASE_URL`: PostgreSQL connection string
- `LANGFUSE_INIT_*`: Headless initialization variables (set automatically by start.sh)

#### LiteLLM (.env)
- `OPENAI_API_KEY`: Your OpenAI API key
- `LANGFUSE_PUBLIC_KEY`: Langfuse public API key (set automatically by start.sh)
- `LANGFUSE_SECRET_KEY`: Langfuse secret API key (set automatically by start.sh)
- `LANGFUSE_BASE_URL`: Langfuse base URL (http://langfuse-web:3000)

## Security Notes

For production deployment:
- Change default admin credentials
- Use strong, randomly generated secrets
- Configure proper network isolation
- Set up SSL/TLS certificates
- Review and update all security-related environment variables

## Troubleshooting

### Common Issues

1. **Port conflicts**: If ports 3000, 4000, 5432, etc. are already in use, modify the docker-compose.yml files
2. **Database connection issues**: Ensure PostgreSQL containers are healthy before starting dependent services
3. **API key issues**: Regenerate keys by re-running `./start.sh` (will create new keys)

### Logs

Check service logs:

```bash
# Langfuse logs
cd langfuse && docker-compose logs -f

# LiteLLM logs
cd litellm && docker-compose logs -f
```

### Reset

To reset everything and start fresh:

```bash
# Stop and remove all containers and volumes
docker-compose -f langfuse/docker-compose.yml -f litellm/docker-compose.yml down -v

# Remove generated .env files
rm langfuse/.env litellm/.env

# Re-run setup
./start.sh
```
```

### 3. Verify

- Langfuse Web: http://localhost:3000
- LiteLLM Proxy: http://localhost:4000
- Prometheus Metrics: http://localhost:9191

## Configuration

Each service has its own README with detailed configuration options:
- [Langfuse Configuration](./langfuse/README.md)
- [LiteLLM Configuration](./litellm/README.md)

## Key Environment Variables

### Langfuse
See [langfuse/.env.example](./langfuse/.env.example)

### LiteLLM
See [litellm/.env.example](./litellm/.env.example)

### Critical for Integration
When setting up LiteLLM, ensure these are configured in `litellm/.env`:
```
LANGFUSE_PUBLIC_KEY=your-key
LANGFUSE_SECRET_KEY=your-secret
LANGFUSE_BASE_URL=http://langfuse-web:3000
```

## Usage

### Make a request through LiteLLM

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer sk-1234" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o-mini",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

All requests will be logged to Langfuse. You can view them in the Langfuse web UI.

## Stopping Services

To stop all services:

```bash
cd langfuse && docker-compose down
cd ../litellm && docker-compose down
```

To remove all data (volumes):

```bash
cd langfuse && docker-compose down -v
cd ../litellm && docker-compose down -v
```

## Security Notes

This is a development setup. For production:

1. **Change all default passwords** in `.env` files
2. **Use strong secrets** for encryption keys
3. **Secure the database** with complex passwords
4. **Use environment-specific configurations**
5. **Don't commit `.env` files** to git
6. **Use secrets management** (AWS Secrets Manager, HashiCorp Vault, etc.)

## Troubleshooting

### Services won't start
- Check Docker is running
- Verify ports 3000, 4000, 5432, etc. are available
- Check logs: `docker-compose logs`

### Can't connect to Langfuse from LiteLLM
- Ensure both services are running
- Check network connectivity: `docker exec litellm ping langfuse-web` (use service names)
- Verify `LANGFUSE_BASE_URL` in LiteLLM `.env`

### Database issues
- Delete volumes and restart: `docker-compose down -v && docker-compose up -d`
- Check database logs: `docker-compose logs db`

## References

- [Langfuse Docs](https://langfuse.com/docs)
- [LiteLLM Docs](https://docs.litellm.ai)
- [LiteLLM Callbacks](https://docs.litellm.ai/docs/observability/callbacks)
