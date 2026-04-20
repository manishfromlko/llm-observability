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
├── .gitignore
└── README.md
```

## Overview

This setup provides:

- **Langfuse**: Open-source LLM observability and tracing platform
- **LiteLLM**: LLM proxy with unified API and callback logging
- **Integrated Logging**: LiteLLM automatically logs all requests to Langfuse

## Quick Start

### 1. Start Langfuse

```bash
cd langfuse
cp .env.example .env
# Update .env with your desired configuration
docker-compose up -d
```

Wait for Langfuse to be healthy (check: `http://localhost:3000`)

### 2. Start LiteLLM

```bash
cd ../litellm
cp .env.example .env
# Update .env with your API keys and Langfuse credentials
docker-compose up -d
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
