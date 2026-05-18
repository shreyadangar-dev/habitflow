import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/theme.dart';

class Chip2 extends StatelessWidget {
  final String label; final bool selected; final Color color; final VoidCallback onTap;
  const Chip2({super.key,required this.label,required this.selected,required this.color,required this.onTap});
  @override
  Widget build(BuildContext context)=>GestureDetector(onTap:onTap,
    child:AnimatedContainer(duration:const Duration(milliseconds:180),
      padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),
      decoration:BoxDecoration(color:selected?color.withOpacity(0.18):TH.cardAlt(context),
        borderRadius:BorderRadius.circular(12),border:Border.all(color:selected?color:TH.border(context),width:selected?1.5:1)),
      child:Text(label,style:TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:selected?color:TH.sub(context)))));
}

class GradBtn extends StatelessWidget {
  final String label; final VoidCallback onTap; final LinearGradient? gradient; final IconData? icon;
  const GradBtn({super.key,required this.label,required this.onTap,this.gradient,this.icon});
  @override
  Widget build(BuildContext context)=>GestureDetector(onTap:onTap,child:Container(width:double.infinity,
    padding:const EdgeInsets.symmetric(vertical:16),
    decoration:BoxDecoration(gradient:gradient??AC.grad,borderRadius:BorderRadius.circular(16),
      boxShadow:[BoxShadow(color:AC.primary.withOpacity(0.3),blurRadius:20,offset:const Offset(0,8))]),
    child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
      if(icon!=null)...[Icon(icon,color:Colors.white,size:18),const SizedBox(width:8)],
      Text(label,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w700,color:Colors.white)),
    ])));
}

class SecHdr extends StatelessWidget {
  final String title; final Widget? trailing;
  const SecHdr({super.key,required this.title,this.trailing});
  @override
  Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(horizontal:20,vertical:8),
    child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      Text(title,style:TextStyle(fontSize:16,fontWeight:FontWeight.w700,color:TH.text(context))),
      if(trailing!=null)trailing!,
    ]));
}
