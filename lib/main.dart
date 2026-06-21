import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const BlockPuzzleApp());
}

class BlockPuzzleApp extends StatelessWidget {
  const BlockPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Block Puzzle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121225),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

/// ----------------- MODELLER -----------------

const int gridSize = 8; // 10x10 istersen bu değeri 10 yap.

class BlockShape {
  final List<Point<int>> cells; // x = sütun, y = satır (göreceli)
  final Color color;
  final int id;

  BlockShape(this.cells, this.color, this.id);

  int get width => cells.map((c) => c.x).reduce(max) + 1;
  int get height => cells.map((c) => c.y).reduce(max) + 1;
}

// Olası blok şekilleri: [satır, sütun] formatında göreceli hücreler.
final List<List<List<int>>> _shapeDefs = [
  [[0, 0]],
  [[0, 0], [0, 1]],
  [[0, 0], [1, 0]],
  [[0, 0], [0, 1], [0, 2]],
  [[0, 0], [1, 0], [2, 0]],
  [[0, 0], [0, 1], [1, 0], [1, 1]], // kare
  [[0, 0], [0, 1], [0, 2], [0, 3]], // çizgi 4 yatay
  [[0, 0], [1, 0], [2, 0], [3, 0]], // çizgi 4 dikey
  [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]], // çizgi 5 yatay
  [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]], // çizgi 5 dikey
  [[0, 0], [1, 0], [1, 1]], // L
  [[0, 0], [0, 1], [1, 0]], // L
  [[0, 1], [1, 0], [1, 1]], // L
  [[0, 0], [0, 1], [1, 1]], // L
  [[0, 0], [0, 1], [0, 2], [1, 0]], // J
  [[0, 0], [0, 1], [0, 2], [1, 2]], // L büyük
  [[1, 0], [1, 1], [1, 2], [0, 0]], // J ters
  [[1, 0], [1, 1], [1, 2], [0, 2]], // L ters
  [[0, 0], [1, 0], [1, 1], [2, 1]], // S
  [[0, 1], [1, 0], [1, 1], [2, 0]], // Z
  [[0, 0], [0, 1], [0, 2], [1, 1]], // T
  [[0, 1], [1, 0], [1, 1], [1, 2]], // T ters
  [[0, 0], [0, 1], [1, 0], [1, 1], [2, 0], [2, 1]], // 3x2 blok
  [[0, 0], [0, 1], [0, 2], [1, 0], [1, 1], [1, 2]], // 2x3 blok
];

final List<Color> _palette = [
  const Color(0xFFFF6B6B),
  const Color(0xFF4ECDC4),
  const Color(0xFFFFD93D),
  const Color(0xFF6C63FF),
  const Color(0xFF1AAB7B),
  const Color(0xFFFF8C42),
  const Color(0xFFC084FC),
  const Color(0xFF38BDF8),
];

final Random _rng = Random();

/// ----------------- OYUN EKRANI -----------------

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<List<Color?>> grid;
  late List<BlockShape?> tray;
  int score = 0;
  int highScore = 0;
  bool gameOver = false;
  int _pieceIdCounter = 0;

  final GlobalKey _gridKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
  double cellSize = 0;

  Set<Point<int>> previewCells = {};
  bool previewValid = false;
  Set<Point<int>> clearingCells = {};

  // Elle sürükleme takibi (parmak yukarıda, blok kaldırılmış şekilde gösterilir)
  BlockShape? _draggingShape;
  int? _draggingIndex;
  Offset? _fingerPos;
  Point<int>? _previewTopLeft;

  @override
  void initState() {
    super.initState();
    grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => null));
    tray = List.generate(3, (_) => _newShape());
    _loadHighScore();
  }

  BlockShape _newShape() {
    _pieceIdCounter++;
    final def = _shapeDefs[_rng.nextInt(_shapeDefs.length)];
    final cells = def.map((c) => Point<int>(c[1], c[0])).toList();
    final color = _palette[_rng.nextInt(_palette.length)];
    return BlockShape(cells, color, _pieceIdCounter);
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      highScore = prefs.getInt('high_score') ?? 0;
    });
  }

  Future<void> _saveHighScoreIfNeeded() async {
    if (score > highScore) {
      highScore = score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('high_score', highScore);
      if (mounted) setState(() {});
    }
  }

  bool _canPlaceAt(BlockShape shape, int row, int col) {
    for (final c in shape.cells) {
      final r = row + c.y;
      final cc = col + c.x;
      if (r < 0 || r >= gridSize || cc < 0 || cc >= gridSize) return false;
      if (grid[r][cc] != null) return false;
    }
    return true;
  }

  bool _canPlaceAnywhere(BlockShape shape) {
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (_canPlaceAt(shape, r, c)) return true;
      }
    }
    return false;
  }

  Future<void> _placeAt(BlockShape shape, int row, int col, int trayIndex) async {
    setState(() {
      for (final c in shape.cells) {
        grid[row + c.y][col + c.x] = shape.color;
      }
      score += shape.cells.length;
      tray[trayIndex] = null;
      previewCells = {};
    });

    await _checkLines();

    if (tray.every((p) => p == null)) {
      setState(() {
        tray = List.generate(3, (_) => _newShape());
      });
    }

    _checkGameOverState();
  }

  Future<void> _checkLines() async {
    final List<int> fullRows = [];
    final List<int> fullCols = [];

    for (int r = 0; r < gridSize; r++) {
      if (grid[r].every((cell) => cell != null)) fullRows.add(r);
    }
    for (int c = 0; c < gridSize; c++) {
      bool full = true;
      for (int r = 0; r < gridSize; r++) {
        if (grid[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) fullCols.add(c);
    }

    if (fullRows.isEmpty && fullCols.isEmpty) return;

    final Set<Point<int>> toClear = {};
    for (final r in fullRows) {
      for (int c = 0; c < gridSize; c++) toClear.add(Point(c, r));
    }
    for (final c in fullCols) {
      for (int r = 0; r < gridSize; r++) toClear.add(Point(c, r));
    }

    setState(() => clearingCells = toClear);
    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    final int linesCleared = fullRows.length + fullCols.length;
    int gained = linesCleared * gridSize * 2;
    if (linesCleared > 1) {
      gained += (linesCleared - 1) * 30; // Combo bonusu
    }

    setState(() {
      for (final p in toClear) {
        grid[p.y][p.x] = null;
      }
      clearingCells = {};
      score += gained;
    });

    await _saveHighScoreIfNeeded();
  }

  void _checkGameOverState() {
    for (final shape in tray) {
      if (shape != null && _canPlaceAnywhere(shape)) return;
    }
    setState(() => gameOver = true);
    _saveHighScoreIfNeeded();
  }

  void _restart() {
    setState(() {
      grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => null));
      tray = List.generate(3, (_) => _newShape());
      score = 0;
      gameOver = false;
      previewCells = {};
      clearingCells = {};
    });
  }

  void _updateDragPosition(Offset globalPos) {
    final shape = _draggingShape;
    if (shape == null) return;
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || cellSize == 0) return;

    // Parçayı parmaktan yukarı kaldırıyoruz ki görüş kapanmasın ve
    // tek elle en alt satıra kadar rahatça erişilebilsin.
    final lift = cellSize * 1.4;
    final anchor = globalPos.translate(0, -lift);
    final local = box.globalToLocal(anchor);

    int topLeftCol = (local.dx / cellSize - shape.width / 2).round();
    int topLeftRow = (local.dy / cellSize - shape.height / 2).round();

    topLeftCol = topLeftCol.clamp(0, gridSize - shape.width);
    topLeftRow = topLeftRow.clamp(0, gridSize - shape.height);

    final cells = shape.cells.map((c) => Point(topLeftCol + c.x, topLeftRow + c.y)).toSet();
    final valid = _canPlaceAt(shape, topLeftRow, topLeftCol);

    setState(() {
      _fingerPos = globalPos;
      previewCells = cells;
      previewValid = valid;
      _previewTopLeft = Point(topLeftCol, topLeftRow);
    });
  }

  void _onDragEnd() {
    final shape = _draggingShape;
    final index = _draggingIndex;
    final tl = _previewTopLeft;
    if (shape != null && index != null && tl != null && _canPlaceAt(shape, tl.y, tl.x)) {
      _placeAt(shape, tl.y, tl.x, index);
    }
    setState(() {
      _draggingShape = null;
      _draggingIndex = null;
      _fingerPos = null;
      _previewTopLeft = null;
      previewCells = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSide = min(constraints.maxWidth - 24, constraints.maxHeight * 0.55);
            cellSize = boardSide / gridSize;
            final floatingPiece = _buildFloatingPiece();
            return Stack(
              key: _stackKey,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildGrid(boardSide),
                    const Spacer(),
                    _buildTray(),
                    const SizedBox(height: 16),
                    if (gameOver) _buildGameOverBanner(),
                    const SizedBox(height: 12),
                  ],
                ),
                if (floatingPiece != null) floatingPiece,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget? _buildFloatingPiece() {
    final shape = _draggingShape;
    final pos = _fingerPos;
    if (shape == null || pos == null || cellSize == 0) return null;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return null;

    final lift = cellSize * 1.4;
    final anchor = pos.translate(0, -lift);
    final local = stackBox.globalToLocal(anchor);
    final pieceW = shape.width * cellSize;
    final pieceH = shape.height * cellSize;

    return Positioned(
      left: local.dx - pieceW / 2,
      top: local.dy - pieceH / 2,
      child: IgnorePointer(
        child: _shapeWidget(shape, cellSize, opacity: 0.95),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _scoreCard('SKOR', score, const Color(0xFF6C63FF)),
          const Text('Block Puzzle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
          _scoreCard('REKOR', highScore, const Color(0xFFFFD93D)),
        ],
      ),
    );
  }

  Widget _scoreCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          Text('$value',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildGrid(double boardSide) {
    return Container(
      key: _gridKey,
      width: boardSide,
      height: boardSide,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B33),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: List.generate(gridSize, (r) {
          return Expanded(
            child: Row(
              children: List.generate(gridSize, (c) => Expanded(child: _buildCell(r, c))),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    final point = Point(col, row);
    final isClearing = clearingCells.contains(point);
    final isPreview = previewCells.contains(point);
    final baseColor = grid[row][col];

    Color? displayColor = baseColor;
    if (isPreview) {
      displayColor = previewValid ? Colors.greenAccent.withOpacity(0.55) : Colors.redAccent.withOpacity(0.55);
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: AnimatedOpacity(
        opacity: isClearing ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: displayColor ?? const Color(0xFF26264A),
            borderRadius: BorderRadius.circular(6),
            border: baseColor == null && !isPreview
                ? Border.all(color: Colors.white.withOpacity(0.04))
                : null,
            boxShadow: baseColor != null
                ? [BoxShadow(color: baseColor.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTray() {
    return SizedBox(
      height: cellSize * 4.4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (i) {
          final shape = tray[i];
          if (shape == null) return SizedBox(width: cellSize * 3.4);
          return _buildTrayPiece(shape, i);
        }),
      ),
    );
  }

  Widget _buildTrayPiece(BlockShape shape, int index) {
    final isDraggingThis = _draggingIndex == index;
    final pieceWidget = _shapeWidget(shape, cellSize * 0.78);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        setState(() {
          _draggingShape = shape;
          _draggingIndex = index;
          _fingerPos = details.globalPosition;
        });
        _updateDragPosition(details.globalPosition);
      },
      onPanUpdate: (details) => _updateDragPosition(details.globalPosition),
      onPanEnd: (_) => _onDragEnd(),
      onPanCancel: () {
        setState(() {
          _draggingShape = null;
          _draggingIndex = null;
          _fingerPos = null;
          _previewTopLeft = null;
          previewCells = {};
        });
      },
      child: Opacity(opacity: isDraggingThis ? 0.2 : 1.0, child: pieceWidget),
    );
  }

  Widget _shapeWidget(BlockShape shape, double cs, {double opacity = 1.0}) {
    return SizedBox(
      width: shape.width * cs,
      height: shape.height * cs,
      child: Stack(
        children: shape.cells.map((c) {
          return Positioned(
            left: c.x * cs,
            top: c.y * cs,
            width: cs,
            height: cs,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  decoration: BoxDecoration(
                    color: shape.color,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(color: shape.color.withOpacity(0.6), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGameOverBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('OYUN BİTTİ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
          const SizedBox(height: 8),
          Text('Skor: $score', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _restart,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Yeniden Başla', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
