class Residence {
  final String id;
  final String titre;
  final String type; // studio, appartement, villa...
  final double prix;
  final double latitude;
  final double longitude;
  final List<String> photos;
  final bool disponible;
  final double? note;
  final String? adresse;
  final String? description;

  Residence({
    required this.id,
    required this.titre,
    required this.type,
    required this.prix,
    required this.latitude,
    required this.longitude,
    required this.photos,
    required this.disponible,
    this.note,
    this.adresse,
    this.description,
  });

  factory Residence.fromJson(Map<String, dynamic> json) {
    return Residence(
      id: json['id'].toString(),
      titre: json['titre'] ?? json['name'] ?? '',
      type: json['type'] ?? '',
      prix: (json['prix'] ?? json['price'] ?? 0).toDouble(),
      latitude: (json['latitude'] ?? json['lat'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? 0).toDouble(),
      photos: (json['photos'] as List?)?.map((e) => e.toString()).toList() ?? [],
      disponible: json['disponible'] ?? true,
      note: json['note'] != null ? (json['note'] as num).toDouble() : null,
      adresse: json['adresse'],
      description: json['description'],
    );
  }
}
