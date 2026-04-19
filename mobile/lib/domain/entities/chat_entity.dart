class ChatEntity {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool showMap;
  final String? mapKeyword;
  final List<String>? imageUrls;

  ChatEntity({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.showMap = false,
    this.mapKeyword,
    this.imageUrls,
  });
}