import 'package:hive/hive.dart';

// ── HabitModel (typeId 0) ─────────────────────────────────────────
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

  HabitModel({
    required this.id, required this.name, required this.icon,
    required this.colorIndex, required this.category, required this.frequency,
    required this.createdAt, this.note='', this.isArchived=false,
    this.sortOrder=0, List<String>? completedDates, List<int>? customDays,
  }) : completedDates=completedDates??[], customDays=customDays??[];

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  bool isCompletedOn(DateTime d) => completedDates.contains(_fmt(d));

  bool isDueOn(DateTime d) {
    switch(frequency) {
      case 'Daily':        return true;
      case 'Weekdays':     return d.weekday<=5;
      case 'Weekends':     return d.weekday>=6;
      case '3x per week':  return [1,3,5].contains(d.weekday);
      case '4x per week':  return [1,2,4,5].contains(d.weekday);
      case 'Custom':       return customDays.contains(d.weekday);
      default:             return true;
    }
  }

  void toggle(DateTime d) {
    final k=_fmt(d);
    if(completedDates.contains(k)) completedDates.remove(k); else completedDates.add(k);
    save();
  }

  int get currentStreak {
    int streak=0;
    final now=DateTime.now();
    for(int i=0;i<365;i++){
      final d=DateTime(now.year,now.month,now.day-i);
      if(!isDueOn(d)) continue;
      if(isCompletedOn(d)) streak++; else if(i>0) break;
    }
    return streak;
  }

  int get longestStreak {
    if(completedDates.isEmpty) return 0;
    final dates=completedDates.map((s)=>DateTime.parse(s)).toList()..sort();
    int best=1,cur=1;
    for(int i=1;i<dates.length;i++){
      if(dates[i].difference(dates[i-1]).inDays==1){cur++;if(cur>best)best=cur;}else cur=1;
    }
    return best;
  }

  int get totalCompletions => completedDates.length;

  double completionRate(int days) {
    int due=0,done=0;
    for(int i=0;i<days;i++){
      final d=DateTime.now().subtract(Duration(days:i));
      final day=DateTime(d.year,d.month,d.day);
      if(isDueOn(day)){due++;if(isCompletedOn(day))done++;}
    }
    return due>0?done/due:0;
  }

  List<bool> last7() => List.generate(7,(i){
    final d=DateTime.now().subtract(Duration(days:6-i));
    return isCompletedOn(DateTime(d.year,d.month,d.day));
  });

  // Heatmap: completions per day for past N days
  Map<DateTime,int> heatmapData(int days) {
    final map=<DateTime,int>{};
    for(int i=0;i<days;i++){
      final d=DateTime.now().subtract(Duration(days:i));
      final day=DateTime(d.year,d.month,d.day);
      if(isCompletedOn(day)) map[day]=1;
    }
    return map;
  }
}

class HabitAdapter extends TypeAdapter<HabitModel> {
  @override final int typeId=0;
  @override HabitModel read(BinaryReader r) {
    final n=r.readByte(); final f=<int,dynamic>{for(var i=0;i<n;i++) r.readByte():r.read()};
    return HabitModel(id:f[0],name:f[1],icon:f[2],colorIndex:f[3],category:f[4],
        frequency:f[5],completedDates:(f[6] as List).cast<String>(),createdAt:f[7],
        note:f[8]??'',isArchived:f[9]??false,
        customDays:f[10]!=null?(f[10] as List).cast<int>():[],sortOrder:f[11]??0);
  }
  @override void write(BinaryWriter w,HabitModel o)=>w
    ..writeByte(12)
    ..writeByte(0)..write(o.id)      ..writeByte(1)..write(o.name)
    ..writeByte(2)..write(o.icon)    ..writeByte(3)..write(o.colorIndex)
    ..writeByte(4)..write(o.category)..writeByte(5)..write(o.frequency)
    ..writeByte(6)..write(o.completedDates)..writeByte(7)..write(o.createdAt)
    ..writeByte(8)..write(o.note)    ..writeByte(9)..write(o.isArchived)
    ..writeByte(10)..write(o.customDays)..writeByte(11)..write(o.sortOrder);
}

// ── JournalModel (typeId 1) ───────────────────────────────────────
@HiveType(typeId: 1)
class JournalModel extends HiveObject {
  @HiveField(0) late String   id;
  @HiveField(1) late DateTime date;
  @HiveField(2) late int      moodIndex; // 0=Great..4=Rough
  @HiveField(3) late String   note;

  JournalModel({required this.id, required this.date, required this.moodIndex, this.note=''});
}

class JournalAdapter extends TypeAdapter<JournalModel> {
  @override final int typeId=1;
  @override JournalModel read(BinaryReader r) {
    final n=r.readByte(); final f=<int,dynamic>{for(var i=0;i<n;i++) r.readByte():r.read()};
    return JournalModel(id:f[0],date:f[1],moodIndex:f[2],note:f[3]??'');
  }
  @override void write(BinaryWriter w,JournalModel o)=>w
    ..writeByte(4)
    ..writeByte(0)..write(o.id)..writeByte(1)..write(o.date)
    ..writeByte(2)..write(o.moodIndex)..writeByte(3)..write(o.note);
}
