/// ユーザー自身のプロフィール（名前・顔写真アイコン）
class Profile {
  String name;
  String? avatarPath;

  Profile({this.name = '', this.avatarPath});

  Map<String, dynamic> toJson() => {
        'name': name,
        'avatarPath': avatarPath,
      };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        name: json['name'] as String? ?? '',
        avatarPath: json['avatarPath'] as String?,
      );

  Profile copyWith({String? name, String? avatarPath, bool clearAvatar = false}) {
    return Profile(
      name: name ?? this.name,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
    );
  }
}
