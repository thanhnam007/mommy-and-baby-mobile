class BabyModel {
  final int id;
  final String name;
  final String? nickname;
  final String gender; // 'boy' or 'girl'
  final String birthDate; // 'YYYY-MM-DD'
  final String? avatarUrl;
  final String ageText;
  final int? ageInMonths;
  final int? ageInDays;

  BabyModel({
    required this.id,
    required this.name,
    this.nickname,
    required this.gender,
    required this.birthDate,
    this.avatarUrl,
    required this.ageText,
    this.ageInMonths,
    this.ageInDays,
  });

  bool get isGirl => gender.toLowerCase() == 'girl';
  String get genderEmoji => isGirl ? '👧' : '👦';

  factory BabyModel.fromJson(Map<String, dynamic> json) {
    return BabyModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      nickname: json['nickname'],
      gender: json['gender'] ?? 'boy',
      birthDate: json['birth_date']?.toString() ?? '',
      avatarUrl: json['avatar_url'],
      ageText: json['age_text'] ?? '',
      ageInMonths: json['age_in_months'],
      ageInDays: json['age_in_days'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nickname': nickname,
      'gender': gender,
      'birth_date': birthDate,
      'avatar_url': avatarUrl,
    };
  }
}
