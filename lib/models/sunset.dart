class Sunset {
  final int? id;
  final String title;
  final String place;
  final String description;
  final String imagePath;
  final String date;
  final double latitude;
  final double longitude;

  Sunset({
    this.id,
    required this.title,
    required this.place,
    required this.description,
    required this.imagePath,
    required this.date,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'place': place,
      'description': description,
      'imagePath': imagePath,
      'date': date,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Sunset.fromMap(Map<String, dynamic> map) {
    return Sunset(
      id: map['id'] as int,
      title: map['title'] as String,
      place: map['place'] as String,
      description: map['description'] as String,
      imagePath: map['imagePath'] as String,
      date: map['date'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }
}
