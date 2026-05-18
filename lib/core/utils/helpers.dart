import 'package:intl/intl.dart';

class H {
  static String date(DateTime d)      => DateFormat('dd MMM yyyy').format(d);
  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);
  static String weekday(DateTime d)   => DateFormat('EEE').format(d);
  static String shortDate(DateTime d) => DateFormat('dd MMM').format(d);
  static String fmtKey(DateTime d)    => DateFormat('yyyy-MM-dd').format(d);
  static bool   sameDay(DateTime a,DateTime b) => a.year==b.year&&a.month==b.month&&a.day==b.day;
  static DateTime today() { final n=DateTime.now(); return DateTime(n.year,n.month,n.day); }
  static DateTime daysAgo(int n) { final t=today(); return DateTime(t.year,t.month,t.day-n); }

  static String streakLabel(int n) {
    if(n==0) return 'Start today!';
    if(n==1) return '1 day 🔥';
    if(n<7)  return '$n days 🔥';
    if(n<30) return '$n days 🔥🔥';
    return '$n days 🔥🔥🔥';
  }

  static String completionLabel(double p) {
    if(p>=1.0) return 'Perfect day! 🏆';
    if(p>=0.7) return 'Great work! 💪';
    if(p>=0.5) return 'Good progress 👍';
    if(p>=0.3) return 'Keep going! 💡';
    if(p>0)    return 'Just started 🌱';
    return 'Let\'s begin! 🚀';
  }

  static const List<String> quotes = [
    '"We are what we repeatedly do. Excellence is not an act, but a habit." — Aristotle',
    '"The secret of getting ahead is getting started." — Mark Twain',
    '"Small daily improvements are the key to staggering long-term results." — Unknown',
    '"Motivation gets you going, but habit gets you there." — Zig Ziglar',
    '"You do not rise to the level of your goals. You fall to the level of your systems." — James Clear',
    '"A habit is a formula our brain automatically follows." — Charles Duhigg',
    '"Success is the sum of small efforts repeated day in and day out." — Robert Collier',
    '"The difference between who you are and who you want to be is what you do." — Unknown',
    '"Consistency is the true foundation of trust." — Roy T. Bennett',
    '"Every action you take is a vote for the person you want to become." — James Clear',
    '"It\'s not about perfect. It\'s about effort." — Jillian Michaels',
    '"Dream big. Start small. Act now." — Robin Sharma',
  ];

  static String dailyQuote() {
    final idx = DateTime.now().dayOfYear % quotes.length;
    return quotes[idx];
  }
}

extension DateTimeExt on DateTime {
  int get dayOfYear {
    return difference(DateTime(year, 1, 1)).inDays;
  }
}
