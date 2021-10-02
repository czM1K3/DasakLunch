class Review {
  Review(
      {required this.id,
      required this.content,
      required this.date,
      required this.imageUrl});

  int id;
  String content;
  DateTime date;
  String? imageUrl;
}
