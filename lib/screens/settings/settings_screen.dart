import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../providers/providers.dart';
import '../../data/db/db.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context,WidgetRef ref){
    final s=ref.watch(settingsProv);
    final habits=ref.watch(habitProv);
    final totalDone=habits.fold(0,(sum,h)=>sum+h.totalCompletions);
    final bestStreak=habits.isEmpty?0:habits.map((h)=>h.longestStreak).reduce((a,b)=>a>b?a:b);
    return Scaffold(
      backgroundColor:TH.bg(context),
      body:CustomScrollView(physics:const BouncingScrollPhysics(),slivers:[
        SliverAppBar(backgroundColor:TH.bg(context),pinned:true,expandedHeight:96,
          leading:GestureDetector(onTap:()=>Navigator.pop(context),child:Icon(Iconsax.arrow_left,color:TH.text(context))),
          flexibleSpace:FlexibleSpaceBar(titlePadding:const EdgeInsets.fromLTRB(55,0,20,16),
            title:Text('Settings',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:TH.text(context))))),
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.all(20),child:Container(padding:const EdgeInsets.all(20),
          decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF2D1B6B),Color(0xFF0D1A3D)],begin:Alignment.topLeft,end:Alignment.bottomRight),
            borderRadius:BorderRadius.circular(24),border:Border.all(color:AC.primary.withOpacity(0.3))),
          child:Row(children:[
            Container(width:58,height:58,decoration:const BoxDecoration(gradient:AC.grad,shape:BoxShape.circle),
              child:Center(child:Text(s.name.isNotEmpty?s.name[0].toUpperCase():'S',style:const TextStyle(fontSize:26,fontWeight:FontWeight.w800,color:Colors.white)))),
            const SizedBox(width:16),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(s.name,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w700,color:Colors.white)),
              const SizedBox(height:4),
              Row(children:[_badge('${habits.length} habits'),const SizedBox(width:6),_badge('$totalDone done'),const SizedBox(width:6),_badge('🔥 $bestStreak best')]),
            ])),
            GestureDetector(onTap:()=>_editName(context,ref,s.name),child:Container(padding:const EdgeInsets.all(8),
              decoration:BoxDecoration(color:AC.primary.withOpacity(0.2),borderRadius:BorderRadius.circular(10)),
              child:const Icon(Iconsax.edit,color:AC.pLight,size:18))),
          ])))),
        SliverToBoxAdapter(child:_Sec(title:'🎨 Appearance',children:[
          _Tile(icon:Iconsax.moon,iconColor:AC.primary,title:'Dark Mode',subtitle:s.dark?'Enabled':'Disabled',
            trailing:Switch(value:s.dark,onChanged:(v)=>ref.read(settingsProv.notifier).setDark(v),activeColor:AC.primary)),
        ])),
        const SliverToBoxAdapter(child:SizedBox(height:12)),
        SliverToBoxAdapter(child:_Sec(title:'📁 Data',children:[
          _Tile(icon:Iconsax.trash,iconColor:AC.danger,title:'Clear All Data',subtitle:'Permanently delete everything',
            onTap:()=>_confirmClear(context,ref),trailing:Icon(Iconsax.arrow_right_3,color:TH.muted(context),size:16)),
        ])),
        const SliverToBoxAdapter(child:SizedBox(height:12)),
        SliverToBoxAdapter(child:_Sec(title:'ℹ️ About',children:[
          _Tile(icon:Iconsax.info_circle,iconColor:AC.info,title:'HabitFlow',subtitle:'Version 2.0.0 — Advanced Edition'),
          const Divider(height:1),
          _Tile(icon:Iconsax.star_1,iconColor:AC.warning,title:'Rate Us ⭐',subtitle:'Love the app? Leave a review!',
            onTap:()=>ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Thank you! ⭐'),backgroundColor:AC.success)),
            trailing:Icon(Iconsax.arrow_right_3,color:TH.muted(context),size:16)),
        ])),
        const SliverToBoxAdapter(child:SizedBox(height:80)),
      ]),
    );
  }
  Widget _badge(String t)=>Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
    decoration:BoxDecoration(color:Colors.white.withOpacity(0.1),borderRadius:BorderRadius.circular(6)),
    child:Text(t,style:const TextStyle(fontSize:10,color:Colors.white70,fontWeight:FontWeight.w500)));
  void _editName(BuildContext context,WidgetRef ref,String cur){
    final ctrl=TextEditingController(text:cur);
    showDialog(context:context,builder:(_)=>AlertDialog(backgroundColor:TH.surface(context),
      title:Text('Your Name',style:TextStyle(color:TH.text(context))),
      content:TextField(controller:ctrl,style:TextStyle(color:TH.text(context))),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:Text('Cancel',style:TextStyle(color:TH.muted(context)))),
        TextButton(onPressed:(){ref.read(settingsProv.notifier).setName(ctrl.text.trim().isEmpty?'Friend':ctrl.text.trim());Navigator.pop(context);},
          child:const Text('Save',style:TextStyle(color:AC.primary)))]));
  }
  void _confirmClear(BuildContext context,WidgetRef ref)=>showDialog(context:context,builder:(_)=>AlertDialog(
    backgroundColor:TH.surface(context),
    title:Text('Clear all data?',style:TextStyle(color:TH.text(context))),
    content:Text('This permanently deletes all habits and journal entries.',style:TextStyle(color:TH.sub(context))),
    actions:[TextButton(onPressed:()=>Navigator.pop(context),child:Text('Cancel',style:TextStyle(color:TH.muted(context)))),
      TextButton(onPressed:() async {await DB.clearAll();ref.read(habitProv.notifier);if(context.mounted)Navigator.pop(context);},
        child:const Text('Delete',style:TextStyle(color:AC.danger)))]));
}
class _Sec extends StatelessWidget {
  final String title; final List<Widget> children;
  const _Sec({required this.title,required this.children});
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(horizontal:20),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Padding(padding:const EdgeInsets.only(bottom:10),child:Text(title,style:TextStyle(fontSize:13,fontWeight:FontWeight.w700,color:TH.sub(context)))),
      Container(decoration:BoxDecoration(color:TH.card(context),borderRadius:BorderRadius.circular(20),border:Border.all(color:TH.border(context))),child:Column(children:children)),
    ]));
}
class _Tile extends StatelessWidget {
  final IconData icon; final Color iconColor; final String title,subtitle;
  final VoidCallback? onTap; final Widget? trailing;
  const _Tile({required this.icon,required this.iconColor,required this.title,required this.subtitle,this.onTap,this.trailing});
  @override Widget build(BuildContext context)=>ListTile(onTap:onTap,contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:4),
    leading:Container(width:40,height:40,decoration:BoxDecoration(color:iconColor.withOpacity(0.15),borderRadius:BorderRadius.circular(12)),child:Icon(icon,color:iconColor,size:20)),
    title:Text(title,style:TextStyle(fontSize:14,fontWeight:FontWeight.w600,color:TH.text(context))),
    subtitle:Text(subtitle,style:TextStyle(fontSize:12,color:TH.muted(context))),trailing:trailing);
}
