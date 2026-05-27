import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/constants/constants.dart';
import '../../data/models/habit_model.dart';
import '../../data/db/db.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class AddHabitScreen extends ConsumerStatefulWidget {
  final HabitModel? edit;
  const AddHabitScreen({super.key,this.edit});
  @override ConsumerState<AddHabitScreen> createState()=>_S();
}
class _S extends ConsumerState<AddHabitScreen> {
  final _key=GlobalKey<FormState>();
  final _nameC=TextEditingController();
  final _noteC=TextEditingController();
  String _icon='💪'; int _ci=0; String _freq='Daily',_cat='Health';
  List<int> _customDays=[];
  bool _isQuant=false;
  double _target=8;
  String _unit='glasses';
  static const _commonUnits=['glasses','km','minutes','pages','times','reps','hours','steps'];
  static const _days=['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

  @override void initState(){
    super.initState();
    if(widget.edit!=null){final e=widget.edit!;_nameC.text=e.name;_noteC.text=e.note;_icon=e.icon;_ci=e.colorIndex;_freq=e.frequency;_cat=e.category;_customDays=List.from(e.customDays);}
  }
  @override void dispose(){_nameC.dispose();_noteC.dispose();super.dispose();}

  void _save(){
    if(!_key.currentState!.validate())return;
    final h=HabitModel(id:widget.edit?.id??const Uuid().v4(),name:_nameC.text.trim(),icon:_icon,colorIndex:_ci,category:_cat,
      frequency:_freq,createdAt:widget.edit?.createdAt??DateTime.now(),note:_noteC.text.trim(),
      completedDates:widget.edit?.completedDates,customDays:_customDays,sortOrder:widget.edit?.sortOrder??999,
      isQuantitative:_isQuant,targetValue:_target,unit:_unit);
    if(widget.edit!=null)ref.read(habitProv.notifier).update(h);else ref.read(habitProv.notifier).add(h);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context){
    final color=AC.palette[_ci];
    return Container(
      decoration:BoxDecoration(color:TH.surface(context),borderRadius:const BorderRadius.vertical(top:Radius.circular(28))),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        Container(margin:const EdgeInsets.only(top:12),width:40,height:4,decoration:BoxDecoration(color:TH.border(context),borderRadius:BorderRadius.circular(2))),
        Padding(padding:const EdgeInsets.fromLTRB(20,14,20,0),child:Row(children:[
          Text(widget.edit!=null?'Edit Habit':'New Habit',style:TextStyle(fontSize:20,fontWeight:FontWeight.w700,color:TH.text(context))),
          const Spacer(),
          GestureDetector(onTap:()=>Navigator.pop(context),child:Container(width:32,height:32,
            decoration:BoxDecoration(color:TH.cardAlt(context),borderRadius:BorderRadius.circular(10)),
            child:Icon(Icons.close,size:16,color:TH.text(context)))),
        ])),
        Flexible(child:SingleChildScrollView(
          padding:EdgeInsets.only(left:20,right:20,top:14,bottom:MediaQuery.of(context).viewInsets.bottom+24),
          child:Form(key:_key,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            // Icon preview
            Center(child:GestureDetector(onTap:()=>_pickIcon(context),child:AnimatedContainer(duration:const Duration(milliseconds:200),
              width:80,height:80,decoration:BoxDecoration(color:color.withOpacity(0.15),borderRadius:BorderRadius.circular(24),border:Border.all(color:color,width:2)),
              child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                Text(_icon,style:const TextStyle(fontSize:34)),
                Text('tap',style:TextStyle(fontSize:8,color:TH.muted(context))),
              ])))),
            const SizedBox(height:14),
            _lbl(context,'Habit Name'),const SizedBox(height:8),
            TextFormField(controller:_nameC,style:TextStyle(color:TH.text(context)),
              decoration:InputDecoration(hintText:'e.g. Morning Run',prefixIcon:Icon(Iconsax.edit,color:TH.muted(context),size:18)),
              validator:(v)=>v==null||v.trim().isEmpty?'Please enter a name':null),
            const SizedBox(height:14),
            _lbl(context,'Colour'),const SizedBox(height:10),
            SizedBox(height:38,child:ListView.builder(scrollDirection:Axis.horizontal,itemCount:AC.palette.length,
              itemBuilder:(_,i)=>GestureDetector(onTap:()=>setState(()=>_ci=i),
                child:AnimatedContainer(duration:const Duration(milliseconds:180),width:32,height:32,margin:const EdgeInsets.only(right:10),
                  decoration:BoxDecoration(color:AC.palette[i],shape:BoxShape.circle,
                    border:Border.all(color:Colors.white,width:_ci==i?3:0),
                    boxShadow:_ci==i?[BoxShadow(color:AC.palette[i].withOpacity(0.5),blurRadius:8)]:[]),
                  child:_ci==i?const Icon(Icons.check,color:Colors.white,size:16):null)))),
            const SizedBox(height:14),
            _lbl(context,'Category'),const SizedBox(height:8),
            Wrap(spacing:8,runSpacing:8,children:K.categories.map((cat)=>Chip2(label:'${K.catIcons[cat]} $cat',selected:_cat==cat,color:color,onTap:()=>setState(()=>_cat=cat))).toList()),
            const SizedBox(height:14),
            _lbl(context,'Frequency'),const SizedBox(height:8),
            Wrap(spacing:8,runSpacing:8,children:K.frequencies.map((f)=>Chip2(label:f,selected:_freq==f,color:color,onTap:()=>setState(()=>_freq=f))).toList()),
            if(_freq=='Custom')...[const SizedBox(height:10),_lbl(context,'Select Days'),const SizedBox(height:8),
              Row(children:List.generate(7,(i){final d=i+1;final s=_customDays.contains(d);
                return GestureDetector(onTap:()=>setState(()=>s?_customDays.remove(d):_customDays.add(d)),
                  child:AnimatedContainer(duration:const Duration(milliseconds:180),width:38,height:38,margin:const EdgeInsets.only(right:8),
                    decoration:BoxDecoration(color:s?color:TH.cardAlt(context),borderRadius:BorderRadius.circular(10),border:Border.all(color:s?color:TH.border(context))),
                    child:Center(child:Text(_days[i],style:TextStyle(fontSize:11,fontWeight:FontWeight.w600,color:s?Colors.white:TH.sub(context))))));
              }))],

            const SizedBox(height:14),
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
              _lbl(context,'Quantitative Habit?'),
              Switch(value:_isQuant,onChanged:(v)=>setState(()=>_isQuant=v),activeTrackColor:color,activeColor:Colors.white,inactiveThumbColor:Colors.white),
            ]),
            if(_isQuant)...[
              const SizedBox(height:10),
              Row(children:[
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  _lbl(context,'Daily Target'),
                  const SizedBox(height:8),
                  Row(children:[
                    GestureDetector(onTap:()=>setState(()=>_target=(_target-1).clamp(1,999)),
                      child:Container(width:36,height:36,decoration:BoxDecoration(color:color.withOpacity(0.15),borderRadius:BorderRadius.circular(10),border:Border.all(color:color)),
                        child:Icon(Icons.remove,color:color,size:18))),
                    const SizedBox(width:12),
                    Text(_target.toStringAsFixed(0),style:TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:TH.text(context))),
                    const SizedBox(width:12),
                    GestureDetector(onTap:()=>setState(()=>_target=(_target+1).clamp(1,999)),
                      child:Container(width:36,height:36,decoration:BoxDecoration(color:color.withOpacity(0.15),borderRadius:BorderRadius.circular(10),border:Border.all(color:color)),
                        child:Icon(Icons.add,color:color,size:18))),
                  ]),
                ])),
                const SizedBox(width:16),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  _lbl(context,'Unit'),
                  const SizedBox(height:8),
                  Wrap(spacing:6,runSpacing:6,children:_commonUnits.map((u)=>GestureDetector(onTap:()=>setState(()=>_unit=u),
                    child:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),
                      decoration:BoxDecoration(color:_unit==u?color.withOpacity(0.15):TH.cardAlt(context),borderRadius:BorderRadius.circular(8),border:Border.all(color:_unit==u?color:TH.border(context))),
                      child:Text(u,style:TextStyle(fontSize:11,fontWeight:FontWeight.w600,color:_unit==u?color:TH.sub(context)))))).toList()),
                ])),
              ]),
            ],
            const SizedBox(height:14),
            _lbl(context,'Note (optional)'),const SizedBox(height:8),
            TextFormField(controller:_noteC,maxLines:2,style:TextStyle(color:TH.text(context)),
              decoration:InputDecoration(hintText:'Why does this habit matter?',prefixIcon:Icon(Iconsax.note,color:TH.muted(context),size:18))),
            const SizedBox(height:22),
            GradBtn(label:widget.edit!=null?'Update Habit':'Create Habit 🔥',onTap:_save),
          ])),
        )),
      ]),
    );
  }

  void _pickIcon(BuildContext context)=>showModalBottomSheet(context:context,backgroundColor:TH.surface(context),
    shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(24))),
    builder:(_)=>Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,children:[
      Text('Choose Icon',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700,color:TH.text(context))),
      const SizedBox(height:14),
      Wrap(spacing:12,runSpacing:12,children:K.habitIcons.map((ic)=>GestureDetector(onTap:(){setState(()=>_icon=ic);Navigator.pop(context);},
        child:Container(width:52,height:52,decoration:BoxDecoration(color:ic==_icon?AC.palette[_ci].withOpacity(0.2):TH.cardAlt(context),
          borderRadius:BorderRadius.circular(14),border:Border.all(color:ic==_icon?AC.palette[_ci]:TH.border(context))),
          child:Center(child:Text(ic,style:const TextStyle(fontSize:26)))))).toList()),
      const SizedBox(height:14),
    ])));

  Widget _lbl(BuildContext c,String t)=>Text(t,style:TextStyle(fontSize:13,fontWeight:FontWeight.w600,color:TH.sub(c),letterSpacing:0.3));
}
// Note: Reminder logic added to HabitModel and providers
// Per-habit reminder can be set from habit detail screen
