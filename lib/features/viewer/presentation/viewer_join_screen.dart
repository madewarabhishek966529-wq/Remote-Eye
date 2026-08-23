import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onJoinPressed() {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a 6-digit pairing PIN code.'),
          backgroundColor: AppTheme.statusWarning,
        ),
      );
      return;
    }
    ref.read(viewerProvider.notifier).joinSession(code);
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
                'Enter Host Pairing Code',
                style: TextStyle(
                  color: AppTheme.textBright,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the 6-digit code shown on the host phone or scan its QR code to begin live mirroring.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // PIN Code Input Field
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: AppTheme.primaryCyan,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: '000000',
                  counterText: '',
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
                  final String? scannedCode = await context.push<String>('/viewer/qr_scanner');
                  if (scannedCode != null && scannedCode.isNotEmpty) {
                    _codeController.text = scannedCode;
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
