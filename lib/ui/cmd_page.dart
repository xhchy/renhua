import 'package:flutter/material.dart';

import '../core/explain.dart';
import '../core/interpret.dart';
import '../core/runner.dart';
import 'widgets.dart';

/// 自己敲一条命令：边打边解释，跑完再翻译结果。
class CmdPage extends StatefulWidget {
  final String? initial;

  const CmdPage({super.key, this.initial});

  @override
  State<CmdPage> createState() => _CmdPageState();
}

class _CmdPageState extends State<CmdPage> {
  late final TextEditingController _ctrl;
  final _runner = const CommandRunner();
  RunResult? _result;
  List<Insight> _insights = const [];
  bool _running = false;

  static const _samples = <String>[
    'df -h',
    'cat /proc/meminfo | head -3',
    'uname -a',
    'getprop ro.build.version.release',
    'id',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final cmd = _ctrl.text.trim();
    if (cmd.isEmpty || _running) return;
    setState(() {
      _running = true;
      _result = null;
      _insights = const [];
    });
    final r = await _runner.run(cmd);
    if (!mounted) return;
    setState(() {
      _running = false;
      _result = r;
      _insights = interpret(r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = _ctrl.text.trim();
    final exp = explain(text);

    return Scaffold(
      appBar: AppBar(title: const Text('自己敲一条')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'df -h',
              hintStyle: const TextStyle(fontFamily: 'monospace'),
              prefixText: '\$ ',
              prefixStyle: TextStyle(fontFamily: 'monospace', color: scheme.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _ctrl.clear()),
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _run(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final s in _samples)
                ActionChip(
                  label: Text(s, style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5)),
                  onPressed: () {
                    setState(() {
                      _ctrl.text = s;
                      _result = null;
                      _insights = const [];
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '跑之前先讲清楚',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  ExplainView(exp),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              child: FilledButton.icon(
                onPressed: _running ? null : _run,
                icon: _running
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(_running ? '正在跑…' : '执行'),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '在上面输入任意 shell 命令。我会先把它拆开讲清楚（动词、对象、每个开关），再执行，最后把结果翻译成人话。\n\n'
                '不认识的我不会瞎编，会直接告诉你「我不认识」。',
                style: TextStyle(fontSize: 13, height: 1.65, color: scheme.onSurfaceVariant),
              ),
            ),
          if (_result != null) ...[
            const SizedBox(height: 18),
            Text(
              _result!.ok ? '结果（退出码 0，用时 ${_result!.durationMs}ms）' : '结果（退出码 ${_result!.exitCode}）',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            for (final ins in _insights) InsightTile(ins),
            if (_result!.visibleOutput.isNotEmpty) ...[
              const SizedBox(height: 6),
              MonoBlock(_result!.visibleOutput, size: 11.5),
            ],
          ],
        ],
      ),
    );
  }
}
