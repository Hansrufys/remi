import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

enum VoiceState { idle, listening, error }

class VoiceInputState {
  final VoiceState status;
  final String transcript;
  final bool hasMicPermission;

  const VoiceInputState({
    this.status = VoiceState.idle,
    this.transcript = '',
    this.hasMicPermission = false,
  });

  VoiceInputState copyWith({
    VoiceState? status,
    String? transcript,
    bool? hasMicPermission,
  }) =>
      VoiceInputState(
        status: status ?? this.status,
        transcript: transcript ?? this.transcript,
        hasMicPermission: hasMicPermission ?? this.hasMicPermission,
      );
}

class VoiceInputNotifier extends StateNotifier<VoiceInputState> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  VoiceInputNotifier() : super(const VoiceInputState()) {
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: _onStatus,
      onError: (_) => state = state.copyWith(status: VoiceState.idle),
    );
    state = state.copyWith(hasMicPermission: available);
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      state = state.copyWith(status: VoiceState.idle);
    }
  }

  Future<void> startListening() async {
    if (!state.hasMicPermission) await _initSpeech();
    if (!state.hasMicPermission) return;

    state = state.copyWith(status: VoiceState.listening, transcript: '');

    await _speech.listen(
      localeId: 'de_DE',
      onResult: (result) {
        debugPrint('VoiceInputNotifier: Recognize words: "${result.recognizedWords}" (final: ${result.finalResult})');
        // Always accept the final confirmed result to prevent cutoffs.
        // Only block partial results that arrive AFTER we've stopped, which
        // is what caused the duplicate 'ghost text' bug previously.
        if (state.status == VoiceState.listening || result.finalResult) {
          state = state.copyWith(transcript: result.recognizedWords);
        }
      },
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 20),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<String?> stopListening() async {
    // 300ms buffer allows the engine to deliver the final words
    await Future.delayed(const Duration(milliseconds: 300));
    await _speech.stop();
    final text = state.transcript;
    state = state.copyWith(status: VoiceState.idle, transcript: '');
    return text.isEmpty ? null : text;
  }

  void resetState() {
    state = state.copyWith(status: VoiceState.idle, transcript: '');
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}

final voiceInputProvider =
    StateNotifierProvider<VoiceInputNotifier, VoiceInputState>(
  (ref) => VoiceInputNotifier(),
);
