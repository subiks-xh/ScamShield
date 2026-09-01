import 'package:hive/hive.dart';

part 'analysis_result.g.dart';

@HiveType(typeId: 0)
class AnalysisResult extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String transcript;

  @HiveField(2)
  double voiceAuthenticityScore;

  @HiveField(3)
  double contentRiskScore;

  @HiveField(4)
  String verdict; // 'high_risk' | 'medium_risk' | 'low_risk'

  @HiveField(5)
  String? callerNumber;

  @HiveField(6)
  String? contactName;

  @HiveField(7)
  double? voiceMatchScore;

  @HiveField(8)
  String? languageDetected;

  @HiveField(9)
  String? analysisMethod;

  @HiveField(10)
  DateTime createdAt;

  AnalysisResult({
    required this.id,
    required this.transcript,
    required this.voiceAuthenticityScore,
    required this.contentRiskScore,
    required this.verdict,
    this.callerNumber,
    this.contactName,
    this.voiceMatchScore,
    this.languageDetected,
    this.analysisMethod,
    required this.createdAt,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      transcript: json['transcript'] ?? '',
      voiceAuthenticityScore: (json['voice_authenticity_score'] ?? 50).toDouble(),
      contentRiskScore: (json['content_risk_score'] ?? 0).toDouble(),
      verdict: json['verdict'] ?? 'low_risk',
      callerNumber: json['caller_number'],
      contactName: json['contact_name'],
      voiceMatchScore: json['voice_match_score']?.toDouble(),
      languageDetected: json['language_detected'],
      analysisMethod: json['voice_check_method'],
      createdAt: DateTime.now(),
    );
  }

  String get verdictLabel {
    switch (verdict) {
      case 'high_risk':
        return 'HIGH RISK';
      case 'medium_risk':
        return 'MEDIUM RISK';
      default:
        return 'LOW RISK';
    }
  }

  String get verdictSimpleLabel {
    switch (verdict) {
      case 'high_risk':
        return 'This call looks risky';
      case 'medium_risk':
        return 'This call needs caution';
      default:
        return 'This call looks safe';
    }
  }

  String get verdictTtsText {
    switch (verdict) {
      case 'high_risk':
        return 'Warning. This call looks very risky. It may be a scam. Do not give any personal information or money.';
      case 'medium_risk':
        return 'Caution. This call shows some suspicious signs. Be careful before sharing any information.';
      default:
        return 'This call appears safe. No significant scam signals were detected.';
    }
  }

  String get verdictEmoji {
    switch (verdict) {
      case 'high_risk':
        return '🚨';
      case 'medium_risk':
        return '⚠️';
      default:
        return '✅';
    }
  }
}

@HiveType(typeId: 1)
class ProtectedContact extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? relationship;

  @HiveField(3)
  bool hasVoiceSample;

  @HiveField(4)
  DateTime createdAt;

  ProtectedContact({
    required this.id,
    required this.name,
    this.relationship,
    required this.hasVoiceSample,
    required this.createdAt,
  });
}

@HiveType(typeId: 2)
class AppPreferences extends HiveObject {
  @HiveField(0)
  bool simpleMode;

  @HiveField(1)
  bool darkMode;

  @HiveField(2)
  bool ttsEnabled;

  @HiveField(3)
  bool autoPlaySample;

  @HiveField(4)
  bool onboardingComplete;

  @HiveField(5)
  String guardianCode;

  AppPreferences({
    this.simpleMode = false,
    this.darkMode = true,
    this.ttsEnabled = true,
    this.autoPlaySample = false,
    this.onboardingComplete = false,
    this.guardianCode = '',
  });
}
