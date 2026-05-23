import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import '../models/habit_model.dart';
import '../../core/constants/constants.dart';

// ── JournalModel (typeId 1) ───────────────────────────────────────
@HiveType(typeId: 1)
class JournalModel extends HiveObject {
  @HiveField(0) late String   id;
  @HiveField(1) late DateTime date;
  @HiveField(2) late int      moodIndex;
  @HiveField(3) late String   note;
  JournalModel({required this.id, required this.date, required this.moodIndex, this.note = ''});
  Map<String,dynamic> toJson()=>{'id':id,'date':date.toIso8601String(),'mood':moodIndex,'note':note};
}
class JournalAdapter extends TypeAdapter<JournalModel> {
  @override final int typeId=1;
  @override JournalModel read(BinaryReader r){
    final n=r.readByte(); final f=<int,dynamic>{for(var i=0;i<n;i++) r.readByte():r.read()};
    return JournalModel(id:f[0],date:f[1],moodIndex:f[2],note:f[3]??'');
  }
  @override void write(BinaryWriter w,JournalModel o)=>w..writeByte(4)..writeByte(0)..write(o.id)..writeByte(1)..write(o.date)..writeByte(2)..write(o.moodIndex)..writeByte(3)..write(o.note);
}

// ── DB ────────────────────────────────────────────────────────────
class DB {
  static late Box<HabitModel>   _habits;
  static late Box<JournalModel> _journal;
  static late Box               _settings;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(JournalAdapter());
    _habits   = await Hive.openBox<HabitModel>(K.habitBox);
    _journal  = await Hive.openBox<JournalModel>(K.journalBox);
    _settings = await Hive.openBox(K.settingBox);
    final seeded=_settings.get('seeded',defaultValue:false);
    if(!seeded){await _seed();await _settings.put('seeded',true);}
  }

  static Future<void> _seed() async {
    final samples=[
      HabitModel(id:'seed1',name:'Morning Run',icon:'🏃',colorIndex:2,category:'Fitness',frequency:'Daily',createdAt:DateTime.now().subtract(const Duration(days:14))),
      HabitModel(id:'seed2',name:'Read 20 Pages',icon:'📚',colorIndex:0,category:'Learning',frequency:'Daily',createdAt:DateTime.now().subtract(const Duration(days:10))),
      HabitModel(id:'seed3',name:'Drink 8 Glasses',icon:'💧',colorIndex:3,category:'Health',frequency:'Daily',createdAt:DateTime.now().subtract(const Duration(days:7))),
      HabitModel(id:'seed4',name:'Meditate',icon:'🧘',colorIndex:4,category:'Mindfulness',frequency:'Daily',createdAt:DateTime.now().subtract(const Duration(days:5))),
      HabitModel(id:'seed5',name:'No Social Media',icon:'📵',colorIndex:1,category:'Productivity',frequency:'Weekdays',createdAt:DateTime.now().subtract(const Duration(days:3))),
    ];
    final now=DateTime.now();
    for(int hi=0;hi<samples.length;hi++){
      final h=samples[hi];
      for(int i=1;i<=12;i++){
        if(i%(hi+1)!=0){
          final d=DateTime(now.year,now.month,now.day-i);
          if(h.isDueOn(d))h.completedDates.add('${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}');
        }
      }
      h.sortOrder=hi;
      await _habits.put(h.id,h);
    }
  }

  // Habits
  static List<HabitModel> all()          => _habits.values.where((h)=>!h.isArchived).toList()..sort((a,b)=>a.sortOrder.compareTo(b.sortOrder));
  static List<HabitModel> archived()     => _habits.values.where((h)=>h.isArchived).toList();
  static Future<void> save(HabitModel h) => _habits.put(h.id,h);
  static Future<void> delete(String id)  => _habits.delete(id);

  // Journal
  static List<JournalModel> allJournals()        => _journal.values.toList()..sort((a,b)=>b.date.compareTo(a.date));
  static Future<void> saveJournal(JournalModel j) => _journal.put(j.id,j);
  static Future<void> deleteJournal(String id)    => _journal.delete(id);
  static bool _sd(DateTime a,DateTime b)=>a.year==b.year&&a.month==b.month&&a.day==b.day;
  static JournalModel? journalForDate(DateTime d){
    try{return _journal.values.firstWhere((j)=>_sd(j.date,d));}catch(_){return null;}
  }

  // Settings
  static bool   darkMode()  => _settings.get('dark',      defaultValue:true);
  static String userName()  => _settings.get('name',      defaultValue:'Friend');
  static bool   onboarded() => _settings.get('onboarded', defaultValue:false);
  static Future<void> setDark(bool v)      => _settings.put('dark',v);
  static Future<void> setName(String v)    => _settings.put('name',v);
  static Future<void> setOnboarded(bool v) => _settings.put('onboarded',v);

  // BUG FIX #1: clearAll resets everything + triggers re-seed
  static Future<void> clearAll() async {
    await _habits.clear();
    await _journal.clear();
    await _settings.put('seeded',false);
  }

  // Enhancement #5: Export/Import JSON
  static Map<String,dynamic> exportToJson()=>{
    'version':3,'exportedAt':DateTime.now().toIso8601String(),
    'habits':_habits.values.map((h)=>h.toJson()).toList(),
    'journals':_journal.values.map((j)=>j.toJson()).toList(),
    'settings':{'name':userName(),'dark':darkMode()},
  };

  static Future<void> importFromJson(Map<String,dynamic> data) async {
    await _habits.clear();await _journal.clear();
    for(final h in (data['habits'] as List? ?? [])) await _habits.put(h['id'],HabitModel.fromJson(h as Map<String,dynamic>));
    for(final j in (data['journals'] as List? ?? [])) await _journal.put(j['id'],JournalModel(id:j['id'],date:DateTime.parse(j['date']),moodIndex:j['mood']??0,note:j['note']??''));
    final s=data['settings'] as Map? ?? {};
    if(s['name']!=null)await setName(s['name']);
    if(s['dark']!=null)await setDark(s['dark']);
  }
}
