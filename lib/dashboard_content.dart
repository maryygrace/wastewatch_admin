import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:wastewatch_admin/services/supabase_service.dart';

/// A modern, responsive dashboard layout for the WasteWatch admin panel.
/// This widget implements a desktop-first design with a fixed sidebar and a
/// flexible content area, following a specific layout and color scheme.
class DashboardContent extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;

  const DashboardContent({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  // --- COLOR PALETTE ---
  static const Color _primaryAccent = Color(0xFF2ECC71); // Emerald Green
  static const Color _sidebarBg = Color(0xFF1B5E20); // Dark Green
  static const Color _cardBg = Colors.white;

  // --- Card Colors ---
  static const Color _cardColor1 = Color(0xFF2ECC71); // Emerald Green
  static const Color _cardColor2 = Color(0xFF1ABC9C); // Turquoise
  static const Color _cardColor3 = Color(0xFFE74C3C); // Red
  static const Color _cardColor4 = Color(0xFF3498DB); // Blue

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // --- TOP SUMMARY CARDS (Row 1) ---
          const _SummaryCardsRow(),
          const SizedBox(height: 24),

          // --- MIDDLE CHARTS (Row 2) ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Widget (Flex: 1)
              Expanded(
                flex: 1,
                child: _buildChartCard(
                  title: 'Waste Statistics',
                  child: const _WasteStatisticsChart(),
                ),
              ),
              const SizedBox(width: 24),
              // Revenue Widget (Flex: 2)
              Expanded(
                flex: 2,
                child: _buildChartCard(
                  title: 'Reports by Location',
                  child: _ReportsByLocationChart(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- BOTTOM WIDGETS (Row 3) ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent Reports (Flex: 1)
              Expanded(
                flex: 1,
                child: _buildInfoCard(
                  title: 'Recent Reports',
                  child: const _RecentReportsList(),
                ),
              ),
              const SizedBox(width: 24),
              // Top Collectors (Flex: 1)
              Expanded(
                flex: 1,
                child: _buildInfoCard(
                  title: 'Top Collectors',
                  child: const Center(child: Text('List of top collectors...')),
                ),
              ),
              const SizedBox(width: 24),
              // System Alerts (Flex: 1)
              Expanded(
                flex: 1,
                child: _buildInfoCard(
                  title: 'System Alerts',
                  child: const _SystemAlertsList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a card for displaying a chart or complex data.
  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      height: 350, // Fixed height for chart cards
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  /// Builds a generic card for informational content.
  Widget _buildInfoCard({required String title, required Widget child}) {
    // Re-uses the chart card styling but with a flexible height.
    return Container(
      height: 300, // Fixed height for info cards
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }

  /// Builds the fixed-width sidebar on the left.
  /// This is now a static method to be used across the admin panel.
  static Widget buildSidebar(BuildContext context, int currentIndex, ValueChanged<int> onNavigate) {
    return Container(
      width: 250,
      color: _sidebarBg,
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'WasteWatch',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Navigation Items
          _buildSidebarItem(Icons.dashboard, 'Dashboard', 0, currentIndex, onNavigate),
          _buildSidebarItem(Icons.people, 'Users', 1, currentIndex, onNavigate),
          _buildSidebarItem(Icons.bar_chart, 'Reports', 2, currentIndex, onNavigate),
          _buildSidebarItem(Icons.map, 'Clusters', 3, currentIndex, onNavigate),
          const Spacer(),
          _buildSidebarItem(Icons.person, 'Profile', 4, currentIndex, onNavigate),
          _buildSidebarItem(Icons.logout, 'Log Out', 5, currentIndex, onNavigate),
        ],
      ),
    );
  }

  /// Builds a single navigation item for the sidebar.
  static Widget _buildSidebarItem(IconData icon, String title, int index, int currentIndex, ValueChanged<int> onNavigate) {
    final bool isActive = index == currentIndex;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? _primaryAccent.withAlpha(51) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? _primaryAccent : Colors.white70),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          onNavigate(index);
        },
      ),
    );
  }
}

/// A widget to display a list of the 5 most recent reports.
class _RecentReportsList extends StatefulWidget {
  const _RecentReportsList();

  @override
  State<_RecentReportsList> createState() => _RecentReportsListState();
}

class _RecentReportsListState extends State<_RecentReportsList> {
  final _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch the 5 most recent reports.
    _reportsFuture = _supabaseService.fetchReports(limit: 5);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No recent reports found.'));
        }

        final reports = snapshot.data!;
        return ListView.separated(
          itemCount: reports.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final report = reports[index];
            final reporter = report['reporter'];
            final reporterName = reporter?['full_name'] ?? reporter?['email'] ?? 'Unknown';
            final status = report['status'] ?? 'N/A';
            final date = DateFormat.yMMMd().format(DateTime.parse(report['createdAt']));

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(status).withAlpha(50),
                child: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
              ),
              title: Text(reporterName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Status: $status - $date'),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'pending' => Colors.orange,
      'in-progress' => Colors.blue,
      'resolved' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.grey,
    };
  }

  IconData _getStatusIcon(String status) {
    return switch (status) {
      'pending' => Icons.hourglass_top_rounded,
      'in-progress' => Icons.construction_rounded,
      'resolved' => Icons.check_circle_outline_rounded,
      'rejected' => Icons.cancel_outlined,
      _ => Icons.help_outline,
    };
  }
}

/// A widget to display a list of system alerts (e.g., overdue pending reports).
class _SystemAlertsList extends StatefulWidget {
  const _SystemAlertsList();

  @override
  State<_SystemAlertsList> createState() => _SystemAlertsListState();
}

class _SystemAlertsListState extends State<_SystemAlertsList> {
  final _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = _supabaseService.fetchSystemAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _alertsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No system alerts at this time.'));
        }

        final alerts = snapshot.data!;
        return ListView.separated(
          itemCount: alerts.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return _buildAlertTile(alert);
          },
        );
      },
    );
  }

  Widget _buildAlertTile(Map<String, dynamic> alert) {
    final String type = alert['type'];
    final data = alert['data'];

    return switch (type) {
      'overdue_report' => ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.orange),
          title: Text('Overdue Report: ${data['id'].toString().substring(0, 8)}...'),
          subtitle: Text('Pending for ${DateTime.now().difference(DateTime.parse(data['createdAt'])).inDays} days'),
        ),
      'collector_overload' => ListTile(
          leading: const Icon(Icons.person_search, color: Colors.red),
          title: Text('Collector Overload: ${data['full_name'] ?? data['email']}'),
          subtitle: Text('${data['open_report_count']} open reports'),
        ),
      'high_volume_location' => ListTile(
          leading: const Icon(Icons.location_on, color: Colors.blue),
          title: Text('High Volume: ${data['location']}'),
          subtitle: Text('${data['recent_report_count']} reports in 24h'),
        ),
      _ => const ListTile(title: Text('Unknown alert type')),
    };
  }
}

/// A stateful widget to fetch and display the summary cards data.
class _SummaryCardsRow extends StatefulWidget {
  const _SummaryCardsRow();

  @override
  State<_SummaryCardsRow> createState() => _SummaryCardsRowState();
}

class _SummaryCardsRowState extends State<_SummaryCardsRow> {
  final _supabaseService = SupabaseService();
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _supabaseService.getDashboardSummaryStats();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show placeholders while loading
          return _buildSummaryCards(isLoading: true);
        }
        if (snapshot.hasError || !snapshot.hasData) {
          // Show zero values on error
          return _buildSummaryCards(stats: {'total_reports': 0, 'pending_reports': 0, 'resolved_reports': 0});
        }

        final stats = snapshot.data!;
        return _buildSummaryCards(stats: stats);
      },
    );
  }

  /// Builds the row of four summary cards at the top.
  Widget _buildSummaryCards({Map<String, dynamic>? stats, bool isLoading = false}) {
    final totalReports = stats?['total_reports']?.toString() ?? '...';
    final pendingReports = stats?['pending_reports']?.toString() ?? '...';
    final resolvedReports = stats?['resolved_reports']?.toString() ?? '...';

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Reports',
            value: isLoading ? '...' : totalReports,
            icon: Icons.flag,
            color: DashboardContent._cardColor1,
          ),
        ),
        const SizedBox(width: 24),
        const Expanded(
          child: _SummaryCard(
            title: 'Waste Collected (kg)',
            value: '8,530', // This remains a placeholder for now
            icon: Icons.recycling,
            color: DashboardContent._cardColor2,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _SummaryCard(
            title: 'Pending Reports',
            value: isLoading ? '...' : pendingReports,
            icon: Icons.warning,
            color: DashboardContent._cardColor3,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _SummaryCard(
            title: 'Resolved Reports',
            value: isLoading ? '...' : resolvedReports,
            icon: Icons.check_circle_outline,
            color: DashboardContent._cardColor4,
          ),
        ),
      ],
    );
  }
}

/// A widget that builds the "Reports by Location" pie chart with legends.
class _ReportsByLocationChart extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ReportsByLocationChartState();
}

class _ReportsByLocationChartState extends State<_ReportsByLocationChart> {
  int touchedIndex = -1;
  final _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _chartDataFuture;

  // Colors for each section of the pie chart.
  final List<Color> colorList = [
    const Color(0xFF2ECC71),
    const Color(0xFF3498DB),
    const Color(0xFFF1C40F),
    const Color(0xFFE74C3C),
    const Color(0xFF9B59B6),
    const Color(0xFF1ABC9C),
    const Color(0xFFE67E22),
  ];

  @override
  void initState() {
    super.initState();
    _chartDataFuture = _supabaseService.getReportCountsByLocation();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _chartDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No location data available.'));
        }

        final data = snapshot.data!;
        return _buildChart(data);
      },
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> data) {
    // Find the maximum value to set the chart's horizontal axis limit.
    final maxValue = data.fold<double>(0, (max, item) {
      final value = (item['report_count'] as num).toDouble();
      return value > max ? value : max;
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.1, // Add 10% padding to the top
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final location = data[groupIndex]['location'] as String;
              return BarTooltipItem(
                '$location\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: rod.toY.round().toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final location = data[index]['location'] as String;
                  // Truncate long labels for the axis
                  final shortLabel = location.length > 10 ? '${location.substring(0, 8)}...' : location;
                  return SideTitleWidget(meta: meta, space: 4, child: Text(shortLabel, style: const TextStyle(fontSize: 10)));
                }
                return const Text('');
              },
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                // Use SideTitleWidget for consistency and proper spacing.
                final text = Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                return SideTitleWidget(meta: meta, child: text);
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (i) {
          final item = data[i];
          final value = (item['report_count'] as num).toDouble();
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: value,
                color: colorList[i % colorList.length],
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue > 0 ? maxValue / 5 : 1, // Avoid division by zero
        ),
      ),
    );
  }
}

/// A widget that builds the "Waste Statistics" bar chart.
class _WasteStatisticsChart extends StatefulWidget {
  const _WasteStatisticsChart();

  @override
  State<_WasteStatisticsChart> createState() => _WasteStatisticsChartState();
}

class _WasteStatisticsChartState extends State<_WasteStatisticsChart> {
  final _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _chartDataFuture;

  // A vibrant color palette for the chart bars.
  final List<Color> colorList = [
    const Color(0xFFE67E22),
    const Color(0xFF2980B9),
    const Color(0xFF27AE60),
    const Color(0xFF8E44AD),
    const Color(0xFFC0392B),
    const Color(0xFF16A085),
  ];

  @override
  void initState() {
    super.initState();
    _chartDataFuture = _supabaseService.getReportCountsByCategory();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _chartDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No category data available.'));
        }

        final data = snapshot.data!;
        return _buildChart(data);
      },
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> data) {
    final maxValue = data.fold<double>(0, (max, item) {
      final value = (item['report_count'] as num).toDouble();
      return value > max ? value : max;
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.1, // Add 10% padding to the top
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final category = data[groupIndex]['category'] as String;
              return BarTooltipItem(
                '$category\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: rod.toY.round().toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: const FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide bottom titles for a cleaner look
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (i) {
          final item = data[i];
          final value = (item['report_count'] as num).toDouble();
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: value,
                color: colorList[i % colorList.length],
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxValue > 0 ? maxValue / 5 : 1),
      ),
    );
  }
}

/// A helper widget for the summary cards at the top of the dashboard.
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: Colors.white.withAlpha(204)),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.white.withAlpha(230)),
          ),
        ],
      ),
    );
  }
}