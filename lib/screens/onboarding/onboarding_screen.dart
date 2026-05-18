import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../providers/providers.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override ConsumerState<OnboardingScreen> createState()=>_S();
}
class _S extends ConsumerState<OnboardingScreen> {
  final _ctrl=PageController();
  int _page=0;
  static const _slides=[
    _Slide('🔥','Build habits that stick','Track your daily habits with streaks, reminders and beautiful progress charts.',AC.grad),
    _Slide('📊','See your progress','GitHub-style heatmaps, completion rates and achievement badges keep you motivated.',AC.greenGrad),
    _Slide('🏆','Reach your goals','Every small action counts. Start today and watch yourself transform.',AC.fireGrad),
  ];

  void _next() {
    if(_page<2) _ctrl.nextPage(duration:const Duration(milliseconds:400),curve:Curves.easeInOut);
    else _finish();
  }
  void _finish() async {
    await ref.read(settingsProv.notifier).setOnboarded();
    if(mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder:(_)=>const HomeScreen()));
  }

  @override
  Widget build(BuildContext context)=>Scaffold(
    body:Stack(children:[
      PageView.builder(controller:_ctrl,onPageChanged:(i)=>setState(()=>_page=i),
        itemCount:_slides.length,
        itemBuilder:(_,i)=>_SlidePage(slide:_slides[i])),
      // Dots
      Positioned(bottom:130,left:0,right:0,child:Row(mainAxisAlignment:MainAxisAlignment.center,
        children:List.generate(3,(i)=>AnimatedContainer(duration:const Duration(milliseconds:300),
          width:_page==i?24:8,height:8,margin:const EdgeInsets.symmetric(horizontal:4),
          decoration:BoxDecoration(color:_page==i?Colors.white:Colors.white.withOpacity(0.4),borderRadius:BorderRadius.circular(4)))))),
      // Buttons
      Positioned(bottom:50,left:24,right:24,child:Row(children:[
        if(_page<2)TextButton(onPressed:_finish,child:const Text('Skip',style:TextStyle(color:Colors.white70,fontSize:15))),
        const Spacer(),
        GestureDetector(onTap:_next,child:Container(
          padding:const EdgeInsets.symmetric(horizontal:32,vertical:14),
          decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)),
          child:Text(_page==2?'Get Started 🚀':'Next',style:const TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:AC.primary)))),
      ])),
    ]),
  );
}

class _Slide {
  final String emoji,title,subtitle; final LinearGradient grad;
  const _Slide(this.emoji,this.title,this.subtitle,this.grad);
}

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({super.key,required this.slide});
  @override
  Widget build(BuildContext context)=>Container(
    decoration:BoxDecoration(gradient:LinearGradient(colors:[
      const Color(0xFF0D0D1A), slide.grad.colors.first.withOpacity(0.6), const Color(0xFF0D0D1A)],
      begin:Alignment.topLeft,end:Alignment.bottomRight)),
    child:Padding(padding:const EdgeInsets.all(40),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Text(slide.emoji,style:const TextStyle(fontSize:80)).animate().scale(duration:600.ms,curve:Curves.elasticOut),
      const SizedBox(height:40),
      Text(slide.title,textAlign:TextAlign.center,style:const TextStyle(fontSize:32,fontWeight:FontWeight.w800,color:Colors.white,letterSpacing:-1))
        .animate().fadeIn(delay:200.ms).slideY(begin:0.2,delay:200.ms),
      const SizedBox(height:16),
      Text(slide.subtitle,textAlign:TextAlign.center,style:TextStyle(fontSize:16,color:Colors.white.withOpacity(0.7),height:1.6))
        .animate().fadeIn(delay:400.ms),
    ])),
  );
}
