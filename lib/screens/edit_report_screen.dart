import 'package:flutter/material.dart';
import 'package:wastewatch_admin/services/supabase_service.dart';

class EditReportScreen extends StatefulWidget {
  final Map<String, dynamic> report;

  const EditReportScreen({super.key, required this.report});

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  late final TextEditingController _wasteCategoryController;
  late final TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _wasteCategoryController = TextEditingController(text: widget.report['wasteCategory'] ?? '');
    _descriptionController = TextEditingController(text: widget.report['description'] ?? '');
  }

  @override
  void dispose() {
    _wasteCategoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final theme = Theme.of(context);

    try {
      await _supabaseService.updateReport(
        reportId: widget.report['id'].toString(),
        wasteCategory: _wasteCategoryController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Report updated successfully!'), backgroundColor: Colors.green));
      navigator.pop(true); // Pop with 'true' to indicate success
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error updating report: $e'), backgroundColor: theme.colorScheme.error),
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
        title: const Text('Edit Report'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _wasteCategoryController,
              decoration: const InputDecoration(labelText: 'Waste Category', border: OutlineInputBorder()),
              validator: (value) => (value == null || value.isEmpty) ? 'Please enter a category' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 4,
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
                onPressed: _isLoading ? null : _updateReport,
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