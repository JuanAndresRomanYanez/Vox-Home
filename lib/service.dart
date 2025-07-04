import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/speech_service.dart';

// @pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  await dotenv.load(fileName: ".env");
  final webhookUrl = dotenv.env['DIALOGFLOW_URL']?.trim();
  if (webhookUrl == null || webhookUrl.isEmpty) {
    throw Exception('DIALOGFLOW_URL no está definido en el .env');
  }

  final speech = SpeechService();
  const shakeThreshold = 15.0;
  const debounceMs     = 2000;
  int lastShake        = 0;

  accelerometerEventStream().listen((event) {
    final g   = sqrt(event.x*event.x + event.y*event.y + event.z*event.z);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (g > shakeThreshold && now - lastShake > debounceMs) {
      lastShake = now;
      _handleGesture(speech, webhookUrl);
    }
  });

  service.on('stopService').listen((_) {
    service.stopSelf();
  });
}

Future<void> _handleGesture(SpeechService speech, String webhookUrl) async {
  // 1) Saludo
  await speech.speak("Buenas, soy VoxBot. ¿En qué puedo ayudarte?");

  // 2) Espera a que termine de hablar
  while (speech.ttsState == TtsState.playing) {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // 3) STT
  if (!await speech.initSpeech()) {
    await speech.speak("Error al inicializar el reconocimiento.");
    return;
  }
  final c = Completer<String>();
  speech.startListening((text, isFinal) {
    if (isFinal && !c.isCompleted) c.complete(text);
  });
  final recognized = await c.future;
  speech.stopListening();

  // 4) Si no dijo nada
  if (recognized.trim().isEmpty) {
    await speech.speak("No escuché nada. Hasta la próxima.");
    return;
  }

  // 5) Petición HTTP
  String reply;
  int statusCode;
  String responseBody;
  try {
    final resp = await http.post(
      Uri.parse(webhookUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': recognized}),
    );

    statusCode   = resp.statusCode;
    responseBody = resp.body;
    print("🛰  HTTP status=$statusCode");
    print("📦  body=$responseBody");

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      reply = body['fulfillmentText'] as String? ?? "¡Listo!";
    } else {
      reply =
        "Error ${resp.statusCode}: ${resp.body.replaceAll('\n', ' ')}";
    }
  } catch (_) {
    reply = "Error al conectar con el servidor.";
  }

  print("💬 VOXBOT va a decir: $reply");
  // 6) Hablamos la respuesta
  await speech.speak(reply);

  // 7) Despedida
  await speech.speak("Hasta la próxima.");
}
