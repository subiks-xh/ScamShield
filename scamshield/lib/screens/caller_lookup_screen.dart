import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class CallerLookupScreen extends StatefulWidget {
  const CallerLookupScreen({super.key});

  @override
  State<CallerLookupScreen> createState() => _CallerLookupScreenState();
}

class _CallerLookupScreenState extends State<CallerLookupScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reportController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  Map<String, dynamic>? _searchResult;
  bool _isSearching = false;
  String _message = '';

  Future<void> _searchNumber() async {
    final number = _searchController.text.trim();
    if (number.isEmpty) return;

    setState(() {
      _isSearching = true;
      _message = '';
    });

    try {
      final result = await ApiService.checkNumber(number);
      setState(() {
        _searchResult = result;
      });
    } catch (e) {
      setState(() => _message = 'Error searching number: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _reportNumber() async {
    final number = _reportController.text.trim();
    if (number.isEmpty) return;

    try {
      final result = await ApiService.reportNumber(number, notes: _notesController.text.trim());
      setState(() {
        _message = '✅ Number reported successfully. Total reports: ${result["total_reports"]}';
        _reportController.clear();
        _notesController.clear();
      });
    } catch (e) {
      setState(() => _message = 'Error reporting number: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caller Intelligence Network'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Search Community Database', style: AppTypography.heading2(context)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.search, color: AppColors.antiqueGold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSearching ? null : _searchNumber,
                  child: _isSearching ? const CircularProgressIndicator() : const Text('Search'),
                ),
              ],
            ),
            
            if (_searchResult != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _searchResult!['found'] == true ? AppColors.deepCrimson.withOpacity(0.2) : AppColors.navyLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _searchResult!['found'] == true ? AppColors.crimsonLight : AppColors.antiqueGold.withOpacity(0.3)
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _searchResult!['found'] == true 
                          ? '⚠️ Scam Number Detected' 
                          : '✅ No reports found for this number',
                      style: AppTypography.heading2(context, color: _searchResult!['found'] == true ? AppColors.crimsonLight : Colors.greenAccent),
                    ),
                    if (_searchResult!['found'] == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Reported ${_searchResult!['report_count']} times by the community.',
                        style: AppTypography.body(context),
                      ),
                    ]
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 48),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 24),
            
            Text('Report a Scam Number', style: AppTypography.heading2(context)),
            const SizedBox(height: 16),
            TextField(
              controller: _reportController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Scammer Phone Number',
                prefixIcon: Icon(Icons.phone_disabled, color: AppColors.deepCrimson),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes / Context (Optional)',
                prefixIcon: Icon(Icons.note, color: AppColors.antiqueGold),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _reportNumber,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepCrimson),
              child: const Text('Report to Community Database'),
            ),
            
            if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  _message,
                  style: AppTypography.body(context, color: _message.contains('Error') ? AppColors.crimsonLight : Colors.greenAccent),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
