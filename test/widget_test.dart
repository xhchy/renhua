import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:renhua/main.dart';

void main() {
  testWidgets('首页列出全部任务和自由输入入口', (tester) async {
    await tester.pumpWidget(const RenhuaApp());

    expect(find.text('人话'), findsOneWidget);
    expect(find.text('给手机做个体检'), findsOneWidget);
    expect(find.text('查空间去哪了'), findsOneWidget);
    expect(find.text('读出机型和系统版本'), findsOneWidget);
    expect(find.text('自己敲一条'), findsOneWidget);
  });

  testWidgets('点任务能进到步骤页，并预先解释第一条命令', (tester) async {
    await tester.pumpWidget(const RenhuaApp());

    await tester.tap(find.text('给手机做个体检'));
    await tester.pumpAndSettle();

    // 第一条命令在页面上（ListView 懒加载，只断言首屏可见的）
    expect(find.textContaining('uname -a'), findsWidgets);
    // 解释在跑之前就已经给出
    expect(find.text('为什么用它'), findsWidgets);
    // 开始按钮
    expect(find.text('开始'), findsOneWidget);
  });

  testWidgets('自由输入页随输入实时解释', (tester) async {
    await tester.pumpWidget(const RenhuaApp());

    await tester.tap(find.text('自己敲一条'));
    await tester.pumpAndSettle();

    expect(find.text('跑之前先讲清楚'), findsNothing); // 还没输入

    await tester.enterText(find.byType(TextField), 'df -h');
    await tester.pump();

    expect(find.text('跑之前先讲清楚'), findsOneWidget);
    expect(find.textContaining('还剩多少空间'), findsWidgets);
    expect(find.text('执行'), findsOneWidget);
  });
}
