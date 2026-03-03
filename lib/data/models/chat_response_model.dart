class ChatResponseModel {
  final String pesan;
  final bool tampilkanMap;
  final String? keywordLokasi;
  final List<String>? gambarUrls;

  ChatResponseModel({
    required this.pesan,
    required this.tampilkanMap,
    this.keywordLokasi,
    this.gambarUrls,
  });

  factory ChatResponseModel.fromJson(Map<String, dynamic> json) {
    List<String>? parsedGambarUrls;
    if (json['gambar_urls'] != null) {
      parsedGambarUrls = List<String>.from(json['gambar_urls']);
    }

    return ChatResponseModel(
      pesan: json['pesan'] ?? 'Terjadi kesalahan dalam membaca pesan.',
      tampilkanMap: json['tampilkan_map'] ?? false,
      keywordLokasi: json['keyword_lokasi'],
      gambarUrls: parsedGambarUrls,
    );
  }
}