import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wastewatch_admin/services/supabase_service.dart';
import 'package:wastewatch_admin/screens/edit_user_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // We will fetch a list of maps, which is what Supabase returns from a table query.
  late Future<List<Map<String, dynamic>>> _usersFuture;
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;
  bool _isSearching = false; // New state for toggling search bar
  final _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _usersFuture = _supabaseService.fetchUsers(searchQuery: _searchQuery);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchQuery != _searchController.text) {
      _refreshUsers(newSearchQuery: _searchController.text);
    }
  }

  void _refreshUsers({String? newSearchQuery}) {
    // If a new search query is provided, update _searchQuery.
    // Otherwise, use the existing _searchQuery.
    // If _isSearching is false, clear the search query.
    _searchQuery = _isSearching ? (newSearchQuery ?? _searchQuery) : null;

    setState(() {
      _usersFuture = _supabaseService.fetchUsers(searchQuery: _searchQuery);
    });
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    // Guard against async gaps by checking if the widget is mounted before navigating.
    if (!mounted) return;

    // Navigate to the edit screen and wait for a result.
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditUserScreen(user: user),
      ),
    );

    // If the edit screen returns 'true', it means the user was updated,
    // so we should refresh the list.
    // After an async gap, we should use the State's `mounted` property before calling `setState`.
    if (result == true && mounted) _refreshUsers();
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final didRequestDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the user: ${user['email']}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (didRequestDelete == true && mounted) {
      // Capture the ScaffoldMessenger before the async gap.
      final theme = Theme.of(context);
      final userEmail = user['email'] ?? 'with unknown email';
      try {
        await _supabaseService.deleteUser(user['id']);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User $userEmail deleted successfully.'), backgroundColor: Colors.green),
        );
        _refreshUsers(); // Refresh with current search query after successful deletion (guarded by mounted)
      } on AuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: ${e.message}'), backgroundColor: theme.colorScheme.error),
        );
      }  catch (e) {
        if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('An unexpected error occurred: $e'), backgroundColor: theme.colorScheme.error));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? SafeArea(
                child: SizedBox(
                  height: kToolbarHeight - 16, // Adjust height to fit comfortably in AppBar
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Search users by name or email...',
                    leading: const Icon(Icons.search),
                    trailing: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            // _onSearchChanged listener will handle the refresh
                          },
                        ),
                    ],
                    onChanged: (value) {
                      // The _onSearchChanged listener already handles this,
                      // but onChanged can be used for immediate UI updates if needed.
                    },
                    // The elevation and padding can be customized for the SearchBar
                    elevation: WidgetStateProperty.all(0),
                    backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16.0)),
                  ),
                ),
              )
            : const Text('Manage Users'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear(); // Clear search when closing
                  _refreshUsers(); // Refresh to show all users
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUsers,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshUsers(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _usersFuture,
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
                    ElevatedButton(onPressed: _refreshUsers, child: const Text('Retry')),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No users found.'));
            }

            final users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Text(user['full_name'] ?? user['email'] ?? 'No Email'),
                  subtitle: Text('Role: ${user['role']} - Joined: ${DateFormat.yMMMd().format(DateTime.parse(user['created_at']))}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        _deleteUser(user);
                      } else if (value == 'edit') {
                        _editUser(user);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit User'),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                          title: Text('Delete User', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
