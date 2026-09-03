import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';

import '../theme/app_theme.dart';
import '../widgets/shield_emblem.dart';
import '../widgets/amplitude_bars.dart';
import '../services/api_service.dart';
import '../models/analysis_result.dart';
import '../main.dart' show currentResult, prefs;

enum RecordState { idle, recording, analyzing, error }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  RecordState _state = RecordState.idle;
  String _errorMessage = '';
  double _amplitude = 0;
  int _recordingSeconds = 0;
  Timer? _timer;
  Timer? _amplitudeTimer;
  String? _recordingPath;
  final TextEditingController _callerController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  bool _showAdvanced = false;
  Map<String, dynamic>? _numberCheckResult;
  String? _detectedIncomingCall;
  String _audioQualityMessage = '';

  static const _platform = MethodChannel('com.example.scamshield/call_screening');

  bool get simpleMode => prefs.getBool('simpleMode') ?? false;

  // Weekly summary from history
  (int total, int highRisk) get weeklySummary {
    final box = Hive.box<AnalysisResult>('history');
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final thisWeek = box.values.where((r) => r.createdAt.isAfter(weekAgo)).toList();
    return (thisWeek.length, thisWeek.where((r) => r.verdict == 'high_risk').length);
  }

  @override
  void initState() {
    super.initState();
    _platform.setMethodCallHandler((call) async {
      if (call.method == "onIncomingCall") {
        final phoneNumber = call.arguments as String?;
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          setState(() {
            _detectedIncomingCall = phoneNumber;
            _callerController.text = phoneNumber;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    _callerController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _checkNumber(String number) async {
    try {
      final result = await ApiService.checkNumber(number);
      if (mounted) setState(() => _numberCheckResult = result);
    } catch (_) {
      // silent
    }
  }

  Future<void> _startRecording() async {
    setState(() {
      _errorMessage = '';
      _state = RecordState.idle;
    });

    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      setState(() {
        _errorMessage = 'Microphone permission denied. Please allow access in Settings.';
        _state = RecordState.error;
      });
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ), 
      path: path
    );
    _recordingPath = path;

    setState(() {
      _state = RecordState.recording;
      _recordingSeconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordingSeconds++);
    });

    // Amplitude polling
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      final amp = await _recorder.getAmplitude();
      if (mounted) {
        final normalised = ((amp.current + 60) / 60).clamp(0.0, 1.0);
        setState(() {
          _amplitude = normalised;
          if (normalised < 0.05) {
            _audioQualityMessage = "The recording is too quiet to analyze reliably";
          } else if (normalised > 0.8) {
            _audioQualityMessage = "There is too much background noise";
          } else {
            _audioQualityMessage = "Audio quality is good";
          }
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    setState(() {
      _amplitude = 0;
      _audioQualityMessage = '';
    });
    await _recorder.stop();
    if (_recordingPath != null) {
      await _submitAudio(File(_recordingPath!), isDemo: false);
    }
  }

  Future<void> _submitAudio(File audioFile, {required bool isDemo}) async {
    setState(() => _state = RecordState.analyzing);

    try {
      final result = await ApiService.analyzeAudio(
        audioFile: audioFile,
        callerNumber: _callerController.text.trim().isEmpty ? null : _callerController.text.trim(),
        contactName: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
        isDemo: isDemo,
      );

      // Save to history
      final box = Hive.box<AnalysisResult>('history');
      await box.add(result);

      // Set as current
      currentResult = result;

      if (mounted) context.push('/results');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _state = RecordState.error;
        });
      }
    }
  }

  Future<void> _useDemo() async {
    // Create tiny placeholder file
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/demo.webm')..writeAsBytesSync([]);
    await _submitAudio(file, isDemo: true);
  }

  @override
  Widget build(BuildContext context) {
    final summary = weeklySummary;
    final isRecording = _state == RecordState.recording;
    final isAnalyzing = _state == RecordState.analyzing;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
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
                child: Row(
                  children: [
                    ShieldEmblem(size: 52, variant: ShieldVariant.home),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ScamShield', style: AppTypography.heading1(context)),
                        Text(
                          'AI scam call detector',
                          style: AppTypography.label(context, color: AppColors.antiqueGold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Weekly summary
              if (summary.$1 > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.navyLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.antiqueGold.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Text('📊', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This Week',
                            style: AppTypography.label(context, color: AppColors.antiqueGold),
                          ),
                          Text(
                            '${summary.$1} calls analyzed${summary.$2 > 0 ? " · ${summary.$2} high-risk 🚨" : ""}',
                            style: AppTypography.body(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Incoming call alert
              if (_detectedIncomingCall != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.royalNavy.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.antiqueGold),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Incoming Call Detected',
                        style: AppTypography.heading2(context, color: AppColors.antiqueGold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _detectedIncomingCall!,
                        style: AppTypography.heading1(context, color: AppColors.ivory),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ScamShield can detect when a call arrives using Android’s call-screening system. Android does not give third-party apps direct access to cellular call audio. To analyze sound, tap Record and place the phone near the conversation or use speaker mode, where legally permitted.',
                        style: AppTypography.label(context, color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Caller number input
              if (!simpleMode) ...[
                TextField(
                  controller: _callerController,
                  keyboardType: TextInputType.phone,
                  style: AppTypography.body(context, color: AppColors.ivory),
                  decoration: const InputDecoration(
                    labelText: 'Caller number (optional)',
                    prefixText: '📞 ',
                  ),
                  onChanged: (v) {
                    if (v.length >= 7) _checkNumber(v);
                  },
                ),
                if (_numberCheckResult != null && _numberCheckResult!['found'] == true) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.deepCrimson.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.deepCrimson.withOpacity(0.4)),
                    ),
                    child: Text(
                      '⚠️ Reported by ${_numberCheckResult!['report_count']} users as scam',
                      style: AppTypography.body(context, color: AppColors.crimsonLight),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],

              // Main recording area
              Center(
                child: SizedBox(
                  width: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background shield
                      Opacity(
                        opacity: 0.12,
                        child: ShieldEmblem(size: 180, variant: ShieldVariant.home, animate: false),
                      ),

                      Column(
                        children: [
                          const SizedBox(height: 30),
                          // Mic button
                          GestureDetector(
                            onTap: isAnalyzing
                                ? null
                                : isRecording
                                    ? _stopRecording
                                    : _startRecording,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: simpleMode ? 110 : 88,
                              height: simpleMode ? 110 : 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: isRecording
                                      ? [AppColors.deepCrimson, AppColors.crimsonLight]
                                      : [AppColors.antiqueGold, AppColors.goldLight],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isRecording ? AppColors.deepCrimson : AppColors.antiqueGold)
                                        .withOpacity(0.4),
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  isRecording ? '⏹' : isAnalyzing ? '⏳' : '🎙️',
                                  style: TextStyle(fontSize: simpleMode ? 38 : 32),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Status
                          if (isRecording)
                            Column(
                              children: [
                                Text(
                                  '● Recording ${_recordingSeconds}s',
                                  style: AppTypography.body(context, color: AppColors.crimsonLight),
                                ),
                                if (_audioQualityMessage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      _audioQualityMessage,
                                      style: AppTypography.label(
                                        context, 
                                        color: _audioQualityMessage.contains('good') ? Colors.greenAccent : Colors.orangeAccent
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          else if (isAnalyzing)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.antiqueGold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('Analyzing…', style: AppTypography.body(context, color: AppColors.antiqueGold)),
                              ],
                            )
                          else
                            Text(
                              simpleMode
                                  ? 'Tap the button and start talking'
                                  : 'Tap to record a call snippet',
                              style: AppTypography.body(context, color: AppColors.textMuted),
                              textAlign: TextAlign.center,
                            ),

                          const SizedBox(height: 20),

                          // Amplitude bars
                          if (isRecording || isAnalyzing)
                            AmplitudeBars(
                              isRecording: isRecording,
                              amplitude: _amplitude,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Error state
              if (_state == RecordState.error) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.deepCrimson.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.deepCrimson.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Text(_errorMessage, style: AppTypography.body(context, color: AppColors.crimsonLight)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => setState(() => _state = RecordState.idle),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 16),

              // Demo button
              OutlinedButton(
                onPressed: (isAnalyzing || isRecording) ? null : _useDemo,
                child: const Text('🎭 Use Sample Scam Call Instead'),
              ),
              if (!simpleMode) ...[
                const SizedBox(height: 6),
                Text(
                  'Guaranteed demo — works without mic or network',
                  style: AppTypography.label(context),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
