import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vox_home/infrastructure/services/services.dart';

final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechService();
});
