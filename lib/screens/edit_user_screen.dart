import 'package:flutter/material.dart';
import 'package:wastewatch_admin/services/supabase_service.dart';

class EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  late final TextEditingController _fullNameController;
  late String _currentRole;
  bool _isLoading = false;

  // Available roles for the dropdown
  final List<String> _roles = ['user', 'collector'];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user['full_name'] ?? '');
    _currentRole = widget.user['role'] ?? 'user';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final theme = Theme.of(context);

    try {
      await _supabaseService.updateUser(
        userId: widget.user['id'],
        fullName: _fullNameController.text.trim(),
        role: _currentRole,
      );

      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('User updated successfully!'), backgroundColor: Colors.green));
      navigator.pop(true); // Pop with a 'true' result to indicate success
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error updating user: $e'), backgroundColor: theme.colorScheme.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _currentRole,
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
              items: _roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _currentRole = value);
                }
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: _isLoading ? null : _updateUser,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}