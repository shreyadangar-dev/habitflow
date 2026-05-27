import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../data/db/db.dart';
import '../../data/models/habit_model.dart';
import '../../providers/providers.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archived = DB.archived();

    return Scaffold(
      backgroundColor: TH.bg(context),
      body: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
        SliverAppBar(
          backgroundColor: TH.bg(context), pinned: true, expandedHeight: 96,
          leading: GestureDetector(onTap: () => Navigator.pop(context),
              child: Icon(Iconsax.arrow_left, color: TH.text(context))),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(55, 0, 20, 16),
            title: Text('Archived Habits', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: TH.text(context)))),
        ),

        if (archived.isEmpty)
          SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('📦', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('No archived habits', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: TH.text(context))),
            const SizedBox(height: 8),
            Text('Swipe a habit left on the home screen to archive it', textAlign: TextAlign.center,
                style: TextStyle(color: TH.muted(context))),
          ])))
        else
          SliverList(delegate: SliverChildBuilderDelegate((_, i) {
            final h = archived[i];
            final color = AC.palette[h.colorIndex % AC.palette.length];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TH.card(context), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TH.border(context))),
              child: Row(children: [
                Container(width: 48, height: 48,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(h.icon, style: const TextStyle(fontSize: 24)))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: TH.text(context))),
                  Text('${h.category} · ${h.totalCompletions} completions',
                      style: TextStyle(fontSize: 12, color: TH.muted(context))),
                ])),
                // Restore button
                GestureDetector(
                  onTap: () => _restore(context, ref, h),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: AC.success.withOpacity(0.12), borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AC.success.withOpacity(0.3))),
                    child: const Text('Restore', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AC.success))),
                ),
                const SizedBox(width: 8),
                // Delete permanently
                GestureDetector(
                  onTap: () => _deletePermanently(context, ref, h),
                  child: Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AC.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Iconsax.trash, color: AC.danger, size: 18)),
                ),
              ]),
            ).animate().fadeIn(delay: Duration(milliseconds: 50 * i));
          }, childCount: archived.length)),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ]),
    );
  }

  void _restore(BuildContext ctx, WidgetRef ref, HabitModel h) async {
    h.isArchived = false;
    await DB.save(h);
    ref.read(habitProv.notifier).reload();
    if (ctx.mounted) {
      Navigator.pop(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('${h.name} restored! ✅'),
        backgroundColor: AC.success, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  void _deletePermanently(BuildContext ctx, WidgetRef ref, HabitModel h) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: TH.surface(ctx),
      title: Text('Delete permanently?', style: TextStyle(color: TH.text(ctx))),
      content: Text('This will permanently delete "${h.name}" and all its history.',
          style: TextStyle(color: TH.sub(ctx))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: TH.muted(ctx)))),
        TextButton(onPressed: () async {
          await DB.delete(h.id);
          ref.read(habitProv.notifier).reload();
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Delete', style: TextStyle(color: AC.danger))),
      ]));
  }
}
