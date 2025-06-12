import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' show SpeechListenOptions, ListenMode;
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, paused, stopped }

class SpeechService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool isListening = false;
  TtsState ttsState = TtsState.stopped;
  Function(String, bool) _lastOnResult = (_, __) {};

  SpeechService() {
    _initTts();
  }

  void _initTts() {
    _flutterTts.setLanguage("es-ES");
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setStartHandler(() => ttsState = TtsState.playing);
    _flutterTts.setCompletionHandler(() => ttsState = TtsState.stopped);
    _flutterTts.setErrorHandler((_) => ttsState = TtsState.stopped);
  }

  /// Inicializa STT y, si está disponible, arranca la escucha continua.
  Future<void> startContinuousListening(Function(String recognized, bool isFinal) onResult) async {
    _lastOnResult = onResult;

    final available = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' && !isListening) {
          // relanzar escucha automática
          startListening(_lastOnResult);
        }
      },
      onError: (err) {
        isListening = false;
        // reintentar tras un pequeño delay
        Future.delayed(const Duration(milliseconds: 500), () {
          startListening(_lastOnResult);
        });
      },
    );

    if (!available) {
      throw Exception("STT no disponible en este dispositivo.");
    }

    // Si se inicializó con éxito, arrancamos la primera escucha
    startListening(onResult);
  }

  /// Llama a listen() ya sabiendo que STT está inicializado.
  void startListening(Function(String recognizedWords, bool isFinal) onResult) {
    isListening = true;
    _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
        if (result.finalResult) {
          isListening = false;
        }
      },
      listenFor: const Duration(seconds: 30),
      // en vez de cancelar y partialResults sueltos, los pasamos aquí:
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        onDevice: false,
        listenMode: ListenMode.confirmation,
        sampleRate: 0,
        autoPunctuation: false,
        enableHapticFeedback: false,
      ),
    );
  }

  void stopListening() {
    _speechToText.stop();
    isListening = false;
  }

  Future<void> speak(String text) async {
    final sanitized = text.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (m) => m.group(1) ?? '',
    );
    await _flutterTts.speak(sanitized);
  }

  Future<void> pause() async {
    if (await _flutterTts.pause() == 1) ttsState = TtsState.paused;
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    ttsState = TtsState.stopped;
  }
}
