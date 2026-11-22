import 'knowledge.dart';
import 'shell_cmd.dart';

/// 解释结果里的一行。
class ExplainLine {
  /// 这一行在讲什么：动词 / 对象 / 开关 / 为什么 / 结果怎么看
  final String label;
  final String text;

  const ExplainLine(this.label, this.text);
}

/// 对一条命令的完整解释。
class Explanation {
  final String raw;
  final String summary;
  final List<ExplainLine> lines;
  final Risk risk;
  final bool known;

  const Explanation({
    required this.raw,
    required this.summary,
    required this.lines,
    required this.risk,
    required this.known,
  });

  /// 没被认识的部分——用来提示「我讲不全，别全信我」。
  List<String> get gaps => lines
      .where((l) => l.label == '开关' && l.text.contains('这个开关我不认识'))
      .map((l) => l.text)
      .toList();
}

/// 把一条命令翻译成人话。
///
/// 设计原则：宁可说「我不认识」，也不硬编一个像模像样的假解释。
/// 猜错比不解释更糟，因为用户会照着错的去操作。
Explanation explain(String raw) {
  final cmd = ShellCommand.parse(raw.trim());
  final risk = judgeRisk(raw);

  if (cmd.program.isEmpty) {
    return Explanation(
      raw: raw,
      summary: '这里还没写命令。',
      lines: const [],
      risk: risk,
      known: true,
    );
  }

  final info = commandBook[cmd.program];
  if (info == null) {
    return Explanation(
      raw: raw,
      summary: '我不认识 `${cmd.program}` 这条命令，所以不敢乱解释。',
      lines: [
        ExplainLine('动词', '`${cmd.program}` —— 知识库里没有它'),
        if (cmd.args.isNotEmpty) ExplainLine('对象', cmd.args.join('、')),
        if (cmd.flags.isNotEmpty) ExplainLine('开关', cmd.flags.join('、')),
        ExplainLine('建议', '可以先跑 `which ${cmd.program}` 看它到底装没装；'
            '要查它的用法，通用写法是 `命令 --help`。'),
      ],
      risk: risk,
      known: false,
    );
  }

  // 正常通道：认识这条命令。
  final lines = <ExplainLine>[
    ExplainLine('动词', '`${cmd.program}` —— ${info.plain}'),
  ];

  for (final a in cmd.args) {
    final note = info.notes[a];
    lines.add(ExplainLine('对象', note == null ? '`$a`' : '`$a` —— $note'));
  }

  for (final f in cmd.flags) {
    final text = _explainFlag(f, info);
    lines.add(ExplainLine('开关', text));
  }

  if (cmd.args.isEmpty && cmd.flags.isEmpty) {
    lines.add(const ExplainLine('作用范围', '没加任何额外参数，作用在当前位置。'));
  }

  lines.add(ExplainLine('为什么用它', info.why));
  lines.add(ExplainLine('结果怎么看', info.howToRead));

  if (risk != Risk.safe) {
    lines.add(ExplainLine('风险', risk.hint));
  }

  return Explanation(
    raw: raw,
    summary: _summary(cmd, info),
    lines: lines,
    risk: risk,
    known: true,
  );
}

/// 拼一句人话总述：动词 + 对象 + 修饰。
String _summary(ShellCommand cmd, CommandInfo info) {
  final buf = StringBuffer(info.plain);
  if (cmd.args.isNotEmpty) {
    buf.write('，针对 ${cmd.args.join('、')}');
  }
  final flagWords = <String>[];
  for (final f in cmd.flags) {
    final w = _flagWord(f, info);
    if (w != null) flagWords.add(w);
  }
  if (flagWords.isNotEmpty) {
    buf.write('，并且${flagWords.join('、')}');
  }
  buf.write('。');
  return buf.toString();
}

/// 把开关翻译成一个短动作，用于总述。不认识就返回 null。
String? _flagWord(String flag, CommandInfo info) {
  final body = flag.replaceFirst(RegExp(r'^-+'), '');
  if (body.isEmpty) return null;
  if (info.notes.containsKey(flag)) return null;
  final parts = <String>[];
  for (final ch in body.split('')) {
    final note = info.notes[ch];
    if (note == null) return null;
    parts.add(note);
  }
  return parts.isEmpty ? null : parts.first;
}

/// 开关逐字解释。组合开关 -lh 会被拆成 -l 和 -h 分别讲。
String _explainFlag(String flag, CommandInfo info) {
  final body = flag.replaceFirst(RegExp(r'^-+'), '');
  if (body.isEmpty) return '`$flag`';
  if (info.notes.containsKey(flag)) {
    return '`$flag` —— ${info.notes[flag]}';
  }
  if (body.length == 1) {
    final note = info.notes[body];
    return note == null
        ? '`$flag` —— 这个开关我不认识，跑之前自己查一下 `$flag` 的用法'
        : '`$flag` —— $note';
  }

  // 组合开关
  final known = <String>[];
  final unknown = <String>[];
  for (final ch in body.split('')) {
    final note = info.notes[ch];
    if (note == null) {
      unknown.add('-$ch');
    } else {
      known.add('-$ch 是$note');
    }
  }
  final buf = StringBuffer('`$flag` 是组合开关：');
  buf.write(known.join('；'));
  if (unknown.isNotEmpty) {
    if (known.isNotEmpty) buf.write('；');
    buf.write('但 ${unknown.join('、')} 我不认识');
  }
  return buf.toString();
}
