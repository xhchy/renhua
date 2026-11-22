import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// 一次命令执行的结果。
class RunResult {
  final String command;
  final int exitCode;
  final String stdout;
  final String stderr;
  final bool timedOut;
  final int durationMs;
  final bool truncated;

  const RunResult({
    required this.command,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.timedOut,
    required this.durationMs,
    required this.truncated,
  });

  bool get ok => exitCode == 0 && !timedOut;

  /// 给用户看的那段输出：优先 stdout，空的就用 stderr。
  String get visibleOutput {
    final out = stdout.trim();
    if (out.isNotEmpty) return out;
    return stderr.trim();
  }
}

/// 在 App 自己的沙箱里执行命令。
///
/// 用 /system/bin/sh 是因为安卓每个 App 自带一个 sh，不需要 root，
/// 也不需要装 Termux。代价是权限被锁在 App 自己的目录里，
/// 看不到别人的文件——这正是我们想验证的场景：新手不需要全盘权限。
class CommandRunner {
  /// 输出上限，防止 cat 一个大文件把内存吃满。
  final int maxChars;

  /// 单条命令的超时。卡住的命令不能把界面一起拖死。
  final Duration timeout;

  const CommandRunner({
    this.maxChars = 6000,
    this.timeout = const Duration(seconds: 10),
  });

  Future<RunResult> run(String command) async {
    final started = DateTime.now();
    try {
      final proc = await Process.run(
        '/system/bin/sh',
        ['-c', command],
        runInShell: false,
      ).timeout(timeout);

      var out = _decode(proc.stdout);
      var err = _decode(proc.stderr);
      var cut = false;
      if (out.length > maxChars) {
        out = '${out.substring(0, maxChars)}\n…（后面还有 ${out.length - maxChars} 个字符没显示）';
        cut = true;
      }
      if (err.length > maxChars) {
        err = '${err.substring(0, maxChars)}\n…（错误输出也被截断了）';
        cut = true;
      }

      return RunResult(
        command: command,
        exitCode: proc.exitCode,
        stdout: out,
        stderr: err,
        timedOut: false,
        durationMs: DateTime.now().difference(started).inMilliseconds,
        truncated: cut,
      );
    } on TimeoutException {
      return RunResult(
        command: command,
        exitCode: -1,
        stdout: '',
        stderr: '命令超过 ${timeout.inSeconds} 秒还没结束，被中止了。',
        timedOut: true,
        durationMs: DateTime.now().difference(started).inMilliseconds,
        truncated: false,
      );
    } catch (e) {
      // 沙箱里跑（flutter test / 桌面）时 /system/bin/sh 不存在，这里要接住。
      return RunResult(
        command: command,
        exitCode: -2,
        stdout: '',
        stderr: '执行失败：$e',
        timedOut: false,
        durationMs: DateTime.now().difference(started).inMilliseconds,
        truncated: false,
      );
    }
  }

  String _decode(dynamic raw) {
    if (raw is String) return raw;
    if (raw is List<int>) return utf8.decode(raw, allowMalformed: true);
    return raw?.toString() ?? '';
  }
}
