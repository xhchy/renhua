/// 常用命令的中文知识库。
///
/// 这不是「翻译单词」，是讲清楚三件事：
/// 这条命令在干什么、为什么有人用它、输出该看哪一列。
///
/// 刻意只收 Android 沙箱里不带 root 就能跑的常见命令。
class CommandInfo {
  /// 命令名，例如 df。
  final String name;

  /// 一句话人话：它到底在干什么。
  final String plain;

  /// 为什么用它（使用场景，不是技术定义）。
  final String why;

  /// 输出怎么看。
  final String howToRead;

  /// 参数/开关的含义，键是不带前导斜杠的写法，例如 'h'、'-h'、'/data'。
  final Map<String, String> notes;

  const CommandInfo({
    required this.name,
    required this.plain,
    required this.why,
    required this.howToRead,
    this.notes = const {},
  });
}

const Map<String, CommandInfo> commandBook = {
  'ls': CommandInfo(
    name: 'ls',
    plain: '列出这个文件夹里有哪些东西',
    why: '想知道一个目录里有什么，第一步就是它。',
    howToRead: '每行一个名字。带 / 结尾的是文件夹，其余是文件。',
    notes: {
      'l': '用「一行一个、带权限和大小」的详细格式显示，不是挤成几列',
      'a': '连隐藏文件（名字以点开头）也显示出来',
      'h': '大小用人看得懂的 K/M/G，不用字节数',
    },
  ),
  'cd': CommandInfo(
    name: 'cd',
    plain: '切换当前所在的文件夹',
    why: '后面的命令默认在当前文件夹里找东西，进错地方就会找不到文件。',
    howToRead: '这条命令没有输出。没报错就是成功了。',
    notes: {
      '..': '回到上一级文件夹',
      '~': '回到自己的家目录',
    },
  ),
  'pwd': CommandInfo(
    name: 'pwd',
    plain: '打印我现在到底站在哪个文件夹里',
    why: '迷路的时候用。很多「找不到文件」的报错，根因都是站错了地方。',
    howToRead: '输出的就是完整路径。',
  ),
  'cat': CommandInfo(
    name: 'cat',
    plain: '把一个文本文件的全部内容直接打印出来',
    why: '看配置文件、看系统信息文件时最常用。',
    howToRead: '原样显示文件内容，不做任何加工。',
  ),
  'df': CommandInfo(
    name: 'df',
    plain: '查看每块存储还剩多少空间',
    why: '装东西失败、App 存不了文件时，第一个要查的就是这里。',
    howToRead: '看 Use% 那一列：超过 85% 就该清东西了，100% 会直接写不进去。',
    notes: {
      'h': '用 GB/MB 显示，不用一大堆字节数',
      '/data': '只看 /data 这块（App 数据都在这），不是全部',
    },
  ),
  'du': CommandInfo(
    name: 'du',
    plain: '算出一个文件夹总共占了多少空间',
    why: 'df 告诉你「盘满了」，du 告诉你「是哪个目录吃掉的」。',
    howToRead: '最后一行是总计。中间是各个子目录各自的体积。',
    notes: {
      's': '只给一个总数，不逐层列出来',
      'h': '用人看得懂的单位',
    },
  ),
  'uname': CommandInfo(
    name: 'uname',
    plain: '报告这台机器的内核信息',
    why: '判断「我这台是什么架构」——装软件前必须先知道，装错架构的包装不上。',
    howToRead: 'aarch64 是 ARM 64 位（绝大多数手机），x86_64 是模拟器或平板。',
    notes: {
      'a': '把所有字段都列出来：内核名、主机名、版本、架构',
    },
  ),
  'id': CommandInfo(
    name: 'id',
    plain: '看我现在是用什么身份在跑命令',
    why: '很多操作失败只是因为权限不够。先确认自己是谁，再怀疑命令写错。',
    howToRead: 'uid=0 是 root（最高权限）；uid=10xxx 是普通 App 身份。',
  ),
  'getprop': CommandInfo(
    name: 'getprop',
    plain: '读安卓系统的属性表（相当于系统的说明书）',
    why: '查系统版本、机型、CPU 型号都靠它，不需要任何权限。',
    howToRead: '输出是 键 = 值 的形式，方括号里是值。',
  ),
  'echo': CommandInfo(
    name: 'echo',
    plain: '把一段文字原样打印出来',
    why: '最常用于查看一个变量的值，比如看 PATH 里有哪些目录。',
    howToRead: '就是把内容重复一遍。',
  ),
  'ps': CommandInfo(
    name: 'ps',
    plain: '列出当前在跑的进程',
    why: '想确认「我起的服务到底活着没有」。',
    howToRead: '注意：安卓上普通 App 只能看到自己的进程，看不到别人的。',
    notes: {
      'A': '列出所有进程（安卓上通常被限制，只能看到自己的）',
    },
  ),
  'grep': CommandInfo(
    name: 'grep',
    plain: '在一堆文字里只挑出包含某个词的行',
    why: '输出太长的时候用它过滤，比如从属性表里只找版本号。',
    howToRead: '只显示命中的行，没命中的不显示。',
    notes: {
      'i': '忽略大小写',
      'v': '反过来，显示「不包含」这个词的行',
    },
  ),
  'head': CommandInfo(
    name: 'head',
    plain: '只看开头几行',
    why: '文件太长，先看开头判断这是什么格式。',
    howToRead: '默认前 10 行。',
    notes: {
      'n': '指定看前几行，例如 -n 3 是前三行',
    },
  ),
  'tail': CommandInfo(
    name: 'tail',
    plain: '只看最后几行',
    why: '看日志最常用——最新的记录永远在末尾。',
    howToRead: '默认最后 10 行。',
    notes: {
      'n': '指定看最后几行',
      'f': '持续盯着文件，有新内容就实时打出来（会一直占着不动，按 Ctrl+C 退出）',
    },
  ),
  'which': CommandInfo(
    name: 'which',
    plain: '查一个命令装在哪个路径',
    why: '报「command not found」时，用它确认这个命令到底装没装。',
    howToRead: '有输出＝装了；什么都没有＝没装或不在 PATH 里。',
  ),
  'free': CommandInfo(
    name: 'free',
    plain: '查看内存还剩多少',
    why: 'App 被杀、系统卡顿时，先看内存是不是真的不够。',
    howToRead: '看 available 那一列，那是「真正还能用的」。',
    notes: {
      'h': '用 GB/MB 显示',
    },
  ),
  'python': CommandInfo(
    name: 'python',
    plain: '启动 Python 解释器',
    why: '跑 Python 脚本、进交互环境。',
    howToRead: '看到 >>> 就是进去了，输入 exit() 退出。',
  ),
  'sh': CommandInfo(
    name: 'sh',
    plain: '启动一个 shell 命令解释器',
    why: '跑 .sh 脚本，或者把一串命令当参数交给它执行。',
    howToRead: '脚本没输出且没报错＝跑成功了。',
    notes: {
      'c': '把后面引号里的整串内容当一条命令执行，常用写法 sh -c "命令"',
    },
  ),
};

/// 常见报错的中文解释。按关键词匹配 stderr。
const Map<String, String> errorBook = {
  'Permission denied': '权限不够。这个文件或目录不让你动——不是命令写错了，是身份不够。',
  'No such file or directory': '找不到这个文件或目录。先确认名字没拼错，再用 pwd 确认自己站的地方对不对。',
  'not found': '系统里没有这个命令。它没装，或者装了但不在 PATH 里。',
  'Read-only file system': '这个位置是只读的，不能往里写。安卓的系统分区默认如此。',
  'No space left on device': '盘满了，一个字节都写不进去。先去清空间。',
  'Operation not permitted': '操作被系统拒绝。常见于普通 App 想动系统级的东西。',
  'Killed': '进程被系统杀掉了，通常是内存不够或者超时。',
  'timed out': '超时。命令卡住了，可能一直在等输入，或者在下载很慢的东西。',
};
