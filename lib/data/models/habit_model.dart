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
  // Enhancement #3: Quantitative tracking
  @HiveField(15) late bool   isQuantitative;
  @HiveField(16) late double targetValue;
  @HiveField(17) late String unit;           // e.g. "glasses", "km", "minutes"
  // Enhancement #2: Set-based lookup stored as list, converted on read
  @HiveField(18) late Map<String, double> dailyValues; // date -> value achieved

  HabitModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorIndex,
    required this.category,
    required this.frequency,
    required this.createdAt,
    this.note = '',
    this.isArchived = false,
    this.sortOrder = 0,
    this.reminderOn = false,
    this.reminderHour = 8,
    this.reminderMinute = 0,
    this.isQuantitative = false,
    this.targetValue = 1,
    this.unit = 'times',
    List<String>? completedDates,
    List<int>? customDays,
    Map<String, double>? dailyValues,
  }) : completedDates = completedDates ?? [],
       customDays = customDays ?? [],
       dailyValues = dailyValues ?? {};

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  // Enhancement #2: Use Set for O(1) lookup
  late final Set<String> _completedSet = completedDates.toSet();

  // BUG FIX #1: habits only appear from createdAt onward
  bool isDueOn(DateTime d) {
    final dayStart = DateTime(d.year, d.month, d.day);
    final created  = DateTime(createdAt.year, createdAt.month, createdAt.day);
    if (dayStart.isBefore(created)) return false; // ← key fix
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

  // Enhancement #2: O(1) set lookup
  bool isCompletedOn(DateTime d) => _completedSet.contains(_fmt(d));

  void toggle(DateTime d) {
    final key = _fmt(d);
    if (_completedSet.contains(key)) {
      _completedSet.remove(key);
      completedDates.remove(key);
    } else {
      _completedSet.add(key);
      completedDates.add(key);
    }
    save();
  }

  // Quantitative: log a value for a day
  void logValue(DateTime d, double value) {
    final key = _fmt(d);
    dailyValues[key] = value;
    if (value >= targetValue) {
      if (!_completedSet.contains(key)) {
        _completedSet.add(key);
        completedDates.add(key);
      }
    } else {
      _completedSet.remove(key);
      completedDates.remove(key);
    }
    save();
  }

  double getValueFor(DateTime d) => dailyValues[_fmt(d)] ?? 0;

  int get currentStreak {
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final d = DateTime(now.year, now.month, now.day - i);
      if (!isDueOn(d)) continue;
      if (isCompletedOn(d)) streak++;
      else if (i > 0) break;
    }
    return streak;
  }

  int get longestStreak {
    if (completedDates.isEmpty) return 0;
    final dates = completedDates.map((s) => DateTime.parse(s)).toList()..sort();
    int best = 1, cur = 1;
    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i-1]).inDays;
      int nonDue = 0;
      for (int j = 1; j < diff; j++) {
        if (!isDueOn(dates[i-1].add(Duration(days: j)))) nonDue++;
      }
      if (diff - nonDue == 1) { cur++; if (cur > best) best = cur; }
      else cur = 1;
    }
    return best;
  }

  int    get totalCompletions => completedDates.length;

  double completionRate(int days) {
    int due = 0, done = 0;
    for (int i = 0; i < days; i++) {
      final d   = DateTime.now().subtract(Duration(days: i));
      final day = DateTime(d.year, d.month, d.day);
      if (isDueOn(day)) { due++; if (isCompletedOn(day)) done++; }
    }
    return due > 0 ? done / due : 0;
  }

  List<bool> last7() => List.generate(7, (i) {
    final d = DateTime.now().subtract(Duration(days: 6 - i));
    return isCompletedOn(DateTime(d.year, d.month, d.day));
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'icon': icon, 'colorIndex': colorIndex,
    'category': category, 'frequency': frequency,
    'completedDates': completedDates,
    'createdAt': createdAt.toIso8601String(),
    'note': note, 'isArchived': isArchived,
    'customDays': customDays, 'sortOrder': sortOrder,
    'isQuantitative': isQuantitative,
    'targetValue': targetValue, 'unit': unit,
    'dailyValues': dailyValues,
  };

  static HabitModel fromJson(Map<String, dynamic> j) => HabitModel(
    id: j['id'], name: j['name'], icon: j['icon'],
    colorIndex: j['colorIndex'], category: j['category'],
    frequency: j['frequency'],
    completedDates: (j['completedDates'] as List?)?.cast<String>() ?? [],
    createdAt: DateTime.parse(j['createdAt']),
    note: j['note'] ?? '', isArchived: j['isArchived'] ?? false,
    customDays: (j['customDays'] as List?)?.cast<int>() ?? [],
    sortOrder: j['sortOrder'] ?? 0,
    isQuantitative: j['isQuantitative'] ?? false,
    targetValue: (j['targetValue'] ?? 1).toDouble(),
    unit: j['unit'] ?? 'times',
    dailyValues: (j['dailyValues'] as Map?)?.map((k,v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {},
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
      createdAt: f[7], note: f[8] ?? '',
      isArchived: f[9] ?? false,
      customDays: f[10] != null ? (f[10] as List).cast<int>() : [],
      sortOrder: f[11] ?? 0,
      reminderOn: f[12] ?? false,
      reminderHour: f[13] ?? 8,
      reminderMinute: f[14] ?? 0,
      isQuantitative: f[15] ?? false,
      targetValue: f[16] != null ? (f[16] as num).toDouble() : 1.0,
      unit: f[17] ?? 'times',
      dailyValues: f[18] != null
          ? (f[18] as Map).map((k,v) => MapEntry(k.toString(), (v as num).toDouble()))
          : {},
    );
  }
  @override
  void write(BinaryWriter w, HabitModel o) => w
    ..writeByte(19)
    ..writeByte(0)..write(o.id)         ..writeByte(1)..write(o.name)
    ..writeByte(2)..write(o.icon)       ..writeByte(3)..write(o.colorIndex)
    ..writeByte(4)..write(o.category)   ..writeByte(5)..write(o.frequency)
    ..writeByte(6)..write(o.completedDates) ..writeByte(7)..write(o.createdAt)
    ..writeByte(8)..write(o.note)       ..writeByte(9)..write(o.isArchived)
    ..writeByte(10)..write(o.customDays)..writeByte(11)..write(o.sortOrder)
    ..writeByte(12)..write(o.reminderOn)..writeByte(13)..write(o.reminderHour)
    ..writeByte(14)..write(o.reminderMinute)
    ..writeByte(15)..write(o.isQuantitative)
    ..writeByte(16)..write(o.targetValue)
    ..writeByte(17)..write(o.unit)
    ..writeByte(18)..write(o.dailyValues);
}
