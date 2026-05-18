import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../providers/providers.dart';

class _Badge {
  final String emoji, title, desc; final Color color;
  final bool Function(List<dynamic>) earned;
  const _Badge(this.emoji,this.title,this.desc,this.color,this.earned);
}

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  static final _badges = [
    _Badge('🌱','First Step','Complete your first habit',AC.success,(h)=>h.any((x)=>x.totalCompletions>=1)),
    _Badge('🔥','On Fire','Reach a 3-day streak',AC.warning,(h)=>h.any((x)=>x.currentStreak>=3)),
    _Badge('⚡','Week Warrior','Reach a 7-day streak',AC.primary,(h)=>h.any((x)=>x.currentStreak>=7)),
    _Badge('💎','Diamond Streak','Reach a 30-day streak',const Color(0xFF74B9FF),(h)=>h.any((x)=>x.currentStreak>=30)),
    _Badge('🎯','Centurion','Complete 100 total check-ins',AC.pink,(h)=>h.fold(0,(s,x)=>s+x.totalCompletions as int)>=100),
    _Badge('🏆','Perfect Week','100% completion for 7 days straight',AC.warning,(h){
      final now=DateTime.now();
      for(int i=0;i<7;i++){final d=DateTime(now.year,now.month,now.day-i);
        final due=h.where((x)=>x.isDueOn(d)).toList();
        if(due.isEmpty)continue;
        if(due.any((x)=>!x.isCompletedOn(d)))return false;}
      return true;
    }),
    _Badge('🌍','Habit Builder','Create 5 habits',const Color(0xFF55EFC4),(h)=>h.length>=5),
    _Badge('📚','Scholar','Complete Reading habit 30 times',const Color(0xFFA29BFE),(h)=>h.any((x)=>x.name.toLowerCase().contains('read')&&x.totalCompletions>=30)),
    _Badge('🏃','Runner','Complete a Fitness habit 20 times',AC.success,(h)=>h.any((x)=>x.category=='Fitness'&&x.totalCompletions>=20)),
    _Badge('🧘','Zen Master','Complete Mindfulness 15 times',const Color(0xFF74B9FF),(h)=>h.any((x)=>x.category=='Mindfulness'&&x.totalCompletions>=15)),
    _Badge('🌅','Early Bird','Have 3+ habits for a month',AC.warning,(h){
      final now=DateTime.now();
      final start=DateTime(now.year,now.month-1,now.day);
      return h.any((x)=>x.createdAt.isBefore(start));
    }),
    _Badge('🔮','Legendary','Complete 500 total check-ins',AC.primary,(h)=>h.fold(0,(s,x)=>s+x.totalCompletions as int)>=500),
  ];

  @override
  Widget build(BuildContext context,WidgetRef ref){
    final habits=ref.watch(habitProv);
    final earned=_badges.where((b)=>b.earned(habits)).length;

    return Scaffold(
      backgroundColor:TH.bg(context),
      body:CustomScrollView(physics:const BouncingScrollPhysics(),slivers:[
        SliverAppBar(backgroundColor:TH.bg(context),pinned:true,expandedHeight:96,
          leading:GestureDetector(onTap:()=>Navigator.pop(context),child:Icon(Iconsax.arrow_left,color:TH.text(context))),
          flexibleSpace:FlexibleSpaceBar(titlePadding:const EdgeInsets.fromLTRB(55,0,20,16),
            title:Text('Achievements',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:TH.text(context))))),
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.all(20),
          child:Container(padding:const EdgeInsets.all(20),
            decoration:BoxDecoration(gradient:AC.grad,borderRadius:BorderRadius.circular(22)),
            child:Row(children:[
              const Text('🏆',style:TextStyle(fontSize:40)),const SizedBox(width:16),
              Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text('$earned/${_badges.length} Unlocked',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:Colors.white)),
                const SizedBox(height:4),
                Text('${_badges.length-earned} badges remaining',style:TextStyle(fontSize:13,color:Colors.white.withOpacity(0.8))),
                const SizedBox(height:8),
                ClipRRect(borderRadius:BorderRadius.circular(4),child:SizedBox(width:180,child:LinearProgressIndicator(
                  value:earned/_badges.length,minHeight:6,backgroundColor:Colors.white.withOpacity(0.2),
                  valueColor:const AlwaysStoppedAnimation(Colors.white)))),
              ]),
            ])).animate().fadeIn())),
        SliverPadding(padding:const EdgeInsets.symmetric(horizontal:16),
          sliver:SliverGrid(delegate:SliverChildBuilderDelegate((_,i){
            final b=_badges[i]; final e=b.earned(habits);
            return Container(
              margin:const EdgeInsets.all(6),padding:const EdgeInsets.all(16),
              decoration:BoxDecoration(color:e?b.color.withOpacity(0.12):TH.card(context),
                borderRadius:BorderRadius.circular(20),
                border:Border.all(color:e?b.color.withOpacity(0.4):TH.border(context),width:e?1.5:1)),
              child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                Stack(alignment:Alignment.center,children:[
                  Text(b.emoji,style:TextStyle(fontSize:36,color:e?null:null)).animate(target:e?1:0),
                  if(!e)Container(width:44,height:44,decoration:BoxDecoration(color:TH.bg(context).withOpacity(0.7),shape:BoxShape.circle),
                    child:const Center(child:Text('🔒',style:TextStyle(fontSize:18)))),
                ]),
                const SizedBox(height:8),
                Text(b.title,style:TextStyle(fontSize:13,fontWeight:FontWeight.w700,
                  color:e?b.color:TH.muted(context)),textAlign:TextAlign.center),
                const SizedBox(height:4),
                Text(b.desc,style:TextStyle(fontSize:10,color:TH.muted(context)),textAlign:TextAlign.center,maxLines:2),
              ])).animate().fadeIn(delay:Duration(milliseconds:50*i));
          },childCount:_badges.length),
          gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,childAspectRatio:0.85))),
        const SliverToBoxAdapter(child:SizedBox(height:80)),
      ]),
    );
  }
}
