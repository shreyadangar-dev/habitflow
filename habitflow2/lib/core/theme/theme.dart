import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AT {
  static ThemeData dark()  => _build(true);
  static ThemeData light() => _build(false);
  static ThemeData _build(bool d) {
    final bg=d?AC.dBg:AC.lBg; final sf=d?AC.dSurface:AC.lSurface;
    final cd=d?AC.dCard:AC.lCard; final br=d?AC.dBorder:AC.lBorder;
    final tx=d?AC.dText:AC.lText; final ts=d?AC.dTextSub:AC.lTextSub;
    final mu=d?AC.dMuted:AC.lMuted; final alt=d?AC.dCardAlt:AC.lCardAlt;
    return ThemeData(
      useMaterial3: true, brightness: d?Brightness.dark:Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: d
        ? ColorScheme.dark(primary:AC.primary,secondary:AC.success,surface:sf,error:AC.danger)
        : ColorScheme.light(primary:AC.primary,secondary:AC.success,surface:sf,error:AC.danger),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge:  GoogleFonts.plusJakartaSans(fontSize:32,fontWeight:FontWeight.w800,color:tx,letterSpacing:-1),
        headlineLarge: GoogleFonts.plusJakartaSans(fontSize:24,fontWeight:FontWeight.w700,color:tx),
        headlineMedium:GoogleFonts.plusJakartaSans(fontSize:20,fontWeight:FontWeight.w700,color:tx),
        titleLarge:    GoogleFonts.plusJakartaSans(fontSize:16,fontWeight:FontWeight.w600,color:tx),
        bodyLarge:     GoogleFonts.plusJakartaSans(fontSize:14,color:tx),
        bodyMedium:    GoogleFonts.plusJakartaSans(fontSize:12,color:ts),
        labelLarge:    GoogleFonts.plusJakartaSans(fontSize:14,fontWeight:FontWeight.w600,color:tx),
      ),
      appBarTheme: AppBarTheme(backgroundColor:Colors.transparent,elevation:0,
        systemOverlayStyle:d?SystemUiOverlayStyle.light:SystemUiOverlayStyle.dark,
        iconTheme:IconThemeData(color:tx),
        titleTextStyle:GoogleFonts.plusJakartaSans(fontSize:20,fontWeight:FontWeight.w700,color:tx)),
      cardTheme: CardThemeData(color:cd,elevation:0,shape:RoundedRectangleBorder(
        borderRadius:BorderRadius.circular(20),side:BorderSide(color:br))),
      inputDecorationTheme: InputDecorationTheme(filled:true,fillColor:alt,
        border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide(color:br)),
        enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide(color:br)),
        focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:const BorderSide(color:AC.primary,width:2)),
        hintStyle:GoogleFonts.plusJakartaSans(color:mu,fontSize:14),
        contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:14)),
      elevatedButtonTheme: ElevatedButtonThemeData(style:ElevatedButton.styleFrom(
        backgroundColor:AC.primary,foregroundColor:Colors.white,elevation:0,
        padding:const EdgeInsets.symmetric(horizontal:24,vertical:15),
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),
        textStyle:GoogleFonts.plusJakartaSans(fontSize:15,fontWeight:FontWeight.w600))),
      switchTheme: SwitchThemeData(
        thumbColor:WidgetStateProperty.resolveWith((s)=>s.contains(WidgetState.selected)?Colors.white:mu),
        trackColor:WidgetStateProperty.resolveWith((s)=>s.contains(WidgetState.selected)?AC.primary:br)),
      dividerTheme: DividerThemeData(color:br,thickness:1),
      dialogTheme: DialogThemeData(backgroundColor:sf,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(24))),
    );
  }
}

class TH {
  static bool  dark(BuildContext c)    => Theme.of(c).brightness==Brightness.dark;
  static Color bg(BuildContext c)      => dark(c)?AC.dBg:AC.lBg;
  static Color surface(BuildContext c) => dark(c)?AC.dSurface:AC.lSurface;
  static Color card(BuildContext c)    => dark(c)?AC.dCard:AC.lCard;
  static Color cardAlt(BuildContext c) => dark(c)?AC.dCardAlt:AC.lCardAlt;
  static Color border(BuildContext c)  => dark(c)?AC.dBorder:AC.lBorder;
  static Color text(BuildContext c)    => dark(c)?AC.dText:AC.lText;
  static Color sub(BuildContext c)     => dark(c)?AC.dTextSub:AC.lTextSub;
  static Color muted(BuildContext c)   => dark(c)?AC.dMuted:AC.lMuted;
}
