# zepp

A full-stack voice transcription application that captures audio and converts speech to text in real time. Built with a FastAPI backend and Flutter frontend, it provides user authentication, persistent transcript history, and cross-platform support.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [API Reference](#api-reference)
- [Database Schema](#database-schema)
- [Usage](#usage)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Real-time voice transcription** -- Stream audio from the device microphone and receive instant text output via the Whisper large-v3-turbo model on Groq.
- **User authentication** -- Signup, login, and session management powered by Supabase Auth with JWT tokens.
- **Transcript history** -- Browse, search, and manage all past transcriptions.
- **Session persistence** -- Automatic session restoration on app restart using secure local storage.
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
    A -- "Local storage" --> E[(SharedPreferences)]
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
| Framework        | FastAPI 0.124+                |
| Language         | Python 3.13+                  |
| ORM              | SQLAlchemy 2.0+ (async)       |
| Database Driver  | asyncpg 0.29+                 |
| Authentication   | Supabase Auth, python-jose    |
| Transcription    | Groq API (Whisper)            |
| HTTP Client      | httpx 0.28+                   |
| Configuration    | Pydantic Settings 2.12+       |

### Frontend

| Component        | Technology                    |
| ---------------- | ----------------------------- |
| Framework        | Flutter 3.10+                 |
| Language         | Dart 3.10+                    |
| State Management | Provider 6.1                  |
| Audio Recording  | flutter_sound 9.2             |
| WebSocket        | web_socket_channel 3.0        |
| HTTP Client      | http 1.2                      |
| Local Storage    | shared_preferences 2.2        |
| Animations       | flutter_animate 4.5           |

## Project Structure

```
zepp-app/
  backend/
    pyproject.toml
    app/
      main.py                       # Application entry point
      api/
        api.py                      # Router aggregation
        v1/routers/
          audio_ws.py               # WebSocket audio streaming
          auth.py                   # Authentication endpoints
          transcripts.py            # Transcript CRUD
      config/settings.py            # Pydantic-based configuration
      controllers/
        audio_transcription.py      # Groq API integration
      crud/
        transcript.py               # Transcript DB operations
        user.py                     # User DB operations
      db/database.py                # Async SQLAlchemy engine
      deps/auth.py                  # Auth dependencies
      models/
        transcript.py               # Transcript ORM model
        user.py                     # User ORM model
      schemas/
        auth.py                     # Auth request/response schemas
        transcript.py               # Transcript schemas
        user.py                     # User schemas
      utils/security.py             # JWT verification

  frontend-app/flutter_app/
    pubspec.yaml
    lib/
      main.dart                     # Application entry point
      core/
        app_config.dart             # Backend URL configuration
        app_theme.dart              # Theme definitions
        widgets/                    # Shared UI components
      features/
        authentication/             # Login and signup (MVVM)
        transcribe/                 # Voice recording (MVVM)
        home/                       # Navigation and history (MVVM)
        account/                    # User settings
```

## Prerequisites

### Backend

- Python 3.13 or higher
- pip
- PostgreSQL database (or a Supabase project)

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

# Create .env (see Configuration section)

# Start the development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`. Interactive docs are at `http://localhost:8000/docs`.

### Frontend Setup

```bash
cd frontend-app/flutter_app

# Install dependencies
flutter pub get

# Run on default emulator
flutter run

# Run with custom backend URLs
flutter run \
  --dart-define=BACKEND_BASE_URL=http://your-server:8000 \
  --dart-define=BACKEND_WS_URL=ws://your-server:8000/ws/audio
```

## Configuration

### Environment Variables

Create a `.env` file in the `backend/` directory:

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
GET /
```

Returns `{"status": "ok", "message": "zepp API is running"}`.

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
    }
    users ||--o{ transcripts : "has many"
```

## Usage

**Recording** -- Open the Transcribe tab, grant microphone permissions, tap the microphone button, speak, and tap again to stop. The transcription appears on screen and is saved automatically when logged in.

**History** -- Log in and navigate to the History tab to browse past transcriptions.

**Account** -- View profile information, toggle themes, or log out from the Account tab.

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

## Contributing

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes with a descriptive message.
4. Push and open a pull request.

Follow the existing code style, add tests for new functionality, and ensure all tests pass before submitting.

## License

This project is available under the [MIT License](LICENSE).
