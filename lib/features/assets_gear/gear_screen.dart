import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gf_network_pill.dart';
import '../../core/network/data_usage_manager.dart';

class GearScreen extends StatefulWidget {
  final String eventId;
  const GearScreen({super.key, required this.eventId});

  @override
  State<GearScreen> createState() => _GearScreenState();
}

class _GearScreenState extends State<GearScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _filter = 'All';

  final List<_GearBundle> _bundles = [
    _GearBundle(
      kitCode: 'KIT-A-01',
      title: 'Camera Master Kit Alpha',
      holder: 'Arjun Mehta (Squad A)',
      dueTime: '01:30 PM',
      status: 'In Use',
      items: [
        'Sony FX3 Cinema Body (SN: #88921)',
        'Sony 24-70mm f/2.8 GM Lens',
        '2x NP-FZ100 Lithium Batteries (Full)',
        'SanDisk Extreme Pro 128GB V90 Card',
        'Manfrotto Carbon Tripod',
      ],
    ),
    _GearBundle(
      kitCode: 'KIT-A-02',
      title: 'Drone Aerial Kit 1',
      holder: 'Dhruv Patel (Drone Pilot)',
      dueTime: '02:00 PM',
      status: 'In Use',
      items: [
        'DJI Mini 3 Pro Drone & RC Controller',
        '3x Intelligent Flight Batteries',
        'ND Filter Set (4/8/16/32)',
        'SanDisk 64GB Extreme Pro MicroSD',
      ],
    ),
    _GearBundle(
      kitCode: 'KIT-A-03',
      title: 'Mobile Audio Capture Rig',
      holder: 'In Locker (Gear Room B-104)',
      dueTime: '—',
      status: 'Available',
      items: [
        'Rode Wireless PRO Dual Transmitter',
        '2x Lavalier Lapel Microphones',
        'Zoom H6 Handy Recorder',
      ],
    ),
    _GearBundle(
      kitCode: 'KIT-B-01',
      title: 'Gimbal Stabilizer Rig',
      holder: 'Chen Wei (Overdue 20m)',
      dueTime: '11:30 AM',
      status: 'Overdue',
      items: [
        'DJI RS3 Pro Gimbal Stabilizer',
        'Extended Battery Grip',
        'Focus Motor & Cable Bundle',
      ],
    ),
  ];

  final List<_BatteryStatus> _batteries = [
    _BatteryStatus('BAT-01', 'NP-FZ100', 98, 'In Camera (Kit #1)', Colors.green),
    _BatteryStatus('BAT-02', 'NP-FZ100', 100, 'Charging Hub #1', Colors.blue),
    _BatteryStatus('BAT-03', 'NP-FZ100', 25, 'Returning for Swap', Colors.orange),
    _BatteryStatus('BAT-04', 'V-Mount 95Wh', 85, 'Auditorium Rig', Colors.green),
    _BatteryStatus('BAT-05', 'DJI Flight Bat 1', 12, 'Empty (Needs Charge)', Colors.red),
    _BatteryStatus('BAT-06', 'DJI Flight Bat 2', 90, 'Ready in Hub', Colors.green),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
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
            Text('Gear & QR Custody', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text('Bundles, Batteries & SD Health', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
            Tab(text: 'Kits & Bundles'),
            Tab(text: 'Battery & Cards'),
            Tab(text: 'Shortage Alerts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildKitsTab(),
          _buildBatteriesAndCardsTab(),
          _buildShortageForecastTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        label: const Text('Scan QR Check-out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        onPressed: () => _showScanModal(context),
      ),
    );
  }

  Widget _buildKitsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Search & Filters
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search gear or serial number...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Summary mini chips
        Row(
          children: [
            _MiniBadge(label: 'Total Bundles: 14', color: AppColors.primary),
            const SizedBox(width: 8),
            _MiniBadge(label: 'In Use: 11', color: Colors.blue),
            const SizedBox(width: 8),
            _MiniBadge(label: 'Overdue: 1', color: AppColors.danger),
          ],
        ),
        const SizedBox(height: 16),

        ..._bundles.map((bundle) {
          final isOverdue = bundle.status == 'Overdue';
          final isAvailable = bundle.status == 'Available';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isOverdue ? AppColors.danger : AppColors.border,
                width: isOverdue ? 1.5 : 1,
              ),
            ),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? AppColors.danger.withOpacity(0.12)
                      : isAvailable
                          ? Colors.green.withOpacity(0.12)
                          : AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.camera_rounded,
                  color: isOverdue
                      ? AppColors.danger
                      : isAvailable
                          ? Colors.green
                          : AppColors.primary,
                  size: 22,
                ),
              ),
              title: Text(
                bundle.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                '${bundle.kitCode} • Holder: ${bundle.holder}',
                style: TextStyle(
                  fontSize: 12,
                  color: isOverdue ? AppColors.danger : AppColors.textSecondary,
                  fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? AppColors.danger.withOpacity(0.12)
                      : isAvailable
                          ? Colors.green.withOpacity(0.12)
                          : Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bundle.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isOverdue
                        ? AppColors.danger
                        : isAvailable
                            ? Colors.green
                            : Colors.blue,
                  ),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 16),
                      const Text(
                        'Verified Checklist Items in Kit:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      ...bundle.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, size: 14, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item, style: const TextStyle(fontSize: 12))),
                              ],
                            ),
                          )),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                              icon: const Icon(Icons.history_rounded, size: 16),
                              label: const Text('Custody Log', style: TextStyle(fontSize: 12)),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOverdue ? AppColors.danger : AppColors.primary,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.assignment_return_outlined, size: 16, color: Colors.white),
                              label: Text(
                                isAvailable ? 'Check-Out' : 'Check-In',
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                              ),
                              onPressed: () {
                                DataUsageManager().trackNetworkTransfer(upload: 350);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Status updated for ${bundle.kitCode}')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildBatteriesAndCardsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Battery Charging Matrix', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Keep squads from running dry mid-keynote', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 14),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
          ),
          itemCount: _batteries.length,
          itemBuilder: (ctx, i) {
            final bat = _batteries[i];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.battery_charging_full_rounded, color: bat.color, size: 18),
                      const SizedBox(width: 6),
                      Text(bat.code, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const Spacer(),
                      Text('${bat.percent}%', style: TextStyle(fontWeight: FontWeight.w800, color: bat.color, fontSize: 13)),
                    ],
                  ),
                  const Spacer(),
                  Text(bat.type, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(bat.location, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 24),
        const Text('SD Card State Tracker', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Prevents overwriting un-ingested event footage', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 12),

        _buildSdCardRow('SD-01 (128GB)', 'Contains Morning Keynote', 'Ingested (Needs Backup)', Colors.orange),
        _buildSdCardRow('SD-02 (128GB)', 'Robotics Trials B-Roll', 'Shot (In Transit to Dump)', Colors.purple),
        _buildSdCardRow('SD-03 (64GB)', 'Formatted & Blank', 'Available in Locker', Colors.green),
        _buildSdCardRow('SD-04 (256GB)', 'Day 1 All Raw Archive', 'Safe (2 Copies on NAS)', Colors.teal),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildSdCardRow(String title, String desc, String state, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.sd_card_rounded, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            state,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildShortageForecastTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.danger.withOpacity(0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OR-Tools Shortage Alert', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.danger)),
                    SizedBox(height: 2),
                    Text(
                      'Short 2 Gimbals during 02:00 PM – 04:00 PM peak overlap. Consider shifting Tech Exhibition shoot to tripod.',
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Peak Hour Asset Utilization', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _utilizationBar('Camera Bodies (6/6)', 1.0, Colors.red),
        _utilizationBar('Wireless Audio (4/6)', 0.66, Colors.blue),
        _utilizationBar('Gimbals (3/2)', 1.5, Colors.red),
        _utilizationBar('Lighting Kits (2/4)', 0.50, Colors.green),
        _utilizationBar('Drones (1/1)', 1.0, Colors.orange),
      ],
    );
  }

  Widget _utilizationBar(String label, double ratio, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(ratio >= 1.0 ? 'Over Capacity' : '${(ratio * 100).toInt()}%',
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            color: color,
            backgroundColor: Colors.grey.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  void _showScanModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Scan Gear QR Tag', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code_scanner_rounded, size: 64, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Point camera at gear QR sticker or volunteer ID card', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () {
                  Navigator.pop(ctx);
                  DataUsageManager().trackNetworkTransfer(upload: 220);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Gear checked out to your account.')),
                  );
                },
                child: const Text('Simulate Scan Success', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _GearBundle {
  final String kitCode, title, holder, dueTime, status;
  final List<String> items;
  _GearBundle({
    required this.kitCode,
    required this.title,
    required this.holder,
    required this.dueTime,
    required this.status,
    required this.items,
  });
}

class _BatteryStatus {
  final String code, type, location;
  final int percent;
  final Color color;
  _BatteryStatus(this.code, this.type, this.percent, this.location, this.color);
}
