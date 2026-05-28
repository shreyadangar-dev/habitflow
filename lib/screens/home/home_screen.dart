import 'package:table_calendar/table_calendar.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/habit_model.dart';
import '../../data/db/db.dart';
import '../../providers/providers.dart';
import '../add_habit/add_habit_screen.dart';
import '../analytics/analytics_screen.dart';
import '../achievements/achievements_screen.dart';
import '../journal/journal_screen.dart';
import '../settings/settings_screen.dart';
import '../detail/habit_detail_screen.dart';
import '../archive/archive_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override ConsumerState<HomeScreen> createState()=>_S();
}
class _S extends ConsumerState<HomeScreen> {
  late ConfettiController _confetti;
  double _lastRate=0;

  @override void initState(){super.initState();_confetti=ConfettiController(duration:const Duration(seconds:2));}
  @override void dispose(){_confetti.dispose();super.dispose();}

  void _checkConfetti(double rate){
    if(rate>=1.0&&_lastRate<1.0)_confetti.play();
    _lastRate=rate;
  }

  @override
  Widget build(BuildContext context){
    final habits=ref.watch(habitProv);
    final sel=ref.watch(selectedDateProv);
    final settings=ref.watch(settingsProv);
    final notifier=ref.read(habitProv.notifier);
    final rate=notifier.rateOn(sel);
    _checkConfetti(rate);
    final dueOnSel=habits.where((h)=>h.isDueOn(sel)).toList();
    final doneCount=notifier.completedOn(sel);
    final dueCount=notifier.dueCount(sel);

    return Scaffold(
      backgroundColor:TH.bg(context),
      body:Stack(children:[
        CustomScrollView(physics:const BouncingScrollPhysics(),slivers:[
          SliverToBoxAdapter(child:_Header(name:settings.name,
            onAnalytics:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AnalyticsScreen())),
            onAchievements:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AchievementsScreen())),
            onJournal:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const JournalScreen())),
            onSettings:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SettingsScreen())),
          )),
          SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(20,0,20,16),
            child:_TodayCard(done:doneCount,total:dueCount,rate:rate).animate().fadeIn(delay:100.ms))),
          // Quote
          SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(20,0,20,14),
            child:_QuoteCard().animate().fadeIn(delay:150.ms))),
          // 7-day selector
          SliverToBoxAdapter(child:SizedBox(height:72,
            child:ListView.builder(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:20),
              itemCount:14,itemBuilder:(_,i)=>_DayDot(offset:i-13,ref:ref))).animate().fadeIn(delay:200.ms)),
          const SliverToBoxAdapter(child:SizedBox(height:10)),
          // Habit list header
          SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(20,4,20,4),
            child:Row(children:[
              Text(H.sameDay(sel,H.today())?"Today's Habits":"Habits — ${H.shortDate(sel)}",
                style:TextStyle(fontSize:17,fontWeight:FontWeight.w700,color:TH.text(context))),
              const Spacer(),
              if(dueOnSel.isNotEmpty)Text('$doneCount/$dueCount',style:TextStyle(fontSize:12,color:TH.muted(context),fontWeight:FontWeight.w500)),
            ]))),
          // Draggable habit list
          dueOnSel.isEmpty
            ? SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.only(top:40),
                child:Column(children:[
                  const Text('🎉',style:TextStyle(fontSize:48)),const SizedBox(height:12),
                  Text(habits.isEmpty?'No habits yet!':'Rest day — enjoy it!',
                    style:TextStyle(fontSize:16,fontWeight:FontWeight.w600,color:TH.text(context))),
                  const SizedBox(height:6),
                  Text(habits.isEmpty?'Tap + to create your first habit':'Nothing scheduled today 🌿',
                    style:TextStyle(color:TH.muted(context))),
                ])))
            : SliverReorderableList(
                onReorder:(o,n)=>ref.read(habitProv.notifier).reorder(o,n>o?n-1:n),
                itemCount:dueOnSel.length,
                itemBuilder:(_,i)=>KeyedSubtree(
                    key:Key(dueOnSel[i].id),
                    child:_HabitTile(
                      habit:dueOnSel[i], date:sel, index:i,
                      onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>HabitDetailScreen(habit:dueOnSel[i]))),
                      onToggle:()=>ref.read(habitProv.notifier).toggle(dueOnSel[i],sel),
                      onReload:()=>ref.read(habitProv.notifier).reload(),
                    ).animate().fadeIn(delay:Duration(milliseconds:50*i))),
                ),
          const SliverToBoxAdapter(child:SizedBox(height:100)),
        ]),
        // Confetti
        Align(alignment:Alignment.topCenter,child:ConfettiWidget(
          confettiController:_confetti,blastDirectionality:BlastDirectionality.explosive,
          particleDrag:0.05,emissionFrequency:0.07,numberOfParticles:20,gravity:0.2,
          colors:const[AC.primary,AC.success,AC.warning,AC.pink,Colors.white])),
      ]),
      floatingActionButton:FloatingActionButton.extended(
        onPressed:()=>showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(_)=>const AddHabitScreen()),
        backgroundColor:AC.primary,
        icon:const Icon(Iconsax.add,color:Colors.white),
        label:const Text('New Habit',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w600)),
      ).animate().scale(delay:500.ms,curve:Curves.elasticOut),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final VoidCallback onAnalytics,onAchievements,onJournal,onSettings;
  const _Header({required this.name,required this.onAnalytics,required this.onAchievements,required this.onJournal,required this.onSettings});
  @override
  Widget build(BuildContext context){
    final h=DateTime.now().hour;
    final g=h<12?'☀️ Morning':h<17?'🌤 Afternoon':'🌙 Evening';
    return Container(
      padding:EdgeInsets.only(top:MediaQuery.of(context).padding.top+12,left:20,right:20,bottom:14),
      child:Row(children:[
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Good $g',style:TextStyle(fontSize:13,color:TH.sub(context))),
          Text(name,style:TextStyle(fontSize:24,fontWeight:FontWeight.w800,color:TH.text(context),letterSpacing:-0.5)),
        ])),
        _btn(context,Iconsax.chart_21,onAnalytics),const SizedBox(width:8),
        _btn(context,Iconsax.medal,onAchievements),const SizedBox(width:8),
        _btn(context,Iconsax.note_21,onJournal),const SizedBox(width:8),
        _btn(context,Iconsax.setting_2,onSettings),
      ]),
    );
  }
  Widget _btn(BuildContext c,IconData ic,VoidCallback t)=>GestureDetector(onTap:t,child:Container(
    width:38,height:38,decoration:BoxDecoration(color:TH.card(c),borderRadius:BorderRadius.circular(12),border:Border.all(color:TH.border(c))),
    child:Icon(ic,color:TH.text(c),size:18)));
}

class _TodayCard extends StatelessWidget {
  final int done,total; final double rate;
  const _TodayCard({required this.done,required this.total,required this.rate});
  @override
  Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.all(20),
    decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF2D1B6B),Color(0xFF1A0E3D),Color(0xFF0D1A3D)],begin:Alignment.topLeft,end:Alignment.bottomRight),
      borderRadius:BorderRadius.circular(28),border:Border.all(color:AC.primary.withOpacity(0.3)),
      boxShadow:[BoxShadow(color:AC.primary.withOpacity(0.2),blurRadius:30,spreadRadius:2)]),
    child:Row(children:[
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text("Today's Progress",style:TextStyle(fontSize:13,color:AC.dTextSub)),
        const SizedBox(height:6),
        Text(total==0?'No habits today':'$done of $total completed',
          style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:Colors.white)),
        const SizedBox(height:6),
        Text(H.completionLabel(rate),style:const TextStyle(fontSize:13,color:AC.pLight,fontWeight:FontWeight.w500)),
        const SizedBox(height:10),
        if(total>0)ClipRRect(borderRadius:BorderRadius.circular(6),child:LinearProgressIndicator(
          value:rate,minHeight:8,backgroundColor:Colors.white.withOpacity(0.1),
          valueColor:AlwaysStoppedAnimation(rate>=1?AC.success:AC.pLight))),
      ])),
      const SizedBox(width:14),
      CircularPercentIndicator(radius:44,lineWidth:6,percent:rate.clamp(0.0,1.0),
        center:Text('${(rate*100).toInt()}%',style:const TextStyle(fontSize:13,fontWeight:FontWeight.w800,color:Colors.white)),
        progressColor:rate>=1?AC.success:AC.pLight,backgroundColor:Colors.white.withOpacity(0.1),
        circularStrokeCap:CircularStrokeCap.round),
    ]),
  );
}

class _QuoteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.all(14),
    decoration:BoxDecoration(color:TH.card(context),borderRadius:BorderRadius.circular(16),
      border:Border.all(color:TH.border(context))),
    child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('💡',style:TextStyle(fontSize:18)),const SizedBox(width:10),
      Expanded(child:Text(H.dailyQuote(),style:TextStyle(fontSize:12,color:TH.sub(context),fontStyle:FontStyle.italic,height:1.5))),
    ]));
}

class _DayDot extends ConsumerWidget {
  final int offset; final WidgetRef ref;
  const _DayDot({required this.offset,required this.ref});
  @override
  Widget build(BuildContext context,WidgetRef _){
    final now=DateTime.now();
    final day=DateTime(now.year,now.month,now.day+offset);
    final sel=ref.watch(selectedDateProv);
    final isSel=H.sameDay(day,sel);
    final isToday=H.sameDay(day,H.today());
    final isFut=day.isAfter(H.today());
    final habits=ref.watch(habitProv);
    final due=habits.where((h)=>h.isDueOn(day)).length;
    final done=habits.where((h)=>h.isDueOn(day)&&h.isCompletedOn(day)).length;
    final full=due>0&&done==due;
    return GestureDetector(
      onTap:()=>ref.read(selectedDateProv.notifier).state=day,
      child:AnimatedContainer(duration:const Duration(milliseconds:200),width:52,margin:const EdgeInsets.only(right:8),
        decoration:BoxDecoration(color:isSel?AC.primary:(full?AC.success.withOpacity(0.12):TH.card(context)),
          borderRadius:BorderRadius.circular(16),border:Border.all(color:isSel?AC.primary:(isToday?AC.primary.withOpacity(0.4):TH.border(context)))),
        child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
          Text(H.weekday(day),style:TextStyle(fontSize:10,fontWeight:FontWeight.w600,color:isSel?Colors.white:TH.muted(context))),
          const SizedBox(height:3),
          Text('${day.day}',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800,color:isSel?Colors.white:TH.text(context))),
          const SizedBox(height:3),
          if(!isFut&&due>0)Row(mainAxisAlignment:MainAxisAlignment.center,children:List.generate(due.clamp(0,3),(i)=>Container(
            width:5,height:5,margin:const EdgeInsets.symmetric(horizontal:1),
            decoration:BoxDecoration(shape:BoxShape.circle,color:i<done?(isSel?Colors.white:AC.success):(isSel?Colors.white.withOpacity(0.4):TH.muted(context))))))
          else const SizedBox(height:7),
        ])));
  }
}

class _HabitTile extends StatelessWidget {
  final HabitModel habit; final DateTime date; final int index; final VoidCallback onTap, onToggle, onReload;
  const _HabitTile({required this.habit,required this.date,required this.index,required this.onTap,required this.onToggle,required this.onReload});
  @override
  Widget build(BuildContext context){
    final color=AC.palette[habit.colorIndex%AC.palette.length];
    final done=habit.isCompletedOn(date);
    final streak=habit.currentStreak;
    return Dismissible(
      key:Key(habit.id),
      direction:DismissDirection.endToStart,
      background:Container(
        alignment:Alignment.centerRight,
        padding:const EdgeInsets.only(right:24),
        margin:const EdgeInsets.symmetric(horizontal:20,vertical:5),
        decoration:BoxDecoration(color:AC.warning.withOpacity(0.2),borderRadius:BorderRadius.circular(20)),
        child:Row(mainAxisAlignment:MainAxisAlignment.end,children:[
          const Icon(Iconsax.archive_1,color:AC.warning,size:22),
          const SizedBox(width:8),
          const Text('Archive',style:TextStyle(color:AC.warning,fontWeight:FontWeight.w700,fontSize:13)),
          const SizedBox(width:8),
        ])),
      confirmDismiss:(_) async => true,
      onDismissed:(_) async {
        habit.isArchived=true;
        await DB.save(habit);
        // Must reload immediately so dismissed widget leaves the tree
        onReload();
        if(context.mounted){
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:Text("${habit.name} archived 📦"),
            backgroundColor:AC.warning,
            behavior:SnackBarBehavior.floating,
            duration:const Duration(seconds:4),
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),
            action:SnackBarAction(label:'UNDO',textColor:Colors.white,onPressed:() async {
              habit.isArchived=false;
              await DB.save(habit);
              onReload();
            })));
        }
      },
      child:GestureDetector(
        onTap:onTap,
        onLongPress:()=>_showHabitMenu(context,habit),
        child:AnimatedContainer(duration:const Duration(milliseconds:250),
          margin:const EdgeInsets.symmetric(horizontal:20,vertical:5),
          padding:const EdgeInsets.all(14),
          decoration:BoxDecoration(color:done?color.withOpacity(0.08):TH.card(context),
            borderRadius:BorderRadius.circular(20),
            border:Border.all(color:done?color.withOpacity(0.4):TH.border(context),width:done?1.5:1)),
          child:Row(children:[
            GestureDetector(onTap:onToggle,child:AnimatedContainer(duration:const Duration(milliseconds:250),
            width:46,height:46,
            decoration:BoxDecoration(color:done?color:color.withOpacity(0.1),borderRadius:BorderRadius.circular(15),
              border:Border.all(color:color,width:done?0:1.5)),
            child:Center(child:done?const Icon(Icons.check_rounded,color:Colors.white,size:22):Text(habit.icon,style:const TextStyle(fontSize:22))))),
          const SizedBox(width:12),
          Expanded(child:GestureDetector(onTap:onTap,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(habit.name,style:TextStyle(fontSize:15,fontWeight:FontWeight.w700,
              color:done?TH.sub(context):TH.text(context),decoration:done?TextDecoration.lineThrough:null)),
            const SizedBox(height:3),
            Row(children:[
              Text(habit.category,style:TextStyle(fontSize:11,color:TH.muted(context))),
              if(streak>0)...[Text('  •  ',style:TextStyle(color:TH.muted(context))),
                Text(H.streakLabel(streak),style:const TextStyle(fontSize:11,color:AC.warning,fontWeight:FontWeight.w600))],
            ]),
          ]))),
          // Quantitative stepper
          if(habit.isQuantitative)
            Column(mainAxisAlignment:MainAxisAlignment.center,children:[
              Text('${habit.getValueFor(date).toStringAsFixed(0)}/${habit.targetValue.toStringAsFixed(0)}',
                style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:color)),
              Text(habit.unit,style:TextStyle(fontSize:9,color:TH.muted(context))),
              const SizedBox(height:4),
              Row(children:[
                GestureDetector(
                  onTap:(){final v=(habit.getValueFor(date)-1).clamp(0.0,habit.targetValue*2);habit.logValue(date,v.toDouble());onReload();},
                  child:Container(width:36,height:36,decoration:BoxDecoration(color:color.withOpacity(0.15),borderRadius:BorderRadius.circular(10),border:Border.all(color:color.withOpacity(0.3))),
                    child:Icon(Icons.remove_rounded,size:20,color:color))),
                const SizedBox(width:6),
                GestureDetector(
                  onTap:(){final v=(habit.getValueFor(date)+1).clamp(0.0,habit.targetValue*2);habit.logValue(date,v.toDouble());onReload();},
                  child:Container(width:36,height:36,decoration:BoxDecoration(color:color,borderRadius:BorderRadius.circular(10),boxShadow:[BoxShadow(color:color.withOpacity(0.3),blurRadius:6,offset:const Offset(0,2))]),
                    child:const Icon(Icons.add_rounded,size:20,color:Colors.white))),
              ]),
            ])
          else
          // Mini 7-day track
          Column(mainAxisAlignment:MainAxisAlignment.center,children:[
            Row(children:List.generate(7,(i){
              final d=DateTime.now().subtract(Duration(days:6-i));
              final day=DateTime(d.year,d.month,d.day);
              final c=habit.isCompletedOn(day);
              return Container(width:7,height:7,margin:const EdgeInsets.all(1.5),
                decoration:BoxDecoration(shape:BoxShape.circle,color:c?color:color.withOpacity(0.15)));
            })),
            const SizedBox(height:3),
            Text('7d',style:TextStyle(fontSize:9,color:TH.muted(context))),
          ]),
          const SizedBox(width:4),
          ReorderableDragStartListener(index:index,
            child:Icon(Icons.drag_handle,color:TH.muted(context),size:22)),
        ]))));
  }

  void _showHabitMenu(BuildContext context, HabitModel habit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: TH.surface(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20,20,20,32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width:40,height:4,decoration:BoxDecoration(color:TH.border(context),borderRadius:BorderRadius.circular(2))),
          const SizedBox(height:16),
          Row(children:[
            Text(habit.icon, style:const TextStyle(fontSize:28)),
            const SizedBox(width:12),
            Expanded(child:Text(habit.name, style:TextStyle(fontSize:17,fontWeight:FontWeight.w700,color:TH.text(context)))),
          ]),
          const SizedBox(height:16),
          ListTile(onTap:(){
            Navigator.pop(context);
            showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,
              builder:(_)=>AddHabitScreen(edit:habit));
          },
            leading:Container(width:40,height:40,decoration:BoxDecoration(color:AC.primary.withOpacity(0.12),borderRadius:BorderRadius.circular(12)),child:const Icon(Iconsax.edit,color:AC.primary,size:20)),
            title:const Text('Edit Habit',style:TextStyle(fontWeight:FontWeight.w600))),
          const Divider(height:1),
          ListTile(onTap:() async {
            Navigator.pop(context);
            habit.isArchived=true;
            await DB.save(habit);
            onReload();
            if(context.mounted){
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:Text("${habit.name} archived 📦"),
                backgroundColor:AC.warning,behavior:SnackBarBehavior.floating,
                duration:const Duration(seconds:4),
                shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),
                action:SnackBarAction(label:'UNDO',textColor:Colors.white,onPressed:() async {
                  habit.isArchived=false;
                  await DB.save(habit);
                  onReload();
                })));
            }
          },
            leading:Container(width:40,height:40,decoration:BoxDecoration(color:AC.warning.withOpacity(0.12),borderRadius:BorderRadius.circular(12)),child:const Icon(Iconsax.archive_1,color:AC.warning,size:20)),
            title:const Text('Archive',style:TextStyle(color:AC.warning,fontWeight:FontWeight.w600))),
          const Divider(height:1),
          ListTile(onTap:(){
            Navigator.pop(context);
            showDialog(context:context,builder:(_)=>AlertDialog(
              backgroundColor:TH.surface(context),
              title:Text("Delete \${habit.name}?",style:TextStyle(color:TH.text(context))),
              content:Text("This permanently deletes this habit.",style:TextStyle(color:TH.sub(context))),
              actions:[
                TextButton(onPressed:()=>Navigator.pop(context),child:Text('Cancel',style:TextStyle(color:TH.muted(context)))),
                TextButton(onPressed:() async {await DB.delete(habit.id);if(context.mounted)Navigator.pop(context);},
                  child:const Text('Delete',style:TextStyle(color:AC.danger))),
              ]));
          },
            leading:Container(width:40,height:40,decoration:BoxDecoration(color:AC.danger.withOpacity(0.12),borderRadius:BorderRadius.circular(12)),child:const Icon(Iconsax.trash,color:AC.danger,size:20)),
            title:const Text('Delete',style:TextStyle(color:AC.danger,fontWeight:FontWeight.w600))),
        ]),
      ),
    );
  }
}
