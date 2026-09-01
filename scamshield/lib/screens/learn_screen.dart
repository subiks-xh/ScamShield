import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../main.dart' show prefs;

// ─── Scam Patterns ────────────────────────────────────────────────────────────
const _patterns = [
  {
    'emoji': '🤖',
    'title': 'AI Voice Cloning Scam',
    'description': 'Scammers use AI to clone a loved one\'s voice from social media clips, then call you pretending to be them in an emergency.',
    'signs': ['Voice sounds slightly "off" or too smooth', 'Claims to be in immediate danger', 'Asks you not to contact anyone else', 'Requests money urgently'],
  },
  {
    'emoji': '👴',
    'title': 'Grandparent Scam',
    'description': 'A caller pretends to be your grandchild (or their lawyer/police officer) claiming they\'re in trouble and need bail money immediately.',
    'signs': ['"Don\'t tell Mom/Dad"', 'Needs money for bail or emergency', 'Says to keep it secret', 'Asks for wire transfer or gift cards'],
  },
  {
    'emoji': '🏦',
    'title': 'Fake Bank Call',
    'description': 'Imposters call claiming to be your bank\'s fraud department, asking you to "verify" by sharing your PIN or OTP.',
    'signs': ['Asks for OTP, PIN, or password', 'Claims your account is frozen', 'Urgent pressure to act immediately', 'May already know your account number'],
  },
  {
    'emoji': '📱',
    'title': 'OTP Theft / SIM Swap',
    'description': 'Scammers who have your personal info call to get the one-time password sent to your phone, giving them full account access.',
    'signs': ['You receive an unexpected OTP', 'Caller asks you to read it aloud', 'Claims to be "verifying your identity"', '"Your account will be locked"'],
  },
  {
    'emoji': '🏛️',
    'title': 'Government Impersonator',
    'description': 'Callers impersonate IRS agents, Social Security Administration, or police, threatening arrest unless you pay immediately.',
    'signs': ['Threat of arrest or legal action', 'Demands immediate payment', 'Accepts only gift cards or crypto', 'Uses official-sounding case numbers'],
  },
];

// ─── Quiz questions ───────────────────────────────────────────────────────────
const _questions = [
  {
    'q': 'You get a call from someone claiming to be your grandchild in trouble. They beg you not to tell anyone. What should you do?',
    'options': ['Send money right away to help', 'Hang up and call your grandchild on their known number', 'Keep it secret as asked', 'Give them your bank details'],
    'correct': 1,
    'explanation': 'Always verify by calling the person directly on a number you already know. Scammers count on urgency and secrecy to prevent you from checking.',
  },
  {
    'q': 'A caller says your bank account is frozen and asks for your OTP to unfreeze it. What is the red flag?',
    'options': ['They mentioned your bank name', 'They sound friendly', 'Banks never ask for OTPs over the phone', 'They called in the morning'],
    'correct': 2,
    'explanation': 'No legitimate bank, government, or service will ever ask you for an OTP, PIN, or password over the phone. This is always a scam.',
  },
  {
    'q': 'Someone claiming to be from the IRS calls and says you\'ll be arrested unless you pay in gift cards. What should you do?',
    'options': ['Pay with gift cards to avoid arrest', 'Ask them to call back later', 'Hang up — government agencies never demand gift card payments', 'Give them your address'],
    'correct': 2,
    'explanation': 'The IRS communicates via postal mail first. They never demand immediate payment in gift cards, cryptocurrency, or wire transfers.',
  },
  {
    'q': 'How can you tell if a voice on a call might be AI-generated?',
    'options': ['It speaks very fast', 'It sounds oddly smooth, lacks natural pauses/breaths, or pitch doesn\'t vary naturally', 'It has an accent', 'It calls at night'],
    'correct': 1,
    'explanation': 'AI voice clones often sound unnaturally smooth, with consistent pitch and fewer natural speech imperfections like breathing pauses or filler words.',
  },
  {
    'q': 'Which combination of factors should make you MOST suspicious of a call?',
    'options': ['The caller is polite and patient', 'The caller wants to discuss a bill', 'Urgent demand + secrecy request + asking for money', 'The caller knows your name'],
    'correct': 2,
    'explanation': 'The scam trifecta: urgency (act now!), secrecy (don\'t tell anyone), and money request. All three together is almost certainly a scam.',
  },
];

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  bool _showQuiz = false;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📚 Learn', style: AppTypography.heading1(context)),
                  Text(
                    'Understand scam patterns and test your awareness',
                    style: AppTypography.label(context, color: AppColors.antiqueGold.withOpacity(0.7)),
                  ),
                ],
              ),
            ),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _tab('🎭 Scam Patterns', !_showQuiz, () => setState(() => _showQuiz = false)),
                  const SizedBox(width: 8),
                  _tab('🧠 Quiz', _showQuiz, () => setState(() => _showQuiz = true)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _showQuiz
                  ? _QuizTab(simpleMode: simpleMode)
                  : _PatternsTab(simpleMode: simpleMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: simpleMode ? 14 : 10),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(colors: [AppColors.antiqueGold, AppColors.goldLight])
                : null,
            color: active ? null : AppColors.navyLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: simpleMode ? 16 : 13,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.royalNavy : AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  bool get simpleMode => prefs.getBool('simpleMode') ?? false;
}

class _PatternsTab extends StatelessWidget {
  final bool simpleMode;
  const _PatternsTab({required this.simpleMode});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _patterns.length,
      itemBuilder: (_, i) => _PatternCard(pattern: _patterns[i], simpleMode: simpleMode),
    );
  }
}

class _PatternCard extends StatefulWidget {
  final Map<String, dynamic> pattern;
  final bool simpleMode;
  const _PatternCard({required this.pattern, required this.simpleMode});

  @override
  State<_PatternCard> createState() => _PatternCardState();
}

class _PatternCardState extends State<_PatternCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.navyLight, AppColors.surfaceDark],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _expanded ? AppColors.antiqueGold.withOpacity(0.4) : AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.pattern['emoji']!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.pattern['title']!,
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: widget.simpleMode ? 18 : 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ivory,
                    ),
                  ),
                ),
                Text(_expanded ? '▲' : '▼', style: TextStyle(color: AppColors.antiqueGold)),
              ],
            ),
            if (_expanded) ...[
              const Divider(color: AppColors.divider, height: 20),
              Text(widget.pattern['description']!, style: AppTypography.body(context, simple: widget.simpleMode)),
              const SizedBox(height: 12),
              Text(
                'Warning Signs',
                style: AppTypography.label(context, color: AppColors.antiqueGold),
              ),
              const SizedBox(height: 6),
              ...(_patterns[_patterns.indexOf(widget.pattern)]['signs'] as List<String>).map(
                (sign) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('▶ ', style: TextStyle(color: AppColors.deepCrimson, fontSize: 12)),
                      Expanded(child: Text(sign, style: AppTypography.body(context, simple: widget.simpleMode))),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuizTab extends StatefulWidget {
  final bool simpleMode;
  const _QuizTab({required this.simpleMode});

  @override
  State<_QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<_QuizTab> {
  int _current = 0;
  int? _selected;
  bool _answered = false;
  int _score = 0;
  bool _finished = false;
  final List<bool> _answers = [];

  void _select(int idx) {
    if (_answered) return;
    setState(() {
      _selected = idx;
      _answered = true;
      final correct = idx == _questions[_current]['correct'];
      if (correct) _score++;
      _answers.add(correct);
    });
  }

  void _next() {
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
        _answered = false;
      });
    } else {
      setState(() => _finished = true);
    }
  }

  void _reset() {
    setState(() {
      _current = 0;
      _selected = null;
      _answered = false;
      _score = 0;
      _finished = false;
      _answers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      final pct = (_score / _questions.length * 100).round();
      final emoji = pct >= 80 ? '🏆' : pct >= 60 ? '👍' : '📚';
      final msg = pct >= 80 ? 'Excellent! You\'re well-protected.' : pct >= 60 ? 'Good awareness!' : 'Keep learning — knowledge is protection.';
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: AppCard(
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 50)),
              const SizedBox(height: 12),
              Text(msg, style: AppTypography.heading2(context), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: AppTypography.body(context),
                  children: [
                    const TextSpan(text: 'You scored '),
                    TextSpan(
                      text: '$_score/${_questions.length} ($pct%)',
                      style: AppTypography.scoreNumber(
                        color: pct >= 80 ? AppColors.emeraldLight : pct >= 60 ? AppColors.amberWarnLight : AppColors.crimsonLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _answers.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(c ? '✅' : '❌', style: const TextStyle(fontSize: 20)),
                )).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _reset, child: const Text('Try Again')),
            ],
          ),
        ),
      );
    }

    final q = _questions[_current];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress
            Row(
              children: List.generate(_questions.length, (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < _questions.length - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i < _current ? AppColors.deepEmerald : i == _current ? AppColors.antiqueGold : AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 12),
            Text('Q${_current + 1} of ${_questions.length}', style: AppTypography.label(context, color: AppColors.antiqueGold)),
            const SizedBox(height: 8),
            Text(q['q']!, style: AppTypography.heading2(context)),
            const SizedBox(height: 16),
            ...(q['options'] as List<String>).asMap().entries.map((e) {
              final idx = e.key;
              final opt = e.value;
              Color bg = AppColors.surfaceDark;
              Color border = AppColors.divider;
              Color textColor = AppColors.ivoryDim;
              if (_answered) {
                if (idx == q['correct']) { bg = AppColors.deepEmerald.withOpacity(0.2); border = AppColors.deepEmerald; textColor = AppColors.emeraldLight; }
                else if (idx == _selected) { bg = AppColors.deepCrimson.withOpacity(0.2); border = AppColors.deepCrimson; textColor = AppColors.crimsonLight; }
              } else if (idx == _selected) {
                bg = AppColors.antiqueGold.withOpacity(0.1); border = AppColors.antiqueGold; textColor = AppColors.ivory;
              }
              return GestureDetector(
                onTap: () => _select(idx),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(widget.simpleMode ? 14 : 10),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border, width: 1.5),
                  ),
                  child: Text(
                    '${String.fromCharCode(65 + idx)}. $opt',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: widget.simpleMode ? 16 : 14,
                      color: textColor,
                    ),
                  ),
                ),
              );
            }),
            if (_answered) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.navyLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selected == q['correct'] ? '✓ Correct!' : '✗ Not quite —',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        color: _selected == q['correct'] ? AppColors.emeraldLight : AppColors.amberWarnLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(q['explanation']!, style: AppTypography.body(context)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _next,
                child: Text(_current == _questions.length - 1 ? 'See Results →' : 'Next →'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
