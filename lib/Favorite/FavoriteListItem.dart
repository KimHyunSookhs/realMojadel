class FavoriteListItem{
  final String? email;
  final String? nickname;
  final String? profileImage;

  FavoriteListItem({
    this.email,
    this.nickname,
    this.profileImage,
      }
      );

  factory FavoriteListItem.fromJson(Map<String, dynamic> json) {
    return FavoriteListItem(
      email: json['email'],
      nickname: json['nickname'],
      profileImage: json['profileImage'],
    );
  }
}


