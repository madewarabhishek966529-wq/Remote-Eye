import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'viewer_provider.dart';

class ViewerJoinScreen extends ConsumerStatefulWidget {
  const ViewerJoinScreen({super.key});

  @override
  ConsumerState<ViewerJoinScreen> createState() => _ViewerJoinScreenState();
}

class _ViewerJoinScreenState extends ConsumerState<ViewerJoinScreen> {
  final TextEditingController _ipController = TextEditingController();

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _onJoinPressed() {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Host IP address or scan QR code.'),
          backgroundColor: AppTheme.statusWarning,
        ),
      );
      return;
    }
    ref.read(viewerProvider.notifier).joinSession(ip);
    context.push('/viewer/stream');
  }

  @override
  Widget build(BuildContext context) {
    final viewerState = ref.watch(viewerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Another Screen'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.display_settings, size: 70, color: AppTheme.primaryCyan),
              const SizedBox(height: 16),
              const Text(
                'Connect to Host Device',
                style: TextStyle(
                  color: AppTheme.textBright,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the Host IP address shown on the host phone or scan its QR code to begin live P2P mirroring.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Host IP Input Field
              TextField(
                controller: _ipController,
                keyboardType: TextInputType.url,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppTheme.primaryCyan,
                ),
                decoration: const InputDecoration(
                  labelText: 'Host IP Address',
                  hintText: 'e.g. 192.168.1.42',
                  prefixIcon: Icon(Icons.wifi, color: AppTheme.primaryCyan),
                ),
              ),

              if (viewerState.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  viewerState.errorMessage!,
                  style: const TextStyle(color: AppTheme.statusError, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),

              // Connect Button
              ElevatedButton.icon(
                onPressed: _onJoinPressed,
                icon: const Icon(Icons.cast_connected),
                label: const Text('Connect to Host Screen'),
              ),

              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.darkSurface)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: AppTheme.darkSurface)),
                ],
              ),
              const SizedBox(height: 16),

              // Scan QR Code Button
              OutlinedButton.icon(
                onPressed: () async {
                  final String? scannedTarget = await context.push<String>('/viewer/qr_scanner');
                  if (scannedTarget != null && scannedTarget.isNotEmpty) {
                    _ipController.text = scannedTarget;
                    _onJoinPressed();
                  }
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Host QR Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
