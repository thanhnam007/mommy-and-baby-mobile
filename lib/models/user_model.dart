class UserModel {
  final int id;
  final String username;
  final String? email;
  final String? fullName;
  final String? nickname;
  final String? avatarUrl;
  final String tier; // 'free' or 'vip'
  final String role; // 'user', 'moderator', 'admin'

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.fullName,
    this.nickname,
    this.avatarUrl,
    required this.tier,
    required this.role,
  });

  bool get isVip => tier.toLowerCase() == 'vip';
  bool get isAdmin => role.toLowerCase() == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      username: json['username'] ?? '',
      email: json['email'],
      fullName: json['full_name'],
      nickname: json['nickname'],
      avatarUrl: json['avatar_url'],
      tier: json['tier'] ?? 'free',
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'tier': tier,
      'role': role,
    };
  }
}
