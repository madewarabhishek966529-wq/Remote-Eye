import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/host/presentation/host_pairing_screen.dart';
import 'features/host/presentation/host_streaming_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/viewer/presentation/qr_scanner_screen.dart';
import 'features/viewer/presentation/viewer_join_screen.dart';
import 'features/viewer/presentation/viewer_stream_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/host/pairing',
      builder: (context, state) => const HostPairingScreen(),
    ),
    GoRoute(
      path: '/host/streaming',
      builder: (context, state) => const HostStreamingScreen(),
    ),
    GoRoute(
      path: '/viewer/join',
      builder: (context, state) => const ViewerJoinScreen(),
    ),
    GoRoute(
      path: '/viewer/qr_scanner',
      builder: (context, state) => const QrScannerScreen(),
    ),
    GoRoute(
      path: '/viewer/stream',
      builder: (context, state) => const ViewerStreamScreen(),
    ),
  ],
);

class RemoteEyeApp extends StatelessWidget {
  const RemoteEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RemoteEye',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
