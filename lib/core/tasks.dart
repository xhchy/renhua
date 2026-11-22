/// 预设任务：把「我不知道该敲什么」变成「点一下，看它一步步干」。
///
/// 每个任务只做一件事，而且每步都能用一句话说清为什么。
class TaskStep {
  /// 真正要执行的命令。
  final String command;

  /// 这一步想搞清楚什么。用问题写，不用功能写。
  final String goal;

  const TaskStep(this.command, this.goal);
}

class BenchTask {
  final String id;
  final String title;

  /// 做完这个任务，你会得到什么。这是任务的承诺。
  final String promise;

  final List<TaskStep> steps;

  const BenchTask({
    required this.id,
    required this.title,
    required this.promise,
    required this.steps,
  });
}

const List<BenchTask> benchTasks = [
  BenchTask(
    id: 'checkup',
    title: '给手机做个体检',
    promise: '搞清楚这台机器是什么架构、多少内存、还剩多少空间、你是什么权限。'
        '装任何东西之前，这四项必须先知道。',
    steps: [
      TaskStep('uname -a', '这台机器是什么架构？'),
      TaskStep('cat /proc/meminfo | head -3', '内存总共多少、还能用多少？'),
      TaskStep('df -h', '存储还剩多少？哪一块快满了？'),
      TaskStep('id', '我现在是什么身份？够不够权限？'),
    ],
  ),
  BenchTask(
    id: 'space',
    title: '查空间去哪了',
    promise: 'df 只说「盘满了」，说不清是谁吃的。这个任务把它落到具体目录上。',
    steps: [
      TaskStep('df -h /data', '/data 这块还剩多少？'),
      TaskStep('du -sh /data/data/com.xhchy.renhua', '我自己的数据占了多少？'),
      TaskStep('du -sh /data/data/com.xhchy.renhua/*', '具体是哪个子目录最大？'),
    ],
  ),
  BenchTask(
    id: 'device',
    title: '读出机型和系统版本',
    promise: '报 Bug、查兼容、找教程，都需要这三个值。它们不会被系统藏起来。',
    steps: [
      TaskStep('getprop ro.product.model', '这是什么机型？'),
      TaskStep('getprop ro.build.version.release', '安卓几？'),
      TaskStep('getprop ro.product.cpu.abi', 'CPU 指令集是什么？决定下载哪个包。'),
    ],
  ),
];
