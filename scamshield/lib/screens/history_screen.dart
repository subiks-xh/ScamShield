import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../widgets/shield_emblem.dart';
import '../models/analysis_result.dart';
import '../main.dart' show currentResult, prefs;

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  bool get simpleMode => prefs.getBool('simpleMode') ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              margin: const EdgeInsets.all(20),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('History', style: AppTypography.heading1(context)),
                      ValueListenableBuilder(
                        valueListenable: Hive.box<AnalysisResult>('history').listenable(),
                        builder: (_, box, __) => Text(
                          '${box.length} calls analyzed',
                          style: AppTypography.label(context, color: AppColors.antiqueGold.withOpacity(0.7)),
                        ),
                      ),
                    ],
                  ),
                  ValueListenableBuilder(
                    valueListenable: Hive.box<AnalysisResult>('history').listenable(),
                    builder: (_, box, __) {
                      if (box.isEmpty) return const SizedBox();
                      return TextButton(
                        onPressed: () => _showClearDialog(context, box),
                        child: Text(
                          '🗑 Clear',
                          style: AppTypography.label(context, color: AppColors.textMuted),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<AnalysisResult>('history').listenable(),
                builder: (context, box, _) {
                  if (box.isEmpty) {
                    return _EmptyState(onGoHome: () => context.go('/'));
                  }

                  final items = box.values.toList().reversed.toList();
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => _HistoryCard(
                      result: items[i],
                      onTap: () {
                        currentResult = items[i];
                        ctx.push('/results');
                      },
                      onDelete: () => items[i].delete(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, Box box) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.navyLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear History', style: AppTypography.heading2(context)),
        content: Text('Delete all analyzed calls? This cannot be undone.', style: AppTypography.body(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTypography.body(context, color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              box.clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepCrimson),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onGoHome;
  const _EmptyState({required this.onGoHome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShieldEmblem(size: 100, variant: ShieldVariant.empty, animate: false),
          const SizedBox(height: 20),
          Text('No calls analyzed yet', style: AppTypography.heading2(context, color: AppColors.textDim)),
          const SizedBox(height: 8),
          Text(
            'Your analysis history will appear here.',
            style: AppTypography.body(context, color: AppColors.textDim),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onGoHome, child: const Text('Go to Home')),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AnalysisResult result;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryCard({required this.result, required this.onTap, required this.onDelete});

  Color get _verdictColor => AppColors.verdictColor(result.verdict);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.navyLight, AppColors.surfaceDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // Verdict color bar
            Container(
              width: 4,
              height: 90,
              decoration: BoxDecoration(
                color: _verdictColor,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _verdictColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _verdictColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            '${result.verdictEmoji} ${result.verdictLabel}',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _verdictColor.withOpacity(0.9),
                              letterSpacing: 0.04,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat.MMMd().add_jm().format(result.createdAt),
                          style: AppTypography.label(context, color: AppColors.textDim),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"${result.transcript.length > 100 ? "${result.transcript.substring(0, 97)}…" : result.transcript}"',
                      style: AppTypography.body(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Voice: ${result.voiceAuthenticityScore.toStringAsFixed(0)}%  Content: ${result.contentRiskScore.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(Icons.close, size: 16, color: AppColors.textDim),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
