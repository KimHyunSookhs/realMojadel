class BoardListItem {
  final int boardNumber;
  final String title;
  final String content;
  final List<String> boardTitleImage;
  final int favoriteCount; // 추가된 favoriteCount
  final int commentCount; // 추가된 commentCount
  final int viewCount; // 추가된 viewCount
  final String writeDatetime; // 추가된 writeDatetime
  final String writerNickname;
  BoardListItem(
      this.boardNumber,
      this.title,
      this.content,
      this.boardTitleImage,
      this.favoriteCount,
      this.commentCount,
      this.viewCount,
      this.writeDatetime,
      this.writerNickname,
      );
}
