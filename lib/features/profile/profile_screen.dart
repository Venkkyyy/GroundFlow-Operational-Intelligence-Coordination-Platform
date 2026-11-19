import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gf_network_pill.dart';
import '../../core/network/data_usage_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _locationOptIn = true;
  bool _dpdpConsent = true;

  @override
  Widget build(BuildContext context) {
    final manager = DataUsageManager();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: GFNetworkPill(compact: true),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: manager,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: const Text('VS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Vinik Shah', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            const Text('Department Head · Media', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: ['Cinema FX3', 'Drone Certified', 'Lead'].map((s) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(s, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Network & Data Usage Dashboard Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Colors.green, width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.bolt_rounded, color: Colors.green, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Data & Network Optimizer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                                Text('Low Bandwidth Campus Mode', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.green)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statTile('Session Usage', manager.formattedUsage),
                          _statTile('Queued Offline', '${manager.pendingSyncActions} actions'),
                          _statTile('Cache Storage', '3.8 MB'),
                        ],
                      ),
                      const Divider(height: 20),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Aggressive Campus Low-Data Mode', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Fetches metadata only, suppresses large image previews, batches socket frames.', style: TextStyle(fontSize: 11)),
                        value: manager.isLowDataMode,
                        activeColor: Colors.green,
                        onChanged: (val) => manager.setLowDataMode(val),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                        label: const Text('Clear Offline Database Cache', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✓ Cache wiped. Fresh index downloaded.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // DPDP & Privacy Safeguards (Section 8)
              const Text('Privacy & Trust (India DPDP Act 2023)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Shift-Only Location Sharing', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Visible ONLY to your Team Lead & Head during an active shift. Stops automatically at checkout.', style: TextStyle(fontSize: 11)),
                        value: _locationOptIn,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _locationOptIn = val),
                      ),
                      const Divider(),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Event Data Minimization Consent', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Telemetry logs purged after BCS event conclusion per campus policy.', style: TextStyle(fontSize: 11)),
                        value: _dpdpConsent,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _dpdpConsent = val),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger.withOpacity(0.1),
                  foregroundColor: AppColors.danger,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out of GroundFlow', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out.')),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
      ],
    );
  }
}
