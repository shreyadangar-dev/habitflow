import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class HabitModel extends HiveObject {
  @HiveField(0)  late String id;
  @HiveField(1)  late String name;
  @HiveField(2)  late String icon;
  @HiveField(3)  late int    colorIndex;
  @HiveField(4)  late String category;
  @HiveField(5)  late String frequency;
  @HiveField(6)  late List<String> completedDates;
  @HiveField(7)  late DateTime createdAt;
  @HiveField(8)  late String note;
  @HiveField(9)  late bool   isArchived;
  @HiveField(10) late List<int> customDays;
  @HiveField(11) late int    sortOrder;
  @HiveField(12) late bool   reminderOn;
  @HiveField(13) late int    reminderHour;
  @HiveField(14) late int    reminderMinute;

  HabitModel({
    required this.id, required this.name, required this.icon,
    required this.colorIndex, required this.category, required this.frequency,
    required this.createdAt, this.note = '', this.isArchived = false,
    this.sortOrder = 0, this.reminderOn = false,
    this.reminderHour = 8, this.reminderMinute = 0,
    List<String>? completedDates, List<int>? customDays,
  }) : completedDates = completedDates ?? [], customDays = customDays ?? [];

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  bool isCompletedOn(DateTime d) => completedDates.contains(_fmt(d));

  bool isDueOn(DateTime d) {
    switch (frequency) {
      case 'Daily':       return true;
      case 'Weekdays':    return d.weekday <= 5;
      case 'Weekends':    return d.weekday >= 6;
      case '3x per week': return [1, 3, 5].contains(d.weekday);
      case '4x per week': return [1, 2, 4, 5].contains(d.weekday);
      case 'Custom':      return customDays.contains(d.weekday);
      default:            return true;
    }
  }

  void toggle(DateTime d) {
    final key = _fmt(d);
    if (completedDates.contains(key)) completedDates.remove(key);
    else completedDates.add(key);
    save();
  }

  int get currentStreak {
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final d = DateTime(now.year, now.month, now.day - i);
      if (!isDueOn(d)) continue; // BUG FIX #3: skip non-due days
      if (isCompletedOn(d)) streak++;
      else if (i > 0) break;
    }
    return streak;
  }

  // BUG FIX #3: longestStreak now skips non-due days
  int get longestStreak {
    if (completedDates.isEmpty) return 0;
    final dates = completedDates.map((s) => DateTime.parse(s)).toList()..sort();
    int best = 1, cur = 1;
    for (int i = 1; i < dates.length; i++) {
      // Count days between completions, skipping non-due days
      final diff = dates[i].difference(dates[i-1]).inDays;
      // Count non-due days between the two dates
      int nonDueDays = 0;
      for (int j = 1; j < diff; j++) {
        final between = dates[i-1].add(Duration(days: j));
        if (!isDueOn(between)) nonDueDays++;
      }
      if (diff - nonDueDays == 1) {
        cur++;
        if (cur > best) best = cur;
      } else {
        cur = 1;
      }
    }
    return best;
  }

  int get totalCompletions => completedDates.length;

  double completionRate(int days) {
    int due = 0, done = 0;
    for (int i = 0; i < days; i++) {
      final d = DateTime.now().subtract(Duration(days: i));
      final day = DateTime(d.year, d.month, d.day);
      if (isDueOn(day)) { due++; if (isCompletedOn(day)) done++; }
    }
    return due > 0 ? done / due : 0;
  }

  List<bool> last7() => List.generate(7, (i) {
    final d = DateTime.now().subtract(Duration(days: 6 - i));
    return isCompletedOn(DateTime(d.year, d.month, d.day));
  });

  // Export to JSON
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'icon': icon, 'colorIndex': colorIndex,
    'category': category, 'frequency': frequency,
    'completedDates': completedDates, 'createdAt': createdAt.toIso8601String(),
    'note': note, 'isArchived': isArchived, 'customDays': customDays,
    'sortOrder': sortOrder,
  };

  static HabitModel fromJson(Map<String, dynamic> j) => HabitModel(
    id: j['id'], name: j['name'], icon: j['icon'], colorIndex: j['colorIndex'],
    category: j['category'], frequency: j['frequency'],
    completedDates: (j['completedDates'] as List?)?.cast<String>() ?? [],
    createdAt: DateTime.parse(j['createdAt']), note: j['note'] ?? '',
    isArchived: j['isArchived'] ?? false,
    customDays: (j['customDays'] as List?)?.cast<int>() ?? [],
    sortOrder: j['sortOrder'] ?? 0,
  );
}

class HabitAdapter extends TypeAdapter<HabitModel> {
  @override final int typeId = 0;
  @override
  HabitModel read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{for (var i = 0; i < n; i++) r.readByte(): r.read()};
    return HabitModel(
      id: f[0], name: f[1], icon: f[2], colorIndex: f[3],
      category: f[4], frequency: f[5],
      completedDates: (f[6] as List).cast<String>(),
      createdAt: f[7], note: f[8] ?? '', isArchived: f[9] ?? false,
      customDays: f[10] != null ? (f[10] as List).cast<int>() : [],
      sortOrder: f[11] ?? 0,
      reminderOn: f[12] ?? false,
      reminderHour: f[13] ?? 8,
      reminderMinute: f[14] ?? 0,
    );
  }
  @override
  void write(BinaryWriter w, HabitModel o) => w
    ..writeByte(15)
    ..writeByte(0)..write(o.id)       ..writeByte(1)..write(o.name)
    ..writeByte(2)..write(o.icon)     ..writeByte(3)..write(o.colorIndex)
    ..writeByte(4)..write(o.category) ..writeByte(5)..write(o.frequency)
    ..writeByte(6)..write(o.completedDates) ..writeByte(7)..write(o.createdAt)
    ..writeByte(8)..write(o.note)     ..writeByte(9)..write(o.isArchived)
    ..writeByte(10)..write(o.customDays) ..writeByte(11)..write(o.sortOrder)
    ..writeByte(12)..write(o.reminderOn) ..writeByte(13)..write(o.reminderHour)
    ..writeByte(14)..write(o.reminderMinute);
}
