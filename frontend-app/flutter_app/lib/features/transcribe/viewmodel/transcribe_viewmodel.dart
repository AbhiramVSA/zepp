import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../authentication/viewmodel/auth_viewmodel.dart';
import '../../home/viewmodel/history_viewmodel.dart';
import '../repository/transcribe_repository.dart';

enum TranscribeState { idle, recording, processing, completed, error }

class TranscribeViewModel extends ChangeNotifier {
  TranscribeViewModel(this._repository, this._auth, this._history);

  final TranscribeRepository _repository;
  final AuthViewModel _auth;
  final HistoryViewModel _history;

  TranscribeState _state = TranscribeState.idle;
  String _transcript = '';
  String? _error;
  StreamSubscription<String>? _transcriptionSub;
  bool _disposed = false;

  TranscribeState get state => _state;
  String get transcript => _transcript;
  String? get error => _error;

  bool get isBusy =>
      _state == TranscribeState.recording || _state == TranscribeState.processing;

  Future<void> start() async {
    if (_disposed) return;
    if (isBusy) return;
    _error = null;
    _transcript = '';
    _state = TranscribeState.recording;
    notifyListeners();

    try {
      _repository.setAuthToken(_auth.session?.accessToken);
      await _repository.connectWebSocket();
      await _repository.startRecording();
      _listenForTranscriptions();
    } catch (e, st) {
      _handleError(e, st);
    }
  }

  Future<void> stop() async {
    if (_disposed) return;
    if (_state != TranscribeState.recording) return;
    _state = TranscribeState.processing;
    notifyListeners();

    try {
      await _repository.stopRecording();
      final String text = await _repository.transcriptionStream.first;
      _transcript = text;
      _state = TranscribeState.completed;
      notifyListeners();
    } catch (e, st) {
      _handleError(e, st);
    }
  }

  void reset() {
    _transcript = '';
    _error = null;
    _state = TranscribeState.idle;
    notifyListeners();
  }

  void _listenForTranscriptions() {
    _transcriptionSub?.cancel();
    _transcriptionSub = _repository.transcriptionStream.listen(
      (text) {
        if (_disposed) return;
        _transcript = text;
        _state = TranscribeState.completed;
        notifyListeners();
        // refresh history view on successful transcript save
        if (_auth.isAuthenticated) {
          unawaited(_history.load(refresh: true));
        }
      },
      onError: (Object err, [StackTrace? st]) {
        if (_disposed) return;
        _handleError(err, st);
      },
    );
  }

  void _handleError(Object err, [StackTrace? st]) {
    if (_disposed) return;
    if (kDebugMode) {
      // ignore: avoid_print
      print('Transcription error: $err');
      if (st != null) {
        // ignore: avoid_print
        print(st);
      }
    }
    _error = err.toString();
    _state = TranscribeState.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _transcriptionSub?.cancel();
    // fire-and-forget cleanup; recorder stop/close handled inside
    unawaited(_repository.close());
    super.dispose();
  }
}
