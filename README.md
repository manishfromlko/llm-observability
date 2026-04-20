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
├── .gitignore
└── README.md
```

## Overview

This setup provides:

- **Langfuse**: Open-source LLM observability and tracing platform
- **LiteLLM**: LLM proxy with unified API and callback logging
- **Integrated Logging**: LiteLLM automatically logs all requests to Langfuse
- **Automated Setup**: One-command setup with automatic organization, project, and API key creation

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

## Stopping Services

```bash
# Stop all services
docker-compose -f langfuse/docker-compose.yml -f litellm/docker-compose.yml down

# Stop and remove volumes (deletes all data)
docker-compose -f langfuse/docker-compose.yml -f litellm/docker-compose.yml down -v
```

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
