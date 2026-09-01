import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/shield_emblem.dart';
import '../main.dart' show prefs;

const _slides = [
  {
    'useShield': true,
    'emoji': null,
    'title': 'Welcome to ScamShield',
    'body': 'ScamShield helps protect you from AI voice-cloning scam calls — one of the fastest-growing threats to families today.',
  },
  {
    'useShield': false,
    'emoji': '🎭',
    'title': 'How AI Voice Scams Work',
    'body': 'Scammers can clone anyone\'s voice from as little as 3 seconds of audio on social media. They call pretending to be a loved one in distress — and it sounds real.',
  },
  {
    'useShield': false,
    'emoji': '🔍',
    'title': 'Two Independent Signals',
    'body': 'ScamShield checks two things: (1) Does the voice sound AI-generated? (2) Does the content contain scam language? Only when BOTH are present do we raise a High Risk alert — so real emergencies are never wrongly flagged.',
  },
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _slide = 0;

  void _complete() {
    prefs.setBool('onboardingComplete', true);
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_slide];
    final isLast = _slide == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: i == _slide ? 24 : 8,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _slide ? AppColors.antiqueGold : AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                )),
              ),

              const Spacer(),

              // Icon
              if (slide['useShield'] == true)
                ShieldEmblem(size: 100, variant: ShieldVariant.home, animate: false)
              else
                Text(slide['emoji']!, style: const TextStyle(fontSize: 70)),

              const SizedBox(height: 32),

              Text(
                slide['title']!,
                style: AppTypography.heading1(context),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                slide['body']!,
                style: AppTypography.body(context),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _complete,
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isLast) _complete();
                        else setState(() => _slide++);
                      },
                      child: Text(isLast ? 'Get Started →' : 'Next →'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
