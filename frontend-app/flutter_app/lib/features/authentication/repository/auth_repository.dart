import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/app_config.dart';
import '../model/auth_session.dart';

class AuthRepository {
  const AuthRepository();

  Future<AuthSession> login({required String email, required String password}) async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw AuthException('Supabase configuration missing. Set SUPABASE_URL and SUPABASE_ANON_KEY.');
    }

    final uri = Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password');
    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'apikey': supabaseAnonKey,
        'Accept': 'application/json',
        'Authorization': 'Bearer $supabaseAnonKey',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      String message = 'Login failed (code ${response.statusCode}).';
      try {
        final Map<String, dynamic> errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        message = errorBody['error_description'] as String? ?? errorBody['message'] as String? ?? message;
      } catch (_) {}
      throw AuthException(message);
    }

    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    final String? token = body['access_token'] as String?;
    final Map<String, dynamic>? user = body['user'] as Map<String, dynamic>?;
    final String? userId = user?['id'] as String?;
    final String? userEmail = user?['email'] as String?;

    if (token == null || userId == null || userEmail == null) {
      throw AuthException('Malformed login response');
    }

    return AuthSession(
      accessToken: token,
      refreshToken: body['refresh_token'] as String?,
      userId: userId,
      email: userEmail,
    );
  }
}
