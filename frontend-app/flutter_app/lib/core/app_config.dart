/// Centralized app configuration. Override at build time with --dart-define.
const String backendBaseUrl = String.fromEnvironment(
  'BACKEND_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

const String backendWsUrl = String.fromEnvironment(
  'BACKEND_WS_URL',
  defaultValue: 'ws://10.0.2.2:8000/ws/audio',
);
