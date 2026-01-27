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
  
  final int price; 
  final int capacity;

  // ✅ NEW FIELDS
  final String? coverUrl;
  final String? videoUrl;
  final String? meetingLink;
  final String? instructions;
  final List<Map<String, dynamic>> faqs;

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
    this.price = 0,
    this.capacity = 100,
    this.coverUrl,
    this.videoUrl,
    this.meetingLink,
    this.instructions,
    this.faqs = const [],
  });

  int get joined => attendeesCount;
  int get spotsLeft => (capacity - attendeesCount) > 0 ? (capacity - attendeesCount) : 0;

  factory SpaceEvent.fromJson(Map<String, dynamic> json) {
    return SpaceEvent(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Untitled Event',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      date: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : DateTime.now(),
      location: json['location'] ?? 'Online',
      hostId: json['hostUid'] is Map ? json['hostUid']['_id'] : (json['hostUid'] ?? ''),
      hostName: json['hostUid'] is Map ? json['hostUid']['name'] : null,
      hostAvatar: json['hostUid'] is Map ? json['hostUid']['photoURL'] : null,
      attendeesCount: json['attendeesCount'] ?? 0,
      isJoined: json['joinedByMe'] ?? false,
      price: json['price'] ?? 0,
      capacity: json['capacity'] ?? 50,
      
      // ✅ Map new fields
      coverUrl: json['coverUrl'],
      videoUrl: json['videoUrl'],
      meetingLink: json['meetingLink'],
      instructions: json['instructions'],
      faqs: json['faqs'] != null 
          ? List<Map<String, dynamic>>.from(json['faqs']) 
          : [],
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
      price: price,
      capacity: capacity,
      coverUrl: coverUrl,
      videoUrl: videoUrl,
      meetingLink: meetingLink,
      instructions: instructions,
      faqs: faqs,
    );
  }
}