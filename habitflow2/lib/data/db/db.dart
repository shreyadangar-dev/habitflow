import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/helpers.dart';
import 'package:uuid/uuid.dart';

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
    // Seed sample data on first launch
    final seeded = _settings.get('seeded', defaultValue: false);
    if (!seeded) { await _seedSampleHabits(); await _settings.put('seeded', true); }
  }

  static Future<void> _seedSampleHabits() async {
    final samples = [
      HabitModel(id:const Uuid().v4(),name:'Morning Run',icon:'🏃',colorIndex:2,category:'Fitness',frequency:'Daily',createdAt:DateTime.now().subtract(const Duration(days:14)),note:'30 min jog around the park'),
      HabitModel(id:const Uuid().v4(),name:'Read 20 Pages',icon:'📚',colorIndex:0,category:'Learning',frequency:'Daily',createdAt:DateTime.now().subtract(const Duration(days:10)),note:'Read before bedtime'),
      HabitModel(id:const Uuid().v4(),name:'Drink 8 Glasses',icon:'💧',colorIndex:3,category:'Health',frequency:'Daily',createdAt:DateTime.now().subtract(const Duration(days:7)),note:'Stay hydrated!'),
      HabitModel(id:const Uuid().v4(),name:'Meditate',icon:'🧘',colorIndex:4,category:'Mindfulness',frequency:'Daily',createdAt:DateTime.now().subtract(const Duration(days:5)),note:'10 min morning meditation'),
      HabitModel(id:const Uuid().v4(),name:'No Social Media',icon:'📵',colorIndex:1,category:'Productivity',frequency:'Weekdays',createdAt:DateTime.now().subtract(const Duration(days:3)),note:'Focus on deep work'),
    ];
    // Add some past completions to make it look used
    final now = DateTime.now();
    for (int hi = 0; hi < samples.length; hi++) {
      final h = samples[hi];
      for (int i = 1; i <= 12; i++) {
        if (i % (hi + 1) != 0) { // vary completions per habit
          final d = DateTime(now.year, now.month, now.day - i);
          if (h.isDueOn(d)) {
            final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
            h.completedDates.add(key);
          }
        }
      }
      h.sortOrder = hi;
      await _habits.put(h.id, h);
    }
  }

  // Habits
  static List<HabitModel> all()          => _habits.values.where((h)=>!h.isArchived).toList()..sort((a,b)=>a.sortOrder.compareTo(b.sortOrder));
  static List<HabitModel> archived()     => _habits.values.where((h)=>h.isArchived).toList();
  static Future<void> save(HabitModel h) => _habits.put(h.id, h);
  static Future<void> delete(String id)  => _habits.delete(id);

  // Journal
  static List<JournalModel> allJournals()        => _journal.values.toList()..sort((a,b)=>b.date.compareTo(a.date));
  static Future<void> saveJournal(JournalModel j) => _journal.put(j.id, j);
  static Future<void> deleteJournal(String id)    => _journal.delete(id);
  static JournalModel? journalForDate(DateTime d) {
    try { return _journal.values.firstWhere((j)=>H.sameDay(j.date,d)); } catch(_) { return null; }
  }

  // Settings
  static bool   darkMode()  => _settings.get('dark',  defaultValue:true);
  static String userName()  => _settings.get('name',  defaultValue:'Shreya');
  static bool   onboarded() => _settings.get('onboarded', defaultValue:false);
  static Future<void> setDark(bool v)       => _settings.put('dark', v);
  static Future<void> setName(String v)     => _settings.put('name', v);
  static Future<void> setOnboarded(bool v)  => _settings.put('onboarded', v);
  static Future<void> clearAll() async { await _habits.clear(); await _journal.clear(); await _settings.put('seeded',false); }
}
