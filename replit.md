# Stirling PDF

Stirling PDF is a powerful, open-source PDF editing platform. It provides 50+ PDF tools including editing, merging, splitting, signing, redacting, converting, OCR, compression, and more.

## Project Structure

- `frontend/` - React + Vite frontend (TypeScript, Tailwind, Mantine UI)
- `app/` - Java Spring Boot backend (Gradle build system)
- `engine/` - Python AI engine (optional, for AI-powered features)
- `docker/` - Docker compose files for full-stack deployment

## Build Modes

The frontend supports multiple build modes:
- `core` - Open source features only
- `proprietary` - Core + proprietary features  
- `saas` - SaaS cloud version
- `desktop` - Tauri desktop app
- `prototypes` - Prototype features

## Running the App

The frontend dev server runs on port 5000 in `core` mode.

### Frontend only (default workflow):
```bash
cd frontend && PORT=5000 npx vite --mode core --port 5000
```

### Full stack (frontend + backend):
The Java backend requires Gradle and runs on port 8080. Start it with:
```bash
./gradlew :stirling-pdf:bootRun
```
Then start the frontend (it proxies `/api/*` to `localhost:8080`).

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

## User Preferences

- Frontend port: 5000
- Frontend host: 0.0.0.0
- Build mode: core (open source) for development
