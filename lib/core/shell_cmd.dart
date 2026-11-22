/// 一条 shell 命令的结构化表示。
///
/// 不做完整的 POSIX 词法分析，只把「动词 + 参数 + 开关」拆出来，
/// 够讲清一条命令就够了。引号内的空格不会被切开。
class ShellCommand {
  final String raw;
  final String program;
  final List<String> args;
  final List<String> flags;

  const ShellCommand({
    required this.raw,
    required this.program,
    required this.args,
    required this.flags,
  });

  /// 解析失败时 program 为空串。
  static ShellCommand parse(String raw) {
    final tokens = tokenize(raw);
    if (tokens.isEmpty) {
      return ShellCommand(raw: raw, program: '', args: const [], flags: const []);
    }
    final program = tokens.first;
    final args = <String>[];
    final flags = <String>[];
    for (final t in tokens.skip(1)) {
      if (t.startsWith('-') && t.length > 1) {
        flags.add(t);
      } else {
        args.add(t);
      }
    }
    return ShellCommand(raw: raw, program: program, args: args, flags: flags);
  }

  /// 按空格切分，但保留引号/单引号包裹的整体。
  static List<String> tokenize(String raw) {
    final out = <String>[];
    final buf = StringBuffer();
    String? quote;
    var hasToken = false;
    for (final ch in raw.runes) {
      final c = String.fromCharCode(ch);
      if (quote != null) {
        if (c == quote) {
          quote = null;
        } else {
          buf.write(c);
        }
        continue;
      }
      if (c == '"' || c == "'") {
        quote = c;
        hasToken = true;
        continue;
      }
      if (c == ' ' || c == '\t') {
        if (hasToken || buf.isNotEmpty) {
          out.add(buf.toString());
          buf.clear();
          hasToken = false;
        }
        continue;
      }
      buf.write(c);
      hasToken = true;
    }
    if (hasToken || buf.isNotEmpty) out.add(buf.toString());
    return out;
  }
}

/// 风险等级。这里只按「这条命令会不会把系统弄坏」分，不按「难不难懂」分。
enum Risk {
  /// 只读，看完就走。
  safe,

  /// 会改文件或改状态，但影响面限于自己的目录。
  caution,

  /// 可能让机器变砖、丢数据、或者需要重装。
  danger,
}

extension RiskLabel on Risk {
  String get label => switch (this) {
        Risk.safe => '只读',
        Risk.caution => '会改东西',
        Risk.danger => '危险',
      };

  String get hint => switch (this) {
        Risk.safe => '这条命令只读取信息，不会改动任何文件。',
        Risk.caution => '这条会改动文件或系统状态，跑之前先看清楚动的是哪里。',
        Risk.danger => '这条可能删数据或让系统起不来。确认你知道后果再跑。',
      };
}

/// 危险模式：命中即判 danger。
const _dangerPatterns = <String>[
  'rm -rf /',
  'rm -rf /*',
  'rm -rf ~',
  'mkfs',
  'dd if=',
  'dd of=',
  'reboot',
  'shutdown',
  '> /dev/block',
  'chmod 777 /',
  'mount -o remount',
  'pm uninstall',
  'pm clear',
  'wipe',
];

/// 改动模式：命中即判 caution。
const _cautionPatterns = <String>[
  'rm ',
  'mv ',
  'cp ',
  'mkdir',
  'touch',
  'chmod',
  'chown',
  'apt ',
  'pkg ',
  'pip ',
  'npm ',
  'curl ',
  'wget ',
  'git clone',
  '>',
  'tee ',
];

Risk judgeRisk(String raw) {
  final s = raw.toLowerCase();
  for (final p in _dangerPatterns) {
    if (s.contains(p)) return Risk.danger;
  }
  for (final p in _cautionPatterns) {
    if (s.contains(p)) return Risk.caution;
  }
  return Risk.safe;
}
