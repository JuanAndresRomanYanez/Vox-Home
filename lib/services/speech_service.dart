import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' show SpeechListenOptions, ListenMode;
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, paused, stopped }

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts        = FlutterTts();

  bool isListening     = false;
  TtsState ttsState    = TtsState.stopped;
  // Function(String, bool) _onResult = (_, __) {};

  SpeechService() {
    _initTts();
  }

  void _initTts() {
    _tts.setLanguage("es-ES");
    _tts.setSpeechRate(0.5);
    _tts.setStartHandler(() => ttsState = TtsState.playing);
    _tts.setCompletionHandler(() => ttsState = TtsState.stopped);
    _tts.setErrorHandler((_) => ttsState = TtsState.stopped);
    _tts.awaitSpeakCompletion(true);
  }

  /// Inicia STT y retorna `true` si está disponible.
  Future<bool> initSpeech() async {
    bool available = await _speech.initialize();
    isListening = false;
    return available;
  }

  /// Empieza a escuchar durante 10 s como máximo.
  void startListening(Function(String words, bool isFinal) onResult) {
    isListening = true;
    _speech.listen(
      onResult: (res) {
        onResult(res.recognizedWords, res.finalResult);
        if (res.finalResult) {
          isListening = false;
        }
      },
      listenFor: const Duration(seconds: 10),
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        onDevice: false,
        listenMode: ListenMode.confirmation,
        autoPunctuation: false,
        enableHapticFeedback: false,
      ),
    );
  }

  void stopListening() {
    _speech.stop();
    isListening = false;
  }

  Future<void> speak(String text) async {
    final clean = text.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (m) => m.group(1)!,
    );
    await _tts.speak(clean);
  }

  Future<void> stop()   async => await _tts.stop();
  Future<void> pause()  async {
    if (await _tts.pause() == 1) ttsState = TtsState.paused;
  }
}
