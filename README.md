<h1 align="center">
  <img src="assets/zepp-logo.png" alt="A sound waveform that becomes transcript lines" width="200">
  <br>
  zepp
  <br>
</h1>

<h4 align="center">Record speech in Flutter and get a transcript when you stop.</h4>

<p align="center">
  <img alt="FastAPI backend" src="https://img.shields.io/badge/FastAPI-backend-009688?logo=fastapi&amp;logoColor=white">
  <img alt="Python requirement greater than or equal to 3.13" src="https://img.shields.io/badge/Python-%3E%3D3.13-3776AB?logo=python&amp;logoColor=white">
  <img alt="Flutter client" src="https://img.shields.io/badge/Flutter-client-02569B?logo=flutter&amp;logoColor=white">
  <img alt="Dart SDK constraint caret 3.10.3" src="https://img.shields.io/badge/Dart-%5E3.10.3-0175C2?logo=dart&amp;logoColor=white">
</p>

<p align="center"><a href="#key-features">Features</a> • <a href="#how-to-use">Setup</a> • <a href="#license">License</a></p>

## Key Features

- **Speech capture:** The Flutter client sends mono, 16 kHz PCM audio to `/ws/audio`. The backend buffers the audio and sends it to Groq after it receives `{"event":"end"}`.
- **Transcription:** The backend uses Groq Whisper with the `whisper-large-v3-turbo` model.
- **Authentication and history:** Sign-up and login use Supabase Auth. The backend writes transcript records to PostgreSQL. Signed-in users can read transcript history.
- **Local history:** The Flutter client uses memory and SQLite caches for transcript history.
- **Display:** Users can change the theme and copy transcript text to the clipboard.

## How To Use

### Requirements

- Python 3.13+ and [uv](https://docs.astral.sh/uv/)
- Flutter SDK
- Dart SDK constraint: `^3.10.3` in `pubspec.yaml`
- Android Studio for Android builds
- Xcode for iOS builds
- A Supabase project for authentication
- A PostgreSQL database for transcript records
- A Groq API key for transcription

### Backend

`backend/pyproject.toml` names `backend/README.md`, but that file is absent. The original README gives this editable-install command. This command has not been tested in this refresh:

```bash
cd backend
pip install -e .
```

Create `backend/.env` from `backend/.env.example`. The Configuration section lists the values that the backend reads.

Run the backend from the repository root:

```bash
cd backend
uv sync --locked --extra dev
uv run --no-sync uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Use `http://localhost:8000/health` to check the backend. Open `http://localhost:8000/docs` for the API docs.

### Flutter App

Run the app from `frontend-app/flutter_app`:

```bash
cd frontend-app/flutter_app
flutter pub get
flutter run
```

The default backend URLs use `10.0.2.2` for Android emulators. Set `BACKEND_BASE_URL` and `BACKEND_WS_URL` with `--dart-define` for other devices.

## Configuration

The backend reads `DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_KEY`, `SUPABASE_JWT_SECRET`, and `GROQ_API_KEY` from `backend/.env`. `JWT_AUDIENCE` is optional.

The Flutter client reads `BACKEND_BASE_URL` and `BACKEND_WS_URL` at build time. Its default values are `http://10.0.2.2:8000` and `ws://10.0.2.2:8000/ws/audio`.

## API

- `GET /health` checks the backend.
- `WS /ws/audio` accepts mono, 16 kHz PCM audio. Send `{"event":"end"}` when you stop. The backend sends the transcript in its response.

## Tests

Run the available tests from each project directory.

```bash
cd backend
uv run --no-sync pytest
```

```bash
cd frontend-app/flutter_app
flutter test
```

## License

The source README has this statement: “This project is available under the MIT License.” The repository has no `LICENSE` file.

---

<p align="center"><a href="https://github.com/AbhiramVSA/zepp">Source repository</a></p>
