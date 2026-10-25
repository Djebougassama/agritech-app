class Formation {
  final String id;
  final String titre;
  final String description;
  final String imageUrl;
  final String datePublication;
  final String videoUrl;

  Formation({
    required this.id,
    required this.titre,
    required this.description,
    required this.imageUrl,
    required this.datePublication,
    required this.videoUrl,
  });

  factory Formation.fromMap(Map<String, dynamic> data, String documentId) {
    return Formation(
      id: documentId,
      titre: data['titre'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      datePublication: data['datePublication'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
    );
  }
}
