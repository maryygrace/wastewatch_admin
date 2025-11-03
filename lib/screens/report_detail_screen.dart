import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wastewatch_admin/services/supabase_service.dart';

class ReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late String _currentStatus;
  bool _isUpdating = false;
  Future<String?>? _validImageUrlFuture;
  late Map<String, dynamic> _currentReport;
  late Future<List<Map<String, dynamic>>> _collectorsFuture;
  final _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.report['status'];
    _currentReport = Map<String, dynamic>.from(widget.report);

    _collectorsFuture = _supabaseService.fetchCollectors();

    if (widget.report['imageUrl'] != null) {
      _validImageUrlFuture = _supabaseService.createSignedImageUrl(widget.report['imageUrl']);
    }
  }

  Future<void> _updateReportStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await _supabaseService.updateReportStatus(
        reportId: _currentReport['id'].toString(),
        newStatus: newStatus,
      );

      if (!mounted) return;

      setState(() {
        _currentStatus = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report status updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _assignToCollector(String collectorId) async {
    setState(() {
      _isUpdating = true;
    });

    if (!mounted) return;

    try {
      if (collectorId == 'none') {
        await _supabaseService.unassignReport(
          reportId: _currentReport['id'].toString(),
        );
      } else {
        await _supabaseService.assignReportToCollector(
          reportId: _currentReport['id'].toString(),
          collectorId: collectorId,
        );
      }

      if (!mounted) return;

      setState(() {
        _currentStatus = 'in-progress'; // Automatically update status
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Report assigned successfully!'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error assigning report: $e'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteReport() async {
    final didRequestDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this report? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (didRequestDelete == true && mounted) {
      try {
        await _supabaseService.deleteReport(_currentReport['id'].toString());
        if (!mounted) return; // Check mounted after async operation
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report deleted successfully.'), backgroundColor: Colors.green));
        Navigator.of(context).pop(true); // Pop with true to signal a refresh on the previous screen
      } catch (e) {
        if (!mounted) return; // Check mounted after async operation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting report: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final report = _currentReport;
    // The 'users' object is passed along with the report data.
    final reporter = report['reporter'];
    final reporterName = reporter?['full_name'] ?? reporter?['email'] ?? 'Unknown User';

    return PopScope(
      // canPop should be false because we are handling the pop manually.
      canPop: false,
      // onPopInvokedWithResult is called when a pop is attempted.
      onPopInvokedWithResult: (didPop, result) {
        final hasChanged = _currentStatus != widget.report['status'] || _currentReport != widget.report;
        // If didPop is false, it means a pop was attempted but blocked by canPop. We then handle it manually.
        if (!didPop) Navigator.of(context).pop(hasChanged);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Report Details'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteReport();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error), title: Text('Delete Report', style: TextStyle(color: Theme.of(context).colorScheme.error))),
                ),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildDetailCard('Report ID', report['id'].toString()),
            _buildDetailCard('Reporter', reporterName),
            _buildDetailCard('Status', _currentStatus, isStatus: true),
            _buildDetailCard('Waste Category', report['wasteCategory']),
            _buildDetailCard('Description', report['description'] ?? 'No description provided.'),
            _buildDetailCard('Location Address', report['location'] ?? 'Not specified'),
            _buildDetailCard('Coordinates', 'Lat: ${report['latitude']}, Lng: ${report['longitude']}'),
            _buildDetailCard('Created At', DateFormat.yMMMd().add_jm().format(DateTime.parse(report['createdAt']))),
            if (report['imageUrl'] != null)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Image', style: textTheme.titleMedium),
                      const SizedBox(height: 12),
                      FutureBuilder<String?>(
                        future: _validImageUrlFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                            return Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                  const SizedBox(height: 8),
                                  const Text('Could not load image.'),
                                  if (snapshot.hasError)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                                    ),
                                ],
                              ),
                            );
                          }
                          final validUrl = snapshot.data!;
                          // Constrain the image height to prevent it from being too large.
                          return ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 300, // You can adjust this value as needed
                            ),
                            child: Image.network(validUrl, fit: BoxFit.contain, loadingBuilder: (context, child, progress) {
                              return progress == null ? child : const Center(child: CircularProgressIndicator());
                            }),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text('Assign to Collector', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _collectorsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No collectors available to assign.');
                }
                final collectors = snapshot.data!;
                final items = collectors.map((collector) {
                  return DropdownMenuItem<String>(
                    value: collector['uid'], // Use the correct 'uid' (UUID) column
                    child: Text(collector['full_name'] ?? collector['email']),
                  );
                }).toList();

                // Add a "None" option to the beginning of the list
                items.insert(0, const DropdownMenuItem<String>(
                  value: 'none',
                  child: Text('None', style: TextStyle(fontStyle: FontStyle.italic)),
                ));

                return DropdownButtonFormField<String>(
                  initialValue: report['collector_id'] ?? 'none',
                  hint: const Text('Select a collector...'),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: items,
                  onChanged: _isUpdating || _currentStatus == 'resolved' ? null : (collectorId) {
                    if (collectorId != null && collectorId != report['collector_id']) {
                      // Handle both assigning and un-assigning
                      _assignToCollector(collectorId);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Update Status', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            _isUpdating
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    initialValue: _currentStatus,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: ['pending', 'in-progress', 'resolved', 'rejected']
                        .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                        .toList(),
                    onChanged: _currentStatus == 'resolved' ? null : (value) {
                      if (value != null && value != _currentStatus) {
                        _updateReportStatus(value);
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value, {bool isStatus = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: isStatus ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }
}