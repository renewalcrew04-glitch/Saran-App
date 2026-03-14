class VoiceProfile {

  final String id;
  final String gender;

  const VoiceProfile(this.id, this.gender);

}

class VoiceProfiles {

  static const List<VoiceProfile> female = [

    VoiceProfile("saran_luna","female"),
    VoiceProfile("saran_maya","female"),
    VoiceProfile("saran_aria","female"),
    VoiceProfile("saran_kavya","female"),
    VoiceProfile("saran_meera","female"),

  ];

  static const List<VoiceProfile> male = [

    VoiceProfile("saran_arjun","male"),
    VoiceProfile("saran_dev","male"),
    VoiceProfile("saran_karthik","male"),
    VoiceProfile("saran_vikram","male"),
    VoiceProfile("saran_rahul","male"),

  ];

}