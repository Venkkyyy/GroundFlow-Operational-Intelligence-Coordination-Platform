import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gf_network_pill.dart';
import '../../core/network/data_usage_manager.dart';

class PipelineScreen extends StatefulWidget {
  final String eventId;
  const PipelineScreen({super.key, required this.eventId});

  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> {
  final List<_DumpStation> _dumpStations = [
    _DumpStation(
      name: 'Dump Station B-204 (Primary)',
      location: 'Building B, 2nd Floor Room 204',
      operatorName: 'Meera Reddy',
      status: 'Open',
      activeCardsCount: 3,
      totalGigaBytesToday: 480,
    ),
    _DumpStation(
      name: 'Amphitheatre Field Hub',
      location: 'Backstage Media Tent',
      operatorName: 'Deepak Singh',
      status: 'Busy',
      activeCardsCount: 5,
      totalGigaBytesToday: 310,
    ),
  ];

  final List<_ShootPipelineItem> _shoots = [
    _ShootPipelineItem(
      id: 'P-101',
      title: 'Morning Keynote & Dignitary Inauguration',
      location: 'Hall A (Auditorium)',
      cardId: 'SD-128-01',
      runner: 'Ravi Kumar (Squad A)',
      currentStageIndex: 4, // Backed up (copy 2)
      copiesCount: 2,
      fileCount: 412,
      totalSizeGb: 64.2,
      nasFolderLink: 'nas://bcs2026/media/day1/keynote_hall_a',
      timeShot: '11:30 AM',
      isStalled: false,
    ),
    _ShootPipelineItem(
      id: 'P-102',
      title: 'Robotics Arena Challenge 1',
      location: 'Tech Block Arena',
      cardId: 'SD-128-02',
      runner: 'Chen Wei',
      currentStageIndex: 2, // Ingested
      copiesCount: 1,
      fileCount: 280,
      totalSizeGb: 38.0,
      nasFolderLink: 'nas://bcs2026/media/day1/robotics_arena',
      timeShot: '01:15 PM',
      isStalled: false,
    ),
    _ShootPipelineItem(
      id: 'P-103',
      title: 'Design Hackathon Opening Talks',
      location: 'Seminar Hall 3',
      cardId: 'SD-64-05',
      runner: 'Waiting for Runner',
      currentStageIndex: 0, // Shot but card not handed in
      copiesCount: 0,
      fileCount: 0,
      totalSizeGb: 0,
      nasFolderLink: null,
      timeShot: '10:15 AM',
      isStalled: true, // Over 2 hours since shot!
    ),
    _ShootPipelineItem(
      id: 'P-104',
      title: 'Dean Speech & Merit Awards',
      location: 'Central Lawn Stage',
      cardId: 'SD-256-01',
      runner: 'Ananya Patel',
      currentStageIndex: 5, // Editing
      copiesCount: 2,
      fileCount: 618,
      totalSizeGb: 92.5,
      nasFolderLink: 'nas://bcs2026/media/day1/dean_awards',
      timeShot: '09:45 AM',
      isStalled: false,
    ),
  ];

  static const List<String> _stages = [
    'Shot',
    'Card Handed',
    'Ingested',
    'Verified (Hash)',
    'Backed Up (2x)',
    'Editing',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    final safeCount = _shoots.where((s) => s.copiesCount >= 2).length;
    final atRiskCount = _shoots.where((s) => s.copiesCount == 1).length;
    final stalledCount = _shoots.where((s) => s.isStalled).length;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data Dump & Pipeline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text('Ingest Tracking & 2-Copy Backup Rule', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: GFNetworkPill(compact: true),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Low Network Architecture Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.cloud_off_rounded, color: Colors.green, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Zero video stored in cloud DB. Raw media stays on campus SSD/NAS drives; app synchronizes checksum & verification metadata only (~1 KB).',
                    style: TextStyle(fontSize: 11.5, color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Safe / At Risk / Stalled Counters
          Row(
            children: [
              _PipelineCounterCard(
                label: 'Safe (2 Copies)',
                count: safeCount,
                color: Colors.green,
                icon: Icons.shield_rounded,
              ),
              const SizedBox(width: 8),
              _PipelineCounterCard(
                label: 'At Risk (1 Copy)',
                count: atRiskCount,
                color: Colors.orange,
                icon: Icons.warning_amber_rounded,
              ),
              const SizedBox(width: 8),
              _PipelineCounterCard(
                label: 'Stalled (>2h)',
                count: stalledCount,
                color: AppColors.danger,
                icon: Icons.alarm_rounded,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Dump Stations Status
          const Text('Campus Dump Stations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),

          ..._dumpStations.map((station) {
            final isOpen = station.status == 'Open';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOpen ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.storage_rounded,
                    color: isOpen ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ),
                title: Text(station.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                subtitle: Text('${station.location} • Operator: ${station.operatorName}', style: const TextStyle(fontSize: 11.5)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOpen ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    station.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isOpen ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),
          const Text('Shoot Footage Pipeline Stages', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),

          ..._shoots.map((item) => _buildShootPipelineCard(context, item)),
        ],
      ),
    );
  }

  Widget _buildShootPipelineCard(BuildContext context, _ShootPipelineItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: item.isStalled ? AppColors.danger : AppColors.border,
          width: item.isStalled ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                if (item.isStalled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error_outline, size: 12, color: AppColors.danger),
                        SizedBox(width: 4),
                        Text(
                          'STALLED >2h',
                          style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.copiesCount >= 2 ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.copiesCount >= 2 ? 'SAFE (2x Copy)' : '1 COPY ONLY',
                      style: TextStyle(
                        color: item.copiesCount >= 2 ? Colors.green : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${item.location} • Shot at ${item.timeShot} • Card: ${item.cardId}',
              style: const TextStyle(fontSize: 11.5, color: Colors.blueGrey),
            ),
            const SizedBox(height: 12),

            // Horizontal Step Progress Indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stage: ${_stages[item.currentStageIndex]}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    Text(
                      '${item.currentStageIndex + 1}/${_stages.length}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (item.currentStageIndex + 1) / _stages.length,
                    minHeight: 8,
                    backgroundColor: Colors.grey.withOpacity(0.15),
                    color: item.isStalled ? AppColors.danger : AppColors.primary,
                  ),
                ),
              ],
            ),

            if (item.fileCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Files: ${item.fileCount} clips (${item.totalSizeGb} GB)', style: const TextStyle(fontSize: 11.5)),
                    const Text('MD5 Checksum: ✓ Verified', style: TextStyle(fontSize: 11.5, color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.qr_code_scanner, size: 15),
                  label: const Text('Handoff Scan', style: TextStyle(fontSize: 11.5)),
                  onPressed: () {
                    DataUsageManager().trackNetworkTransfer(upload: 150);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Card handoff verified for ${item.cardId}')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                if (item.nasFolderLink != null)
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.folder_shared_outlined, size: 15),
                      label: const Text('NAS Folder', style: TextStyle(fontSize: 11.5)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Path copied: ${item.nasFolderLink}')),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PipelineCounterCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _PipelineCounterCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DumpStation {
  final String name, location, operatorName, status;
  final int activeCardsCount, totalGigaBytesToday;
  _DumpStation({
    required this.name,
    required this.location,
    required this.operatorName,
    required this.status,
    required this.activeCardsCount,
    required this.totalGigaBytesToday,
  });
}

class _ShootPipelineItem {
  final String id, title, location, cardId, runner;
  final int currentStageIndex, copiesCount, fileCount;
  final double totalSizeGb;
  final String? nasFolderLink;
  final String timeShot;
  final bool isStalled;

  _ShootPipelineItem({
    required this.id,
    required this.title,
    required this.location,
    required this.cardId,
    required this.runner,
    required this.currentStageIndex,
    required this.copiesCount,
    required this.fileCount,
    required this.totalSizeGb,
    required this.nasFolderLink,
    required this.timeShot,
    required this.isStalled,
  });
}
