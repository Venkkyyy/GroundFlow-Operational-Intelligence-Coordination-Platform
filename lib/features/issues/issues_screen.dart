import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gf_network_pill.dart';
import '../../core/network/data_usage_manager.dart';

class IssuesScreen extends StatefulWidget {
  final String eventId;
  const IssuesScreen({super.key, required this.eventId});

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _priorityFilter = 'All';

  final List<_IssueRecord> _issues = [
    _IssueRecord(
      id: 'ISS-401',
      title: 'Auditorium Side Wing Door Locked',
      category: 'Access',
      squad: 'Squad Alpha',
      building: 'Building A (Main Auditorium)',
      reportedBy: 'Arjun Mehta',
      priority: 'High',
      status: 'Escalated to Head',
      minutesElapsed: 8,
      isCrossDept: true,
      crossDeptTarget: 'Security Department',
      description: 'Camera crew cannot access side risers to mount high-angle keynote shot.',
    ),
    _IssueRecord(
      id: 'ISS-402',
      title: 'Primary FX3 Battery Drain Issue',
      category: 'Gear',
      squad: 'Squad Alpha',
      building: 'Building A',
      reportedBy: 'Sara Ali',
      priority: 'High',
      status: 'Open',
      minutesElapsed: 3,
      isCrossDept: false,
      crossDeptTarget: null,
      description: 'NP-FZ100 battery drained after 20 minutes in 4K 60fps recording. Fresh battery needed.',
    ),
    _IssueRecord(
      id: 'ISS-403',
      title: 'Power Extension Cable Needed',
      category: 'Other',
      squad: 'Squad Beta',
      building: 'Tech Block Arena',
      reportedBy: 'Priya Sharma',
      priority: 'Medium',
      status: 'Assigned',
      minutesElapsed: 14,
      isCrossDept: true,
      crossDeptTarget: 'Logistics Department',
      description: 'Need 10m heavy duty extension reel for drone charging station.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeIssues = _issues.where((i) {
      if (_priorityFilter == 'All') return true;
      return i.priority == _priorityFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Issues & Cross-Dept', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text('5-Min Auto Escalation Engine', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
            Tab(text: 'Active Issues (3)'),
            Tab(text: 'Cross-Dept Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIssuesTab(activeIssues),
          _buildCrossDeptTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: const Text('Raise Issue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        onPressed: () => _showCreateIssueSheet(context),
      ),
    );
  }

  Widget _buildIssuesTab(List<_IssueRecord> list) {
    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: ['All', 'High', 'Medium', 'Low'].map((p) {
              final isSel = _priorityFilter == p;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(p),
                  selected: isSel,
                  onSelected: (_) => setState(() => _priorityFilter = p),
                  selectedColor: p == 'High' ? AppColors.danger.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
                  checkmarkColor: p == 'High' ? AppColors.danger : AppColors.primary,
                ),
              );
            }).toList(),
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final issue = list[i];
              final isEscalated = issue.status.contains('Escalated');
              final isHigh = issue.priority == 'High';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isEscalated ? AppColors.danger : AppColors.border,
                    width: isEscalated ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isHigh ? AppColors.danger.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${issue.priority} Priority',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isHigh ? AppColors.danger : Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isEscalated)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ESCALATED TO HEAD (>5m)',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.purple),
                              ),
                            ),
                          const Spacer(),
                          Text(
                            '${issue.minutesElapsed}m ago',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        issue.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        issue.description,
                        style: const TextStyle(fontSize: 12.5, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '📍 ${issue.building} • By ${issue.reportedBy} (${issue.squad})',
                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                      const Divider(height: 18),
                      Row(
                        children: [
                          if (issue.isCrossDept)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Target: ${issue.crossDeptTarget}',
                                style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600),
                              ),
                            ),
                          const Spacer(),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Chat channel opened with assignee.')),
                              );
                            },
                            child: const Text('Message', style: TextStyle(fontSize: 11.5)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              setState(() {
                                _issues.remove(issue);
                              });
                              DataUsageManager().trackNetworkTransfer(upload: 180);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✓ Issue marked as resolved.')),
                              );
                            },
                            child: const Text('Resolve', style: TextStyle(fontSize: 11.5, color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCrossDeptTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Media requests sent to Logistics, Security, Tech, or Hospitality queues. Routed automatically with audit receipts.',
                  style: TextStyle(fontSize: 11.5, color: Colors.blueGrey),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _crossDeptCard(
          toDept: 'Security / Discipline',
          request: 'Open Auditorium Side Wing Fire Doors for tripod line of sight',
          status: 'Accepted (Guard Dispatched)',
          time: '5m ago',
          color: Colors.orange,
        ),
        _crossDeptCard(
          toDept: 'Logistics',
          request: 'Deliver 10m power cord to Tech Arena Media Table',
          status: 'In Transit via Trolley 2',
          time: '12m ago',
          color: Colors.blue,
        ),
        _crossDeptCard(
          toDept: 'Hospitality',
          request: 'Lunch packets (12x) for Media Squad Alpha stationed at Hall A',
          status: 'Delivered ✓',
          time: '35m ago',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _crossDeptCard({
    required String toDept,
    required String request,
    required String status,
    required String time,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.send_rounded, color: color, size: 20),
        ),
        title: Text(toDept, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
        subtitle: Text(request, style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            ),
            const SizedBox(height: 2),
            Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showCreateIssueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Report Incident or Shortage', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['Gear', 'Access', 'Crew', 'Safety', 'Cross-Dept'].map((c) => ChoiceChip(
                  label: Text(c),
                  selected: c == 'Gear',
                  onSelected: (_) {},
                )).toList(),
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Brief summary (e.g. Card reader not responding)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              const TextField(
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Location & additional context...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () {
                    Navigator.pop(ctx);
                    DataUsageManager().trackNetworkTransfer(upload: 280);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✓ Issue logged. Escalation timer started (5m).')),
                    );
                  },
                  child: const Text('Dispatch Ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueRecord {
  final String id, title, category, squad, building, reportedBy, priority, status, description;
  final int minutesElapsed;
  final bool isCrossDept;
  final String? crossDeptTarget;

  _IssueRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.squad,
    required this.building,
    required this.reportedBy,
    required this.priority,
    required this.status,
    required this.minutesElapsed,
    required this.isCrossDept,
    required this.crossDeptTarget,
    required this.description,
  });
}
