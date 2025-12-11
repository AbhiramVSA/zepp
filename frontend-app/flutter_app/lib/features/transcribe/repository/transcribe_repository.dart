import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:http/http.dart' as http;

import '../../../core/app_config.dart' as config;

/// Handles audio capture and WebSocket streaming to the backend.
class TranscribeRepository {
  // For Android emulators, host loopback is 10.0.2.2
    TranscribeRepository({String? backendWsUrl})
      : backendWsUrl = backendWsUrl ?? config.backendWsUrl;

    final String backendWsUrl;
    String? _authToken;

    final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
    final StreamController<Uint8List> _pcmController =
      StreamController<Uint8List>.broadcast();
  final StreamController<String> _transcriptionController =
      StreamController<String>.broadcast();

  IOWebSocketChannel? _channel;
  StreamSubscription<Uint8List>? _pcmSubscription;
  StreamSubscription<dynamic>? _wsSubscription;
  bool _isInitialized = false;

  Stream<String> get transcriptionStream => _transcriptionController.stream;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(const Duration(milliseconds: 50));
    _isInitialized = true;
  }

  Future<void> connectWebSocket() async {
    await closeWebSocket();
    final uri = Uri.parse(backendWsUrl);
    _channel = IOWebSocketChannel.connect(
      uri,
      headers: _authToken != null ? {'Authorization': 'Bearer $_authToken'} : null,
    );
    _wsSubscription = _channel!.stream.listen(
      _handleWsMessage,
      onError: (Object err, [StackTrace? st]) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('WS error: $err');
        }
        _transcriptionController.addError(err, st);
      },
      onDone: () {
        if (kDebugMode) {
          // ignore: avoid_print
          print('WS closed');
        }
      },
      cancelOnError: true,
    );
  }

  Future<void> closeWebSocket() async {
    await _wsSubscription?.cancel();
    _wsSubscription = null;
    await _channel?.sink.close(ws_status.normalClosure);
    _channel = null;
  }

  Future<void> startRecording() async {
    await _ensureInitialized();

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw MicPermissionException('Microphone permission not granted');
    }

    _pcmSubscription?.cancel();
    _pcmSubscription = _pcmController.stream.listen(
      _sendPcmChunk,
      onError: (Object err, [StackTrace? st]) {
        _transcriptionController.addError(err, st);
      },
    );

    await _recorder.startRecorder(
      toStream: _pcmController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
    );
  }

  Future<void> stopRecording() async {
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
    }
    await _pcmSubscription?.cancel();
    _pcmSubscription = null;
    _channel?.sink.add(jsonEncode({'event': 'end'}));
  }

  void _sendPcmChunk(Uint8List data) {
    if (_channel == null) return;
    if (data.isNotEmpty) {
      _channel!.sink.add(data);
    }
  }

  void _handleWsMessage(dynamic message) {
    try {
      final String jsonStr;
      if (message is String) {
        jsonStr = message;
      } else if (message is List<int>) {
        jsonStr = utf8.decode(message);
      } else {
        throw Exception('Unsupported message type: ${message.runtimeType}');
      }

      final Map<String, dynamic> payload = jsonDecode(jsonStr) as Map<String, dynamic>;
      final String? text = payload['text'] as String?;
      final String? error = payload['error'] as String?;

      if (text != null) {
        _transcriptionController.add(text);
        // Fire-and-forget persist if authenticated
        unawaited(_persistTranscript(text));
      } else if (error != null) {
        _transcriptionController.addError(error);
      } else {
        _transcriptionController.addError('Malformed response');
      }
    } catch (e, st) {
      _transcriptionController.addError(e, st);
    }
  }

  Future<void> close() async {
    await stopRecording();
    await closeWebSocket();
    await _recorder.closeRecorder();
    await _pcmController.close();
    await _transcriptionController.close();
    _isInitialized = false;
  }

  Future<void> _persistTranscript(String text) async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('DEBUG: _persistTranscript called with text: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');
      print('DEBUG: authToken is ${_authToken == null ? 'NULL' : (_authToken!.isEmpty ? 'EMPTY' : 'SET (${_authToken!.length} chars)')}');
    }
    if (_authToken == null || _authToken!.isEmpty) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('DEBUG: No auth token, skipping persist');
      }
      return;
    }
    final uri = Uri.parse('${config.backendBaseUrl}/transcripts/');
    if (kDebugMode) {
      // ignore: avoid_print
      print('DEBUG: POST to $uri');
    }
    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'text': text}),
      );
      if (kDebugMode) {
        // ignore: avoid_print
        print('DEBUG: Response status: ${response.statusCode}');
        print('DEBUG: Response body: ${response.body}');
      }
      if (response.statusCode >= 400) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Persist transcript failed: ${response.statusCode} ${response.body}');
        }
      } else {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Transcript saved successfully');
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Persist transcript exception: $e');
        print('Stack trace: $st');
      }
    }
  }
}

class MicPermissionException implements Exception {
  MicPermissionException(this.message);
  final String message;

  @override
  String toString() => 'MicPermissionException: $message';
}
