class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.userId,
    required this.email,
    this.refreshToken,
  });

  final String accessToken;
  final String userId;
  final String email;
  final String? refreshToken;
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => 'AuthException: $message';
}
