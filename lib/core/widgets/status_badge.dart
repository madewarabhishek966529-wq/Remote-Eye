import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ConnectionStatus {
  idle,
  creating,
  waitingForViewer,
  connecting,
  connected,
  reconnecting,
  disconnected,
  error,
}

class StatusBadge extends StatelessWidget {
  final ConnectionStatus status;
  final String? customMessage;

  const StatusBadge({
    super.key,
    required this.status,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final label = customMessage ?? _getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return AppTheme.statusGreen;
      case ConnectionStatus.connecting:
      case ConnectionStatus.waitingForViewer:
      case ConnectionStatus.creating:
        return AppTheme.primaryCyan;
      case ConnectionStatus.reconnecting:
        return AppTheme.statusWarning;
      case ConnectionStatus.disconnected:
      case ConnectionStatus.error:
        return AppTheme.statusError;
      case ConnectionStatus.idle:
        return AppTheme.textMuted;
    }
  }

  String _getStatusLabel(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.idle:
        return 'Idle';
      case ConnectionStatus.creating:
        return 'Initializing Session...';
      case ConnectionStatus.waitingForViewer:
        return 'Waiting for Viewer...';
      case ConnectionStatus.connecting:
        return 'Establishing Connection...';
      case ConnectionStatus.connected:
        return 'Connected Live';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting...';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.error:
        return 'Connection Failed';
    }
  }
}
