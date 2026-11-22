import 'knowledge.dart';
import 'runner.dart';

/// 一句话结论的严重程度，决定卡片颜色。
enum Severity { good, notice, warn }

/// 从原始输出里提炼出来的一条人话结论。
class Insight {
  final String title;
  final String body;
  final Severity severity;

  const Insight(this.title, this.body, this.severity);
}

/// 把「一堆英文输出」翻译成「几句人话」。
///
/// 只在能确定的时候下结论：解析失败就退回到「原样给你看」，
/// 不猜。新手最怕的不是看不懂，是看到了一个自信但错误的解释。
List<Insight> interpret(RunResult r) {
  final out = <Insight>[];

  if (r.timedOut) {
    out.add(const Insight('卡住了', '这条命令在限定时间内没有结束。常见原因是它在等输入，或者在下一盘很大的东西。', Severity.warn));
    return out;
  }

  // 失败优先讲，而且要先讲原因，不要先甩栈。
  if (r.exitCode != 0) {
    final reason = _matchError('${r.stderr}\n${r.stdout}');
    out.add(Insight(
      '没跑成（退出码 ${r.exitCode}）',
      reason ?? '命令自己报了失败，但我没认出具体原因。下面的原始输出里应该有关键词。',
      Severity.warn,
    ));
  }

  final program = r.command.trim().split(RegExp(r'\s+')).first;
  switch (program) {
    case 'df':
      out.addAll(_explainDf(r.stdout));
    case 'cat':
      if (r.command.contains('meminfo')) out.addAll(_explainMeminfo(r.stdout));
    case 'free':
      out.addAll(_explainMeminfo(r.stdout));
    case 'uname':
      out.addAll(_explainUname(r.stdout));
    case 'id':
      out.addAll(_explainId(r.stdout));
    case 'getprop':
      out.addAll(_explainGetprop(r.stdout));
    case 'du':
      out.addAll(_explainDu(r.stdout));
    case 'which':
      out.addAll(_explainWhich(r));
  }

  if (out.isEmpty) {
    if (r.visibleOutput.isEmpty) {
      out.add(const Insight('没有输出', '这不等于失败。很多命令成功时就是一言不发——没消息就是好消息。', Severity.good));
    } else {
      final n = r.visibleOutput.split('\n').length;
      out.add(Insight('拿到 $n 行输出', '我没有专门解析这条命令，你可以对照上面的「结果怎么看」自己看原文。', Severity.notice));
    }
  }

  if (r.truncated) {
    out.add(const Insight('输出被截断了', '只显示了前面一部分。想看完整内容，用 grep 或者 head 缩小范围。', Severity.notice));
  }

  return out;
}

String? _matchError(String text) {
  for (final entry in errorBook.entries) {
    if (text.contains(entry.key)) return entry.value;
  }
  return null;
}

/// df 的关键是 Use% 那一列。
List<Insight> _explainDf(String stdout) {
  final out = <Insight>[];
  final rows = <(String, int, String)>[]; // mount, percent, size
  for (final line in stdout.split('\n')) {
    final t = line.trim();
    if (t.isEmpty) continue;
    final m = RegExp(r'^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\d+)%\s+(\S+)').firstMatch(t);
    if (m == null) continue;
    rows.add((m.group(6)!, int.parse(m.group(5)!), m.group(2)!));
  }
  if (rows.isEmpty) return out;

  rows.sort((a, b) => b.$2.compareTo(a.$2));
  final worst = rows.first;

  if (worst.$2 >= 95) {
    out.add(Insight(
      '几乎满了：${worst.$1}',
      '这块只剩 ${100 - worst.$2}% 的空间（用了 ${worst.$2}%）。再装东西很可能直接失败。',
      Severity.warn,
    ));
  } else if (worst.$2 >= 85) {
    out.add(Insight(
      '偏紧：${worst.$1}',
      '用了 ${worst.$2}%，建议清一些东西。安卓在空间不足时会开始杀后台。',
      Severity.notice,
    ));
  } else {
    out.add(Insight(
      '空间还算宽裕',
      '占用最高的一块是 ${worst.$1}，用了 ${worst.$2}%。共 ${rows.length} 块存储。',
      Severity.good,
    ));
  }

  final data = rows.where((r) => r.$1 == '/data').toList();
  if (data.isNotEmpty) {
    out.add(Insight('/data 是重点', '/data 是 App 数据所在的分区，现在用了 ${data.first.$2}%。装环境、存文件都吃这一块。', Severity.notice));
  }
  return out;
}

List<Insight> _explainMeminfo(String stdout) {
  final out = <Insight>[];
  int? total, avail;
  for (final line in stdout.split('\n')) {
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 2) continue;
    final kb = int.tryParse(parts[1]);
    if (kb == null) continue;
    if (parts[0].startsWith('MemTotal')) total = kb;
    if (parts[0].startsWith('MemAvailable')) avail = kb;
  }
  if (total == null) return out;
  final totalGb = total / 1024 / 1024;
  if (avail == null) {
    out.add(Insight('总内存 ${totalGb.toStringAsFixed(1)} GB', '没读到可用内存那一项。', Severity.notice));
    return out;
  }
  final availGb = avail / 1024 / 1024;
  final ratio = avail / total;
  out.add(Insight(
    '可用内存 ${availGb.toStringAsFixed(1)} GB / 共 ${totalGb.toStringAsFixed(1)} GB',
    ratio < 0.12
        ? '可用不到一成，后台很容易被系统杀掉——装大环境前先关点 App。'
        : '还有 ${(ratio * 100).round()}% 可用，正常跑东西没问题。',
    ratio < 0.12 ? Severity.warn : Severity.good,
  ));
  return out;
}

List<Insight> _explainUname(String stdout) {
  final t = stdout.trim();
  if (t.isEmpty) return const [];
  final isArm = t.contains('aarch64') || t.contains('armv');
  return [
    Insight(
      isArm ? '架构：ARM 64 位（正常手机）' : '架构：${t.split(' ').last}',
      isArm
          ? '装软件要选 aarch64 / arm64 的包，选 x86 的装了跑不起来。'
          : '注意目标架构和这个不一致的包装不上。',
      Severity.good,
    ),
  ];
}

List<Insight> _explainId(String stdout) {
  final m = RegExp(r'uid=(\d+)').firstMatch(stdout);
  if (m == null) return const [];
  final uid = int.parse(m.group(1)!);
  return [
    Insight(
      uid == 0 ? '身份：root（最高权限）' : '身份：普通 App（uid=$uid）',
      uid == 0
          ? 'root 能改任何东西，也因此能一句话把系统弄坏。'
          : '这是安全状态。代价是系统目录只读，动不了别人的文件。',
      uid == 0 ? Severity.notice : Severity.good,
    ),
  ];
}

List<Insight> _explainGetprop(String stdout) {
  final out = <Insight>[];
  final map = <String, String>{};
  for (final line in stdout.split('\n')) {
    final m = RegExp(r'^\[(.+?)\]: \[(.*)\]$').firstMatch(line.trim());
    if (m != null) map[m.group(1)!] = m.group(2)!;
  }
  if (map.isEmpty) return out;
  final ver = map['ro.build.version.release'];
  final model = map['ro.product.model'];
  if (ver != null) out.add(Insight('安卓版本 $ver', '低于 8 的老系统，很多新工具跑不了。', Severity.good));
  if (model != null) out.add(Insight('机型 $model', '查兼容问题时，这个值要一起报出去。', Severity.notice));
  if (out.isEmpty) out.add(Insight('读到 ${map.length} 条系统属性', '没匹配到常见字段，可以自己往下翻。', Severity.notice));
  return out;
}

List<Insight> _explainDu(String stdout) {
  final lines = stdout.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.isEmpty) return const [];
  final last = lines.last.trim();
  return [
    Insight('合计 $last', lines.length > 1 ? '这是总计行。上面 ${lines.length - 1} 行是各子目录各自的体积。' : '只有一行，就是总大小。', Severity.good),
  ];
}

List<Insight> _explainWhich(RunResult r) {
  if (r.visibleOutput.isEmpty) {
    return [
      const Insight(
        '这个命令没装',
        'which 什么也没输出，就是系统里找不到它。先装，再跑。',
        Severity.warn,
      ),
    ];
  }
  return [
    Insight('装在这里', r.visibleOutput.split('\n').first.trim(), Severity.good),
  ];
}
