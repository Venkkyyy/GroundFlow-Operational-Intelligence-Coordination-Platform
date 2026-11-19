import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsScreen extends StatefulWidget {
  final String eventId;
  const ReportsScreen({super.key, this.eventId = 'bcs-2026'});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Attendance'),
            Tab(text: 'Gear'),
            Tab(text: 'Pipeline'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export',
            onPressed: () => _showExportDialog(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _OverviewTab(),
          _AttendanceTab(),
          _GearTab(),
          _PipelineTab(),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart_outlined, color: Color(0xFF217346)),
              title: const Text('Export to Excel'),
              subtitle: const Text('.xlsx format'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFD32F2F)),
              title: const Text('Export to PDF'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_outlined, color: Color(0xFF4285F4)),
              title: const Text('Sync to Google Sheets'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final String? trend;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trend!.startsWith('+')
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      trend!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: trend!.startsWith('+') ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: const [
            _StatCard(
              value: '78',
              label: 'Total Members',
              icon: Icons.people_outline,
              color: Color(0xFF3D5AFE),
              trend: '+3 today',
            ),
            _StatCard(
              value: '94%',
              label: 'Attendance Rate',
              icon: Icons.check_circle_outline,
              color: Color(0xFF00C853),
              trend: '+2%',
            ),
            _StatCard(
              value: '23',
              label: 'Shoots Completed',
              icon: Icons.camera_alt_outlined,
              color: Color(0xFFFF6D00),
            ),
            _StatCard(
              value: '5',
              label: 'Issues Resolved',
              icon: Icons.bug_report_outlined,
              color: Color(0xFFD32F2F),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Issue Resolution Time',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 60,
              barGroups: [
                _bar(0, 45, const Color(0xFF3D5AFE)),
                _bar(1, 20, const Color(0xFF3D5AFE)),
                _bar(2, 55, const Color(0xFF3D5AFE)),
                _bar(3, 10, const Color(0xFF3D5AFE)),
                _bar(4, 30, const Color(0xFF3D5AFE)),
              ],
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text(
                      ['Gear', 'Access', 'Safety', 'Crew', 'Other'][v.toInt()],
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Pipeline Completion',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  value: 14,
                  color: const Color(0xFF00C853),
                  title: 'Safe\n14',
                  radius: 50,
                  titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
                PieChartSectionData(
                  value: 6,
                  color: const Color(0xFFFFB300),
                  title: 'At Risk\n6',
                  radius: 50,
                  titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
                PieChartSectionData(
                  value: 3,
                  color: const Color(0xFFD32F2F),
                  title: 'Stalled\n3',
                  radius: 50,
                  titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          width: 24,
        )
      ],
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rounds = [
      ('Round 1 — 10:00', '74/78', 0.95),
      ('Round 2 — 12:00', '70/78', 0.90),
      ('Round 3 — 14:00', '68/78', 0.87),
      ('Round 4 — 16:00', '65/78', 0.83),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Attendance by Round',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                const SizedBox(height: 16),
                ...rounds.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(r.$1,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              const Spacer(),
                              Text(r.$2,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: r.$3,
                              minHeight: 8,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                r.$3 > 0.9
                                    ? const Color(0xFF00C853)
                                    : r.$3 > 0.8
                                        ? const Color(0xFFFFB300)
                                        : const Color(0xFFD32F2F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Missed Check-ins',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
        const SizedBox(height: 8),
        ...[
          ('Arjun Mehta', 'Squad Alpha', 2),
          ('Priya Shah', 'Squad Beta', 1),
          ('Ravi Kumar', 'Squad Alpha', 3),
        ].map(
          (m) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF3D5AFE).withOpacity(0.1),
                child: Text(
                  m.$1[0],
                  style: const TextStyle(
                      color: Color(0xFF3D5AFE), fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(m.$1),
              subtitle: Text(m.$2),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${m.$3} missed',
                  style: const TextStyle(
                      color: Color(0xFFD32F2F),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GearTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: const [
            _StatCard(
                value: '34',
                label: 'Items Issued',
                icon: Icons.camera_outlined,
                color: Color(0xFF3D5AFE)),
            _StatCard(
                value: '31',
                label: 'Returned',
                icon: Icons.assignment_return_outlined,
                color: Color(0xFF00C853)),
            _StatCard(
                value: '2',
                label: 'Overdue',
                icon: Icons.access_time,
                color: Color(0xFFFFB300)),
            _StatCard(
                value: '1',
                label: 'Missing',
                icon: Icons.search_off_outlined,
                color: Color(0xFFD32F2F)),
          ],
        ),
        const SizedBox(height: 20),
        Text('Gear Utilization by Category',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
        const SizedBox(height: 12),
        ...[
          ('Cameras & Lenses', 0.92, 12),
          ('Batteries', 0.78, 24),
          ('SD Cards', 0.65, 16),
          ('Gimbals', 1.0, 4),
          ('Tripods', 0.5, 8),
          ('Mics / Audio', 0.75, 6),
        ].map(
          (g) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Text(g.$1,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: g.$2,
                      minHeight: 10,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        g.$2 >= 1.0
                            ? const Color(0xFFD32F2F)
                            : g.$2 > 0.75
                                ? const Color(0xFFFFB300)
                                : const Color(0xFF3D5AFE),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(g.$2 * 100).toInt()}%',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PipelineTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stages = [
      'Shot',
      'Card In',
      'Ingested',
      'Verified',
      'Backed Up',
      'Editing',
      'Delivered'
    ];
    final counts = [23, 21, 19, 17, 14, 8, 5];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shoots by Stage',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 25,
                      barGroups: List.generate(
                        stages.length,
                        (i) => BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: counts[i].toDouble(),
                              color: Color.lerp(
                                  const Color(0xFF3D5AFE),
                                  const Color(0xFF00C853),
                                  i / (stages.length - 1))!,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                              width: 20,
                            )
                          ],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) => Transform.rotate(
                              angle: -0.4,
                              child: Text(
                                stages[v.toInt()],
                                style: const TextStyle(fontSize: 9),
                              ),
                            ),
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _PipelineStat(
                  label: 'Safe\n(2 copies)',
                  value: '14',
                  color: const Color(0xFF00C853)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PipelineStat(
                  label: 'At Risk\n(1 copy)',
                  value: '6',
                  color: const Color(0xFFFFB300)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PipelineStat(
                  label: 'Stalled\n(>2h)',
                  value: '3',
                  color: const Color(0xFFD32F2F)),
            ),
          ],
        ),
      ],
    );
  }
}

class _PipelineStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PipelineStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
