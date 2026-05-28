import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/habit_model.dart';
import '../../data/db/db.dart';
import '../../providers/providers.dart';
import '../add_habit/add_habit_screen.dart';

class HabitDetailScreen extends ConsumerWidget {
  final HabitModel habit;
  const HabitDetailScreen({super.key,required this.habit});

  @override
  Widget build(BuildContext context,WidgetRef ref){
    ref.watch(habitProv); // rebuild on changes
    final color=AC.palette[habit.colorIndex%AC.palette.length];
    final rate30=habit.completionRate(30);
    final rate7=habit.completionRate(7);

    return Scaffold(
      backgroundColor:TH.bg(context),
      body:CustomScrollView(physics:const BouncingScrollPhysics(),slivers:[
        SliverAppBar(backgroundColor:TH.bg(context),pinned:true,expandedHeight:180,
          leading:GestureDetector(onTap:()=>Navigator.pop(context),child:Icon(Iconsax.arrow_left,color:TH.text(context))),
          actions:[
            IconButton(onPressed:()=>showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,
              builder:(_)=>AddHabitScreen(edit:habit)),icon:Icon(Iconsax.edit,color:TH.text(context))),
            IconButton(onPressed:()=>_confirmArchive(context,ref),icon:const Icon(Iconsax.archive_1,color:AC.warning)),
            IconButton(onPressed:()=>_confirmDelete(context,ref),icon:const Icon(Iconsax.trash,color:AC.danger)),
          ],
          flexibleSpace:FlexibleSpaceBar(
            background:Container(decoration:BoxDecoration(gradient:LinearGradient(
              colors:[color.withOpacity(0.3),TH.bg(context)],begin:Alignment.topCenter,end:Alignment.bottomCenter)),
              child:SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(20,60,20,20),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Container(width:64,height:64,decoration:BoxDecoration(color:color.withOpacity(0.2),borderRadius:BorderRadius.circular(20),border:Border.all(color:color,width:2)),
                  child:Center(child:Text(habit.icon,style:const TextStyle(fontSize:32)))),
                const SizedBox(width:16),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(habit.name,style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:TH.text(context))),
                  Text('${habit.category} • ${habit.frequency}',style:TextStyle(fontSize:13,color:TH.sub(context))),
                  if(habit.note.isNotEmpty)Text(habit.note,style:TextStyle(fontSize:12,color:TH.muted(context)),maxLines:1,overflow:TextOverflow.ellipsis),
                ])),
              ])))),
          ),
        ),

        // Stats row
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.all(16),
          child:Row(children:[
            Expanded(child:_StatBox('🔥','Current Streak',H.streakLabel(habit.currentStreak),color)),
            const SizedBox(width:10),
            Expanded(child:_StatBox('🏆','Best Streak','${habit.longestStreak} days',AC.warning)),
            const SizedBox(width:10),
            Expanded(child:_StatBox('✅','Total Done','${habit.totalCompletions}',AC.success)),
          ]).animate().fadeIn())),

        // Bug 2: Quantitative progress on detail screen
        if(habit.isQuantitative)
          SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(16,0,16,16),
            child:Container(padding:const EdgeInsets.all(18),
              decoration:BoxDecoration(color:TH.card(context),borderRadius:BorderRadius.circular(20),border:Border.all(color:TH.border(context))),
              child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text("Today's Progress",style:TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:TH.text(context))),
                const SizedBox(height:16),
                Row(children:[
                  Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Row(children:[
                      Text('${habit.getValueFor(DateTime.now()).toStringAsFixed(0)}',style:TextStyle(fontSize:36,fontWeight:FontWeight.w800,color:color)),
                      Text(' / ${habit.targetValue.toStringAsFixed(0)} ${habit.unit}',style:TextStyle(fontSize:16,color:TH.sub(context),fontWeight:FontWeight.w500)),
                    ]),
                    const SizedBox(height:8),
                    ClipRRect(borderRadius:BorderRadius.circular(6),child:LinearProgressIndicator(
                      value:(habit.getValueFor(DateTime.now())/habit.targetValue).clamp(0.0,1.0),
                      minHeight:10,backgroundColor:color.withOpacity(0.12),
                      valueColor:AlwaysStoppedAnimation(color))),
                  ])),
                  const SizedBox(width:20),
                  // +/- stepper
                  Column(children:[
                    GestureDetector(
                      onTap:(){final d=DateTime.now();final v=(habit.getValueFor(d)+1).clamp(0.0,habit.targetValue*2);habit.logValue(d,v);ref.read(habitProv.notifier).reload();},
                      child:Container(width:48,height:48,decoration:BoxDecoration(color:color,borderRadius:BorderRadius.circular(14),boxShadow:[BoxShadow(color:color.withOpacity(0.3),blurRadius:8,offset:const Offset(0,3))]),
                        child:const Icon(Icons.add_rounded,color:Colors.white,size:24))),
                    const SizedBox(height:8),
                    GestureDetector(
                      onTap:(){final d=DateTime.now();final v=(habit.getValueFor(d)-1).clamp(0.0,habit.targetValue*2);habit.logValue(d,v);ref.read(habitProv.notifier).reload();},
                      child:Container(width:48,height:48,decoration:BoxDecoration(color:color.withOpacity(0.15),borderRadius:BorderRadius.circular(14),border:Border.all(color:color.withOpacity(0.3))),
                        child:Icon(Icons.remove_rounded,color:color,size:24))),
                  ]),
                ]),
              ])))),

        // Completion rates
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(16,0,16,16),
          child:Row(children:[
            Expanded(child:_RateBox('7 Days',rate7,color)),
            const SizedBox(width:10),
            Expanded(child:_RateBox('30 Days',rate30,color)),
          ]).animate().fadeIn(delay:100.ms))),

        // Heatmap-style 28-day grid
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(16,0,16,16),
          child:Container(padding:const EdgeInsets.all(16),
            decoration:BoxDecoration(color:TH.card(context),borderRadius:BorderRadius.circular(20),border:Border.all(color:TH.border(context))),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('28-Day Activity',style:TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:TH.text(context))),
              const SizedBox(height:12),
              GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
                gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:7,mainAxisSpacing:5,crossAxisSpacing:5),
                itemCount:28,
                itemBuilder:(_,i){
                  final d=DateTime.now().subtract(Duration(days:27-i));
                  final day=DateTime(d.year,d.month,d.day);
                  final done=habit.isCompletedOn(day);
                  final due=habit.isDueOn(day);
                  return Tooltip(message:H.date(day),child:AnimatedContainer(duration:const Duration(milliseconds:200),
                    decoration:BoxDecoration(color:done?color:(due?color.withOpacity(0.1):TH.cardAlt(context)),
                      borderRadius:BorderRadius.circular(6),
                      border:Border.all(color:done?color.withOpacity(0.5):Colors.transparent)),
                    child:done?const Center(child:Text('✓',style:TextStyle(fontSize:10,color:Colors.white))):null));
                }),
            ])).animate().fadeIn(delay:200.ms))),

        // Calendar
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(16,0,16,16),
          child:Container(padding:const EdgeInsets.all(8),
            decoration:BoxDecoration(color:TH.card(context),borderRadius:BorderRadius.circular(20),border:Border.all(color:TH.border(context))),
            child:TableCalendar(
              firstDay:DateTime.utc(2020,1,1),lastDay:DateTime.now(),focusedDay:DateTime.now(),
              calendarFormat:CalendarFormat.month,
              headerStyle:HeaderStyle(formatButtonVisible:false,titleCentered:true,
                titleTextStyle:TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:TH.text(context)),
                leftChevronIcon:Icon(Icons.chevron_left,color:TH.text(context)),
                rightChevronIcon:Icon(Icons.chevron_right,color:TH.text(context))),
              calendarStyle:CalendarStyle(
                defaultTextStyle:TextStyle(color:TH.text(context)),
                weekendTextStyle:TextStyle(color:TH.sub(context)),
                outsideDaysVisible:false,
                todayDecoration:BoxDecoration(color:color.withOpacity(0.3),shape:BoxShape.circle),
                selectedDecoration:BoxDecoration(color:color,shape:BoxShape.circle),
                markerDecoration:BoxDecoration(color:color,shape:BoxShape.circle)),
              calendarBuilders:CalendarBuilders(defaultBuilder:(_,day,__){
                final done=habit.isCompletedOn(day);
                final due=habit.isDueOn(day);
                if(done)return Container(margin:const EdgeInsets.all(4),
                  decoration:BoxDecoration(color:color,shape:BoxShape.circle),
                  child:const Center(child:Text('✓',style:TextStyle(color:Colors.white,fontSize:14,fontWeight:FontWeight.w700))));
                if(!due)return Container(margin:const EdgeInsets.all(4),
                  child:Center(child:Text('${day.day}',style:TextStyle(color:TH.muted(context),fontSize:13))));
                return null;
              }),
              onDaySelected:(sel,_)=>ref.read(habitProv.notifier).toggle(habit,sel),
              selectedDayPredicate:(d)=>habit.isCompletedOn(d),
            )).animate().fadeIn(delay:300.ms))),

        const SliverToBoxAdapter(child:SizedBox(height:80)),
      ]),
    );
  }

  void _confirmArchive(BuildContext context,WidgetRef ref)=>showDialog(context:context,builder:(_)=>AlertDialog(
    backgroundColor:TH.surface(context),
    title:Text("Archive ${habit.name}?",style:TextStyle(color:TH.text(context))),
    content:Text("You can restore it from Settings → Archived Habits.",style:TextStyle(color:TH.sub(context))),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(context),child:Text('Cancel',style:TextStyle(color:TH.muted(context)))),
      TextButton(onPressed:() async {
        habit.isArchived=true;
        await DB.save(habit);
        ref.read(habitProv.notifier).reload();
        if(context.mounted){Navigator.pop(context);Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text("${habit.name} archived 📦"),
            backgroundColor:AC.warning,behavior:SnackBarBehavior.floating,
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))));}
      },child:const Text('Archive',style:TextStyle(color:AC.warning))),
    ]));

  void _confirmDelete(BuildContext context,WidgetRef ref)=>showDialog(context:context,builder:(_)=>AlertDialog(
    backgroundColor:TH.surface(context),
    title:Text("Delete ${habit.name}?",style:TextStyle(color:TH.text(context))),
    content:Text("This will permanently delete this habit and all its history.",style:TextStyle(color:TH.sub(context))),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(context),child:Text('Cancel',style:TextStyle(color:TH.muted(context)))),
      TextButton(onPressed:(){ref.read(habitProv.notifier).delete(habit.id);Navigator.pop(context);Navigator.pop(context);},
        child:const Text('Delete',style:TextStyle(color:AC.danger))),
    ]));
}

class _StatBox extends StatelessWidget {
  final String emoji,label,value; final Color color;
  const _StatBox(this.emoji,this.label,this.value,this.color);
  @override
  Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(12),
    decoration:BoxDecoration(color:TH.card(context),borderRadius:BorderRadius.circular(16),border:Border.all(color:TH.border(context))),
    child:Column(children:[Text(emoji,style:const TextStyle(fontSize:22)),const SizedBox(height:6),
      Text(value,style:TextStyle(fontSize:13,fontWeight:FontWeight.w700,color:color),textAlign:TextAlign.center),
      Text(label,style:TextStyle(fontSize:10,color:TH.muted(context)),textAlign:TextAlign.center)]));
}

class _RateBox extends StatelessWidget {
  final String label; final double rate; final Color color;
  const _RateBox(this.label,this.rate,this.color);
  @override
  Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(14),
    decoration:BoxDecoration(color:TH.card(context),borderRadius:BorderRadius.circular(16),border:Border.all(color:TH.border(context))),
    child:Row(children:[
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('$label Rate',style:TextStyle(fontSize:12,color:TH.muted(context))),
        const SizedBox(height:4),
        Text('${(rate*100).toStringAsFixed(0)}%',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:color)),
        const SizedBox(height:6),
        ClipRRect(borderRadius:BorderRadius.circular(4),child:LinearProgressIndicator(value:rate,minHeight:5,backgroundColor:color.withOpacity(0.15),valueColor:AlwaysStoppedAnimation(color))),
      ])),
    ]));
}
