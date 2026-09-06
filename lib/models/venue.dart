class Venue {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final String status; // 'pending' або 'approved'

  Venue({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }

  factory Venue.fromMap(Map<String, dynamic> map) {
    return Venue(
      id: map['id'],
      name: map['name'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      status: map['status'],
    );
  }
}