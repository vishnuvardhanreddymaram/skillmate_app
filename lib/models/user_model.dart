class UserModel {
  final String uid;
  final String name;
  final String email;
  final String bio;
  final String skillsHave;
  final String skillsWant;
  final String? phone;
  final String? photoBase64;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.bio,
    required this.skillsHave,
    required this.skillsWant,
    this.phone,
    this.photoBase64,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      bio: data['bio'] ?? '',
      skillsHave: data['skillsHave'] ?? '',
      skillsWant: data['skillsWant'] ?? '',
      phone: data['phone'],
      photoBase64: data['photoBase64'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'bio': bio,
      'skillsHave': skillsHave,
      'skillsWant': skillsWant,
      if (phone != null) 'phone': phone,
      if (photoBase64 != null) 'photoBase64': photoBase64,
    };
  }
}
