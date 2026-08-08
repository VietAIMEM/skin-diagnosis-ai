/// User profile with optional personal information.
/// All fields are nullable; nothing is required.
class UserProfile {
  final int? age;
  final String? sex;
  final String? lesionLocation;

  const UserProfile({
    this.age,
    this.sex,
    this.lesionLocation,
  });

  bool get isEmpty => age == null && sex == null && lesionLocation == null;

  UserProfile copyWith({
    int? age,
    String? sex,
    String? lesionLocation,
  }) {
    return UserProfile(
      age: age ?? this.age,
      sex: sex ?? this.sex,
      lesionLocation: lesionLocation ?? this.lesionLocation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (age != null) 'age': age,
      if (sex != null) 'sex': sex,
      if (lesionLocation != null) 'lesionLocation': lesionLocation,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      age: json['age'] as int?,
      sex: json['sex'] as String?,
      lesionLocation: json['lesionLocation'] as String?,
    );
  }

  /// Builds a short one-line description for the prompt builder.
  String describe() {
    final parts = <String>[
      if (age != null) 'Age: $age',
      if (sex != null) 'Sex: $sex',
      if (lesionLocation != null) 'Lesion location: $lesionLocation',
    ];
    return parts.join(', ');
  }
}
