import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../providers/providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context,WidgetRef ref){
    final habits=ref.watch(habitProv);
    if(habits.isEmpty)return Scaffold(backgroundColor:TH.bg(context),
      appBar:AppBar(leading:GestureDetector(onTap:()=>Navigator.pop(context),child:Icon(Iconsax.arrow_left,color:TH.text(context))),
        title:Text('Analytics',style:TextStyle(color:TH.text(context)))),
      body:const Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
        Text('📊',style:TextStyle(fontSize:60)),SizedBox(height:16),Text('Add habits to see analytics')])));

    final totalDone=habits.fold(0,(s,h)=>s+h.totalCompletions);
    final bestStreak=habits.map((h)=>h.longestStreak).reduce((a,b)=>a>b?a:b);
    final overallRate=habits.fold(0.0,(s,h)=>s+h.completionRate(30))/habits.length;
    final barData=List.generate(7,(i){
      final d=DateTime.now().subtract(Duration(days:6-i));
      final day=DateTime(d.year,d.month,d.day);
      final due=habits.where((h)=>h.isDueOn(day)).length;
      final done=habits.where((h)=>h.isDueOn(day)&&h.isCompletedOn(day)).length;
      return due>0?done/due:0.0;
    });

    return Scaffold(
      backgroundColor:TH.bg(context),
      body:CustomScrollView(physics:const BouncingScrollPhysics(),slivers:[
        SliverAppBar(backgroundColor:TH.bg(context),pinned:true,expandedHeight:96,
          leading:GestureDetector(onTap:()=>Navigator.pop(context),child:Icon(Iconsax.arrow_left,color:TH.text(context))),
          flexibleSpace:FlexibleSpaceBar(titlePadding:const EdgeInsets.fromLTRB(55,0,20,16),
            title:Text('Analytics',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:TH.text(context))))),
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.all(16),
          child:Row(children:[
            Expanded(child:_SC('🔥','Best Streak','$bestStreak days',AC.warning)),const SizedBox(width:10),
            Expanded(child:_SC('📊','30d Rate','${(overallRate*100).toStringAsFixed(0)}%',overallRate>=0.7?AC.success:overallRate>=0.4?AC.warning:AC.danger)),const SizedBox(width:10),
            Expanded(child:_SC('✅','Total Done','$totalDone',AC.primary)),
          ]).animate().fadeIn(delay:100.ms))),
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(16,0,16,14),
          child:Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:TH.card(context),borderRadius:BorderRadius.circular(22),border:Border.all(color:TH.border(context))),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('7-Day Completion',style:TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:TH.text(context))),
              const SizedBox(height:18),
              SizedBox(height:150,child:BarChart(BarChartData(alignment:BarChartAlignment.spaceAround,maxY:1.0,
                barTouchData:BarTouchData(enabled:false),
                titlesData:FlTitlesData(
                  leftTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),
                  rightTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),
                  topTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),
                  bottomTitles:AxisTitles(sideTitles:SideTitles(showTitles:true,getTitlesWidget:(v,_){
                    final d=DateTime.now().subtract(Duration(days:6-v.toInt()));
                    return Padding(padding:const EdgeInsets.only(top:4),child:Text(DateFormat('E').format(d),style:TextStyle(fontSize:10,color:TH.muted(context))));
                  }))),
                gridData:FlGridData(show:true,drawVerticalLine:false,getDrawingHorizontalLine:(_)=>FlLine(color:TH.border(context),strokeWidth:1)),
                borderData:FlBorderData(show:false),
                barGroups:List.generate(7,(i)=>BarChartGroupData(x:i,barRods:[BarChartRodData(
                  toY:barData[i],width:20,borderRadius:BorderRadius.circular(6),
                  gradient:LinearGradient(colors:[barData[i]>=1?AC.success:AC.primary,barData[i]>=1?AC.success.withOpacity(0.7):AC.pLight],begin:Alignment.bottomCenter,end:Alignment.topCenter),
                  backDrawRodData:BackgroundBarChartRodData(show:true,toY:1,color:TH.cardAlt(context)))])),
              ))),
            ])).animate().fadeIn(delay:200.ms))),
        // Heatmap — full year grid (compact dots)
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(16,0,16,14),
          child:Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:TH.card(context),borderRadius:BorderRadius.circular(22),border:Border.all(color:TH.border(context))),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('Activity Heatmap (90 days)',style:TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:TH.text(context))),
              const SizedBox(height:12),
              GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
                gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:18,mainAxisSpacing:4,crossAxisSpacing:4,childAspectRatio:1),
                itemCount:90,
                itemBuilder:(_,i){
                  final d=DateTime.now().subtract(Duration(days:89-i));
                  final day=DateTime(d.year,d.month,d.day);
                  final total=habits.where((h)=>h.isDueOn(day)).length;
                  final done=habits.where((h)=>h.isDueOn(day)&&h.isCompletedOn(day)).length;
                  final intensity=total>0?done/total:0.0;
                  final baseColor=intensity>=1?AC.success:intensity>0?AC.primary:null;
                  return Container(decoration:BoxDecoration(color:baseColor!=null?baseColor.withOpacity(intensity*0.9+0.1):TH.cardAlt(context),borderRadius:BorderRadius.circular(2)));
                }),
              const SizedBox(height:10),
              Row(children:[_dot(context,TH.cardAlt(context),'None'),const SizedBox(width:12),_dot(context,AC.primary.withOpacity(0.4),'Partial'),const SizedBox(width:12),_dot(context,AC.success,'Complete')]),
            ])).animate().fadeIn(delay:250.ms))),
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.symmetric(horizontal:16),
          child:Text('Per-Habit (30 days)',style:TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:TH.text(context))))),
        SliverList(delegate:SliverChildBuilderDelegate((_,i){
          final h=habits[i]; final rate=h.completionRate(30); final col=AC.palette[h.colorIndex%AC.palette.length];
          return Container(margin:const EdgeInsets.fromLTRB(16,8,16,0),padding:const EdgeInsets.all(14),
            decoration:BoxDecoration(color:TH.card(context),borderRadius:BorderRadius.circular(18),border:Border.all(color:TH.border(context))),
            child:Row(children:[Text(h.icon,style:const TextStyle(fontSize:26)),const SizedBox(width:12),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
                  Text(h.name,style:TextStyle(fontSize:14,fontWeight:FontWeight.w700,color:TH.text(context))),
                  Text('${(rate*100).toStringAsFixed(0)}%',style:TextStyle(fontSize:14,fontWeight:FontWeight.w700,color:col))]),
                const SizedBox(height:5),
                ClipRRect(borderRadius:BorderRadius.circular(4),child:LinearProgressIndicator(value:rate,minHeight:6,backgroundColor:col.withOpacity(0.12),valueColor:AlwaysStoppedAnimation(col))),
                const SizedBox(height:4),
                Text('🔥 ${h.currentStreak} streak  •  ${h.totalCompletions} total',style:TextStyle(fontSize:11,color:TH.muted(context))),
              ]))])
          ).animate().fadeIn(delay:Duration(milliseconds:300+i*40));
        },childCount:habits.length)),
        const SliverToBoxAdapter(child:SizedBox(height:80)),
      ]),
    );
  }
  Widget _dot(BuildContext context,Color c,String l)=>Row(mainAxisSize:MainAxisSize.min,children:[Container(width:12,height:12,decoration:BoxDecoration(color:c,borderRadius:BorderRadius.circular(3))),const SizedBox(width:4),Text(l,style:TextStyle(fontSize:10,color:TH.muted(context)))]);
}
class _SC extends StatelessWidget {
  final String e,l,v; final Color c;
  const _SC(this.e,this.l,this.v,this.c);
  @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(12),
    decoration:BoxDecoration(color:TH.card(context),borderRadius:BorderRadius.circular(16),border:Border.all(color:TH.border(context))),
    child:Column(children:[Text(e,style:const TextStyle(fontSize:22)),const SizedBox(height:6),
      Text(v,style:TextStyle(fontSize:16,fontWeight:FontWeight.w800,color:c)),
      Text(l,style:TextStyle(fontSize:10,color:TH.muted(context)),textAlign:TextAlign.center)]));
}
