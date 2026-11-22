import 'package:flutter/material.dart';

import '../core/explain.dart';
import '../core/interpret.dart';
import '../core/runner.dart';
import '../core/tasks.dart';
import 'widgets.dart';

enum StepStatus { idle, running, done, failed }

class _StepState {
  StepStatus status = StepStatus.idle;
  RunResult? result;
  List<Insight> insights = const [];
}

/// 跑一个预设任务：一条一条执行，每次都先说清楚在干什么，再给结果。
class TaskPage extends StatefulWidget {
  final BenchTask task;

  const TaskPage({super.key, required this.task});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final _runner = const CommandRunner();
  late List<_StepState> _states;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _states = List.generate(widget.task.steps.length, (_) => _StepState());
  }

  Future<void> _runAll() async {
    if (_running) return;
    setState(() {
      _running = true;
      _states = List.generate(widget.task.steps.length, (_) => _StepState());
    });

    for (var i = 0; i < widget.task.steps.length; i++) {
      if (!mounted) return;
      setState(() => _states[i].status = StepStatus.running);
      final r = await _runner.run(widget.task.steps[i].command);
      if (!mounted) return;
      setState(() {
        _states[i].result = r;
        _states[i].insights = interpret(r);
        _states[i].status = r.ok ? StepStatus.done : StepStatus.failed;
      });
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }

    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.task.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.flag_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.task.promise,
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < widget.task.steps.length; i++) ...[
            _StepCard(
              index: i + 1,
              step: widget.task.steps[i],
              state: _states[i],
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _running ? null : _runAll,
        icon: _running
            ? const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.play_arrow_rounded),
        label: Text(_running ? '正在跑…' : (_states.any((s) => s.status != StepStatus.idle) ? '再跑一遍' : '开始')),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final TaskStep step;
  final _StepState state;

  const _StepCard({required this.index, required this.step, required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final exp = explain(step.command);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusDot(state.status, index),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step.goal,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MonoBlock('\$ ${step.command}', size: 12.5),
          const SizedBox(height: 10),
          ExplainView(exp),
          if (state.insights.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text('翻译成人话', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final ins in state.insights) InsightTile(ins),
            if (state.result != null && state.result!.visibleOutput.isNotEmpty)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text('原始输出', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  children: [MonoBlock(state.result!.visibleOutput, size: 11.5)],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final StepStatus status;
  final int index;

  const _StatusDot(this.status, this.index);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (status == StepStatus.running) {
      return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
    }
    final (bg, fg, icon) = switch (status) {
      StepStatus.done => (const Color(0xFF4CAF50), Colors.white, Icons.check),
      StepStatus.failed => (const Color(0xFFE53935), Colors.white, Icons.close),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant, null),
    };
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: icon == null
          ? Text('$index', style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w700))
          : Icon(icon, size: 13, color: fg),
    );
  }
}
