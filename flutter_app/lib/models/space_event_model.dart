class SpaceEvent {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime date;
  final String location;
  final String hostId;
  final String? hostName;
  final String? hostAvatar;
  final int attendeesCount;
  final bool isJoined;
  final bool isOnline;
  final String? meetingLink;

  final int price;
  final int capacity;
  final String? coverUrl;
  final DateTime? updatedAt;

  SpaceEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.location,
    required this.hostId,
    this.hostName,
    this.hostAvatar,
    this.attendeesCount = 0,
    this.isJoined = false,
    this.isOnline = false,
    this.meetingLink,
    this.price = 0,
    this.capacity = 100,
    this.coverUrl,
    this.updatedAt,
  });

  // ✅ Getters: This maps the UI names to our actual data
  int get joined => attendeesCount;
  int get spotsLeft => (capacity - attendeesCount) > 0 ? (capacity - attendeesCount) : 0;

  factory SpaceEvent.fromJson(Map<String, dynamic> json) {
    return SpaceEvent(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Untitled Event',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      // Backend uses 'startDate', so we map it here
      date: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : DateTime.now(),
      location: json['location'] is Map
          ? (json['location']['address'] ?? json['location']?.toString() ?? '')
          : (json['location']?.toString() ?? ''),
      hostId: json['uid'] is Map ? json['uid']['_id'] : (json['uid'] ?? ''),
      isOnline: json['isOnline'] == true,
      meetingLink: json['meetingLink']?.toString(),
      hostName: json['uid'] is Map ? json['uid']['name'] : null,
      hostAvatar: json['uid'] is Map ? json['uid']['photoURL'] : null,
      attendeesCount: json['attendeesCount'] ?? 0,
      isJoined: json['joinedByMe'] ?? false,
      
      price: json['price'] ?? 0,
      capacity: json['capacity'] ?? 50,
      coverUrl: json['coverUrl']?.toString(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  SpaceEvent copyWith({
    bool? isJoined,
    int? attendeesCount,
  }) {
    return SpaceEvent(
      id: id,
      title: title,
      description: description,
      category: category,
      date: date,
      location: location,
      hostId: hostId,
      hostName: hostName,
      hostAvatar: hostAvatar,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      isJoined: isJoined ?? this.isJoined,
      isOnline: isOnline,
      meetingLink: meetingLink,
      price: price,
      capacity: capacity,
      coverUrl: coverUrl,
      updatedAt: updatedAt,
    );
  }
}