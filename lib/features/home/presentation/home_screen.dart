import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RemoteEye'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const BrandLogo(size: 90, showTagline: true),
              const SizedBox(height: 24),

              // Host Card ("Share My Screen")
              _buildFeatureCard(
                context,
                title: 'Share My Screen',
                subtitle: 'Host mode: Generate a 6-digit PIN or QR code to mirror this phone\'s screen to another device.',
                icon: Icons.screen_share,
                buttonLabel: 'Start Host Sharing',
                isPrimary: true,
                onTap: () => context.push('/host/pairing'),
              ),

              const SizedBox(height: 16),

              // Viewer Card ("View Another Screen")
              _buildFeatureCard(
                context,
                title: 'View Another Screen',
                subtitle: 'Viewer mode: Join with a 6-digit PIN or scan QR code to view and remotely control a host phone.',
                icon: Icons.cast_connected,
                buttonLabel: 'Join as Viewer',
                isPrimary: false,
                onTap: () => context.push('/viewer/join'),
              ),

              const SizedBox(height: 24),
              const Text(
                'Low Latency Peer-to-Peer • Firebase & WebRTC Powered',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String buttonLabel,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isPrimary ? AppTheme.primaryCyan : AppTheme.accentNeon).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isPrimary ? AppTheme.primaryCyan : AppTheme.accentNeon,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textBright,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isPrimary
                  ? ElevatedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(buttonLabel),
                    )
                  : OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(buttonLabel),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
