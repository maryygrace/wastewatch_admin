import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A service class to interact with Supabase.
/// This helps in organizing data-fetching logic in one place.
class SupabaseService {
  // Create a logger for this service
  final _log = Logger('SupabaseService');

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches users from the 'users' table, but only those with the role
  /// 'user' or 'collector'. This excludes admins from the list.
  Future<List<Map<String, dynamic>>> fetchUsers({String? searchQuery}) async {
    try {
      var query = _supabase
          .from('users')
          .select()
          .inFilter('role', ['user', 'collector']);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Filter by full_name or email using case-insensitive LIKE
        // The pattern '$searchQuery%' matches text that STARTS WITH the query.
        // Using '.%searchQuery%' would match text that CONTAINS the query.
        query = query.or(
          'full_name.ilike.$searchQuery%,email.ilike.$searchQuery%',
        );
      }
      final response = await query.order('created_at', ascending: false);
      return response;
    } catch (e) {
      _log.severe('Error fetching users', e);
      rethrow;
    }
  }

  /// Deletes a user from Supabase Auth.
  /// This requires admin privileges for the Supabase client.
  Future<void> deleteUser(String userId) async {
    try {
      await _supabase.auth.admin.deleteUser(userId);
    } catch (e) {
      _log.severe('Error deleting user with ID: $userId', e);
      rethrow;
    }
  }

  /// Updates user data in the 'users' table.
  Future<void> updateUser({
    required String userId,
    required String fullName,
    required String role,
  }) async {
    try {
      await _supabase.from('users').update({
        'full_name': fullName,
        'role': role,
      }).eq('id', userId);
    } catch (e) {
      _log.severe('Error updating user with ID: $userId', e);
      rethrow;
    }
  }

  /// Fetches all users with the 'collector' role.
  Future<List<Map<String, dynamic>>> fetchCollectors() async {
    try {
      final response = await _supabase
          .from('users')
          .select('uid, full_name, email') // Select 'uid' which is the UUID, not 'id'
          .eq('role', 'collector')
          .order('full_name', ascending: true);
      return response;
    } catch (e) {
      _log.severe('Error fetching collectors', e);
      rethrow;
    }
  }

  /// Fetches all reports from the 'reports' table.
  Future<List<Map<String, dynamic>>> fetchReports({String? status, int? limit}) async {
    try {
      // The type of the query changes as we add filters and transformers.
      // By using 'dynamic', we allow the variable to hold different builder types.
      dynamic query = _supabase
          .from('reports')
          // Join with the 'users' table to get the reporter's name and email.
          // This explicit syntax tells Supabase which foreign key column on the 'reports' table to use for the join.
          // We join 'users' twice: once for the reporter (via the 'user_id' column) and once for the assignee (via the 'assigned_to' column).
          // The alias (e.g., 'reporter:') is what the joined data will be named in the result.
          .select('*, reporter:users!userId(full_name, email), assignee:users!reports_collector_id_fkey(full_name, email)');
      
      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }

      query = query.order('createdAt', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }
      
      final response = await query;
      return response;
    } catch (e) {
      _log.severe('Error fetching reports', e);
      rethrow;
    }
  }

  /// Fetches the total count of reports.
  Future<int> getReportsCount() async {
    try {
      // Using `count: CountOption.exact` is efficient as it only fetches the count.
      final count = await _supabase.from('reports').count();
      return count;
    } catch (e) {
      _log.severe('Error fetching reports count', e);
      // Return 0 or rethrow, depending on how you want to handle errors.
      return 0;
    }
  }

  /// Updates the status of a specific report.
  Future<void> updateReportStatus({
    required String reportId,
    required String newStatus,
  }) async {
    try {
      await _supabase.from('reports').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reportId);
    } catch (e) {
      _log.severe('Error updating report status for ID: $reportId', e);
      rethrow;
    }
  }

  /// Updates a report's details in the 'reports' table.
  Future<void> updateReport({
    required String reportId,
    required String wasteCategory,
    required String description,
  }) async {
    try {
      await _supabase.from('reports').update({
        'wasteCategory': wasteCategory,
        'description': description,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reportId);
    } catch (e) {
      _log.severe('Error updating report with ID: $reportId', e);
      rethrow;
    }
  }

  /// Deletes a report from the 'reports' table.
  Future<void> deleteReport(String reportId) async {
    try {
      // Note: This performs a soft delete if RLS is configured for it,
      // or a hard delete otherwise. Ensure your table policies are correct.
      await _supabase.from('reports').delete().eq('id', reportId);
    } catch (e) {
      _log.severe('Error deleting report with ID: $reportId', e);
      rethrow;
    }
  }

  /// Assigns a report to a specific collector.
  Future<void> assignReportToCollector({
    required String reportId,
    required String collectorId,
  }) async {
    try {
      await _supabase.from('reports').update({ // Using correct column names from your schema
        'collector_id': collectorId,
        'status': 'in-progress',
        'assigned_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reportId);
    } catch (e) {
      _log.severe('Error assigning report ID: $reportId to collector ID: $collectorId', e);
      rethrow;
    }
  }

  /// Un-assigns a report from a collector and sets its status back to 'pending'.
  Future<void> unassignReport({required String reportId}) async {
    try {
      await _supabase.from('reports').update({
        'collector_id': null,
        'status': 'pending',
        'assigned_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reportId);
    } catch (e) {
      _log.severe('Error un-assigning report ID: $reportId', e);
      rethrow;
    }
  }

  /// Creates a fresh, valid signed URL for a report image.
  /// This handles cases where the stored value is an old, expired signed URL.
  /// This works for both public and private buckets.
  Future<String> createSignedImageUrl(String imageUrl) async {
    try {
      String imagePath;
      const String bucketName = 'report_images';
      final pathIndex = imageUrl.lastIndexOf('$bucketName/');

      if (pathIndex == -1) {
        // If the bucket name isn't in the URL, we have to assume the imageUrl is the path itself.
        // This can be a fallback, but the former is more reliable.
        _log.warning('Could not find bucket marker in URL, assuming imageUrl is the path: $imageUrl');
        imagePath = imageUrl;
      } else {
        // Extract the path from a full URL (e.g., .../report_images/user_id/image.jpg)
        imagePath = imageUrl.substring(pathIndex + bucketName.length + 1);
      }

      // Remove query parameters if they exist (from old signed URLs)
      final queryIndex = imagePath.indexOf('?');
      if (queryIndex != -1) {
        imagePath = imagePath.substring(0, queryIndex);
      }

      // Create a new signed URL with a 1-hour validity.
      return await _supabase.storage.from(bucketName).createSignedUrl(imagePath, 3600);
    } catch (e) {
      _log.severe('Error creating signed image URL from: $imageUrl', e);
      rethrow;
    }
  }

  /// Fetches all cluster predictions from the 'predictions' table.
  Future<List<Map<String, dynamic>>> fetchPredictions() async {
    try {
      // Selects the necessary columns from your predictions table.
      final response = await _supabase
          .from('predictions')
          .select('latitude, longitude, cluster_label');
      return response;
    } catch (e) {
      _log.severe('Error fetching predictions', e);
      rethrow; // Rethrow to be handled by the UI.
    }
  }

  /// Fetches the count of reports grouped by location.
  /// This calls a PostgreSQL function `get_report_counts_by_location` in Supabase.
  Future<List<Map<String, dynamic>>> getReportCountsByLocation() async {
    try {
      // The RPC call to the function we created in the Supabase SQL Editor.
      final response = await _supabase.rpc('get_report_counts_by_location');

      // The response is a List<dynamic>, so we cast it.
      return (response as List).map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      _log.severe('Error fetching report counts by location', e);
      rethrow;
    }
  }

  /// Fetches dashboard summary statistics using a single RPC call.
  /// This calls a simple and secure SQL function `get_dashboard_stats` to ensure stability.
  Future<Map<String, dynamic>> getDashboardSummaryStats() async {
    try {
      // Call the simple and reliable SQL function.
      final response = await _supabase.rpc('get_dashboard_stats');
      
      // RPC functions that return a single row return a List with one element.
      // If the table is empty, the list might be empty, so we handle that case.
      if (response is List && response.isNotEmpty) {
        return response.first as Map<String, dynamic>;
      }
      // If the list is empty, it means all counts are zero.
      return {'total_reports': 0, 'pending_reports': 0, 'resolved_reports': 0, 'in_progress_reports': 0};
    } catch (e) {
      _log.severe('Error fetching dashboard summary stats', e);
      // Return a map with zero values on error to prevent UI from breaking.
      return {'total_reports': 0, 'pending_reports': 0, 'resolved_reports': 0, 'in_progress_reports': 0};
    }
  }

  /// Fetches pending reports that are older than a specified number of days.
  /// These are considered "overdue" system alerts.
  Future<List<Map<String, dynamic>>> fetchOverduePendingReports(int days) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final response = await _supabase
          .from('reports')
          .select('*, reporter:users!userId(full_name, email)') // Join to get reporter info
          .eq('status', 'pending')
          .lt('createdAt', cutoffDate.toIso8601String()) // 'lt' means 'less than' (older than)
          .order('createdAt', ascending: true); // Order by oldest first
      return response;
    } catch (e) {
      _log.severe('Error fetching overdue pending reports', e);
      rethrow;
    }
  }

  /// Fetches the top collectors based on the number of resolved reports.
  /// This calls a PostgreSQL function `get_top_collectors` in Supabase.
  Future<List<Map<String, dynamic>>> getTopCollectors({int limit = 5}) async {
    try {
      final response = await _supabase.rpc('get_top_collectors', params: {'p_limit': limit});
      // The response is a List<dynamic>, so we cast it.
      return (response as List).map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      _log.severe('Error fetching top collectors', e);
      rethrow;
    }
  }

  /// Fetches all system alerts by calling multiple RPC functions.
  Future<List<Map<String, dynamic>>> fetchSystemAlerts() async {
    try {
      // Define thresholds
      const int overdueDays = 3;
      const int collectorThreshold = 10;
      const int locationThreshold = 20;

      // Fetch all alerts in parallel
      final results = await Future.wait<dynamic>([
        fetchOverduePendingReports(overdueDays), // Use the existing Dart method to avoid the SQL type error.
        _supabase.rpc('get_overloaded_collectors', params: {'report_threshold': collectorThreshold}),
        _supabase.rpc('get_high_volume_locations', params: {'report_threshold': locationThreshold}),
      ]);

      final List<Map<String, dynamic>> alerts = [];

      // Process overdue reports
      for (var report in (results[0] as List)) {
        alerts.add({'type': 'overdue_report', 'data': report});
      }
      // Process overloaded collectors
      for (var collector in (results[1] as List)) {
        alerts.add({'type': 'collector_overload', 'data': collector});
      }
      // Process high volume locations
      for (var location in (results[2] as List)) {
        alerts.add({'type': 'high_volume_location', 'data': location});
      }

      return alerts;
    } catch (e) {
      _log.severe('Error fetching system alerts', e);
      rethrow;
    }
  }

  /// Fetches the count of reports grouped by waste category.
  /// This calls a PostgreSQL function `get_report_counts_by_category` in Supabase.
  Future<List<Map<String, dynamic>>> getReportCountsByCategory() async {
    try {
      final response = await _supabase.rpc('get_report_counts_by_category');
      // The response is a List<dynamic>, so we cast it.
      return (response as List).map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      _log.severe('Error fetching report counts by category', e);
      rethrow;
    }
  }
}