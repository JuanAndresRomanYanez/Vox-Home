import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final micStatus = await Permission.microphone.request();
  if (!micStatus.isGranted) {
    // Aquí podrías mostrar un diálogo o cerrar la app
    // Pero al menos ya no se quejará de STT no disponible
  }

  await FlutterBackgroundService().configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      
    ),
    iosConfiguration: IosConfiguration(autoStart: true),
  );
  FlutterBackgroundService().startService();

  runApp(const _HeadlessApp());

  // Cerramos inmediatamente la UI de Flutter (no habrá pantalla blanca ni icono)
  SystemNavigator.pop();
}


/// Un widget completamente vacío, solo para que Flutter cree el contexto.
/// No se muestra nada porque justo después llamamos a SystemNavigator.pop().
class _HeadlessApp extends StatelessWidget {
  const _HeadlessApp();
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}