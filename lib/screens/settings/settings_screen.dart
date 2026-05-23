import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../data/db/db.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s      = ref.watch(settingsProv);
    final habits = ref.watch(habitProv);
    final total  = habits.fold(0, (sum, h) => sum + h.totalCompletions);
    final best   = habits.isEmpty ? 0 : habits.map((h) => h.longestStreak).reduce((a,b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: TH.bg(context),
      body: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
        SliverAppBar(backgroundColor: TH.bg(context), pinned: true, expandedHeight: 96,
          leading: GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Iconsax.arrow_left, color: TH.text(context))),
          flexibleSpace: FlexibleSpaceBar(titlePadding: const EdgeInsets.fromLTRB(55, 0, 20, 16),
            title: Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: TH.text(context))))),

        // Profile card
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20),
          child: Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2D1B6B), Color(0xFF0D1A3D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24), border: Border.all(color: AC.primary.withOpacity(0.3))),
            child: Row(children: [
              Container(width: 58, height: 58, decoration: const BoxDecoration(gradient: AC.grad, shape: BoxShape.circle),
                child: Center(child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : 'F',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Row(children: [_badge('${habits.length} habits'), const SizedBox(width: 6),
                  _badge('$total done'), const SizedBox(width: 6), _badge('🔥 $best best')]),
              ])),
              GestureDetector(onTap: () => _editName(context, ref, s.name),
                child: Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AC.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Iconsax.edit, color: AC.pLight, size: 18))),
            ])))),

        // Appearance
        SliverToBoxAdapter(child: _Sec('🎨 Appearance', [
          _Tile(Iconsax.moon, AC.primary, 'Dark Mode', s.dark ? 'Enabled' : 'Disabled',
              trailing: Switch(value: s.dark, onChanged: (v) => ref.read(settingsProv.notifier).setDark(v), activeColor: AC.primary)),
        ])),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Enhancement #5: Backup & Restore
        SliverToBoxAdapter(child: _Sec('📦 Backup & Restore', [
          _Tile(Iconsax.export, AC.success, 'Export Data', 'Share your habits as JSON backup',
            onTap: () => _export(context),
            trailing: Icon(Iconsax.arrow_right_3, color: TH.muted(context), size: 16)),
          const Divider(height: 1),
          _Tile(Iconsax.import, AC.warning, 'Import Data', 'Restore from a JSON backup',
            onTap: () => _import(context, ref),
            trailing: Icon(Iconsax.arrow_right_3, color: TH.muted(context), size: 16)),
          const Divider(height: 1),
          // BUG FIX #1: Clear all now reloads UI immediately
          _Tile(Iconsax.trash, AC.danger, 'Clear All Data', 'Permanently delete everything',
            onTap: () => _confirmClear(context, ref),
            trailing: Icon(Iconsax.arrow_right_3, color: TH.muted(context), size: 16)),
        ])),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // About
        SliverToBoxAdapter(child: _Sec('ℹ️ About', [
          _Tile(Iconsax.info_circle, AC.info, 'HabitFlow', 'Version 3.0.0 — Advanced Edition'),
          const Divider(height: 1),
          // Enhancement #3: Functional Rate Us
          _Tile(Iconsax.star_1, AC.warning, 'Rate HabitFlow ⭐', 'Love it? Leave a review!',
            onTap: () => _rateApp(),
            trailing: Icon(Iconsax.arrow_right_3, color: TH.muted(context), size: 16)),
          const Divider(height: 1),
          _Tile(Iconsax.share, AC.success, 'Share HabitFlow', 'Share with friends',
            onTap: () => Share.share('I am building better habits with HabitFlow! 🔥 Try it!'),
            trailing: Icon(Iconsax.arrow_right_3, color: TH.muted(context), size: 16)),
        ])),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ]),
    );
  }

  Widget _badge(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(t, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500)));

  void _editName(BuildContext ctx, WidgetRef ref, String cur) {
    final c = TextEditingController(text: cur);
    showDialog(context: ctx, builder: (_) => AlertDialog(backgroundColor: TH.surface(ctx),
      title: Text('Your Name', style: TextStyle(color: TH.text(ctx))),
      content: TextField(controller: c, style: TextStyle(color: TH.text(ctx))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: TH.muted(ctx)))),
        TextButton(onPressed: () { ref.read(settingsProv.notifier).setName(c.text.trim().isEmpty ? 'Friend' : c.text.trim()); Navigator.pop(ctx); },
            child: const Text('Save', style: TextStyle(color: AC.primary))),
      ]));
  }

  // Enhancement #3: Opens Play Store
  Future<void> _rateApp() async {
    final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.rishvi.habitflow');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // Enhancement #5: Export
  void _export(BuildContext ctx) {
    final json = const JsonEncoder.withIndent('  ').convert(DB.exportToJson());
    Share.share(json, subject: 'HabitFlow Backup ${DateTime.now().toIso8601String().substring(0,10)}');
  }

  // Enhancement #5: Import
  void _import(BuildContext ctx, WidgetRef ref) {
    final c = TextEditingController();
    showDialog(context: ctx, builder: (_) => AlertDialog(backgroundColor: TH.surface(ctx),
      title: Text('Restore Backup', style: TextStyle(color: TH.text(ctx))),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Paste your exported JSON below:', style: TextStyle(color: TH.sub(ctx), fontSize: 13)),
        const SizedBox(height: 10),
        TextField(controller: c, maxLines: 6, style: TextStyle(color: TH.text(ctx), fontSize: 12),
            decoration: InputDecoration(hintText: 'Paste JSON here...', hintStyle: TextStyle(color: TH.muted(ctx)))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: TH.muted(ctx)))),
        TextButton(onPressed: () async {
          try {
            await DB.importFromJson(jsonDecode(c.text) as Map<String, dynamic>);
            // BUG FIX #1: Reload all providers
            ref.read(habitProv.notifier).reload();
            ref.read(journalProv.notifier).reload();
            if (ctx.mounted) { Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Restored! ✅'), backgroundColor: AC.success, behavior: SnackBarBehavior.floating)); }
          } catch (e) {
            if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Invalid JSON: $e'), backgroundColor: AC.danger, behavior: SnackBarBehavior.floating));
          }
        }, child: const Text('Restore', style: TextStyle(color: AC.primary))),
      ]));
  }

  // BUG FIX #1: Clear all refreshes UI immediately
  void _confirmClear(BuildContext ctx, WidgetRef ref) => showDialog(context: ctx,
    builder: (_) => AlertDialog(backgroundColor: TH.surface(ctx),
      title: Text('Clear all data?', style: TextStyle(color: TH.text(ctx))),
      content: Text('This permanently deletes all habits and journal entries.', style: TextStyle(color: TH.sub(ctx))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: TH.muted(ctx)))),
        TextButton(onPressed: () async {
          await DB.clearAll();
          ref.read(habitProv.notifier).reload();
          ref.read(journalProv.notifier).reload();
          if (ctx.mounted) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
              content: Text('All data cleared ✅'), backgroundColor: AC.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)))));
          }
        }, child: const Text('Delete', style: TextStyle(color: AC.danger))),
      ]));
}

class _Sec extends StatelessWidget {
  final String t; final List<Widget> c;
  const _Sec(this.t, this.c);
  @override
  Widget build(BuildContext ctx) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TH.sub(ctx)))),
      Container(decoration: BoxDecoration(color: TH.card(ctx), borderRadius: BorderRadius.circular(20), border: Border.all(color: TH.border(ctx))), child: Column(children: c)),
    ]));
}

class _Tile extends StatelessWidget {
  final IconData icon; final Color ic; final String t, s; final VoidCallback? onTap; final Widget? trailing;
  const _Tile(this.icon, this.ic, this.t, this.s, {this.onTap, this.trailing});
  @override
  Widget build(BuildContext ctx) => ListTile(onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: ic.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: ic, size: 20)),
    title: Text(t, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TH.text(ctx))),
    subtitle: Text(s, style: TextStyle(fontSize: 12, color: TH.muted(ctx))), trailing: trailing);
}
