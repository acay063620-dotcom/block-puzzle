import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.load();
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
      home: const SplashScreen(),
    );
  }
}

/// ----------------- AYARLAR -----------------

class SettingsService {
  static bool musicOn = true;
  static bool vibrationOn = true;
  static int gridSizeSetting = 8;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    musicOn = prefs.getBool('music_on') ?? true;
    vibrationOn = prefs.getBool('vibration_on') ?? true;
    gridSizeSetting = prefs.getInt('grid_size') ?? 8;
  }

  static Future<void> setMusicOn(bool value) async {
    musicOn = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_on', value);
  }

  static Future<void> setVibrationOn(bool value) async {
    vibrationOn = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_on', value);
  }

  static Future<void> setGridSize(int value) async {
    gridSizeSetting = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('grid_size', value);
  }
}

/// ----------------- MÜZİK -----------------

class MusicController {
  static final AudioPlayer _player = AudioPlayer();
  static bool _started = false;

  static Future<void> start() async {
    if (_started) return;
    _started = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(1.0);
    if (SettingsService.musicOn) {
      await _player.play(AssetSource('audio/bgm.wav'));
    }
  }

  static Future<void> setMusicOn(bool value) async {
    await SettingsService.setMusicOn(value);
    if (value) {
      if (!_started) {
        await start();
      } else {
        await _player.resume();
      }
    } else {
      await _player.pause();
    }
  }
}

/// ----------------- AÇILIŞ (SPLASH) EKRANI -----------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();

    Future.delayed(const Duration(milliseconds: 500), () {
      MusicController.start();
    });

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, __, ___) => const GameScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121225),
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogo(),
              const SizedBox(height: 22),
              const Text(
                'Block Puzzle',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    color: Color(0xFF6C63FF), strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFD93D),
      const Color(0xFF6C63FF),
    ];
    return SizedBox(
      width: 110,
      height: 110,
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: List.generate(4, (i) {
          return Container(
            decoration: BoxDecoration(
              color: colors[i],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: colors[i].withOpacity(0.6),
                    blurRadius: 14,
                    offset: const Offset(0, 5)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// ----------------- AYARLAR EKRANI -----------------

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool musicOn;
  late bool vibrationOn;
  late int gridSizeSetting;
  late int _initialGridSize;

  @override
  void initState() {
    super.initState();
    musicOn = SettingsService.musicOn;
    vibrationOn = SettingsService.vibrationOn;
    gridSizeSetting = SettingsService.gridSizeSetting;
    _initialGridSize = gridSizeSetting;
  }

  @override
  Widget build(BuildContext context) {
    final gridChanged = gridSizeSetting != _initialGridSize;
    return Scaffold(
      backgroundColor: const Color(0xFF121225),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121225),
        elevation: 0,
        title: const Text('Ayarlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, gridChanged),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _switchTile('Müzik', musicOn, (v) async {
            setState(() => musicOn = v);
            await MusicController.setMusicOn(v);
          }),
          _switchTile('Titreşim', vibrationOn, (v) async {
            setState(() => vibrationOn = v);
            await SettingsService.setVibrationOn(v);
          }),
          const SizedBox(height: 24),
          const Text('Grid Boyutu', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _gridSizeButton(8)),
              const SizedBox(width: 12),
              Expanded(child: _gridSizeButton(10)),
            ],
          ),
          if (gridChanged) ...[
            const SizedBox(height: 16),
            const Text(
              'Grid boyutu değişti — geri dönünce oyun sıfırlanacak.',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B33),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(label, style: const TextStyle(color: Colors.white)),
        value: value,
        activeColor: const Color(0xFF6C63FF),
        onChanged: onChanged,
      ),
    );
  }

  Widget _gridSizeButton(int size) {
    final selected = gridSizeSetting == size;
    return GestureDetector(
      onTap: () async {
        setState(() => gridSizeSetting = size);
        await SettingsService.setGridSize(size);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6C63FF) : const Color(0xFF1B1B33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF6C63FF) : Colors.white24),
        ),
        child: Center(
          child: Text(
            '${size}x$size',
            style: TextStyle(
              color: Colors.white,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// ----------------- MODELLER -----------------

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
  late int gridSize;
  late List<List<Color?>> grid;
  late List<BlockShape?> tray;
  int score = 0;
  int highScore = 0;
  bool gameOver = false;
  int _pieceIdCounter = 0;

  bool musicOn = SettingsService.musicOn;
  bool vibrationOn = SettingsService.vibrationOn;

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
    gridSize = SettingsService.gridSizeSetting;
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
    if (vibrationOn) HapticFeedback.lightImpact();

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

    final int linesCleared = fullRows.length + fullCols.length;
    if (vibrationOn) {
      if (linesCleared > 1) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }

    setState(() => clearingCells = toClear);
    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

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

  Future<void> _openSettings() async {
    final gridChanged = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );

    setState(() {
      musicOn = SettingsService.musicOn;
      vibrationOn = SettingsService.vibrationOn;
    });

    if (gridChanged == true && SettingsService.gridSizeSetting != gridSize) {
      setState(() {
        gridSize = SettingsService.gridSizeSetting;
        grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => null));
        tray = List.generate(3, (_) => _newShape());
        score = 0;
        gameOver = false;
        previewCells = {};
        clearingCells = {};
      });
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70),
                onPressed: _openSettings,
              ),
              const Text(
                'Block Puzzle',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              IconButton(
                icon: Icon(musicOn ? Icons.volume_up : Icons.volume_off, color: Colors.white70),
                onPressed: () async {
                  final newVal = !musicOn;
                  setState(() => musicOn = newVal);
                  await MusicController.setMusicOn(newVal);
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _scoreCard('SKOR', score, const Color(0xFF6C63FF)),
              _scoreCard('REKOR', highScore, const Color(0xFFFFD93D)),
            ],
          ),
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
