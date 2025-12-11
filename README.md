# VoiceAI - Real-Time Voice Transcription Application

VoiceAI is a full-stack voice transcription application that enables users to record audio and convert speech to text in real-time. Built with FastAPI on the backend and Flutter on the frontend, it features user authentication, transcript history management, and a modern user interface.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Backend Setup](#backend-setup)
  - [Frontend Setup](#frontend-setup)
- [Configuration](#configuration)
  - [Environment Variables](#environment-variables)
  - [External Services](#external-services)
- [API Reference](#api-reference)
- [Database Schema](#database-schema)
- [Usage](#usage)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **Real-Time Voice Transcription**: Stream audio from your device and receive instant text conversion using the Whisper large-v3-turbo model via Groq API.
- **User Authentication**: Secure signup and login functionality powered by Supabase Auth with JWT token management.
- **Transcript History**: View, manage, and search through all past transcriptions.
- **Session Persistence**: Automatic session restoration on app restart using secure local storage.
- **Modern UI Design**: Animated backgrounds, glassmorphism effects, gradient accents, and smooth animations.
- **Theme Support**: Toggle between dark and light themes.
- **Cross-Platform**: Supports Android, iOS, Web, Windows, macOS, and Linux.

---

## Architecture

### System Overview

```
+------------------+       WebSocket        +------------------+       HTTPS       +------------------+
|                  |  (PCM Audio Stream)    |                  |    (Whisper)      |                  |
|   Flutter App    | ---------------------> |   FastAPI        | ----------------> |   Groq API       |
|                  | <--------------------- |   Backend        | <---------------- |                  |
|                  |    (Transcription)     |                  |   (Text Result)   |                  |
+------------------+                        +------------------+                   +------------------+
        |                                           |
        |  REST API (Auth, Transcripts)             |  SQL Queries
        |                                           |
        v                                           v
+------------------+                        +------------------+
|                  |                        |                  |
| Shared Prefs     |                        |   PostgreSQL     |
| (Local Storage)  |                        |   (Supabase)     |
|                  |                        |                  |
+------------------+                        +------------------+
```

### Audio Transcription Flow

1. The Flutter application captures audio using the device microphone (PCM 16-bit, 16kHz, mono channel).
2. Audio chunks are streamed in real-time via WebSocket to the backend `/ws/audio` endpoint.
3. The backend buffers incoming audio chunks until it receives an "end" event.
4. Raw PCM audio is converted to WAV format with appropriate headers.
5. The WAV audio is sent to the Groq API using the Whisper transcription model.
6. The transcription result is returned to the client via the WebSocket connection.
7. If the user is authenticated, the transcript is automatically saved to the database.

### Authentication Flow

1. User submits credentials via the Flutter app login or signup screen.
2. The backend proxies the authentication request to Supabase Auth.
3. On success, JWT access and refresh tokens are returned.
4. Tokens are stored securely in SharedPreferences for session persistence.
5. Protected API routes validate the JWT using the Supabase JWT secret.
6. Users are automatically created in the local database on their first authenticated request.

---

## Tech Stack

### Backend

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | FastAPI | 0.124.0+ |
| Language | Python | 3.13+ |
| Database ORM | SQLAlchemy (async) | 2.0.36+ |
| Database Driver | asyncpg | 0.29.0+ |
| Authentication | Supabase Auth + python-jose | 3.3.0+ |
| AI/ML | Groq API (Whisper) | - |
| HTTP Client | httpx | 0.28.1+ |
| Configuration | Pydantic Settings | 2.12.0+ |
| Validation | Pydantic | 2.12.5+ |

### Frontend

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | Flutter | 3.10.3+ |
| Language | Dart | 3.10.3+ |
| State Management | Provider | 6.1.2 |
| Audio Recording | flutter_sound | 9.2.13 |
| WebSocket | web_socket_channel | 3.0.1 |
| HTTP Client | http | 1.2.2 |
| Permissions | permission_handler | 11.3.1 |
| Local Storage | shared_preferences | 2.2.3 |
| Typography | google_fonts | 6.2.1 |
| Animations | flutter_animate | 4.5.0 |
| Loading Effects | shimmer | 3.0.0 |
| Date Formatting | intl | 0.19.0 |

---

## Project Structure

```
voice-app/
├── README.md
├── backend/
│   ├── pyproject.toml              # Python dependencies and project metadata
│   ├── .env                        # Environment variables (not in version control)
│   └── app/
│       ├── __init__.py
│       ├── main.py                 # FastAPI application entry point
│       ├── api/
│       │   ├── api.py              # Router aggregation
│       │   └── v1/
│       │       ├── __init__.py
│       │       └── routers/
│       │           ├── audio_ws.py     # WebSocket endpoint for audio streaming
│       │           ├── auth.py         # Authentication endpoints
│       │           └── transcripts.py  # Transcript CRUD operations
│       ├── config/
│       │   └── settings.py         # Environment configuration with Pydantic
│       ├── controllers/
│       │   └── audio_transcription.py  # Groq API integration
│       ├── core/
│       │   └── __init__.py
│       ├── crud/
│       │   ├── transcript.py       # Transcript database operations
│       │   └── user.py             # User database operations
│       ├── db/
│       │   └── database.py         # Async SQLAlchemy engine setup
│       ├── deps/
│       │   └── auth.py             # Authentication dependencies
│       ├── models/
│       │   ├── __init__.py
│       │   ├── base.py             # SQLAlchemy base model
│       │   ├── transcript.py       # Transcript ORM model
│       │   └── user.py             # User ORM model
│       ├── schemas/
│       │   ├── auth.py             # Authentication Pydantic schemas
│       │   ├── transcript.py       # Transcript Pydantic schemas
│       │   └── user.py             # User Pydantic schemas
│       └── utils/
│           └── security.py         # JWT verification utilities
│
└── frontend-app/
    └── flutter_app/
        ├── pubspec.yaml            # Flutter dependencies
        ├── analysis_options.yaml   # Dart linting rules
        ├── lib/
        │   ├── main.dart           # Application entry point
        │   ├── core/
        │   │   ├── app_config.dart     # Backend URL configuration
        │   │   ├── app_theme.dart      # Theme definitions and colors
        │   │   └── widgets/
        │   │       ├── animated_background.dart
        │   │       └── glass_widgets.dart
        │   └── features/
        │       ├── authentication/     # Login and signup (MVVM pattern)
        │       │   ├── model/
        │       │   ├── repository/
        │       │   ├── view/
        │       │   └── viewmodel/
        │       ├── transcribe/         # Voice recording (MVVM pattern)
        │       │   ├── repository/
        │       │   ├── view/
        │       │   └── viewmodel/
        │       ├── home/               # Navigation and history (MVVM pattern)
        │       │   ├── model/
        │       │   ├── repository/
        │       │   ├── view/
        │       │   └── viewmodel/
        │       └── account/            # User settings
        │           └── view/
        ├── android/                # Android-specific configuration
        ├── ios/                    # iOS-specific configuration
        ├── web/                    # Web-specific configuration
        ├── windows/                # Windows-specific configuration
        ├── macos/                  # macOS-specific configuration
        └── linux/                  # Linux-specific configuration
```

---

## Prerequisites

Before setting up the project, ensure you have the following installed:

### Backend Requirements

- Python 3.13 or higher
- pip (Python package manager)
- PostgreSQL database (or Supabase project)

### Frontend Requirements

- Flutter SDK 3.10.3 or higher
- Dart SDK 3.10.3 or higher
- Android Studio (for Android development) or Xcode (for iOS development)
- A physical device or emulator for testing

### External Services

- **Supabase Account**: Required for authentication and PostgreSQL database hosting.
- **Groq API Key**: Required for accessing the Whisper transcription model.

---

## Installation

### Backend Setup

1. Navigate to the backend directory:

```bash
cd backend
```

2. Create and activate a virtual environment:

```bash
# Create virtual environment
python -m venv .venv

# Activate on Windows
.venv\Scripts\activate

# Activate on macOS/Linux
source .venv/bin/activate
```

3. Install dependencies:

```bash
pip install -e .
```

4. Create a `.env` file in the backend directory (see [Environment Variables](#environment-variables) section).

5. Start the development server:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`. API documentation is accessible at `http://localhost:8000/docs`.

### Frontend Setup

1. Navigate to the Flutter app directory:

```bash
cd frontend-app/flutter_app
```

2. Install Flutter dependencies:

```bash
flutter pub get
```

3. Run the application:

```bash
# For Android emulator (uses default localhost mapping)
flutter run

# For physical device or custom backend URL
flutter run --dart-define=BACKEND_BASE_URL=http://your-server:8000 --dart-define=BACKEND_WS_URL=ws://your-server:8000/ws/audio
```

4. Build for production:

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## Configuration

### Environment Variables

Create a `.env` file in the `backend/` directory with the following variables:

```env
# Database Configuration
DATABASE_URL=postgresql+asyncpg://username:password@host:port/database

# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_supabase_anon_or_service_key
SUPABASE_JWT_SECRET=your_supabase_jwt_secret

# JWT Configuration
JWT_AUDIENCE=

# Groq API Configuration
GROQ_API_KEY=your_groq_api_key
```

#### Variable Descriptions

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string with asyncpg driver. For Supabase, use the pooler connection string. |
| `SUPABASE_URL` | Your Supabase project URL (found in project settings). |
| `SUPABASE_KEY` | Supabase anon key or service role key (found in API settings). |
| `SUPABASE_JWT_SECRET` | JWT secret for verifying Supabase tokens (found in API settings under JWT Settings). |
| `JWT_AUDIENCE` | Optional JWT audience claim. Leave empty if not using audience verification. |
| `GROQ_API_KEY` | API key from Groq console for accessing Whisper transcription. |

### Frontend Configuration

Backend URLs are configured at build time using Dart defines:

| Define | Default Value | Description |
|--------|---------------|-------------|
| `BACKEND_BASE_URL` | `http://10.0.2.2:8000` | Base URL for REST API calls. Default is Android emulator localhost mapping. |
| `BACKEND_WS_URL` | `ws://10.0.2.2:8000/ws/audio` | WebSocket URL for audio streaming. |

For production builds, pass your server URLs:

```bash
flutter run \
  --dart-define=BACKEND_BASE_URL=https://api.yourserver.com \
  --dart-define=BACKEND_WS_URL=wss://api.yourserver.com/ws/audio
```

### External Services

#### Supabase Setup

1. Create a new project at [supabase.com](https://supabase.com).
2. Navigate to Project Settings and API section.
3. Copy the following values to your `.env` file:
   - Project URL to `SUPABASE_URL`
   - anon/public key to `SUPABASE_KEY`
   - JWT Secret (under JWT Settings) to `SUPABASE_JWT_SECRET`
4. Use the database connection string (Session pooler recommended) for `DATABASE_URL`.

#### Groq API Setup

1. Create an account at [console.groq.com](https://console.groq.com).
2. Generate an API key from the API Keys section.
3. Copy the key to `GROQ_API_KEY` in your `.env` file.

---

## API Reference

### Health Check

```
GET /
```

Returns API health status.

**Response:**
```json
{
  "status": "ok",
  "message": "VoiceAI API is running"
}
```

### Authentication

#### Sign Up

```
POST /auth/signup
```

Register a new user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response:**
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

#### Login

```
POST /auth/login
```

Authenticate an existing user.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response:** Same as signup.

#### Refresh Token

```
POST /auth/refresh
```

Refresh an expired access token.

**Request Body:**
```json
{
  "refresh_token": "eyJ..."
}
```

#### Get Current User

```
GET /auth/whoami
```

Get the authenticated user's information.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "is_active": true,
  "is_superuser": false,
  "created_at": "2024-01-01T00:00:00Z"
}
```

### Transcripts

#### Create Transcript

```
POST /transcripts/
```

Save a new transcript.

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "text": "Transcribed text content"
}
```

**Response:**
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "text": "Transcribed text content",
  "confidence": null,
  "duration_seconds": null,
  "created_at": "2024-01-01T00:00:00Z"
}
```

#### Get Transcript History

```
GET /transcripts/history?limit=50&offset=0
```

Retrieve the user's transcript history.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `limit` | integer | 50 | Maximum number of transcripts to return |
| `offset` | integer | 0 | Number of transcripts to skip |

**Response:**
```json
{
  "items": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "text": "Transcribed text",
      "confidence": 0.95,
      "duration_seconds": 30.5,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 100
}
```

#### Get Single Transcript

```
GET /transcripts/{transcript_id}
```

Retrieve a specific transcript by ID.

**Headers:**
```
Authorization: Bearer <access_token>
```

### WebSocket Audio Streaming

```
WS /ws/audio
```

Stream audio for real-time transcription.

**Connection:**
```javascript
const ws = new WebSocket('ws://localhost:8000/ws/audio');
```

**Protocol:**

1. Send raw PCM audio data as binary frames (16-bit, 16kHz, mono).
2. Send end signal when recording is complete:
   ```json
   {"event": "end"}
   ```
3. Receive transcription result:
   ```json
   {"text": "Transcribed text content"}
   ```

**Error Response:**
```json
{"error": "Error message"}
```

---

## Database Schema

### Users Table

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR | PRIMARY KEY | Supabase user ID |
| email | VARCHAR | UNIQUE, NOT NULL | User email address |
| is_active | BOOLEAN | DEFAULT true | Account active status |
| is_superuser | BOOLEAN | DEFAULT false | Admin privileges flag |
| created_at | TIMESTAMP | DEFAULT now() | Account creation timestamp |

### Transcripts Table

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Auto-generated UUID |
| user_id | VARCHAR | FOREIGN KEY (users.id) | Owner reference |
| text | TEXT | NOT NULL | Transcription content |
| confidence | FLOAT | NULLABLE | Transcription confidence score |
| duration_seconds | FLOAT | NULLABLE | Audio duration in seconds |
| metadata | JSONB | NULLABLE | Additional metadata |
| audio_url | TEXT | NULLABLE | Original audio file URL |
| created_at | TIMESTAMP | DEFAULT now() | Creation timestamp |

---

## Usage

### Recording a Transcript

1. Open the application and navigate to the Transcribe tab.
2. Grant microphone permissions when prompted.
3. Tap the microphone button to start recording.
4. Speak clearly into your device's microphone.
5. Tap the button again to stop recording.
6. The transcription will appear on screen and be saved automatically if logged in.

### Viewing History

1. Log in to your account.
2. Navigate to the History tab.
3. Browse through your past transcriptions.
4. Use the refresh button to load new transcripts.

### Managing Your Account

1. Navigate to the Account tab.
2. View your profile information.
3. Toggle between dark and light themes.
4. Log out when finished.

---

## Development

### Running Tests

#### Backend

```bash
cd backend
pytest
```

#### Frontend

```bash
cd frontend-app/flutter_app
flutter test
```

### Code Style

#### Backend

The project follows PEP 8 style guidelines. Use the following tools:

```bash
# Format code
black app/

# Sort imports
isort app/

# Type checking
mypy app/
```

#### Frontend

The project uses the Flutter recommended linting rules defined in `analysis_options.yaml`:

```bash
# Analyze code
flutter analyze

# Format code
dart format lib/
```

### Building for Production

#### Backend

For production deployment, use a production ASGI server:

```bash
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

#### Frontend

Build optimized releases:

```bash
# Android
flutter build apk --release --dart-define=BACKEND_BASE_URL=https://api.production.com

# iOS
flutter build ios --release --dart-define=BACKEND_BASE_URL=https://api.production.com

# Web
flutter build web --release --dart-define=BACKEND_BASE_URL=https://api.production.com
```

---

## Contributing

Contributions are welcome. Please follow these steps:

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes and commit: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/your-feature-name`
5. Open a pull request.

### Guidelines

- Follow the existing code style and conventions.
- Write meaningful commit messages.
- Add tests for new functionality.
- Update documentation as needed.
- Ensure all tests pass before submitting.

---

## License

This project is open source and available under the [MIT License](LICENSE).

---

## Acknowledgments

- [FastAPI](https://fastapi.tiangolo.com/) - Modern Python web framework
- [Flutter](https://flutter.dev/) - Cross-platform UI toolkit
- [Supabase](https://supabase.com/) - Open source Firebase alternative
- [Groq](https://groq.com/) - Fast AI inference platform
- [OpenAI Whisper](https://openai.com/research/whisper) - Speech recognition model
