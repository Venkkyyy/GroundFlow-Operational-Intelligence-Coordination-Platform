import 'package:flutter/material.dart';
import '../network/data_usage_manager.dart';
import '../theme/app_colors.dart';

/// Aesthetic Data & Network Usage status badge shown in app bars or floating
class GFNetworkPill extends StatelessWidget {
  final bool compact;
  const GFNetworkPill({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final manager = DataUsageManager();
    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        final isOffline = manager.isOffline;
        final isLowData = manager.isLowDataMode;
        final pending = manager.pendingSyncActions;

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showDataUsageSheet(context, manager),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 12,
              vertical: compact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: isOffline
                  ? AppColors.warning.withOpacity(0.15)
                  : isLowData
                      ? AppColors.success.withOpacity(0.12)
                      : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOffline
                    ? AppColors.warning.withOpacity(0.4)
                    : isLowData
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOffline
                      ? Icons.wifi_off_rounded
                      : isLowData
                          ? Icons.eco_rounded
                          : Icons.bolt_rounded,
                  size: compact ? 13 : 15,
                  color: isOffline
                      ? AppColors.warning
                      : isLowData
                          ? AppColors.success
                          : AppColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  isOffline
                      ? 'Offline ($pending queued)'
                      : compact
                          ? manager.formattedUsage
                          : '${manager.formattedUsage} • Low Data',
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: isOffline
                        ? AppColors.warning
                        : isLowData
                            ? AppColors.success
                            : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDataUsageSheet(BuildContext context, DataUsageManager manager) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.speed_rounded, color: AppColors.success),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data & Bandwidth Saver',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                manager.dataSavingsEstimate,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Metric(
                            label: 'Session Total',
                            value: manager.formattedUsage,
                            color: AppColors.primary,
                          ),
                          Container(width: 1, height: 35, color: Colors.grey.withOpacity(0.2)),
                          _Metric(
                            label: 'Download',
                            value: '${(manager.bytesDownloaded / 1024).toStringAsFixed(1)} KB',
                            color: Colors.blueGrey,
                          ),
                          Container(width: 1, height: 35, color: Colors.grey.withOpacity(0.2)),
                          _Metric(
                            label: 'Upload',
                            value: '${(manager.bytesUploaded / 1024).toStringAsFixed(1)} KB',
                            color: Colors.blueGrey,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: manager.isLowDataMode,
                      title: const Text(
                        'Campus Low-Bandwidth Mode',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Pushes metadata only (no raw heavy media), batches socket events, and caches schedules locally.',
                        style: TextStyle(fontSize: 12),
                      ),
                      activeColor: AppColors.success,
                      onChanged: (val) {
                        manager.setLowDataMode(val);
                        setSheetState(() {});
                      },
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.sync_rounded, size: 18),
                            label: Text(manager.pendingSyncActions > 0
                                ? 'Sync (${manager.pendingSyncActions})'
                                : 'Cache Synced'),
                            onPressed: () {
                              manager.completeSync();
                              setSheetState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Offline queue synchronized with campus server.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.check, size: 18, color: Colors.white),
                            label: const Text('Done', style: TextStyle(color: Colors.white)),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}
