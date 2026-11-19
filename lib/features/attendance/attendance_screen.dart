import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gf_network_pill.dart';
import '../../core/network/data_usage_manager.dart';

class AttendanceScreen extends StatefulWidget {
  final String eventId;
  const AttendanceScreen({super.key, required this.eventId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _qrTimer;
  int _qrSecondsLeft = 45;
  String _currentQrCode = 'GF-ROUND-2-1200-TOKEN-7841';

  bool _isShiftActive = true;
  bool _markedCurrentRound = false;
  String _selectedStatus = 'OK';

  final List<_AttendanceRound> _rounds = [
    _AttendanceRound(roundNumber: 1, time: '10:00 AM', status: 'Verified', method: 'Geofence (Auditorium)', timeLogged: '10:04 AM'),
    _AttendanceRound(roundNumber: 2, time: '12:00 PM', status: 'Active Now', method: 'Rotating QR / Geofence', timeLogged: null),
    _AttendanceRound(roundNumber: 3, time: '02:00 PM', status: 'Pending', method: '—', timeLogged: null),
    _AttendanceRound(roundNumber: 4, time: '04:00 PM', status: 'Pending', method: '—', timeLogged: null),
    _AttendanceRound(roundNumber: 5, time: '06:00 PM', status: 'Pending', method: '—', timeLogged: null),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startRotatingQrTimer();
  }

  void _startRotatingQrTimer() {
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_qrSecondsLeft > 1) {
          _qrSecondsLeft--;
        } else {
          _qrSecondsLeft = 60;
          _currentQrCode = 'GF-ROUND-2-1200-TOKEN-${DateTime.now().millisecondsSinceEpoch % 10000}';
        }
      });
    });
  }

  @override
  void dispose() {
    _qrTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance & Rounds', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text('Timed Geofence & Dynamic QR', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: GFNetworkPill(compact: true),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Attendance'),
            Tab(text: 'Rotating QR (Lead)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyAttendanceTab(),
          _buildLeadRotatingQrTab(),
        ],
      ),
    );
  }

  Widget _buildMyAttendanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shift Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3D5AFE), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Shift: Day 1 (08:30 – 19:00)',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                          SizedBox(width: 4),
                          Text(
                            'ACTIVE SHIFT',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Media Squad Alpha',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Building A & Central Amphitheatre Zone',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('End Shift', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Shift check-out recorded.')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Active Round Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Round 2 Open (12:00 – 12:10 PM)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    Text(
                      '$_qrSecondsLeft s left',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.warning, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap below to verify your presence. Works via Geofence GPS or by scanning your lead\'s rotating QR code.',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ['OK', 'Need Help', 'On Break'].map((status) {
                    final isSel = _selectedStatus == status;
                    return ChoiceChip(
                      label: Text(status),
                      selected: isSel,
                      onSelected: (_) => setState(() => _selectedStatus = status),
                      selectedColor: status == 'Need Help'
                          ? AppColors.danger.withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _markedCurrentRound ? Colors.green : AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(
                      _markedCurrentRound ? Icons.check_circle : Icons.how_to_reg_rounded,
                      color: Colors.white,
                    ),
                    label: Text(
                      _markedCurrentRound ? 'Marked Present (Round 2 Verified)' : 'I\'m Here · Confirm Attendance',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      setState(() => _markedCurrentRound = true);
                      DataUsageManager().trackNetworkTransfer(upload: 512); // minimal 512 B telemetry payload
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Presence verified (Audit timestamp + GPS geofence recorded).'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('Today\'s Attendance Rounds', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rounds.length,
            itemBuilder: (ctx, i) {
              final r = _rounds[i];
              final isVerified = r.status == 'Verified' || (i == 1 && _markedCurrentRound);
              final isActive = r.status == 'Active Now' && !_markedCurrentRound;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isActive ? AppColors.warning : AppColors.border,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isVerified
                          ? Colors.green.withOpacity(0.12)
                          : isActive
                              ? AppColors.warning.withOpacity(0.12)
                              : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isVerified
                            ? Icons.check
                            : isActive
                                ? Icons.access_time
                                : Icons.hourglass_empty,
                        size: 18,
                        color: isVerified
                            ? Colors.green
                            : isActive
                                ? AppColors.warning
                                : Colors.grey,
                      ),
                    ),
                  ),
                  title: Text(
                    'Round ${r.roundNumber} (${r.time})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isVerified ? 'Verified at ${r.timeLogged ?? '12:02 PM'}' : r.method,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? Colors.green.withOpacity(0.1)
                          : isActive
                              ? AppColors.warning.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isVerified
                          ? 'Verified'
                          : isActive
                              ? 'Action Needed'
                              : 'Pending',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isVerified
                            ? Colors.green
                            : isActive
                                ? AppColors.warning
                                : Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeadRotatingQrTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.security_rounded, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Anti-Cheating Token: Regulates physical presence. Token refreshes every 60 seconds to prevent photo forwards.',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  QrImageView(
                    data: _currentQrCode,
                    version: QrVersions.auto,
                    size: 200.0,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primary),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Token expires in $_qrSecondsLeft seconds',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warning),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: _qrSecondsLeft / 60.0,
                    color: AppColors.primary,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Round 2 · Media Squad Alpha',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Open QR Scanner for Volunteer Badges'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scanner ready to log physical checks.')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AttendanceRound {
  final int roundNumber;
  final String time;
  final String status;
  final String method;
  final String? timeLogged;

  _AttendanceRound({
    required this.roundNumber,
    required this.time,
    required this.status,
    required this.method,
    required this.timeLogged,
  });
}
