import 'package:flutter_test/flutter_test.dart';
import 'package:renhua/core/explain.dart';
import 'package:renhua/core/interpret.dart';
import 'package:renhua/core/runner.dart';
import 'package:renhua/core/shell_cmd.dart';

RunResult _r(String cmd,
        {int code = 0, String out = '', String err = '', bool timeout = false}) =>
    RunResult(
      command: cmd,
      exitCode: code,
      stdout: out,
      stderr: err,
      timedOut: timeout,
      durationMs: 5,
      truncated: false,
    );

void main() {
  group('命令拆解', () {
    test('按空格切开，引号里的不切', () {
      expect(ShellCommand.tokenize('sh -c "echo a b"'), ['sh', '-c', 'echo a b']);
      expect(ShellCommand.tokenize("grep 'hello world' f"), ['grep', 'hello world', 'f']);
      expect(ShellCommand.tokenize('   '), isEmpty);
    });

    test('开关和对象分开', () {
      final c = ShellCommand.parse('du -sh /data');
      expect(c.program, 'du');
      expect(c.flags, ['-sh']);
      expect(c.args, ['/data']);
    });
  });

  group('风险判定', () {
    test('只读命令是 safe', () {
      expect(judgeRisk('df -h'), Risk.safe);
      expect(judgeRisk('cat /proc/meminfo'), Risk.safe);
      expect(judgeRisk('uname -a'), Risk.safe);
    });

    test('会改东西是 caution', () {
      expect(judgeRisk('mkdir demo'), Risk.caution);
      expect(judgeRisk('rm a.txt'), Risk.caution);
    });

    test('删根是 danger', () {
      expect(judgeRisk('rm -rf /'), Risk.danger);
      expect(judgeRisk('dd if=/dev/zero of=/data/x'), Risk.danger);
      expect(judgeRisk('reboot'), Risk.danger);
    });
  });

  group('解释', () {
    test('认识的命令给出人话总述', () {
      final e = explain('df -h');
      expect(e.known, isTrue);
      expect(e.summary, contains('还剩多少空间'));
      expect(e.summary, contains('GB/MB'));
      expect(e.lines.any((l) => l.label == '动词'), isTrue);
    });

    test('组合开关逐个拆开讲', () {
      final e = explain('du -sh /data');
      final flag = e.lines.firstWhere((l) => l.label == '开关');
      expect(flag.text, contains('-s'));
      expect(flag.text, contains('-h'));
      expect(e.gaps, isEmpty);
    });

    test('不认识的命令不装懂', () {
      final e = explain('ffmpeg -i a.mp4 out.mp3');
      expect(e.known, isFalse);
      expect(e.summary, contains('不认识'));
    });

    test('认识的命令带不认识的开关时标出来', () {
      final e = explain('df -h -Z');
      expect(e.known, isTrue);
      expect(e.gaps.length, 1);
    });

    test('空输入不报错', () {
      final e = explain('');
      expect(e.lines, isEmpty);
      expect(e.summary, contains('还没写'));
    });
  });

  group('结果翻译', () {
    test('df 解析出占用最高的分区', () {
      const out = '''
Filesystem      Size  Used Avail Use% Mounted on
/dev/block/dm-1 108G   99G  9.0G  92% /data
/dev/block/dm-0  4.0G  2.1G  1.9G  53% /
tmpfs           3.7G     0  3.7G   0% /dev
''';
      final ins = interpret(_r('df -h', out: out));
      expect(ins.first.title, contains('/data'));
      // 92% 落在 85~95 之间：偏紧，但不是告警
      expect(ins.first.severity, Severity.notice);
      expect(ins.first.body, contains('建议清一些东西'));
    });

    test('df 超过 95% 才升级为告警', () {
      const out = 'Filesystem Size Used Avail Use% Mounted on\n/dev/x 108G 105G 3G 97% /data\n';
      final ins = interpret(_r('df -h', out: out));
      expect(ins.first.severity, Severity.warn);
      expect(ins.first.title, contains('几乎满了'));
    });

    test('df 空间充足时是好消息', () {
      const out = 'Filesystem Size Used Avail Use% Mounted on\n/dev/x 108G 20G 80G 20% /data\n';
      final ins = interpret(_r('df -h', out: out));
      expect(ins.first.severity, Severity.good);
      expect(ins.first.title, contains('宽裕'));
    });

    test('内存换算成 GB 并判断紧张程度', () {
      const out = 'MemTotal:        7781234 kB\nMemAvailable:     412000 kB\n';
      final ins = interpret(_r('cat /proc/meminfo', out: out));
      expect(ins.first.body, contains('可用不到一成'));
      expect(ins.first.severity, Severity.warn);
    });

    test('uname 认出 ARM', () {
      final ins = interpret(_r('uname -a', out: 'Linux localhost 5.10 aarch64 Toybox'));
      expect(ins.first.title, contains('ARM'));
    });

    test('uid=0 被点出来是 root', () {
      final ins = interpret(_r('id', out: 'uid=0(root) gid=0(root)'));
      expect(ins.first.title, contains('root'));
    });

    test('getprop 取出版本和机型', () {
      const out = '[ro.product.model]: [Pixel 6]\n[ro.build.version.release]: [14]\n';
      final ins = interpret(_r('getprop', out: out));
      expect(ins.any((i) => i.title.contains('安卓版本 14')), isTrue);
      expect(ins.any((i) => i.title.contains('Pixel 6')), isTrue);
    });

    test('which 没输出说明没装', () {
      final ins = interpret(_r('which python', out: ''));
      expect(ins.first.severity, Severity.warn);
      expect(ins.first.title, contains('没装'));
    });

    test('报错翻译成中文原因，不甩栈', () {
      final ins = interpret(_r('cat /data/secret', code: 1, err: 'cat: /data/secret: Permission denied'));
      expect(ins.first.title, contains('没跑成'));
      expect(ins.first.body, contains('权限不够'));
    });

    test('超时单独提示', () {
      final ins = interpret(_r('sleep 99', timeout: true));
      expect(ins.first.title, contains('卡住'));
    });

    test('成功但没输出时不说失败', () {
      final ins = interpret(_r('mkdir /data/demo'));
      expect(ins.first.severity, Severity.good);
      expect(ins.first.body, contains('没消息就是好消息'));
    });
  });
}
