import 'package:flutter/material.dart';

import 'core/tasks.dart';
import 'ui/cmd_page.dart';
import 'ui/task_page.dart';

void main() => runApp(const RenhuaApp());

class RenhuaApp extends StatelessWidget {
  const RenhuaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '人话',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4DB6AC),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 26, 18, 28),
          children: [
            Text(
              '人话',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '手机上的 Linux，先说人话再动手',
              style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '这个 App 不讲语法。它只做一件事：在你敲下一条命令之前，用中文告诉你它要干什么、会不会弄坏东西；跑完之后，把那一堆英文说成人话。',
                style: TextStyle(fontSize: 13, height: 1.7, color: scheme.onSurface),
              ),
            ),
            const SizedBox(height: 24),
            Text('选一个任务',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            for (final t in benchTasks) ...[
              _TaskTile(task: t),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
            const _CmdTile(),
            const SizedBox(height: 26),
            Divider(color: scheme.outlineVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 14),
            Text(
              '命令直接跑在 App 自己的沙箱里（/system/bin/sh），不需要 root，也不需要装 Termux。'
              '代价是看不到别人的文件——这正是新手该有的边界。',
              style: TextStyle(fontSize: 11.5, height: 1.6, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final BenchTask task;

  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => TaskPage(task: task)),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  Text('${task.steps.length} 步',
                      style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _CmdTile extends StatelessWidget {
  const _CmdTile();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CmdPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.keyboard_alt_outlined, size: 18, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('自己敲一条',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: scheme.primary)),
                  const SizedBox(height: 4),
                  Text('边打边解释，不确定的会直说',
                      style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}
