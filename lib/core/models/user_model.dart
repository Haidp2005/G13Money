class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String avatarInitials;
  final DateTime joinedDate;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatarInitials,
    required this.joinedDate,
  });

  String get firstName => fullName.split(' ').last;

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? avatarInitials,
    DateTime? joinedDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }
}
