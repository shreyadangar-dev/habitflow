import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../data/db/db.dart';

class SetState { final bool dark; final String name; final bool onboarded;
  const SetState({this.dark=true,this.name='Shreya',this.onboarded=false});
  SetState cp({bool? dark,String? name,bool? onboarded})=>SetState(dark:dark??this.dark,name:name??this.name,onboarded:onboarded??this.onboarded);
}
class SetNotifier extends StateNotifier<SetState> {
  SetNotifier():super(const SetState()){_load();}
  void _load()=>state=state.cp(dark:DB.darkMode(),name:DB.userName(),onboarded:DB.onboarded());
  Future<void> setDark(bool v) async {await DB.setDark(v);state=state.cp(dark:v);}
  Future<void> setName(String v) async {await DB.setName(v);state=state.cp(name:v);}
  Future<void> setOnboarded() async {await DB.setOnboarded(true);state=state.cp(onboarded:true);}
}
final settingsProv=StateNotifierProvider<SetNotifier,SetState>((r)=>SetNotifier());

class HabitNotifier extends StateNotifier<List<HabitModel>> {
  HabitNotifier():super([]){_load();}
  void _load()=>state=DB.all();
  Future<void> add(HabitModel h) async {await DB.save(h);_load();}
  Future<void> update(HabitModel h) async {await DB.save(h);_load();}
  Future<void> delete(String id) async {await DB.delete(id);_load();}
  Future<void> toggle(HabitModel h,DateTime d) async {h.toggle(d);_load();}
  Future<void> archive(HabitModel h) async {h.isArchived=true;await DB.save(h);_load();}
  Future<void> reorder(int oldIdx,int newIdx) async {
    final list=List<HabitModel>.from(state);
    final item=list.removeAt(oldIdx);
    list.insert(newIdx,item);
    for(int i=0;i<list.length;i++){list[i].sortOrder=i;await DB.save(list[i]);}
    _load();
  }
  List<HabitModel> dueOn(DateTime d)=>state.where((h)=>h.isDueOn(d)).toList();
  int completedOn(DateTime d)=>state.where((h)=>h.isDueOn(d)&&h.isCompletedOn(d)).length;
  int dueCount(DateTime d)=>dueOn(d).length;
  double rateOn(DateTime d){final due=dueCount(d);return due>0?completedOn(d)/due:0;}
}
final habitProv=StateNotifierProvider<HabitNotifier,List<HabitModel>>((r)=>HabitNotifier());

class JournalNotifier extends StateNotifier<List<JournalModel>> {
  JournalNotifier():super([]){_load();}
  void _load()=>state=DB.allJournals();
  Future<void> save(JournalModel j) async {await DB.saveJournal(j);_load();}
  Future<void> delete(String id) async {await DB.deleteJournal(id);_load();}
  JournalModel? forDate(DateTime d)=>DB.journalForDate(d);
}
final journalProv=StateNotifierProvider<JournalNotifier,List<JournalModel>>((r)=>JournalNotifier());

final selectedDateProv=StateProvider<DateTime>((r){final n=DateTime.now();return DateTime(n.year,n.month,n.day);});
