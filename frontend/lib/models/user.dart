class User {
  final int id;
  final String email;
  final String username;
  final bool isPremium;
  final DateTime? membershipStart;
  final DateTime? membershipEnd;
  final bool isEmailVerified;
  final bool isCancelled;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.isPremium = false,
    this.membershipStart,
    this.membershipEnd,
    this.isEmailVerified = false,
    this.isCancelled = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      isPremium: json['is_premium'] ?? false,
      membershipStart: json['membership_start'] != null 
          ? DateTime.parse(json['membership_start']) 
          : null,
      membershipEnd: json['membership_end'] != null 
          ? DateTime.parse(json['membership_end']) 
          : null,
      isEmailVerified: json['is_email_verified'] ?? false,
      isCancelled: json['is_cancelled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'is_premium': isPremium,
      'membership_start': membershipStart?.toIso8601String(),
      'membership_end': membershipEnd?.toIso8601String(),
      'is_email_verified': isEmailVerified,
      'is_cancelled': isCancelled,
    };
  }
}
