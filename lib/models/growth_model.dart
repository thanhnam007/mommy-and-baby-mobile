class WHOReferencePoint {
  final double ageMonths;
  final double weightSdNeg2;
  final double weightMedian;
  final double weightSdPos2;
  final double heightSdNeg2;
  final double heightMedian;
  final double heightSdPos2;

  WHOReferencePoint({
    required this.ageMonths,
    required this.weightSdNeg2,
    required this.weightMedian,
    required this.weightSdPos2,
    required this.heightSdNeg2,
    required this.heightMedian,
    required this.heightSdPos2,
  });

  factory WHOReferencePoint.fromJson(Map<String, dynamic> json) {
    return WHOReferencePoint(
      ageMonths: (json['age_months'] as num?)?.toDouble() ?? 0.0,
      weightSdNeg2: (json['weight_sd_neg2'] as num?)?.toDouble() ?? 0.0,
      weightMedian: (json['weight_median'] as num?)?.toDouble() ?? 0.0,
      weightSdPos2: (json['weight_sd_pos2'] as num?)?.toDouble() ?? 0.0,
      heightSdNeg2: (json['height_sd_neg2'] as num?)?.toDouble() ?? 0.0,
      heightMedian: (json['height_median'] as num?)?.toDouble() ?? 0.0,
      heightSdPos2: (json['height_sd_pos2'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GrowthRecordModel {
  final int id;
  final int babyId;
  final String recordedAt;
  final double? weightKg;
  final double? heightCm;
  final String? notes;
  final double? ageMonths;
  final String? ageLabel;
  final WHOReferencePoint? whoReference;
  final String? weightStatus;
  final String? heightStatus;

  GrowthRecordModel({
    required this.id,
    required this.babyId,
    required this.recordedAt,
    this.weightKg,
    this.heightCm,
    this.notes,
    this.ageMonths,
    this.ageLabel,
    this.whoReference,
    this.weightStatus,
    this.heightStatus,
  });

  factory GrowthRecordModel.fromJson(Map<String, dynamic> json) {
    return GrowthRecordModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      babyId: json['baby_id'] is int ? json['baby_id'] : int.tryParse(json['baby_id'].toString()) ?? 0,
      recordedAt: json['recorded_at']?.toString() ?? '',
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      notes: json['notes'],
      ageMonths: (json['age_months'] as num?)?.toDouble(),
      ageLabel: json['age_label'],
      whoReference: json['who_reference'] != null ? WHOReferencePoint.fromJson(json['who_reference']) : null,
      weightStatus: json['weight_status'],
      heightStatus: json['height_status'],
    );
  }
}

class GrowthSummaryModel {
  final int babyId;
  final String babyGender;
  final double babyAgeMonths;
  final WHOReferencePoint currentWhoStandard;
  final GrowthRecordModel? latestRecord;
  final double? weightDiffKg;
  final double? heightDiffCm;
  final List<GrowthRecordModel> records;

  GrowthSummaryModel({
    required this.babyId,
    required this.babyGender,
    required this.babyAgeMonths,
    required this.currentWhoStandard,
    this.latestRecord,
    this.weightDiffKg,
    this.heightDiffCm,
    required this.records,
  });

  factory GrowthSummaryModel.fromJson(Map<String, dynamic> json) {
    final list = json['records'] as List? ?? [];
    return GrowthSummaryModel(
      babyId: json['baby_id'] ?? 0,
      babyGender: json['baby_gender'] ?? 'boy',
      babyAgeMonths: (json['baby_age_months'] as num?)?.toDouble() ?? 0.0,
      currentWhoStandard: WHOReferencePoint.fromJson(json['current_who_standard'] ?? {}),
      latestRecord: json['latest_record'] != null ? GrowthRecordModel.fromJson(json['latest_record']) : null,
      weightDiffKg: (json['weight_diff_kg'] as num?)?.toDouble(),
      heightDiffCm: (json['height_diff_cm'] as num?)?.toDouble(),
      records: list.map((item) => GrowthRecordModel.fromJson(item)).toList(),
    );
  }
}
