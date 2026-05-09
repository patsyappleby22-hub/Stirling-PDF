# Stirling PDF

Stirling PDF is a powerful, open-source PDF editing platform. It provides 50+ PDF tools including editing, merging, splitting, signing, redacting, converting, OCR, compression, and more.

## Project Structure

- `frontend/` - React + Vite frontend (TypeScript, Tailwind, Mantine UI)
- `app/` - Java Spring Boot backend (Gradle build system)
- `engine/` - Python AI engine (optional, for AI-powered features)
- `docker/` - Docker compose files for full-stack deployment
- `Dockerfile` - Production Docker image (fat version, all features)
- `northflank.json` - Northflank IaC configuration
- `NORTHFLANK_DEPLOY.md` - Step-by-step Northflank deployment guide

## Build Modes

The frontend supports multiple build modes:
- `core` - Open source features only
- `proprietary` - Core + proprietary features
- `saas` - SaaS cloud version
- `desktop` - Tauri desktop app
- `prototypes` - Prototype features

## Running the App (Development)

Two workflows run simultaneously:
1. **Start application** - React/Vite frontend on port 5000
2. **Backend** - Java Spring Boot backend on port 8080

The frontend proxies all `/api/*` requests to the backend.

### Frontend only:
```bash
cd frontend && PORT=5000 npx vite --mode core --port 5000
```

### Backend:
```bash
SERVER_PORT=8080 ./gradlew :stirling-pdf:bootRun
```

## Key Dependencies

- Node.js 20+
- Java 19+ (GraalVM for backend)
- npm for frontend packages

## Environment Setup

Frontend env vars go in `frontend/.env.local` (gitignored).
Before running, generate icon assets:
```bash
cd frontend && node scripts/generate-icons.js
```

## Northflank Deployment

See `NORTHFLANK_DEPLOY.md` for full step-by-step instructions.

Key points:
- Use the root `Dockerfile` (fat version with all tools)
- Set `SECURITY_ENABLELOGIN=false` to disable mandatory login
- Port: `8080`
- Auto-deploy on GitHub push is supported natively in Northflank

## User Preferences

- Frontend port: 5000
- Frontend host: 0.0.0.0
- Build mode: core (open source) for development
- Login: disabled (SECURITY_ENABLELOGIN=false)
