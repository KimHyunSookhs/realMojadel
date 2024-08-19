class RecipeBoardItem {
  final int boardNumber;
  final String title;
  final String content;
  final List<String> boardTitleImage;
  final int favoriteCount;
  final int commentCount;
  final int viewCount;
  final String writeDatetime;
  final String writerNickname;
  final List<String> writerProfileImage;

  RecipeBoardItem(
      this.boardNumber,
      this.title,
      this.content,
      this.boardTitleImage,
      this.favoriteCount,
      this.commentCount,
      this.viewCount,
      this.writeDatetime,
      this.writerNickname,
      this.writerProfileImage
      );
}