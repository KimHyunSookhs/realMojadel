class CommentListItem {
  final int? commentNumber;
  final String? nickname;
  final String? content;
  final String? writeDatetime;
  final String? profileImage;

  CommentListItem({
    this.commentNumber,
    this.nickname,
    this.content,
    this.writeDatetime,
    this.profileImage,
  });

  factory CommentListItem.fromJson(Map<String, dynamic> json) {
    return CommentListItem(
      commentNumber: json['commentNumber'],
      nickname: json['nickname'],
      content: json['content'],
      writeDatetime: json['writeDatetime'],
      profileImage: json['profileImage'],
    );
  }
}
