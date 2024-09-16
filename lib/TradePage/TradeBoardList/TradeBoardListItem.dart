class TradeBoardListItem {
  final int boardNumber;
  final String title;
  final String content;
  final List<String> boardTitleImage;
  final int favoriteCount;
  final int commentCount;
  final int viewCount;
  final String writeDatetime;
  final String tradeLocation;
  final String price;
  final String writerNickname;
  final String writerProfileImage;

  TradeBoardListItem(
      this.boardNumber,
      this.title,
      this.content,
      this.boardTitleImage,
      this.favoriteCount,
      this.commentCount,
      this.viewCount,
      this.writeDatetime,
      this.tradeLocation,
      this.price,
      this.writerNickname,
      this.writerProfileImage
      );
}