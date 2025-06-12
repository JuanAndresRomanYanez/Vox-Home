import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vox_home/infrastructure/services/services.dart';
import 'package:vox_home/presentation/providers/providers.dart';

class AudioView extends ConsumerStatefulWidget {
  const AudioView({super.key});

  @override
  ConsumerState<AudioView> createState() => _AudioViewState();
}

class _AudioViewState extends ConsumerState<AudioView> {
  String _transcribedText = '';
  late final SpeechService _speech;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _speech = ref.read(speechServiceProvider);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      await _speech.startContinuousListening((text, isFinal) {
        setState(() => _transcribedText = text);
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Error STT: $_error')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('VOX HOME'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            // Aquí va la burbuja de texto con animación de cambio
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: _buildBubble(_transcribedText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(String text) {
    final display = text.isEmpty ? 'Estoy escuchando…' : text;
    return Container(
      key: ValueKey(display),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.9,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        display,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.3,
        ),
      ),
    );
  }


}
