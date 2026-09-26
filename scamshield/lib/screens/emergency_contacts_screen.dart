import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final List<Map<String, String>> _contacts = [
    {'name': 'Police (Emergency)', 'phone': '911'},
    {'name': 'National Fraud Hotline', 'phone': '1-877-382-4357'},
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  void _addContact() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    
    if (name.isNotEmpty && phone.isNotEmpty) {
      setState(() {
        _contacts.add({'name': name, 'phone': phone});
        _nameController.clear();
        _phoneController.clear();
      });
    }
  }

  Future<void> _callNumber(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency & SOS'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quick SOS Trigger', style: AppTypography.heading2(context)),
            const SizedBox(height: 8),
            Text('Instantly alert your family if you feel trapped in a scam call.', style: AppTypography.label(context, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () async {
                  final success = await ApiService.triggerSOS();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? '🚨 SOS Alert Triggered! Guardian notified.' : 'Failed to trigger SOS.')),
                    );
                  }
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.deepCrimson, AppColors.crimsonLight],
                    ),
                    boxShadow: [
                      BoxShadow(color: AppColors.deepCrimson.withOpacity(0.5), blurRadius: 30),
                    ],
                  ),
                  child: const Center(
                    child: Text('SOS', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 24),
            
            Text('Emergency Contacts', style: AppTypography.heading2(context)),
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView.builder(
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  final contact = _contacts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      title: Text(contact['name']!, style: AppTypography.body(context)),
                      subtitle: Text(contact['phone']!, style: AppTypography.label(context, color: AppColors.textMuted)),
                      trailing: IconButton(
                        icon: const Icon(Icons.call, color: Colors.greenAccent),
                        onPressed: () => _callNumber(contact['phone']!),
                      ),
                      tileColor: AppColors.navyLight,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            Text('Add Family Contact', style: AppTypography.heading2(context)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone', isDense: true),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.antiqueGold, size: 36),
                  onPressed: _addContact,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
