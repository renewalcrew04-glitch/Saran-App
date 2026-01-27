class PostCategories {
  static const String forYou = "For You";
  static const String following = "Following";

  static const List<String> categories = [
    "Wellness",
    "Career",
    "Lifestyle",
    "Motherhood",
    "Relationships",
    "Creativity",
    "Travel",
    "Inspiration",
    "Beauty",
    "Fitness",
    "Food",
    "Fashion",
    "Education",
  ];

  static const List<String> homeChips = [
    forYou,
    following,
    ...categories,
  ];
}
