// GENERATED CODE - DO NOT MODIFY BY HAND
// This is a stub for the hackathon build.
// Run `flutter pub run build_runner build` to generate real adapters.

part of 'analysis_result.dart';

// ─── AnalysisResult Adapter ───────────────────────────────────────────────────

class AnalysisResultAdapter extends TypeAdapter<AnalysisResult> {
  @override
  final int typeId = 0;

  @override
  AnalysisResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnalysisResult(
      id: fields[0] as String,
      transcript: fields[1] as String,
      voiceAuthenticityScore: fields[2] as double,
      contentRiskScore: fields[3] as double,
      verdict: fields[4] as String,
      callerNumber: fields[5] as String?,
      contactName: fields[6] as String?,
      voiceMatchScore: fields[7] as double?,
      languageDetected: fields[8] as String?,
      analysisMethod: fields[9] as String?,
      createdAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AnalysisResult obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.transcript)
      ..writeByte(2)
      ..write(obj.voiceAuthenticityScore)
      ..writeByte(3)
      ..write(obj.contentRiskScore)
      ..writeByte(4)
      ..write(obj.verdict)
      ..writeByte(5)
      ..write(obj.callerNumber)
      ..writeByte(6)
      ..write(obj.contactName)
      ..writeByte(7)
      ..write(obj.voiceMatchScore)
      ..writeByte(8)
      ..write(obj.languageDetected)
      ..writeByte(9)
      ..write(obj.analysisMethod)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalysisResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ─── ProtectedContact Adapter ─────────────────────────────────────────────────

class ProtectedContactAdapter extends TypeAdapter<ProtectedContact> {
  @override
  final int typeId = 1;

  @override
  ProtectedContact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProtectedContact(
      id: fields[0] as String,
      name: fields[1] as String,
      relationship: fields[2] as String?,
      hasVoiceSample: fields[3] as bool,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ProtectedContact obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.relationship)
      ..writeByte(3)
      ..write(obj.hasVoiceSample)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProtectedContactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ─── AppPreferences Adapter ───────────────────────────────────────────────────

class AppPreferencesAdapter extends TypeAdapter<AppPreferences> {
  @override
  final int typeId = 2;

  @override
  AppPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppPreferences(
      simpleMode: fields[0] as bool,
      darkMode: fields[1] as bool,
      ttsEnabled: fields[2] as bool,
      autoPlaySample: fields[3] as bool,
      onboardingComplete: fields[4] as bool,
      guardianCode: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppPreferences obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.simpleMode)
      ..writeByte(1)
      ..write(obj.darkMode)
      ..writeByte(2)
      ..write(obj.ttsEnabled)
      ..writeByte(3)
      ..write(obj.autoPlaySample)
      ..writeByte(4)
      ..write(obj.onboardingComplete)
      ..writeByte(5)
      ..write(obj.guardianCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
