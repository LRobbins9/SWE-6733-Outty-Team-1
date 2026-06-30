class UserModel {
  final String id;
  String name;
  int age;
  String bio;
  String? photoUrl;
  String? location;
  List<String> adventureTypes;
  String skillLevel;
  int maxDistance;
  String? instagramHandle;
  String email;
  DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    this.photoUrl,
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
        'location': location,
        'adventureTypes': adventureTypes,
        'skillLevel': skillLevel,
        'maxDistance': maxDistance,
        'instagramHandle': instagramHandle,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        age: json['age'] as int,
        bio: json['bio'] as String,
        photoUrl: json['photoUrl'] as String?,
        location: json['location'] as String?,
        adventureTypes: List<String>.from(
            (json['adventureTypes'] as List?)?.map((e) => e as String) ?? []),
        skillLevel: json['skillLevel'] as String? ?? 'Beginner',
        maxDistance: json['maxDistance'] as int? ?? 50,
        instagramHandle: json['instagramHandle'] as String?,
        email: json['email'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
