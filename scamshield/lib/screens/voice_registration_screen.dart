import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/amplitude_bars.dart';

class VoiceRegistrationScreen extends StatefulWidget {
  const VoiceRegistrationScreen({super.key});

  @override
  State<VoiceRegistrationScreen> createState() => _VoiceRegistrationScreenState();
}

class _VoiceRegistrationScreenState extends State<VoiceRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isEnrolling = false;
  String _message = '';
  double _amplitude = 0;
  int _recordingSeconds = 0;
  Timer? _timer;
  Timer? _amplitudeTimer;
  String? _audioPath;

  @override
  void dispose() {
    _recorder.dispose();
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _message = 'Please enter a contact name first.');
      return;
    }

    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      setState(() => _message = 'Microphone permission denied.');
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/enroll_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _message = 'Recording... Please speak normally for 10-15 seconds.';
      _recordingSeconds = 0;
      _audioPath = path;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _recordingSeconds++;
        if (_recordingSeconds >= 15) {
          _stopRecording(); // auto-stop at 15s
        }
      });
    });

    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      final amp = await _recorder.getAmplitude();
      if (mounted) {
        setState(() {
          _amplitude = ((amp.current + 60) / 60).clamp(0.0, 1.0);
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    await _recorder.stop();

    setState(() {
      _isRecording = false;
      _amplitude = 0;
      _message = 'Recording complete. Enrolling...';
      _isEnrolling = true;
    });

    try {
      final result = await ApiService.enrollVoice(
        audioPath: _audioPath,
        contactName: _nameController.text.trim(),
        relationship: _relationshipController.text.trim(),
      );

      setState(() {
        _message = '✅ Successfully enrolled voice for ${result["contact_name"]}!';
        _isEnrolling = false;
      });
      
      // Cleanup
      if (!kIsWeb && _audioPath != null) {
        final f = File(_audioPath!);
        if (f.existsSync()) {
          f.deleteSync();
        }
      }
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.pop();
      });
    } catch (e) {
      setState(() {
        _message = 'Error: ${e.toString()}';
        _isEnrolling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Biometrics Registration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enroll a Loved One',
              style: AppTypography.heading2(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Register their voice so ScamShield can detect AI deepfake clones of them.',
              style: AppTypography.body(context, color: AppColors.textMuted),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              enabled: !_isRecording && !_isEnrolling,
              decoration: const InputDecoration(
                labelText: 'Contact Name (e.g., Mom, John)',
                prefixIcon: Icon(Icons.person, color: AppColors.antiqueGold),
              ),
              style: AppTypography.body(context, color: AppColors.ivory),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _relationshipController,
              enabled: !_isRecording && !_isEnrolling,
              decoration: const InputDecoration(
                labelText: 'Relationship (optional)',
                prefixIcon: Icon(Icons.family_restroom, color: AppColors.antiqueGold),
              ),
              style: AppTypography.body(context, color: AppColors.ivory),
            ),
            const SizedBox(height: 48),
            
            // Record Button
            Center(
              child: GestureDetector(
                onTap: _isEnrolling ? null : (_isRecording ? _stopRecording : _startRecording),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isRecording
                          ? [AppColors.deepCrimson, AppColors.crimsonLight]
                          : [AppColors.royalPurple, AppColors.purpleLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? AppColors.deepCrimson : AppColors.royalPurple)
                            .withOpacity(0.4),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isRecording ? '⏹' : '🎙️',
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (_isRecording)
              AmplitudeBars(
                isRecording: _isRecording,
                amplitude: _amplitude,
              ),
              
            if (_isRecording)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Text(
                    '● Recording ${_recordingSeconds}s / 15s',
                    style: AppTypography.body(context, color: AppColors.crimsonLight),
                  ),
                ),
              ),
              
            if (_isEnrolling)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: AppColors.antiqueGold),
                ),
              ),
              
            if (_message.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navyLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.antiqueGold.withOpacity(0.2)),
                ),
                child: Text(
                  _message,
                  style: AppTypography.body(context, color: _message.startsWith('Error') ? AppColors.crimsonLight : AppColors.ivory),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
