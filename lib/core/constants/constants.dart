class K {
  static const habitBox   = 'hf_habits';
  static const journalBox = 'hf_journal';
  static const settingBox = 'hf_settings';

  static const List<String> habitIcons = [
    '💪','🏃','🧘','📚','💧','🥗','😴','🎯','✍️','🎵',
    '🧹','💊','🚴','🏊','🧠','🌅','☕','🌿','🎨','🙏',
    '📝','💻','🏋️','🌙','🤸','🥤','❤️','🎤','🌳','⚡',
  ];
  static const List<String> frequencies = ['Daily','Weekdays','Weekends','3x per week','4x per week','Custom'];
  static const List<String> categories  = ['Health','Fitness','Learning','Mindfulness','Productivity','Social','Finance','Creative','Other'];
  static const Map<String,String> catIcons = {'Health':'❤️','Fitness':'💪','Learning':'📚','Mindfulness':'🧘','Productivity':'🎯','Social':'👥','Finance':'💰','Creative':'🎨','Other':'⭐'};
  static const List<String> moods      = ['😄','😊','😐','😔','😢'];
  static const List<String> moodLabels = ['Great','Good','Okay','Low','Rough'];
}
