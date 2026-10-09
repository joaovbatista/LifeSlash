import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SlashStyle {
  neon(
    'Neon',
    'Brilho elétrico azul e branco',
    Icons.bolt,
    Color(0xFF18BCE0),
    Colors.white,
  ),
  fire(
    'Fogo',
    'Rastro quente com faíscas',
    Icons.local_fire_department,
    Color(0xFFFF5722),
    Color(0xFFFFE082),
  ),
  ice(
    'Gelo',
    'Lâmina fria com estilhaços',
    Icons.ac_unit,
    Color(0xFF42C6FF),
    Color(0xFFEAFBFF),
  ),
  shadow(
    'Sombra',
    'Rastro violeta escuro',
    Icons.nights_stay,
    Color(0xFFB34DFF),
    Color(0xFF301044),
  );

  final String label;
  final String description;
  final IconData icon;
  final Color glowColor;
  final Color coreColor;

  const SlashStyle(
    this.label,
    this.description,
    this.icon,
    this.glowColor,
    this.coreColor,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const LifeSlashApp());
}

double playerRotation(int index, int playerCount) =>
    index < (playerCount > 2 ? 2 : 1) ? pi : 0;

List<List<(int, int)>> portraitSeatRows(int count) => switch (count) {
  2 => [
    [(1, 2)],
  ],
  3 => [
    [(1, 1), (2, 3)],
  ],
  4 => [
    [(0, 2), (1, 2)],
    [(2, 0), (3, 0)],
  ],
  5 => [
    [(2, 1), (3, 3)],
    [(1, 1), (4, 3)],
  ],
  6 => [
    [(3, 2)],
    [(2, 1), (4, 3)],
    [(1, 1), (5, 3)],
  ],
  _ => [
    [(1, 2)],
  ],
};

int portraitQuarterTurns(int playerCount, int playerIndex) {
  for (final row in portraitSeatRows(playerCount)) {
    for (final seat in row) {
      if (seat.$1 == playerIndex) return seat.$2;
    }
  }
  return 0;
}

class LifeSlashApp extends StatelessWidget {
  const LifeSlashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Slash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF18BCE0),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const GameScreen(playerCount: 4, initialLife: 40),
    );
  }
}

class GameScreen extends StatefulWidget {
  final int playerCount;
  final int initialLife;

  const GameScreen({
    super.key,
    required this.playerCount,
    required this.initialLife,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const List<Color> playerColors = [
    Color(0xFFB9D7E7),
    Color(0xFFC5D4F3),
    Color(0xFFB9D7C7),
    Color(0xFFF0D39D),
    Color(0xFFEABDBD),
    Color(0xFFC9C2E7),
    Color(0xFF9FD8D5),
    Color(0xFFE3C4A9),
    Color(0xFF17191F),
  ];

  late List<int> lifePoints;
  late List<Color> colors;
  late List<List<int>> damage;
  late int startingLife;
  SlashStyle slashStyle = SlashStyle.neon;
  int? monarchIndex;

  @override
  void initState() {
    super.initState();
    startingLife = widget.initialLife;
    lifePoints = List.filled(widget.playerCount, widget.initialLife);
    colors = List.generate(
      widget.playerCount,
      (index) => playerColors[index % playerColors.length],
    );
    damage = List.generate(
      widget.playerCount,
      (_) => List.filled(widget.playerCount, 0),
    );
  }

  void changeLife(int index, int amount) {
    setState(() => lifePoints[index] += amount);
  }

  Future<void> chooseSlashStyle() async {
    final selectedStyle = await showDialog<SlashStyle>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Efeito de corte'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final style in SlashStyle.values)
              ListTile(
                key: ValueKey('slash-style-${style.name}'),
                selected: style == slashStyle,
                leading: Icon(style.icon, color: style.glowColor),
                title: Text(style.label),
                subtitle: Text(style.description),
                trailing: style == slashStyle
                    ? Icon(Icons.check_circle, color: style.glowColor)
                    : null,
                onTap: () => Navigator.pop(context, style),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
    if (selectedStyle != null && mounted) {
      setState(() => slashStyle = selectedStyle);
    }
  }

  Future<void> editDamage(int target) async {
    final screenSize = MediaQuery.sizeOf(context);
    final updatedDamage = await showDialog<List<int>>(
      context: context,
      builder: (context) => _DamageSelectionDialog(
        target: target,
        damage: damage,
        colors: colors,
        portraitLayout: screenSize.height > screenSize.width,
      ),
    );
    if (updatedDamage == null || !mounted) return;
    setState(() {
      for (var source = 0; source < lifePoints.length; source++) {
        if (source == target) continue;
        final difference = updatedDamage[source] - damage[source][target];
        damage[source][target] = updatedDamage[source];
        lifePoints[target] -= difference;
      }
    });
  }

  Future<void> chooseColor() async {
    final player = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolha o jogador'),
        content: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var index = 0; index < colors.length; index++)
              InkWell(
                key: ValueKey('color-player-$index'),
                onTap: () => Navigator.pop(context, index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 88,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors[index],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'JOGADOR ${index + 1}',
                    style: TextStyle(
                      color: colors[index].computeLuminance() > 0.45
                          ? Colors.black
                          : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (player == null || !mounted) return;
    final color = await showModalBottomSheet<Color>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 18,
            children: [
              for (var index = 0; index < playerColors.length; index++)
                InkWell(
                  key: ValueKey('color-swatch-$index'),
                  onTap: () => Navigator.pop(context, playerColors[index]),
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: playerColors[index],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (color != null && mounted) setState(() => colors[player] = color);
  }

  Future<void> rollDie() async {
    final result = Random().nextInt(6) + 1;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Resultado do dado'),
            const SizedBox(height: 12),
            Text(
              '$result',
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> resetGame() async {
    final reset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reiniciar partida?'),
        content: Text('A vida de todos volta para $startingLife.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (reset == true && mounted) {
      setState(() {
        lifePoints = List.filled(lifePoints.length, startingLife);
        damage = List.generate(
          lifePoints.length,
          (_) => List.filled(lifePoints.length, 0),
        );
        monarchIndex = null;
      });
    }
  }

  Future<void> changePlayerCount() async {
    var count = lifePoints.length;
    var nextStartingLife = startingLife;
    final settings = await showDialog<(int, int)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget stepper({
            required String label,
            required int value,
            required bool canDecrease,
            required bool canIncrease,
            required VoidCallback onDecrease,
            required VoidCallback onIncrease,
          }) => Row(
            children: [
              Expanded(child: Text(label)),
              IconButton(
                tooltip: 'Diminuir $label',
                onPressed: canDecrease ? onDecrease : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Aumentar $label',
                onPressed: canIncrease ? onIncrease : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          );

          return AlertDialog(
            title: const Text('Mesa e vida inicial'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                stepper(
                  label: 'Jogadores',
                  value: count,
                  canDecrease: count > 2,
                  canIncrease: count < 6,
                  onDecrease: () => setDialogState(() => count--),
                  onIncrease: () => setDialogState(() => count++),
                ),
                stepper(
                  label: 'Vida no reinício',
                  value: nextStartingLife,
                  canDecrease: nextStartingLife > 1,
                  canIncrease: nextStartingLife < 100,
                  onDecrease: () => setDialogState(() => nextStartingLife--),
                  onIncrease: () => setDialogState(() => nextStartingLife++),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(context, (count, nextStartingLife)),
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
    if (settings == null || !mounted) return;
    final (updatedCount, updatedStartingLife) = settings;
    final previousDamage = damage;
    setState(() {
      startingLife = updatedStartingLife;
      lifePoints = List.generate(
        updatedCount,
        (index) => index < lifePoints.length ? lifePoints[index] : startingLife,
      );
      colors = List.generate(
        updatedCount,
        (index) => index < colors.length
            ? colors[index]
            : playerColors[index % playerColors.length],
      );
      damage = List.generate(
        updatedCount,
        (source) => List.generate(
          updatedCount,
          (target) =>
              source < previousDamage.length && target < previousDamage.length
              ? previousDamage[source][target]
              : 0,
        ),
      );
      if (monarchIndex != null && monarchIndex! >= updatedCount) {
        monarchIndex = null;
      }
    });
  }

  Widget buildToolbar({required bool vertical}) {
    final diceButton = IconButton(
      tooltip: 'Jogar um dado',
      onPressed: rollDie,
      icon: const Icon(Icons.casino_outlined),
    );
    final playersButton = IconButton(
      tooltip: 'Jogadores e vida inicial',
      onPressed: changePlayerCount,
      icon: const Icon(Icons.people_outline),
    );
    final slashStyleButton = IconButton(
      tooltip: 'Efeito de corte: ${slashStyle.label}',
      onPressed: chooseSlashStyle,
      icon: Icon(Icons.auto_awesome, color: slashStyle.glowColor),
    );
    final colorButton = IconButton(
      tooltip: 'Alterar cor de um jogador',
      onPressed: chooseColor,
      icon: const Icon(Icons.palette_outlined),
    );
    final resetButton = IconButton(
      tooltip: 'Reiniciar partida',
      onPressed: resetGame,
      icon: const Icon(Icons.restart_alt),
    );
    final logo = Container(
      width: 68,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: const Color(0xFF252525)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Image.asset(
        'imgs/life slash.png',
        key: const ValueKey('life-slash-logo'),
        width: 62,
        height: 54,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'Life Slash',
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      width: vertical ? 84 : null,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF252525)),
      ),
      child: vertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                diceButton,
                playersButton,
                logo,
                slashStyleButton,
                colorButton,
                resetButton,
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                diceButton,
                playersButton,
                logo,
                slashStyleButton,
                colorButton,
                resetButton,
              ],
            ),
    );
  }

  Widget playerPanel(int index) => _PlayerPanel(
    key: ValueKey('player-panel-$index'),
    index: index,
    life: lifePoints[index],
    color: colors[index],
    damage: damage,
    slashStyle: slashStyle,
    isMonarch: monarchIndex == index,
    onMakeMonarch: () => setState(() => monarchIndex = index),
    onLifeChange: (amount) => changeLife(index, amount),
    onEditDamage: () => editDamage(index),
  );

  Widget portraitSeat((int, int) seat) => Expanded(
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: RotatedBox(quarterTurns: seat.$2, child: playerPanel(seat.$1)),
    ),
  );

  Widget buildPortraitTable({bool rotateForLandscape = false}) {
    final toolbar = rotateForLandscape
        ? RotatedBox(quarterTurns: 3, child: buildToolbar(vertical: true))
        : buildToolbar(vertical: false);
    if (lifePoints.length == 4) {
      return Column(
        children: [
          Expanded(
            child: Row(children: [portraitSeat((0, 2)), portraitSeat((1, 2))]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: toolbar,
          ),
          Expanded(
            child: Row(children: [portraitSeat((2, 0)), portraitSeat((3, 0))]),
          ),
        ],
      );
    }
    final rows = portraitSeatRows(lifePoints.length);
    return Column(
      children: [
        Expanded(
          flex: rows.length,
          child: Column(
            children: [
              for (final row in rows)
                Expanded(
                  child: Row(
                    children: [for (final seat in row) portraitSeat(seat)],
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: toolbar,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: playerPanel(0),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    return Scaffold(
      body: SafeArea(
        child: landscape && lifePoints.length == 4
            ? LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    GridView.builder(
                      padding: const EdgeInsets.all(5),
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: max(1, constraints.maxHeight - 18) / 2,
                        crossAxisSpacing: 96,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: lifePoints.length,
                      itemBuilder: (context, index) => Transform.rotate(
                        angle: playerRotation(index, lifePoints.length),
                        child: playerPanel(index),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: buildToolbar(vertical: true),
                    ),
                  ],
                ),
              )
            : landscape
            ? LayoutBuilder(
                builder: (context, constraints) => Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: SizedBox(
                      width: constraints.maxHeight,
                      height: constraints.maxWidth,
                      child: buildPortraitTable(rotateForLandscape: true),
                    ),
                  ),
                ),
              )
            : buildPortraitTable(),
      ),
    );
  }
}

class _PlayerPanel extends StatefulWidget {
  final int index;
  final int life;
  final Color color;
  final List<List<int>> damage;
  final SlashStyle slashStyle;
  final bool isMonarch;
  final VoidCallback onMakeMonarch;
  final ValueChanged<int> onLifeChange;
  final VoidCallback onEditDamage;

  const _PlayerPanel({
    super.key,
    required this.index,
    required this.life,
    required this.color,
    required this.damage,
    required this.slashStyle,
    required this.isMonarch,
    required this.onMakeMonarch,
    required this.onLifeChange,
    required this.onEditDamage,
  });

  @override
  State<_PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends State<_PlayerPanel>
    with TickerProviderStateMixin {
  bool dragging = false;
  late final AnimationController slashAnimation;
  List<Offset> slashPoints = [];

  @override
  void initState() {
    super.initState();
    slashAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addStatusListener(_handleSlashAnimationStatus);
  }

  void _handleSlashAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && slashPoints.isNotEmpty) {
      setState(() => slashPoints = []);
    }
  }

  @override
  void dispose() {
    slashAnimation.dispose();
    super.dispose();
  }

  void startSlash(DragStartDetails details) {
    slashAnimation
      ..stop()
      ..value = 0;
    setState(() {
      dragging = true;
      slashPoints = [details.localPosition - const Offset(13, 9)];
    });
  }

  void updateSlash(DragUpdateDetails details) {
    setState(() {
      slashPoints = [
        ...slashPoints,
        details.localPosition - const Offset(13, 9),
      ];
      if (slashPoints.length > 32) {
        slashPoints = slashPoints.sublist(slashPoints.length - 32);
      }
    });
  }

  void finishSlash(DragEndDetails details) {
    setState(() => dragging = false);
    widget.onLifeChange(-1);
    slashAnimation.forward(from: 0);
  }

  void cancelSlash() {
    setState(() => dragging = false);
    slashAnimation.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final readableColor = widget.color.computeLuminance() > 0.45
        ? Colors.black
        : Colors.white;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: startSlash,
      onHorizontalDragUpdate: updateSlash,
      onHorizontalDragEnd: finishSlash,
      onHorizontalDragCancel: cancelSlash,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: dragging ? const Color(0xFF18BCE0) : Colors.white24,
            width: dragging ? 3 : 1,
          ),
        ),
        child: CustomPaint(
          key: ValueKey(
            'slash-trail-${widget.index}-${widget.slashStyle.name}',
          ),
          foregroundPainter: _SlashPainter(
            points: slashPoints,
            animation: slashAnimation,
            active: dragging,
            style: widget.slashStyle,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              children: [
                Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTap: widget.onMakeMonarch,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        'JOGADOR ${widget.index + 1}',
                        style: TextStyle(
                          color: readableColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: constraints.maxWidth * 0.84,
                            height: max(48, constraints.maxHeight * 0.42),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (widget.isMonarch)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      key: ValueKey(
                                        'monarch-crown-${widget.index}',
                                      ),
                                      painter: const _MonarchCrownPainter(),
                                    ),
                                  ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${widget.life}',
                                    style: TextStyle(
                                      color: readableColor,
                                      fontSize: constraints.maxHeight * 0.34,
                                      fontWeight: FontWeight.w300,
                                      height: 0.95,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _LifeButton(
                                icon: Icons.remove,
                                label: 'Tirar 1 vida',
                                color: readableColor,
                                repeatOnHold: true,
                                onPressed: () => widget.onLifeChange(-1),
                              ),
                              const SizedBox(width: 12),
                              _LifeButton(
                                icon: Icons.add,
                                label: 'Adicionar 1 vida',
                                color: readableColor,
                                onPressed: () => widget.onLifeChange(1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4,
                            runSpacing: 3,
                            children: [
                              for (
                                var source = 0;
                                source < widget.damage.length;
                                source++
                              )
                                if (source != widget.index)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.55,
                                      ),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      'J${source + 1}  ${widget.damage[source][widget.index]}',
                                      style: TextStyle(
                                        color: readableColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: TextButton.icon(
                    onPressed: widget.onEditDamage,
                    icon: Icon(Icons.tune, size: 16, color: readableColor),
                    label: Text(
                      'DANO',
                      style: TextStyle(color: readableColor, fontSize: 10),
                    ),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonarchCrownPainter extends CustomPainter {
  const _MonarchCrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final crown = Path()
      ..moveTo(size.width * 0.08, size.height * 0.24)
      ..lineTo(size.width * 0.28, size.height * 0.46)
      ..lineTo(size.width * 0.34, size.height * 0.08)
      ..lineTo(size.width * 0.5, size.height * 0.39)
      ..lineTo(size.width * 0.66, size.height * 0.08)
      ..lineTo(size.width * 0.72, size.height * 0.46)
      ..lineTo(size.width * 0.92, size.height * 0.24)
      ..lineTo(size.width * 0.82, size.height * 0.82)
      ..lineTo(size.width * 0.18, size.height * 0.82)
      ..close();
    final gold = const Color(0xFFFFD54F);
    canvas.drawPath(crown, Paint()..color = gold.withValues(alpha: 0.2));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.18,
          size.height * 0.76,
          size.width * 0.64,
          size.height * 0.13,
        ),
        Radius.circular(size.height * 0.04),
      ),
      Paint()..color = gold.withValues(alpha: 0.24),
    );
  }

  @override
  bool shouldRepaint(covariant _MonarchCrownPainter oldDelegate) => false;
}

class _LifeButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool repeatOnHold;
  final VoidCallback onPressed;

  const _LifeButton({
    required this.icon,
    required this.label,
    required this.color,
    this.repeatOnHold = false,
    required this.onPressed,
  });

  @override
  State<_LifeButton> createState() => _LifeButtonState();
}

class _LifeButtonState extends State<_LifeButton> {
  Timer? repeatTimer;

  void startRepeatingPress(LongPressStartDetails details) {
    if (!widget.repeatOnHold) return;
    widget.onPressed();
    repeatTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => widget.onPressed(),
    );
  }

  void stopRepeatingPress() {
    repeatTimer?.cancel();
    repeatTimer = null;
  }

  @override
  void dispose() {
    stopRepeatingPress();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPressStart: widget.repeatOnHold ? startRepeatingPress : null,
    onLongPressEnd: widget.repeatOnHold ? (_) => stopRepeatingPress() : null,
    onLongPressCancel: widget.repeatOnHold ? stopRepeatingPress : null,
    child: IconButton(
      tooltip: widget.label,
      onPressed: widget.onPressed,
      icon: Icon(widget.icon, color: widget.color),
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.12),
        minimumSize: const Size(40, 36),
      ),
    ),
  );
}

class _SlashPainter extends CustomPainter {
  final List<Offset> points;
  final Animation<double> animation;
  final bool active;
  final SlashStyle style;

  _SlashPainter({
    required this.points,
    required this.animation,
    required this.active,
    required this.style,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final opacity = active ? 1.0 : 1 - animation.value;
    if (opacity <= 0) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    void drawStroke(
      Color color,
      double width, {
      double alpha = 1,
      double blur = 0,
    }) {
      final paint = Paint()
        ..color = color.withValues(alpha: opacity * alpha)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      if (blur > 0) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      canvas.drawPath(path, paint);
    }

    switch (style) {
      case SlashStyle.neon:
        drawStroke(style.glowColor, 16, alpha: 0.55, blur: 6);
        drawStroke(style.coreColor, 4);
        break;
      case SlashStyle.fire:
        drawStroke(style.glowColor, 20, alpha: 0.7, blur: 8);
        drawStroke(style.coreColor, 8, blur: 2);
        drawStroke(Colors.white, 2.5, alpha: 0.9);
        for (var index = 2; index < points.length; index += 4) {
          canvas.drawCircle(
            points[index],
            2.5 * opacity,
            Paint()..color = style.coreColor.withValues(alpha: opacity),
          );
        }
        break;
      case SlashStyle.ice:
        drawStroke(style.glowColor, 15, alpha: 0.65, blur: 4);
        drawStroke(style.coreColor, 3);
        for (final index in [points.length ~/ 3, points.length * 2 ~/ 3]) {
          if (index <= 0 || index >= points.length) continue;
          final direction = points[index] - points[index - 1];
          final length = direction.distance;
          if (length == 0) continue;
          final shard = Offset(-direction.dy, direction.dx) / length * 7;
          canvas.drawLine(
            points[index] - shard,
            points[index] + shard,
            Paint()
              ..color = style.coreColor.withValues(alpha: opacity)
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round,
          );
        }
        break;
      case SlashStyle.shadow:
        drawStroke(style.glowColor, 22, alpha: 0.6, blur: 10);
        drawStroke(style.coreColor, 8, alpha: 0.95);
        drawStroke(style.glowColor, 2, alpha: 0.9);
        break;
    }
    canvas.drawCircle(
      points.last,
      4 * opacity,
      Paint()..color = style.coreColor.withValues(alpha: opacity),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SlashPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.active != active ||
      oldDelegate.style != style;
}

class _DamageSelectionDialog extends StatefulWidget {
  final int target;
  final List<List<int>> damage;
  final List<Color> colors;
  final bool portraitLayout;

  const _DamageSelectionDialog({
    required this.target,
    required this.damage,
    required this.colors,
    required this.portraitLayout,
  });

  @override
  State<_DamageSelectionDialog> createState() => _DamageSelectionDialogState();
}

class _DamageSelectionDialogState extends State<_DamageSelectionDialog> {
  late List<int> totals;

  @override
  void initState() {
    super.initState();
    totals = List.generate(
      widget.damage.length,
      (source) => widget.damage[source][widget.target],
    );
  }

  void adjustDamage(int source, int amount) {
    setState(() => totals[source] = max(0, totals[source] + amount));
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isLandscape = screenSize.width > screenSize.height;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.black,
      child: SizedBox(
        width: min(screenSize.width - 32, 720),
        height: min(screenSize.height * (isLandscape ? 0.94 : 0.84), 640),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Dano recebido · Jogador ${widget.target + 1}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => GridView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio:
                          constraints.maxWidth / (constraints.maxHeight * 0.92),
                    ),
                    itemCount: widget.damage.length,
                    itemBuilder: (context, source) {
                      final isTarget = source == widget.target;
                      final textColor =
                          widget.colors[source].computeLuminance() > 0.45
                          ? Colors.black
                          : Colors.white;
                      final card = Container(
                        key: ValueKey('damage-source-$source'),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: widget.colors[source],
                          borderRadius: BorderRadius.circular(18),
                          border: isTarget
                              ? Border.all(color: Colors.white54, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'JOGADOR ${source + 1}',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                                if (!isTarget)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        key: ValueKey(
                                          'damage-decrease-$source',
                                        ),
                                        tooltip: 'Remover 1 ponto de dano',
                                        onPressed: totals[source] > 0
                                            ? () => adjustDamage(source, -1)
                                            : null,
                                        icon: Icon(
                                          Icons.remove,
                                          color: textColor,
                                          size: 32,
                                        ),
                                        style: IconButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(54, 54),
                                          maximumSize: const Size(54, 54),
                                          backgroundColor: Colors.black
                                              .withValues(alpha: 0.12),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: max(
                                          40,
                                          constraints.maxWidth / 2 - 140,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            '${totals[source]}',
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 56,
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        key: ValueKey(
                                          'damage-increase-$source',
                                        ),
                                        tooltip: 'Adicionar 1 ponto de dano',
                                        onPressed: () =>
                                            adjustDamage(source, 1),
                                        icon: Icon(
                                          Icons.add,
                                          color: textColor,
                                          size: 32,
                                        ),
                                        style: IconButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(54, 54),
                                          maximumSize: const Size(54, 54),
                                          backgroundColor: Colors.black
                                              .withValues(alpha: 0.12),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    'ALVO',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 42,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                      return Transform.rotate(
                        angle: widget.portraitLayout
                            ? portraitQuarterTurns(
                                    widget.damage.length,
                                    source,
                                  ) *
                                  pi /
                                  2
                            : playerRotation(source, widget.damage.length),
                        child: card,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, totals),
                  icon: const Icon(Icons.check),
                  label: const Text('Aplicar danos'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
