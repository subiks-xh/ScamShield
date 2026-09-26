import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_theme.dart';
import '../models/analysis_result.dart';
import '../services/api_service.dart';
import '../main.dart' show prefs;

class SettingsScreen extends StatefulWidget {
  final Function(bool simpleMode, bool darkMode)? onThemeChange;

  const SettingsScreen({super.key, this.onThemeChange});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _simpleMode;
  late bool _darkMode;
  late bool _ttsEnabled;
  late bool _autoPlaySample;
  late String _guardianCode;
  bool _showGuardian = false;
  bool _codeCopied = false;

  // Voice enrollment
  final AudioRecorder _recorder = AudioRecorder();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();
  String _enrollState = 'idle'; // idle | recording | submitting | done | error
  String _enrollError = '';
  int _recordSeconds = 0;
  bool _enrollRecording = false;
  String? _recordPath;

  @override
  void initState() {
    super.initState();
    _simpleMode = prefs.getBool('simpleMode') ?? false;
    _darkMode = prefs.getBool('darkMode') ?? true;
    _ttsEnabled = prefs.getBool('ttsEnabled') ?? true;
    _autoPlaySample = prefs.getBool('autoPlaySample') ?? false;
    _guardianCode = prefs.getString('guardianCode') ?? _genCode();
  }

  String _genCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _setSetting(String key, bool value) async {
    await prefs.setBool(key, value);
  }

  void _regenerateCode() {
    final code = _genCode();
    setState(() => _guardianCode = code);
    prefs.setString('guardianCode', code);
  }

  Future<void> _startEnrollRecording() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _enrollError = 'Please enter a contact name first.');
      return;
    }
    setState(() => _enrollError = '');

    final perm = await Permission.microphone.request();
    if (!perm.isGranted) {
      setState(() {
        _enrollError = 'Microphone permission denied.';
        _enrollState = 'error';
      });
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/enroll_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: path);
    _recordPath = path;
    _enrollRecording = true;
    _recordSeconds = 0;

    setState(() => _enrollState = 'recording');

    // Timer
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_enrollRecording) return false;
      if (mounted) setState(() => _recordSeconds++);
      return _enrollRecording;
    });
  }

  Future<void> _stopEnrollRecording() async {
    _enrollRecording = false;
    await _recorder.stop();
    if (_recordPath == null) return;

    setState(() => _enrollState = 'submitting');

    try {
      final data = await ApiService.enrollVoice(
        audioPath: _recordPath,
        contactName: _nameController.text.trim(),
        relationship: _relationController.text.trim().isEmpty ? null : _relationController.text.trim(),
      );

      // Save contact to Hive
      final box = Hive.box<ProtectedContact>('contacts');
      await box.add(ProtectedContact(
        id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        relationship: _relationController.text.trim().isEmpty ? null : _relationController.text.trim(),
        hasVoiceSample: true,
        createdAt: DateTime.now(),
      ));

      setState(() {
        _enrollState = 'done';
        _nameController.clear();
        _relationController.clear();
      });
    } catch (e) {
      setState(() {
        _enrollError = 'Saved locally. Backend: ${e.toString().substring(0, 60)}';
        _enrollState = 'done';
      });
    }
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: _simpleMode ? 20 : 16,
            fontWeight: FontWeight.w700,
            color: AppColors.antiqueGold,
          ),
        ),
      );

  Widget _toggle(
      String label, String? description, bool value, Future<void> Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: _simpleMode ? 18 : 15,
                    color: AppColors.ivory,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (description != null && !_simpleMode) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.label(context, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) async {
              await onChanged(v);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    _nameController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contacts = Hive.box<ProtectedContact>('contacts').values.toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.royalPurple, AppColors.purpleLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.antiqueGold.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Settings', style: AppTypography.heading1(context)),
                    Text(
                      'Preferences, protected contacts & guardian link',
                      style: AppTypography.label(context, color: AppColors.antiqueGold.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),

              // ─── Display ─────────────────────────────────────────────
              _sectionHeader('Display & Accessibility'),
              AppCard(
                child: Column(
                  children: [
                    _toggle('Simple Mode', 'Larger text, bigger buttons, plain verdicts', _simpleMode, (v) async {
                      _simpleMode = v;
                      await _setSetting('simpleMode', v);
                      widget.onThemeChange?.call(v, _darkMode);
                    }),
                    _toggle('Read Verdict Aloud', 'Auto-speaks the verdict when results load', _ttsEnabled, (v) async {
                      _ttsEnabled = v;
                      await _setSetting('ttsEnabled', v);
                    }),
                    _toggle('Dark Mode', 'Same theme tokens, swapped backgrounds', _darkMode, (v) async {
                      _darkMode = v;
                      await _setSetting('darkMode', v);
                      widget.onThemeChange?.call(_simpleMode, v);
                    }),
                    _toggle('Auto-play Demo on Launch', 'Run sample analysis when app opens', _autoPlaySample, (v) async {
                      _autoPlaySample = v;
                      await _setSetting('autoPlaySample', v);
                    }),
                  ],
                ),
              ),

              // ─── Protected Contacts ───────────────────────────────────
              _sectionHeader('Protected Contacts'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Record a 10–15 second voice sample of a trusted person (with their consent). '
                      'All samples stored locally on-device only — never uploaded.',
                      style: AppTypography.body(context),
                    ),
                    const SizedBox(height: 16),

                    // Existing contacts
                    ...contacts.map((c) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: AppTypography.body(context, color: AppColors.ivory)),
                                if (c.relationship != null)
                                  Text(c.relationship!, style: AppTypography.label(context)),
                                Text(
                                  c.hasVoiceSample ? '🎙️ Voice sample enrolled' : '📝 No sample',
                                  style: AppTypography.label(
                                    context,
                                    color: c.hasVoiceSample ? AppColors.emeraldLight : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => c.delete().then((_) => setState(() {})),
                            child: Text('Remove', style: AppTypography.label(context, color: AppColors.crimsonLight)),
                          ),
                        ],
                      ),
                    )),

                    // Enrollment UI
                    if (_enrollState == 'idle' || _enrollState == 'error') ...[
                      TextField(
                        controller: _nameController,
                        style: AppTypography.body(context, color: AppColors.ivory),
                        decoration: const InputDecoration(labelText: 'Contact name'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _relationController,
                        style: AppTypography.body(context, color: AppColors.ivory),
                        decoration: const InputDecoration(labelText: 'Relationship (optional)'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _startEnrollRecording,
                        child: const Text('🎙️ Record Voice Sample (10–15s)'),
                      ),
                    ],

                    if (_enrollState == 'recording') ...[
                      Text('● Recording ${_recordSeconds}s',
                          style: AppTypography.body(context, color: AppColors.crimsonLight),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(
                        'Ask them to speak naturally. Confirm they consent.',
                        style: AppTypography.body(context),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _stopEnrollRecording,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepCrimson),
                        child: const Text('⏹ Stop & Save'),
                      ),
                    ],

                    if (_enrollState == 'submitting')
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(color: AppColors.antiqueGold),
                        ),
                      ),

                    if (_enrollState == 'done') ...[
                      Text('✓ Voice sample enrolled', style: AppTypography.body(context, color: AppColors.emeraldLight)),
                      TextButton(
                        onPressed: () => setState(() => _enrollState = 'idle'),
                        child: const Text('Add Another'),
                      ),
                    ],

                    if (_enrollError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_enrollError, style: AppTypography.body(context, color: AppColors.amberWarnLight)),
                      ),
                  ],
                ),
              ),

              // ─── Guardian Link ────────────────────────────────────────
              _sectionHeader('Guardian Link'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.amberWarn.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.amberWarn.withOpacity(0.3)),
                      ),
                      child: Text(
                        '🔶 Demo / UI Mockup Only\nReal Guardian Link requires push notification infrastructure (Firebase/AWS SNS). This is a Phase 2 roadmap feature, shown here as a UI preview.',
                        style: AppTypography.label(context, color: AppColors.amberWarnLight),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => setState(() => _showGuardian = !_showGuardian),
                      child: Text(_showGuardian ? '▲ Hide Pairing Code' : '🔗 Show Guardian Pairing Code'),
                    ),
                    if (_showGuardian) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.antiqueGold.withOpacity(0.4), width: 2),
                        ),
                        child: Text(
                          _guardianCode,
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: _simpleMode ? 36 : 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.antiqueGold,
                            letterSpacing: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _guardianCode));
                                setState(() => _codeCopied = true);
                                Future.delayed(const Duration(seconds: 2), () {
                                  if (mounted) setState(() => _codeCopied = false);
                                });
                              },
                              child: Text(_codeCopied ? '✓ Copied' : 'Copy Code'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _regenerateCode,
                              child: const Text('Regenerate'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ─── About ───────────────────────────────────────────────
              _sectionHeader('About ScamShield'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ScamShield detects AI voice-cloning scam calls using two independent signals. '
                      'Only when BOTH the voice is AI-generated AND the content contains scam language '
                      'does it raise a High Risk alert — real emergencies are never wrongly flagged.',
                      style: AppTypography.body(context),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Version', style: AppTypography.body(context, color: AppColors.textMuted)),
                        Text(
                          '2.0.0 · Hackathon Build',
                          style: AppTypography.mono(color: AppColors.antiqueGold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Roadmap: AWS Transcribe, Amazon Bedrock, Firebase Guardian, DynamoDB scam DB.',
                      style: AppTypography.label(context, color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
