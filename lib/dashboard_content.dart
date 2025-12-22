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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // A simple way to trigger a refresh is to navigate to the same index.
              // This can be enhanced with a more direct refresh mechanism if needed.
              onNavigate(currentIndex);
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  child: const _TopCollectorsList(),
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
        ],),
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

/// A utility class to provide consistent colors and icons for report statuses.
class StatusUtils {
  static Color getStatusColor(String status) {
    return switch (status) {
      'pending' => Colors.orange,
      'in-progress' => Colors.blue,
      'resolved' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.grey,
    };
  }

  static IconData getStatusIcon(String status) {
    return switch (status) {
      'pending' => Icons.hourglass_top_rounded,
      'in-progress' => Icons.construction_rounded,
      'resolved' => Icons.check_circle_outline_rounded,
      'rejected' => Icons.cancel_outlined,
      _ => Icons.help_outline,
    };
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
            final date = DateFormat.yMMMd().format(DateTime.parse(report['created_at']));

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: StatusUtils.getStatusColor(status).withAlpha(50),
                child: Icon(StatusUtils.getStatusIcon(status), color: StatusUtils.getStatusColor(status)),
              ),
              title: Text(reporterName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Status: $status - $date'),
            );
          },
        );
      },);
  }
}

/// A widget to display a list of the top-performing collectors.
class _TopCollectorsList extends StatefulWidget {
  const _TopCollectorsList();

  @override
  State<_TopCollectorsList> createState() => _TopCollectorsListState();
}

class _TopCollectorsListState extends State<_TopCollectorsList> {
  final _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _collectorsFuture;

  @override
  void initState() {
    super.initState();
    _collectorsFuture = _supabaseService.getTopCollectors(limit: 5);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _collectorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No collector data available.'));
        }

        final collectors = snapshot.data!;
        return ListView.separated(
          itemCount: collectors.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final collector = collectors[index];
            final name = collector['full_name'] ?? 'Unknown Collector';
            final resolvedCount = collector['resolved_reports_count']?.toString() ?? '0';

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: DashboardContent._primaryAccent.withAlpha(50),
                child: Text(
                  (index + 1).toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: DashboardContent._primaryAccent),
                ),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Text('$resolvedCount Resolved', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            );
          },
        );
      },
    );
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
          subtitle: Text('Pending for ${DateTime.now().difference(DateTime.parse(data['created_at'])).inDays} days'),
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
  // Initialize the future directly. This prevents it from being called on every rebuild.
  Future<Map<String, dynamic>>? _statsFuture;

  @override
  void initState() {
    super.initState();
    // Assign the future in initState.
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
          // On error or no data, show placeholders with error indication if desired.
          return _buildSummaryCards(isLoading: true); // Or show an error message
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
    final inProgressReports = stats?['in_progress_reports']?.toString() ?? '...';

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
        Expanded(
          child: _SummaryCard(
            title: 'In-Progress Reports',
            value: isLoading ? '...' : inProgressReports,
            icon: Icons.construction,
            color: DashboardContent._cardColor2,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _SummaryCard(
            title: 'Pending Reports',
            value: isLoading ? '...' : pendingReports, // This will show '...' if stats is null
            icon: Icons.warning,
            color: DashboardContent._cardColor3,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _SummaryCard(
            title: 'Resolved Reports',
            value: isLoading ? '...' : resolvedReports, // This will show '...' if stats is null
            icon: Icons.check_circle_outline,
            color: DashboardContent._cardColor4,
          ),
        ),
      ],
    );
  }
}

/// A widget that builds the "Reports by Location" bar chart.
class _ReportsByLocationChart extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ReportsByLocationChartState();
}

class _ReportsByLocationChartState extends State<_ReportsByLocationChart> {
  int touchedIndex = -1;
  final _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _chartDataFuture;

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
        // Sort data from highest to lowest report count
        data.sort((a, b) => ((b['report_count'] ?? b['count'] ?? 0) as num).compareTo((a['report_count'] ?? a['count'] ?? 0) as num));
        return _buildChart(data);
      },
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> data) {
    final maxValue = data.fold<double>(0, (max, item) {
      final value = ((item['report_count'] ?? item['count'] ?? 0) as num).toDouble();
      return value > max ? value : max;
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.1, // Add 10% padding to the top
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final location = data[groupIndex]['location'] as String? ?? 'Unknown';
              return BarTooltipItem(
                '$location\n',
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
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide labels to keep it clean
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
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue > 0 ? (maxValue / 4).ceilToDouble() : 1,
        ),
      ),
    );
  }
}

/// A small widget to act as a legend item for charts.
class _Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;

  const _Indicator({required this.color, required this.text, this.isSquare = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: <Widget>[
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
              color: color,
              borderRadius: isSquare ? BorderRadius.circular(4) : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(text)
        ],
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

  // A specific color palette for the 5 waste categories for consistency.
  final Map<String, Color> _categoryColors = {
    'plastic': const Color(0xFF3498DB), // Blue
    'glass': const Color(0xFF1ABC9C),   // Turquoise
    'metal': const Color(0xFF95A5A6),   // Grey
    'paper': const Color(0xFFF1C40F),   // Yellow
    'residual': const Color(0xFFE74C3C),  // Red
  };

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

        // Filter the data to only include the 5 specified waste categories.
        final allowedCategories = _categoryColors.keys.toList();
        final filteredData = snapshot.data!
            .where((item) => allowedCategories.contains(item['waste_category']))
            .toList();

        return _buildChart(filteredData);
      },
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> data) {
    // Sort data to match the order of colors for consistency
    data.sort((a, b) => (_categoryColors.keys.toList().indexOf(a['waste_category']))
        .compareTo(_categoryColors.keys.toList().indexOf(b['waste_category'])));

    return Row(
      children: <Widget>[
        Expanded(
          child: PieChart(
            PieChartData(
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: List.generate(data.length, (i) {
                final item = data[i];
                final value = ((item['report_count'] ?? item['count'] ?? 0) as num).toDouble();
                final category = item['waste_category'] as String;

                return PieChartSectionData(
                  color: _categoryColors[category],
                  value: value,
                  title: '${value.toInt()}',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 28),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _categoryColors.entries.map((entry) {
            return _Indicator(
              color: entry.value,
              text: '${entry.key[0].toUpperCase()}${entry.key.substring(1)}', // Capitalize
              isSquare: true,
            );
          }).toList(),
        ),
      ],
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