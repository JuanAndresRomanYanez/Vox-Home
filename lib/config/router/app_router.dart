
import 'package:go_router/go_router.dart';
import 'package:vox_home/presentation/views/views.dart';

final appRouter = GoRouter(
  initialLocation: '/audio',
  routes: [
    GoRoute(
      path: '/audio',
      name: 'audio',
      builder: (context, state) => const AudioView(),
    ),
    // aquí podrías añadir más rutas en el futuro
  ],
);

