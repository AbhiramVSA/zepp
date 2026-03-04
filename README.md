# zepp

A full-stack voice transcription application that captures audio and converts speech to text in real time. Built with a FastAPI backend and Flutter frontend, it provides user authentication, persistent transcript history, and cross-platform support.

## Features

- **Real-time voice transcription** -- Stream audio from the device microphone and receive instant text output via the Whisper large-v3-turbo model on Groq.
- **User authentication** -- Signup, login, and session management powered by Supabase Auth with JWT tokens.
- **Transcript history** -- Browse, search, and manage all past transcriptions with offline caching.
- **Offline support** -- Two-tier cache (memory + SQLite) with optimistic writes and background sync queue.
- **Theming** -- Toggle between dark and light modes.
- **Cross-platform** -- Supports Android, iOS, Web, Windows, macOS, and Linux.

## Architecture

### System Overview

```mermaid
graph LR
    A[Flutter App] -- "PCM audio (WebSocket)" --> B[FastAPI Backend]
    B -- "Transcription result" --> A
    B -- "Whisper API (HTTPS)" --> C[Groq API]
    C -- "Text result" --> B
    A -- "REST API" --> B
    B -- "SQL" --> D[(PostgreSQL<br/>Supabase)]
    A -- "Local cache" --> E[(SQLite + Memory)]
```

### Audio Transcription Flow

1. The Flutter app captures audio using the device microphone (PCM 16-bit, 16 kHz, mono).
2. Audio chunks stream in real time over a WebSocket connection to the `/ws/audio` endpoint.
3. The backend buffers incoming chunks until it receives an `end` event.
4. Raw PCM audio is converted to WAV format with appropriate headers.
5. The WAV file is sent to the Groq API using the Whisper transcription model.
6. The transcription result is returned to the client over the same WebSocket.
7. If the user is authenticated, the transcript is automatically persisted to the database.

### Authentication Flow

1. The user submits credentials via the login or signup screen.
2. The backend proxies the request to Supabase Auth.
3. On success, JWT access and refresh tokens are returned.
4. Tokens are stored in SharedPreferences for session persistence.
5. Protected API routes validate the JWT against the Supabase JWT secret.
6. Users are created in the local database on first authenticated request.

## Tech Stack

### Backend

| Component        | Technology                    |
| ---------------- | ----------------------------- |
| Framework        | FastAPI                       |
| Language         | Python 3.13+                  |
| ORM              | SQLAlchemy 2.0+ (async)       |
| Database Driver  | asyncpg                       |
| Authentication   | Supabase Auth, python-jose    |
| Transcription    | Groq API (Whisper)            |
| HTTP Client      | httpx                         |
| Configuration    | Pydantic Settings             |

### Frontend

| Component        | Technology                    |
| ---------------- | ----------------------------- |
| Framework        | Flutter 3.10+                 |
| Language         | Dart                          |
| State Management | Provider                      |
| Audio Recording  | flutter_sound                 |
| WebSocket        | web_socket_channel            |
| Local Cache      | Drift (SQLite)                |
| Animations       | flutter_animate               |

## Project Structure

```
zepp-app/
  backend/
    pyproject.toml
    app/
      main.py                       # Application entry point
      api/
        api.py                      # Router aggregation + health check
        v1/routers/
          audio_ws.py               # WebSocket audio streaming
          auth.py                   # Authentication endpoints
          transcripts.py            # Transcript CRUD
      config/settings.py            # Pydantic-based configuration
      crud/
        transcript.py               # Transcript DB operations
        user.py                     # User DB operations
      db/database.py                # Async SQLAlchemy engine
      deps/auth.py                  # Auth dependency injection
      models/
        transcript.py               # Transcript ORM model
        user.py                     # User ORM model
      schemas/
        auth.py                     # Auth request/response schemas
        transcript.py               # Transcript schemas
        user.py                     # User schemas
      utils/security.py             # JWT verification with caching

  frontend-app/flutter_app/
    pubspec.yaml
    lib/
      main.dart                     # Application entry point
      core/
        app_config.dart             # Backend URL configuration
        app_theme.dart              # Theme definitions
        cache/                      # Two-tier caching (memory + SQLite)
        database/                   # Drift database schema
        widgets/                    # Shared UI components
      features/
        authentication/             # Login and signup (MVVM)
        transcribe/                 # Voice recording (MVVM)
        home/                       # Navigation and history (MVVM)
```

## Prerequisites

### Backend

- Python 3.13 or higher
- pip (or [uv](https://docs.astral.sh/uv/))

### Frontend

- Flutter SDK 3.10.3 or higher
- Android Studio or Xcode (for mobile development)
- A physical device or emulator

### External Services

- **Supabase** -- authentication and PostgreSQL hosting
- **Groq** -- Whisper transcription API

## Installation

### Backend Setup

```bash
cd backend

# Create and activate a virtual environment
python -m venv .venv
source .venv/bin/activate        # macOS / Linux
.venv\Scripts\activate           # Windows

# Install dependencies
pip install -e .

# Create .env from example
cp .env.example .env
# Edit .env with your credentials (see Configuration section)

# Start the development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`. Interactive docs are at `http://localhost:8000/docs`.

### Frontend Setup

```bash
cd frontend-app/flutter_app

# Install dependencies
flutter pub get

# Run on default device
flutter run

# Run with custom backend URLs
flutter run \
  --dart-define=BACKEND_BASE_URL=http://your-server:8000 \
  --dart-define=BACKEND_WS_URL=ws://your-server:8000/ws/audio
```

## Configuration

### Environment Variables

Create a `.env` file in the `backend/` directory (see `.env.example`):

```env
DATABASE_URL=postgresql+asyncpg://user:password@host:port/database
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_supabase_anon_key
SUPABASE_JWT_SECRET=your_jwt_secret
JWT_AUDIENCE=
GROQ_API_KEY=your_groq_api_key
```

| Variable             | Description                                                                 |
| -------------------- | --------------------------------------------------------------------------- |
| `DATABASE_URL`       | PostgreSQL connection string using the asyncpg driver.                      |
| `SUPABASE_URL`       | Supabase project URL (Project Settings > API).                              |
| `SUPABASE_KEY`       | Supabase anon or service role key.                                          |
| `SUPABASE_JWT_SECRET`| JWT secret for token verification (API Settings > JWT Settings).            |
| `JWT_AUDIENCE`       | Optional JWT audience claim. Leave empty to skip audience verification.     |
| `GROQ_API_KEY`       | API key from the Groq console.                                              |

### Frontend Configuration

Backend URLs are set at build time via Dart defines:

| Define              | Default                          | Description                        |
| ------------------- | -------------------------------- | ---------------------------------- |
| `BACKEND_BASE_URL`  | `http://10.0.2.2:8000`          | REST API base URL                  |
| `BACKEND_WS_URL`    | `ws://10.0.2.2:8000/ws/audio`   | WebSocket URL for audio streaming  |

### External Service Setup

**Supabase** -- Create a project at [supabase.com](https://supabase.com). Copy the project URL, anon key, JWT secret, and database connection string into `.env`.

**Groq** -- Create an account at [console.groq.com](https://console.groq.com). Generate an API key and add it to `.env`.

## API Reference

### Health Check

```
GET /health
```

Returns `{"status": "ok"}`.

### Authentication

| Method | Endpoint         | Description                  | Auth Required |
| ------ | ---------------- | ---------------------------- | ------------- |
| POST   | `/auth/signup`   | Register a new user          | No            |
| POST   | `/auth/login`    | Authenticate an existing user| No            |
| POST   | `/auth/refresh`  | Refresh an expired token     | No            |
| GET    | `/auth/whoami`   | Get current user info        | Yes           |

**Request body** (signup and login):

```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response** (signup and login):

```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user_id": "uuid",
  "email": "user@example.com"
}
```

### Transcripts

| Method | Endpoint                    | Description                 | Auth Required |
| ------ | --------------------------- | --------------------------- | ------------- |
| POST   | `/transcripts/`             | Save a new transcript       | Yes           |
| GET    | `/transcripts/history`      | List transcript history     | Yes           |
| GET    | `/transcripts/{id}`         | Get a single transcript     | Yes           |

**Query parameters** for `/transcripts/history`:

| Parameter | Type    | Default | Description                     |
| --------- | ------- | ------- | ------------------------------- |
| `limit`   | integer | 50      | Maximum number of results       |
| `offset`  | integer | 0       | Number of results to skip       |

### WebSocket Audio Streaming

```
WS /ws/audio
```

1. Send raw PCM audio data as binary frames (16-bit, 16 kHz, mono).
2. Send `{"event": "end"}` when recording is complete.
3. Receive `{"text": "Transcribed content"}` as the result.

On error, the server responds with `{"error": "Error message"}`.

## Database Schema

```mermaid
erDiagram
    users {
        varchar id PK "Supabase user ID"
        varchar email UK "User email"
        boolean is_active "Default: true"
        boolean is_superuser "Default: false"
        timestamp created_at "Default: now()"
    }
    transcripts {
        uuid id PK "Auto-generated"
        varchar user_id FK "References users.id"
        text text "Transcription content"
        float confidence "Nullable"
        float duration_seconds "Nullable"
        jsonb metadata "Nullable"
        text audio_url "Nullable"
        timestamp created_at "Default: now()"
        timestamp updated_at "Default: now()"
    }
    users ||--o{ transcripts : "has many"
```

## Development

### Running Tests

```bash
# Backend
cd backend && pytest

# Frontend
cd frontend-app/flutter_app && flutter test
```

### Code Style

```bash
# Backend
black app/
isort app/
mypy app/

# Frontend
flutter analyze
dart format lib/
```

### Production Build

**Backend:**

```bash
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

**Frontend:**

```bash
flutter build apk --release --dart-define=BACKEND_BASE_URL=https://api.production.com
flutter build ios --release --dart-define=BACKEND_BASE_URL=https://api.production.com
flutter build web --release --dart-define=BACKEND_BASE_URL=https://api.production.com
```

## License

This project is available under the [MIT License](LICENSE).
