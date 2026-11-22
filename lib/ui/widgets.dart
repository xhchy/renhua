import 'package:flutter/material.dart';

import '../core/explain.dart';
import '../core/interpret.dart';
import '../core/shell_cmd.dart';

/// 等宽字体块：命令原文和原始输出都用它。
class MonoBlock extends StatelessWidget {
  final String text;
  final Color? color;
  final double size;

  const MonoBlock(this.text, {super.key, this.color, this.size = 13});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: size,
          height: 1.45,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// 风险徽章。危险用红色，改动用琥珀，只读用绿。
class RiskChip extends StatelessWidget {
  final Risk risk;

  const RiskChip(this.risk, {super.key});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (risk) {
      Risk.safe => (const Color(0xFF4CAF50), Icons.visibility_outlined),
      Risk.caution => (const Color(0xFFFFB300), Icons.edit_outlined),
      Risk.danger => (const Color(0xFFE53935), Icons.warning_amber_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(risk.label, style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// 解释卡片：把 explain() 的结果渲染成「动词 / 对象 / 开关 / 为什么」几行。
class ExplainView extends StatelessWidget {
  final Explanation exp;

  const ExplainView(this.exp, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                exp.summary,
                style: const TextStyle(fontSize: 14.5, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            RiskChip(exp.risk),
          ],
        ),
        const SizedBox(height: 10),
        for (final line in exp.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 62,
                  child: Text(
                    line.label,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: scheme.primary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      height: 1.55,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    line.text,
                    style: const TextStyle(fontSize: 13, height: 1.55),
                  ),
                ),
              ],
            ),
          ),
        if (!exp.known)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '这条命令不在我的知识库里。上面的拆解只讲了结构，含义不确定——别把「我猜的」当成「我知道的」。',
              style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFFFFCA28)),
            ),
          ),
        if (exp.gaps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '有 ${exp.gaps.length} 个开关我不认识，已在上面标出。',
              style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

/// 一条人话结论。
class InsightTile extends StatelessWidget {
  final Insight insight;

  const InsightTile(this.insight, {super.key});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (insight.severity) {
      Severity.good => (const Color(0xFF4CAF50), Icons.check_circle_outline),
      Severity.notice => (const Color(0xFF42A5F5), Icons.info_outline),
      Severity.warn => (const Color(0xFFFFA726), Icons.error_outline),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(left: BorderSide(color: color)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: color),
                ),
                const SizedBox(height: 3),
                Text(insight.body, style: const TextStyle(fontSize: 12.5, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
