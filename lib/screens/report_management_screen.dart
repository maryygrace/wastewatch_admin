import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wastewatch_admin/screens/report_detail_screen.dart';
import 'package:wastewatch_admin/services/supabase_service.dart';

class ReportManagementScreen extends StatefulWidget {
  const ReportManagementScreen({super.key});

  @override
  State<ReportManagementScreen> createState() => _ReportManagementScreenState();
}

class _ReportManagementScreenState extends State<ReportManagementScreen> {
  late Future<List<Map<String, dynamic>>> _reportsFuture;
  String _currentStatusFilter = 'all'; // Default to show all reports
  final _supabaseService = SupabaseService();
  final List<String> _statusOptions = ['all', 'pending', 'in-progress', 'resolved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _reportsFuture = _supabaseService.fetchReports(status: _currentStatusFilter);
  }

  void _refreshReports({String? newStatus}) {
    setState(() {
      _currentStatusFilter = newStatus ?? _currentStatusFilter;
      _reportsFuture = _supabaseService.fetchReports(status: _currentStatusFilter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final String displayStatus = _currentStatusFilter.capitalize();
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports ($displayStatus)'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String status) => _refreshReports(newStatus: status),
            icon: const Icon(Icons.filter_list),
            itemBuilder: (BuildContext context) {
              return _statusOptions.map((String status) {
                return PopupMenuItem<String>(
                  value: status,
                  child: Text(status.capitalize()),
                );
              }).toList();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshReports,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportsFuture, // This future is now updated by _refreshReports
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _refreshReports, child: const Text('Retry')),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Use a RefreshIndicator here as well so users can pull to refresh an empty list
            return RefreshIndicator(
              onRefresh: () async => _refreshReports(),
              child: Center(child: Text('No reports found with status: "$_currentStatusFilter".')),
            );
          }

          final reports = snapshot.data!;
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              // The 'users' object is now available thanks to the join query.
              final reporter = report['reporter'];
              final reporterName = reporter?['full_name'] ?? reporter?['email'] ?? 'Unknown User';
              return ListTile(
                title: Text('Report by: $reporterName'),
                subtitle: Text('Status: ${report['status']} - Created: ${DateFormat.yMMMd().format(DateTime.parse(report['createdAt']))}'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  // Await navigation and refresh if the detail screen indicates a change.
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportDetailScreen(report: report),
                    ),
                  );

                  // If the detail screen pops with 'true', it means an update happened.
                  if (result == true && mounted) { // This was already correct
                    _refreshReports();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

// A simple extension to capitalize the first letter of a string.
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}