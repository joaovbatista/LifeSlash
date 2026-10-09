// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifeslash/main.dart';

void main() {
  testWidgets('game actions work from the main screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LifeSlashApp());

    expect(find.text('JOGADOR 1'), findsOneWidget);
    expect(find.text('40'), findsNWidgets(4));
    expect(find.text('Iniciar partida'), findsNothing);
    expect(find.byKey(const ValueKey('life-slash-logo')), findsOneWidget);

    Future<void> doubleTap(Finder finder) async {
      await tester.tap(finder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await doubleTap(find.text('JOGADOR 1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('monarch-crown-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('monarch-crown-1')), findsNothing);
    await doubleTap(find.text('JOGADOR 2'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('monarch-crown-0')), findsNothing);
    expect(find.byKey(const ValueKey('monarch-crown-1')), findsOneWidget);

    await tester.tap(find.byTooltip('Efeito de corte: Neon'));
    await tester.pumpAndSettle();
    for (final style in SlashStyle.values) {
      expect(find.byKey(ValueKey('slash-style-${style.name}')), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('slash-style-fire')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Efeito de corte: Fogo'), findsOneWidget);
    expect(find.byKey(const ValueKey('slash-trail-0-fire')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('player-panel-0')),
      const Offset(100, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('39'), findsOneWidget);
    expect(find.byKey(const ValueKey('slash-trail-0-fire')), findsOneWidget);
    expect(
      tester
          .widget<CustomPaint>(find.byKey(const ValueKey('slash-trail-0-fire')))
          .foregroundPainter,
      isNotNull,
    );
    final painterBeforeLifeChange = tester
        .widget<CustomPaint>(find.byKey(const ValueKey('slash-trail-0-fire')))
        .foregroundPainter!;
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('player-panel-0')),
        matching: find.byTooltip('Adicionar 1 vida'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('40'), findsNWidgets(4));
    final painterAfterLifeChange = tester
        .widget<CustomPaint>(find.byKey(const ValueKey('slash-trail-0-fire')))
        .foregroundPainter!;
    expect(
      painterAfterLifeChange.shouldRepaint(painterBeforeLifeChange),
      isFalse,
    );

    final decreaseLifeButton = find.descendant(
      of: find.byKey(const ValueKey('player-panel-0')),
      matching: find.byTooltip('Tirar 1 vida'),
    );
    final hold = await tester.startGesture(
      tester.getCenter(decreaseLifeButton),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 250));
    await hold.up();
    await tester.pumpAndSettle();
    expect(find.text('39'), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('player-panel-1')),
        matching: find.text('DANO'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dano recebido · Jogador 2'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byKey(const ValueKey('player-panel-1')), findsOneWidget);

    final damageCard = find.byKey(const ValueKey('damage-source-0'));
    final damageValue = tester.getRect(
      find.descendant(of: damageCard, matching: find.text('0')),
    );
    final damageDecrease = tester.getRect(
      find.byKey(const ValueKey('damage-decrease-0')),
    );
    final damageIncrease = tester.getRect(
      find.byKey(const ValueKey('damage-increase-0')),
    );
    expect(damageDecrease.width, greaterThanOrEqualTo(50));
    expect(damageIncrease.width, greaterThanOrEqualTo(50));
    expect(
      min(damageDecrease.center.dx, damageIncrease.center.dx),
      lessThan(damageValue.center.dx),
    );
    expect(
      max(damageDecrease.center.dx, damageIncrease.center.dx),
      greaterThan(damageValue.center.dx),
    );

    final topPlayerCard = tester.widget<Transform>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('damage-source-0')),
            matching: find.byType(Transform),
          )
          .first,
    );
    final bottomPlayerCard = tester.widget<Transform>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('damage-source-2')),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(topPlayerCard.transform.storage[0], closeTo(-1, 0.001));
    expect(bottomPlayerCard.transform.storage[0], closeTo(1, 0.001));

    await tester.tap(find.byKey(const ValueKey('damage-increase-0')));
    await tester.tap(find.text('Aplicar danos'));
    await tester.pumpAndSettle();
    expect(find.text('J1  1'), findsOneWidget);

    await tester.tap(find.byTooltip('Jogadores e vida inicial'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Aumentar Jogadores'));
    await tester.tap(find.byTooltip('Aumentar Vida no reinício'));
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(760, 500), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('JOGADOR 5'), findsOneWidget);

    await tester.tap(find.byTooltip('Alterar cor de um jogador'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('color-player-4')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('color-swatch-8')));
    await tester.pumpAndSettle();
    final darkPlayer = find.byKey(const ValueKey('player-panel-4'));
    final darkCard = tester.widget<AnimatedContainer>(
      find.descendant(of: darkPlayer, matching: find.byType(AnimatedContainer)),
    );
    expect(
      (darkCard.decoration as BoxDecoration).color,
      const Color(0xFF17191F),
    );
    final lightLifeText = tester.widget<Text>(
      find.descendant(of: darkPlayer, matching: find.text('41')),
    );
    expect(lightLifeText.style?.color, Colors.white);

    await tester.tap(find.byTooltip('Reiniciar partida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reiniciar'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('player-panel-4')),
        matching: find.text('41'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('monarch-crown-1')), findsNothing);
    expect(find.byKey(const ValueKey('monarch-crown-1')), findsNothing);
  });

  testWidgets('portrait table adapts its seat rows for 2 to 6 players', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LifeSlashApp());

    Future<void> setPlayerCount(int current, int next) async {
      await tester.tap(find.byTooltip('Jogadores e vida inicial'));
      await tester.pumpAndSettle();
      final tooltip = next > current
          ? 'Aumentar Jogadores'
          : 'Diminuir Jogadores';
      for (var index = 0; index < (next - current).abs(); index++) {
        await tester.tap(find.byTooltip(tooltip));
        await tester.pump();
      }
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
    }

    Rect panel(int player) =>
        tester.getRect(find.byKey(ValueKey('player-panel-${player - 1}')));

    expect(panel(1).top, closeTo(panel(2).top, 1));
    expect(panel(3).top, closeTo(panel(4).top, 1));
    expect(panel(1).bottom, lessThan(panel(3).top));
    expect(panel(2).bottom, lessThan(panel(4).top));
    expect(panel(1).width, closeTo(panel(3).width, 2));

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('player-panel-0')),
        matching: find.text('DANO'),
      ),
    );
    await tester.pumpAndSettle();
    final topDamageCard = tester.widget<Transform>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('damage-source-1')),
            matching: find.byType(Transform),
          )
          .first,
    );
    final bottomDamageCard = tester.widget<Transform>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('damage-source-2')),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(topDamageCard.transform.storage[0], closeTo(-1, 0.001));
    expect(bottomDamageCard.transform.storage[0], closeTo(1, 0.001));
    await tester.tap(find.text('Aplicar danos'));
    await tester.pumpAndSettle();

    await setPlayerCount(4, 3);
    expect(panel(2).top, closeTo(panel(3).top, 1));
    expect(panel(1).top, greaterThan(panel(2).bottom));

    await setPlayerCount(3, 2);
    expect(panel(2).width, closeTo(panel(1).width, 2));
    expect(panel(2).bottom, lessThan(panel(1).top));

    await setPlayerCount(2, 5);
    expect(panel(3).top, closeTo(panel(4).top, 1));
    expect(panel(2).top, closeTo(panel(5).top, 1));
    expect(panel(4).bottom, lessThan(panel(2).top));
    expect(panel(5).bottom, lessThan(panel(1).top));

    await setPlayerCount(5, 6);
    expect(panel(4).width, greaterThan(panel(3).width * 1.8));

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('player-panel-0')),
        matching: find.text('DANO'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dano recebido · Jogador 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Aplicar danos'));
    await tester.pumpAndSettle();
    expect(panel(3).top, closeTo(panel(5).top, 1));
    expect(panel(2).top, closeTo(panel(6).top, 1));
    expect(panel(5).bottom, lessThan(panel(2).top));
    expect(panel(6).bottom, lessThan(panel(1).top));
  });

  testWidgets('landscape keeps four-player grid and adapts larger tables', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LifeSlashApp());

    final board = tester.widget<GridView>(find.byType(GridView));
    expect(board.physics, isA<NeverScrollableScrollPhysics>());

    Future<void> addPlayer() async {
      await tester.tap(find.byTooltip('Jogadores e vida inicial'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Aumentar Jogadores'));
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
    }

    Future<void> removePlayer() async {
      await tester.tap(find.byTooltip('Jogadores e vida inicial'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Diminuir Jogadores'));
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
    }

    Rect panel(int player) =>
        tester.getRect(find.byKey(ValueKey('player-panel-$player')));

    expect(panel(0).top, closeTo(panel(1).top, 1));
    expect(panel(2).top, closeTo(panel(3).top, 1));
    expect(panel(0).bottom, lessThan(panel(2).top));
    expect(panel(2).bottom, lessThanOrEqualTo(tester.view.physicalSize.height));

    await addPlayer();
    expect(panel(0).height, greaterThan(panel(1).height * 1.8));
    expect(panel(1).left, closeTo(panel(4).left, 1));
    expect(panel(1).top, lessThan(panel(4).top));
    expect(panel(2).left, closeTo(panel(3).left, 1));
    expect(panel(2).top, lessThan(panel(3).top));
    expect(panel(0).right, lessThan(panel(1).left));
    expect(panel(4).right, lessThan(panel(2).left));

    await addPlayer();
    expect(panel(0).height, greaterThan(panel(1).height * 1.8));
    expect(panel(3).height, greaterThan(panel(2).height * 1.8));
    expect(panel(1).left, closeTo(panel(5).left, 1));
    expect(panel(1).top, lessThan(panel(5).top));
    expect(panel(2).left, closeTo(panel(4).left, 1));
    expect(panel(2).top, lessThan(panel(4).top));
    expect(panel(0).right, lessThan(panel(1).left));
    expect(panel(5).right, lessThan(panel(2).left));
    expect(panel(4).right, lessThan(panel(3).left));

    await removePlayer();
    await removePlayer();
    await removePlayer();
    expect(panel(0).height, greaterThan(panel(1).height * 1.8));
    expect(panel(1).left, closeTo(panel(2).left, 1));
    expect(panel(1).top, lessThan(panel(2).top));
    expect(panel(0).right, lessThan(panel(1).left));

    await removePlayer();
    expect(panel(0).height, closeTo(panel(1).height, 1));
    expect(panel(0).right, lessThan(panel(1).left));
  });
}
