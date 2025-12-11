import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/app_config.dart';
import '../model/auth_session.dart';

class AuthRepository {
  const AuthRepository();

  Future<AuthSession> login({required String email, required String password}) async {
    final uri = Uri.parse('$backendBaseUrl/auth/login');
    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
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
        message = errorBody['detail'] as String? ?? 
                  errorBody['error_description'] as String? ?? 
                  errorBody['message'] as String? ?? message;
      } catch (_) {}
      throw AuthException(message);
    }

    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    final String? token = body['access_token'] as String?;
    final String? userId = body['user_id'] as String?;
    final String? userEmail = body['email'] as String?;

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

  Future<AuthSession> signup({required String email, required String password}) async {
    final uri = Uri.parse('$backendBaseUrl/auth/signup');
    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Signup failed (code ${response.statusCode}).';
      try {
        final Map<String, dynamic> errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        message = errorBody['detail'] as String? ?? 
                  errorBody['error_description'] as String? ?? 
                  errorBody['message'] as String? ?? 
                  errorBody['msg'] as String? ?? message;
      } catch (_) {}
      throw AuthException(message);
    }

    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    final String? token = body['access_token'] as String?;
    final String? userId = body['user_id'] as String?;
    final String? userEmail = body['email'] as String?;

    // Supabase may not return tokens if email confirmation is required
    // In that case, we still consider signup successful but indicate email verification needed
    if (token == null) {
      throw AuthException('Signup successful! Please check your email to confirm your account.');
    }

    if (userId == null || userEmail == null) {
      throw AuthException('Malformed signup response');
    }

    return AuthSession(
      accessToken: token,
      refreshToken: body['refresh_token'] as String?,
      userId: userId,
      email: userEmail,
    );
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final uri = Uri.parse('$backendBaseUrl/auth/refresh');
    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{'refresh_token': refreshToken}),
    );

    if (response.statusCode != 200) {
      throw AuthException('Refresh failed (code ${response.statusCode}).');
    }

    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    final String? token = body['access_token'] as String?;
    final String? userId = body['user_id'] as String?;
    final String? userEmail = body['email'] as String?;

    if (token == null || userId == null || userEmail == null) {
      throw AuthException('Malformed refresh response');
    }

    return AuthSession(
      accessToken: token,
      refreshToken: body['refresh_token'] as String?,
      userId: userId,
      email: userEmail,
    );
  }
}
