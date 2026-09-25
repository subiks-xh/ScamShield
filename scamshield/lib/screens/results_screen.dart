import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../widgets/shield_emblem.dart';
import '../services/api_service.dart';
import '../models/analysis_result.dart';
import '../main.dart' show currentResult, prefs;

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  bool _ttsActive = false;
  bool _reportDone = false;
  bool _shieldAnimated = false;

  bool get simpleMode => prefs.getBool('simpleMode') ?? false;
  bool get ttsEnabled => prefs.getBool('ttsEnabled') ?? true;

  @override
  void initState() {
    super.initState();

    _tts.setStartHandler(() => setState(() => _ttsActive = true));
    _tts.setCompletionHandler(() => setState(() => _ttsActive = false));

    if (currentResult == null) return;

    // Trigger shield animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _shieldAnimated = true);
    });

    // Auto-read verdict
    if (ttsEnabled) {
      Future.delayed(const Duration(milliseconds: 700), () {
        _speak(currentResult!.verdictTtsText);
      });
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await _tts.setSpeechRate(0.85);
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  Future<void> _handleShare() async {
    if (currentResult == null) return;
    final r = currentResult!;
    final text = '''ScamShield Analysis Report
Generated: ${DateFormat.yMMMd().add_jm().format(r.createdAt)}
─────────────────────────────
VERDICT: ${r.verdictLabel}

AI Voice Score: ${r.voiceAuthenticityScore.toStringAsFixed(0)}%
Scam Content Score: ${r.contentRiskScore.toStringAsFixed(0)}%
${r.voiceMatchScore != null ? "Voice Match (${r.contactName ?? 'contact'}): ${r.voiceMatchScore!.toStringAsFixed(0)}%\n" : ""}
Transcript:
"${r.transcript.substring(0, r.transcript.length.clamp(0, 300))}${r.transcript.length > 300 ? "…" : ""}"
─────────────────────────────
ScamShield — AI scam call detector''';

    await Share.share(text, subject: 'ScamShield Analysis Report');
  }

  Future<void> _reportNumber() async {
    if (currentResult?.callerNumber == null) return;
    try {
      await ApiService.reportNumber(
        currentResult!.callerNumber!,
        notes: 'Verdict: ${currentResult!.verdict}',
      );
      if (mounted) setState(() => _reportDone = true);
    } catch (_) {
      // silent
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = currentResult;
    if (result == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final verdictColor = AppColors.verdictColor(result.verdict);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
          tooltip: 'Back to Home',
        ),
        title: Text('Analysis Results', style: AppTypography.heading2(context)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.royalPurple, AppColors.purpleLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Semantics(
            label: 'Read verdict aloud',
            child: IconButton(
              icon: Icon(_ttsActive ? Icons.volume_up : Icons.volume_down),
              color: AppColors.antiqueGold,
              onPressed: () {
                if (_ttsActive) {
                  _tts.stop();
                } else {
                  _speak(result.verdictTtsText);
                }
              },
              tooltip: 'Read verdict aloud',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Shield emblem (animated fill)
              Center(
                child: ShieldEmblem(
                  verdict: _shieldAnimated ? result.verdict : null,
                  size: 100,
                  variant: ShieldVariant.result,
                  animate: true,
                ),
              ),
              const SizedBox(height: 20),

              // Verdict box
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: verdictColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: verdictColor, width: 2),
                ),
                child: Column(
                  children: [
                    Text(result.verdictEmoji, style: const TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                    Text(
                      simpleMode ? result.verdictSimpleLabel : result.verdictLabel,
                      style: AppTypography.verdictText(context, color: verdictColor, simple: simpleMode),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      simpleMode
                          ? 'If unsure, hang up and call them on their real number.'
                          : 'Both signals must exceed 60 for HIGH RISK — real emergencies are never wrongly flagged.',
                      style: AppTypography.body(context),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Score bars
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      simpleMode ? 'Detection Details' : 'Risk Scores',
                      style: AppTypography.heading2(context),
                    ),
                    const SizedBox(height: 16),
                    _ScoreBar(
                      label: 'AI Voice Score',
                      score: result.voiceAuthenticityScore,
                      method: result.analysisMethod,
                      simpleMode: simpleMode,
                    ),
                    const SizedBox(height: 16),
                    _ScoreBar(
                      label: 'Scam Content Score',
                      score: result.contentRiskScore,
                      simpleMode: simpleMode,
                    ),
                    if (!simpleMode) ...[
                      const SizedBox(height: 8),
                      Text(
                        'High Risk requires BOTH scores > 60',
                        style: AppTypography.label(context, color: AppColors.textDim),
                      ),
                    ],
                  ],
                ),
              ),

              // Voice match (bonus signal)
              if (result.voiceMatchScore != null && result.contactName != null) ...[
                const SizedBox(height: 12),
                _VoiceMatchCard(result: result, simpleMode: simpleMode),
              ],

              const SizedBox(height: 12),

              // Transcript
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Transcript', style: AppTypography.heading2(context)),
                        if (result.languageDetected != null && result.languageDetected != 'en')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.antiqueGold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              result.languageDetected!.toUpperCase(),
                              style: AppTypography.mono(color: AppColors.antiqueGold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      result.transcript.isEmpty ? '(No transcript)' : result.transcript,
                      style: AppTypography.body(context, simple: simpleMode),
                      maxLines: simpleMode ? null : 6,
                      overflow: simpleMode ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action buttons
              if (result.callerNumber != null && !_reportDone)
                OutlinedButton(
                  onPressed: _reportNumber,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.crimsonLight,
                    side: BorderSide(color: AppColors.deepCrimson.withOpacity(0.6)),
                  ),
                  child: const Text('🚫 Report This Number as Scam'),
                ),

              if (_reportDone) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.deepEmerald.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.deepEmerald.withOpacity(0.4)),
                  ),
                  child: Text(
                    '✓ Number reported — thank you',
                    style: AppTypography.body(context, color: AppColors.emeraldLight),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 10),

              OutlinedButton(
                onPressed: _handleShare,
                child: const Text('📤 Share This Report'),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('🎙️ Analyze Another Call'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBar extends StatefulWidget {
  final String label;
  final double score;
  final String? method;
  final bool simpleMode;

  const _ScoreBar({required this.label, required this.score, this.method, required this.simpleMode});

  @override
  State<_ScoreBar> createState() => _ScoreBarState();
}

class _ScoreBarState extends State<_ScoreBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.scoreColor(widget.score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: AppTypography.body(context, simple: widget.simpleMode)),
            AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => Text(
                '${(widget.score * _anim.value).toStringAsFixed(0)}%',
                style: AppTypography.scoreNumber(color: color, simple: widget.simpleMode),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => LinearProgressIndicator(
              value: (widget.score / 100) * _anim.value,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: widget.simpleMode ? 12 : 8,
            ),
          ),
        ),
      ],
    );
  }
}

class _VoiceMatchCard extends StatelessWidget {
  final AnalysisResult result;
  final bool simpleMode;

  const _VoiceMatchCard({required this.result, required this.simpleMode});

  @override
  Widget build(BuildContext context) {
    final score = result.voiceMatchScore!;
    final color = score >= 70
        ? AppColors.deepEmerald
        : score >= 40
            ? AppColors.amberWarn
            : AppColors.deepCrimson;
    final label = score >= 70 ? 'Good match ✓' : score >= 40 ? 'Partial' : 'Poor match ⚠️';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔬', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'Bonus Signal · Protected Contact',
                style: AppTypography.label(context, color: AppColors.antiqueGold.withOpacity(0.7)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Voice match to ${result.contactName}',
                style: AppTypography.body(context, simple: simpleMode),
              ),
              Text(
                '${score.toStringAsFixed(0)}% — $label',
                style: AppTypography.scoreNumber(color: color, simple: simpleMode),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bonus signal only · Does not affect the main verdict · Stored locally, never uploaded',
            style: AppTypography.label(context, color: AppColors.textDim),
          ),
        ],
      ),
    );
  }
}
