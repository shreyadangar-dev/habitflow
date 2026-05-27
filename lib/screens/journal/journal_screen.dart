import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/habit_model.dart';
import '../../data/db/db.dart';
import '../../providers/providers.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});
  @override
  Widget build(BuildContext context,WidgetRef ref){
    final entries=ref.watch(journalProv);
    return Scaffold(
      backgroundColor:TH.bg(context),
      body:CustomScrollView(physics:const BouncingScrollPhysics(),slivers:[
        SliverAppBar(backgroundColor:TH.bg(context),pinned:true,expandedHeight:96,
          leading:GestureDetector(onTap:()=>Navigator.pop(context),child:Icon(Iconsax.arrow_left,color:TH.text(context))),
          flexibleSpace:FlexibleSpaceBar(titlePadding:const EdgeInsets.fromLTRB(55,0,20,16),
            title:Text('Daily Journal',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:TH.text(context)))),
          actions:[Padding(padding:const EdgeInsets.only(right:12),child:GestureDetector(
            onTap:()=>_showAdd(context,ref,null),
            child:Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(gradient:AC.grad,borderRadius:BorderRadius.circular(12)),
              child:const Icon(Iconsax.add,color:Colors.white,size:18))))]),
        if(entries.isEmpty)SliverFillRemaining(child:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
          const Text('📝',style:TextStyle(fontSize:60)),const SizedBox(height:16),
          Text('No journal entries yet',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700,color:TH.text(context))),
          const SizedBox(height:8),Text('Tap + to write today\'s entry',style:TextStyle(color:TH.muted(context))),
        ])))
        else SliverList(delegate:SliverChildBuilderDelegate((_,i){
          final e=entries[i];
          final mood=K.moods[e.moodIndex];
          final moodLabel=K.moodLabels[e.moodIndex];
          final moodColors=[AC.success,AC.success,AC.warning,AC.warning,AC.danger];
          final c=moodColors[e.moodIndex];
          return Dismissible(key:Key(e.id),direction:DismissDirection.endToStart,
            confirmDismiss:(dir) async {
                return await showDialog<bool>(context:context,builder:(_)=>AlertDialog(
                  backgroundColor:TH.surface(context),
                  title:Text('Delete Entry?',style:TextStyle(color:TH.text(context))),
                  content:Text('This journal entry will be permanently deleted.',style:TextStyle(color:TH.sub(context))),
                  actions:[
                    TextButton(onPressed:()=>Navigator.pop(context,false),child:Text('Cancel',style:TextStyle(color:TH.muted(context)))),
                    TextButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Delete',style:TextStyle(color:AC.danger))),
                  ])) ?? false;
              },
              onDismissed:(_)=>ref.read(journalProv.notifier).delete(e.id),
            background:Container(alignment:Alignment.centerRight,padding:const EdgeInsets.only(right:20),
              margin:const EdgeInsets.symmetric(horizontal:20,vertical:6),
              decoration:BoxDecoration(color:AC.danger.withOpacity(0.15),borderRadius:BorderRadius.circular(20)),
              child:const Icon(Iconsax.trash,color:AC.danger)),
            child:GestureDetector(onTap:()=>_showAdd(context,ref,e),
              child:Container(margin:const EdgeInsets.symmetric(horizontal:20,vertical:6),padding:const EdgeInsets.all(16),
                decoration:BoxDecoration(color:TH.card(context),borderRadius:BorderRadius.circular(20),border:Border.all(color:TH.border(context))),
                child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Row(children:[Text(mood,style:const TextStyle(fontSize:28)),const SizedBox(width:12),
                    Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Text(H.date(e.date),style:TextStyle(fontSize:14,fontWeight:FontWeight.w700,color:TH.text(context))),
                      Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:2),
                        decoration:BoxDecoration(color:c.withOpacity(0.15),borderRadius:BorderRadius.circular(6)),
                        child:Text(moodLabel,style:TextStyle(fontSize:11,color:c,fontWeight:FontWeight.w600))),
                    ]),const Spacer(),Icon(Iconsax.arrow_right_3,color:TH.muted(context),size:16)],),
                  if(e.note.isNotEmpty)...[const SizedBox(height:10),
                    Text(e.note,style:TextStyle(fontSize:13,color:TH.sub(context),height:1.5),maxLines:3,overflow:TextOverflow.ellipsis)],
                ])).animate().fadeIn(delay:Duration(milliseconds:50*i))));
        },childCount:entries.length)),
        const SliverToBoxAdapter(child:SizedBox(height:80)),
      ]),
    );
  }
  void _showAdd(BuildContext c,WidgetRef ref,JournalModel? edit)=>showModalBottomSheet(
    context:c,isScrollControlled:true,backgroundColor:Colors.transparent,
    builder:(_)=>_AddEntry(edit:edit));
}

class _AddEntry extends ConsumerStatefulWidget {
  final JournalModel? edit;
  const _AddEntry({this.edit});
  @override ConsumerState<_AddEntry> createState()=>_AES();
}
class _AES extends ConsumerState<_AddEntry> {
  final _noteC=TextEditingController();
  int _mood=1;
  @override void initState(){super.initState();if(widget.edit!=null){_noteC.text=widget.edit!.note;_mood=widget.edit!.moodIndex;}}
  @override void dispose(){_noteC.dispose();super.dispose();}

  @override
  Widget build(BuildContext context){
    final moodColors=[AC.success,AC.success,AC.warning,AC.warning,AC.danger];
    final c=moodColors[_mood];
    return Container(
      decoration:BoxDecoration(color:TH.surface(context),borderRadius:const BorderRadius.vertical(top:Radius.circular(28))),
      padding:EdgeInsets.only(left:20,right:20,top:20,bottom:MediaQuery.of(context).viewInsets.bottom+24),
      child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        Center(child:Container(width:40,height:4,decoration:BoxDecoration(color:TH.border(context),borderRadius:BorderRadius.circular(2)))),
        const SizedBox(height:16),
        Text(widget.edit!=null?'Edit Entry':'Today\'s Journal',style:TextStyle(fontSize:20,fontWeight:FontWeight.w700,color:TH.text(context))),
        const SizedBox(height:16),
        Text('How are you feeling?',style:TextStyle(fontSize:13,fontWeight:FontWeight.w600,color:TH.sub(context))),
        const SizedBox(height:12),
        Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:List.generate(5,(i)=>GestureDetector(
          onTap:()=>setState(()=>_mood=i),
          child:AnimatedContainer(duration:const Duration(milliseconds:200),
            width:52,height:52,decoration:BoxDecoration(color:_mood==i?moodColors[i].withOpacity(0.2):TH.cardAlt(context),
              borderRadius:BorderRadius.circular(16),border:Border.all(color:_mood==i?moodColors[i]:TH.border(context),width:_mood==i?2:1)),
            child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
              Text(K.moods[i],style:const TextStyle(fontSize:22)),
              Text(K.moodLabels[i],style:TextStyle(fontSize:8,color:_mood==i?moodColors[i]:TH.muted(context),fontWeight:FontWeight.w600)),
            ]))))),
        const SizedBox(height:16),
        Text('Write your thoughts',style:TextStyle(fontSize:13,fontWeight:FontWeight.w600,color:TH.sub(context))),
        const SizedBox(height:8),
        TextField(controller:_noteC,maxLines:5,style:TextStyle(color:TH.text(context)),
          decoration:InputDecoration(hintText:'What happened today? How do you feel about your habits?...',
            hintStyle:TextStyle(color:TH.muted(context)),border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide(color:TH.border(context))))),
        const SizedBox(height:16),
        GestureDetector(onTap:(){
          final j=JournalModel(id:widget.edit?.id??const Uuid().v4(),date:widget.edit?.date??DateTime.now(),moodIndex:_mood,note:_noteC.text.trim());
          ref.read(journalProv.notifier).save(j);Navigator.pop(context);},
          child:Container(width:double.infinity,padding:const EdgeInsets.symmetric(vertical:15),
            decoration:BoxDecoration(color:c,borderRadius:BorderRadius.circular(16)),
            child:Center(child:Text('Save Entry ${K.moods[_mood]}',style:const TextStyle(fontSize:16,fontWeight:FontWeight.w700,color:Colors.white))))),
      ]),
    );
  }
}
