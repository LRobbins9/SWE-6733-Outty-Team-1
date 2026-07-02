class UserModel {
  final String id;
  String name;
  int age;
  String bio;
  String? photoUrl;
  String? gender;
  String? interestedIn;
  String? location;
  List<String> adventureTypes;
  String skillLevel;
  int maxDistance;
  String? instagramHandle;
  String email;
  DateTime createdAt;

  String? get avatarUrl => photoUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    this.photoUrl,
    this.gender,
    this.interestedIn,
    this.location,
    required this.adventureTypes,
    required this.skillLevel,
    this.maxDistance = 50,
    this.instagramHandle,
    required this.email,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  UserModel copyWith({
    String? name,
    int? age,
    String? bio,
    String? photoUrl,
    String? gender,
    String? interestedIn,
    String? location,
    List<String>? adventureTypes,
    String? skillLevel,
    int? maxDistance,
    String? instagramHandle,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      gender: gender ?? this.gender,
      interestedIn: interestedIn ?? this.interestedIn,
      location: location ?? this.location,
      adventureTypes: adventureTypes ?? List.from(this.adventureTypes),
      skillLevel: skillLevel ?? this.skillLevel,
      maxDistance: maxDistance ?? this.maxDistance,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      email: email,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'bio': bio,
        'photoUrl': photoUrl,
        'gender': gender,
        'interestedIn': interestedIn,
        'location': location,
        'adventureTypes': adventureTypes,
        'skillLevel': skillLevel,
        'maxDistance': maxDistance,
        'instagramHandle': instagramHandle,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date is String) return DateTime.parse(date);
      if (date is DateTime) return date;
      // Handle Firestore Timestamp if present
      try {
        // We don't want to import cloud_firestore here to keep the model clean
        // so we check for the presence of a 'toDate' method via dynamic call
        return (date as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      bio: json['bio'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      gender: json['gender'] as String?,
      interestedIn: json['interestedIn'] as String?,
      location: json['location'] as String?,
      adventureTypes: List<String>.from(
          (json['adventureTypes'] as List?)?.map((e) => e as String) ?? []),
      skillLevel: json['skillLevel'] as String? ?? 'Beginner',
      maxDistance: json['maxDistance'] as int? ?? 50,
      instagramHandle: json['instagramHandle'] as String?,
      email: json['email'] as String,
      createdAt: parseDate(json['createdAt']),
    );
  }
}
