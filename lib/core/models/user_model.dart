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
}
