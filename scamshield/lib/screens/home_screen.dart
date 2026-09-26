import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  Timer? _wsTimer;
  StreamSubscription? _audioSubscription;
  final List<int> _pcmBuffer = [];
  WebSocketChannel? _wsChannel;
  String _liveTranscript = '';
  double _liveScore = 0.0;
  bool _wsFallback = false;
  String? _coachingAdvice;
  
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
    _wsTimer?.cancel();
    _audioSubscription?.cancel();
    _wsChannel?.sink.close();
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
      _liveTranscript = '';
      _liveScore = 0.0;
      _wsFallback = false;
      _coachingAdvice = null;
    });

    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      setState(() {
        _errorMessage = 'Microphone permission denied. Please allow access in Settings.';
        _state = RecordState.error;
      });
      return;
    }

    _pcmBuffer.clear();
    
    // Connect to WebSocket
    try {
      final wsUrl = ApiService.baseUrl.replaceFirst('http', 'ws') + '/ws/analyze-live';
      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _wsChannel!.stream.listen(
        (message) {
          if (mounted) {
            try {
              final data = jsonDecode(message);
              setState(() {
                _liveTranscript = data['transcript'] ?? '';
                _liveScore = (data['score'] ?? 0).toDouble();
              });
              
              if (_liveTranscript.isNotEmpty) {
                ApiService.getCoachingAdvice(_liveTranscript).then((advice) {
                  if (mounted && advice != null) {
                    setState(() => _coachingAdvice = advice);
                  }
                });
              }
            } catch (_) {}
          }
        },
        onError: (e) {
          if (mounted) setState(() => _wsFallback = true);
        },
        onDone: () {
          if (mounted) setState(() => _wsFallback = true);
        },
      );
    } catch (e) {
      _wsFallback = true;
    }

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      )
    );

    _audioSubscription = stream.listen((data) {
      _pcmBuffer.addAll(data);
    });

    setState(() {
      _state = RecordState.recording;
      _recordingSeconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordingSeconds++);
    });
    
    _wsTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (_wsChannel != null && !_wsFallback && _pcmBuffer.isNotEmpty) {
        _wsChannel!.sink.add(Uint8List.fromList(_pcmBuffer));
      }
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

  Uint8List _createWavBytes(List<int> pcmBytes, int sampleRate, int channels) {
    final byteData = ByteData(44 + pcmBytes.length);
    // "RIFF"
    byteData.setUint8(0, 82); byteData.setUint8(1, 73); byteData.setUint8(2, 70); byteData.setUint8(3, 70);
    byteData.setUint32(4, 36 + pcmBytes.length, Endian.little);
    // "WAVE"
    byteData.setUint8(8, 87); byteData.setUint8(9, 65); byteData.setUint8(10, 86); byteData.setUint8(11, 69);
    // "fmt "
    byteData.setUint8(12, 102); byteData.setUint8(13, 109); byteData.setUint8(14, 116); byteData.setUint8(15, 32);
    byteData.setUint32(16, 16, Endian.little); // chunk size
    byteData.setUint16(20, 1, Endian.little); // format (1 = PCM)
    byteData.setUint16(22, channels, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * channels * 2, Endian.little); // byte rate
    byteData.setUint16(32, channels * 2, Endian.little); // block align
    byteData.setUint16(34, 16, Endian.little); // bits per sample
    // "data"
    byteData.setUint8(36, 100); byteData.setUint8(37, 97); byteData.setUint8(38, 116); byteData.setUint8(39, 97);
    byteData.setUint32(40, pcmBytes.length, Endian.little);
    
    // Write PCM data
    for (int i = 0; i < pcmBytes.length; i++) {
      byteData.setUint8(44 + i, pcmBytes[i]);
    }
    
    return byteData.buffer.asUint8List();
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    _wsTimer?.cancel();
    _audioSubscription?.cancel();
    await _recorder.stop();
    _wsChannel?.sink.close();
    
    setState(() {
      _amplitude = 0;
      _audioQualityMessage = '';
    });
    
    if (_pcmBuffer.isNotEmpty) {
      final wavBytes = kIsWeb ? Uint8List.fromList(_pcmBuffer) : _createWavBytes(_pcmBuffer, 16000, 1);
      await _submitAudio(audioBytes: wavBytes, isDemo: false);
    }
  }

  Future<void> _submitAudio({List<int>? audioBytes, required bool isDemo}) async {
    setState(() => _state = RecordState.analyzing);

    try {
      final result = await ApiService.analyzeAudio(
        audioBytes: audioBytes,
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
    await _submitAudio(audioBytes: [], isDemo: true);
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
                      const Icon(Icons.bar_chart, size: 24, color: Colors.blueAccent),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This Week',
                            style: AppTypography.label(context, color: AppColors.antiqueGold),
                          ),
                          Text(
                            '${summary.$1} calls analyzed${summary.$2 > 0 ? " · ${summary.$2} high-risk" : ""}',
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
                    prefixIcon: const Icon(Icons.phone, size: 20, color: Colors.white54),
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
                      'Reported by ${_numberCheckResult!['report_count']} users as scam',
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
                                child: Icon(
                                  isRecording ? Icons.stop : isAnalyzing ? Icons.hourglass_empty : Icons.mic,
                                  size: simpleMode ? 38 : 32,
                                  color: Colors.white,
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
                                if (_wsFallback)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text('Live analysis paused — full analysis will run when stopped', style: AppTypography.label(context, color: AppColors.amberWarnLight)),
                                  )
                                else if (_liveScore > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text('Live Risk Score: ${_liveScore.toInt()}', style: AppTypography.body(context, color: AppColors.antiqueGold)),
                                  ),
                                if (_liveTranscript.isNotEmpty && !_wsFallback)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text('"${_liveTranscript.length > 50 ? _liveTranscript.substring(_liveTranscript.length - 50) : _liveTranscript}..."', style: AppTypography.label(context, color: AppColors.textMuted), textAlign: TextAlign.center),
                                  ),
                                if (_coachingAdvice != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 12.0),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.deepEmerald.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.deepEmerald.withOpacity(0.4)),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.support_agent, color: AppColors.emeraldLight, size: 16),
                                            const SizedBox(width: 4),
                                            Text('AI Coach Advice', style: AppTypography.label(context, color: AppColors.emeraldLight)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(_coachingAdvice!, style: AppTypography.body(context, color: AppColors.ivory), textAlign: TextAlign.center),
                                      ],
                                    ),
                                  )
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
                child: const Text('Use Sample Scam Call Instead'),
              ),
              if (!simpleMode) ...[
                const SizedBox(height: 6),
                Text(
                  'Guaranteed demo — works without mic or network',
                  style: AppTypography.label(context),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 16),
                
                Text(
                  'Advanced Features',
                  style: AppTypography.heading2(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                ListTile(
                  leading: const Icon(Icons.record_voice_over, color: AppColors.antiqueGold),
                  title: Text('Voice Biometrics Registration', style: AppTypography.body(context, color: AppColors.ivory)),
                  subtitle: Text('Protect loved ones from AI clones', style: AppTypography.label(context, color: AppColors.textMuted)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.antiqueGold),
                  onTap: () => context.push('/enroll-voice'),
                  tileColor: AppColors.navyLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.antiqueGold.withOpacity(0.2)),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.security, color: AppColors.antiqueGold),
                  title: Text('Caller Intelligence Network', style: AppTypography.body(context, color: AppColors.ivory)),
                  subtitle: Text('Search and report scam numbers', style: AppTypography.label(context, color: AppColors.textMuted)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.antiqueGold),
                  onTap: () => context.push('/caller-lookup'),
                  tileColor: AppColors.navyLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.antiqueGold.withOpacity(0.2)),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.emergency, color: AppColors.deepCrimson),
                  title: Text('Emergency & SOS', style: AppTypography.body(context, color: AppColors.ivory)),
                  subtitle: Text('Quick access to emergency contacts', style: AppTypography.label(context, color: AppColors.textMuted)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.antiqueGold),
                  onTap: () => context.push('/emergency-contacts'),
                  tileColor: AppColors.navyLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.antiqueGold.withOpacity(0.2)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
