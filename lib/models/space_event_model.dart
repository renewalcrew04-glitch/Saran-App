class SpaceEvent {
  final String id;
  final String title;
  final String category;
  final String location;
  final DateTime dateTime;
  final int price;
  final int capacity;
  final int joined;
  final bool joinedByMe;

  SpaceEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.dateTime,
    required this.price,
    required this.capacity,
    required this.joined,
    required this.joinedByMe,
  });

  int get spotsLeft => capacity - joined;

  SpaceEvent copyWith({
  int? joined,
  bool? joinedByMe,
}) {
  return SpaceEvent(
    id: id,
    title: title,
    category: category,
    location: location,
    dateTime: dateTime,
    price: price,
    capacity: capacity,
    joined: joined ?? this.joined,
    joinedByMe: joinedByMe ?? this.joinedByMe,
  );
}

  factory SpaceEvent.fromJson(Map<String, dynamic> json) {
    return SpaceEvent(
      id: json['_id'],
      title: json['title'],
      category: json['category'],
      location: json['location'],
      dateTime: DateTime.parse(json['date']),
      price: json['price'] ?? 0,
      capacity: json['capacity'] ?? 0,
      joined: json['joinedCount'] ?? 0,
      joinedByMe: json['joinedByMe'] ?? false,
    );
  }
}
