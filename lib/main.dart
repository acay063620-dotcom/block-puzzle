import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

Future<void> _enableHighRefreshRate() async {
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (_) {
    // Cihaz desteklemiyorsa sessizce geç, oyunu etkilemesin.
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await _enableHighRefreshRate();
  runApp(const ParazulaApp());
}

class ParazulaApp extends StatelessWidget {
  const ParazulaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parazula - Block Puzzle',
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

/// ----------------- AYARLAR SERVİSİ -----------------

class AppSettings {
  static bool musicEnabled = true;
  static bool vibrationEnabled = true;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    musicEnabled = prefs.getBool('music_enabled') ?? true;
    vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
  }

  static Future<void> setMusic(bool value) async {
    musicEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', value);
  }

  static Future<void> setVibration(bool value) async {
    vibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
  }
}

/// ----------------- MÜZİK SERVİSİ -----------------

class BgmPlayer {
  static final AudioPlayer _player = AudioPlayer();
  static bool _started = false;

  static Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(AppSettings.musicEnabled ? 0.5 : 0.0);
      await _player.play(AssetSource('audio/bgm.wav'));
    } catch (_) {
      // Müzik çalınamazsa oyun yine de oynanabilir kalsın.
    }
  }

  static Future<void> applySettings() async {
    try {
      await _player.setVolume(AppSettings.musicEnabled ? 0.5 : 0.0);
    } catch (_) {}
  }
}

void _vibrate({bool light = false}) {
  if (!AppSettings.vibrationEnabled) return;
  if (light) {
    HapticFeedback.lightImpact();
  } else {
    HapticFeedback.mediumImpact();
  }
}

/// ----------------- PARAZULA LOGOSU -----------------

class ParazulaLogo extends StatelessWidget {
  final double blockSize;
  const ParazulaLogo({super.key, this.blockSize = 18});

  static const List<List<int>> _pattern = [
    [1, 1, 1, 0],
    [1, 0, 0, 1],
    [1, 0, 0, 1],
    [1, 1, 1, 0],
    [1, 0, 0, 0],
    [1, 0, 0, 0],
  ];

  static const List<Color> _logoColors = [
    Color(0xFF6C63FF),
    Color(0xFF38BDF8),
    Color(0xFF4ECDC4),
    Color(0xFFFFD93D),
    Color(0xFFFF8C42),
    Color(0xFFFF6B6B),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_pattern.length, (r) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_pattern[r].length, (c) {
            final filled = _pattern[r][c] == 1;
            final color = _logoColors[(r + c) % _logoColors.length];
            return Padding(
              padding: EdgeInsets.all(blockSize * 0.1),
              child: Container(
                width: blockSize,
                height: blockSize,
                decoration: filled
                    ? BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(blockSize * 0.28),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: blockSize * 0.3,
                            offset: Offset(0, blockSize * 0.15),
                          ),
                        ],
                      )
                    : null,
              ),
            );
          }),
        );
      }),
    );
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
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _init();
  }

  Future<void> _init() async {
    await AppSettings.load();
    unawaited(BgmPlayer.start());
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const GameScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121225),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ParazulaLogo(blockSize: 22),
                const SizedBox(height: 22),
                const Text(
                  'PARAZULA',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Block Puzzle',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.5),
                    letterSpacing: 2,
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

/// ----------------- AYARLAR EKRANI -----------------

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _music = AppSettings.musicEnabled;
  bool _vibration = AppSettings.vibrationEnabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121225),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _settingTile(
            icon: Icons.music_note_rounded,
            title: 'Müzik',
            subtitle: 'Arka plan melodisini aç/kapat',
            value: _music,
            onChanged: (v) async {
              setState(() => _music = v);
              await AppSettings.setMusic(v);
              await BgmPlayer.applySettings();
            },
          ),
          const SizedBox(height: 12),
          _settingTile(
            icon: Icons.vibration_rounded,
            title: 'Titreşim',
            subtitle: 'Yerleştirme ve oyun olaylarında titreşim',
            value: _vibration,
            onChanged: (v) async {
              setState(() => _vibration = v);
              await AppSettings.setVibration(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B33),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFF6C63FF)),
        title: Text(title,
            style:
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        value: value,
        activeColor: const Color(0xFF6C63FF),
        onChanged: onChanged,
      ),
    );
  }
}

/// ----------------- MODELLER -----------------

const int gridSize = 8; // 10x10 istersen bu değeri 10 yap.

class BlockShape {
  final List<Point<int>> cells; // x = sütun, y = satır (göreceli)
  final Color color;
  final int id;
  final int defIndex;

  BlockShape(this.cells, this.color, this.id, this.defIndex);

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

class _DragData {
  final BlockShape shape;
  final int trayIndex;
  _DragData(this.shape, this.trayIndex);
}

/// ----------------- OYUN EKRANI -----------------

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const _kSavedGame = 'saved_game_v1';

  late List<List<Color?>> grid;
  late List<BlockShape?> tray;
  int score = 0;
  int highScore = 0;
  bool gameOver = false;
  int _pieceIdCounter = 0;

  final GlobalKey _gridKey = GlobalKey();
  double cellSize = 0;

  Set<Point<int>> previewCells = {};
  bool previewValid = false;
  Set<Point<int>> clearingCells = {};

  @override
  void initState() {
    super.initState();
    grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => null));
    tray = List.generate(3, (_) => _newShape());
    _init();
  }

  Future<void> _init() async {
    await _loadHighScore();
    await _loadGameState();
    _checkGameOverState();
  }

  BlockShape _newShape() {
    _pieceIdCounter++;
    final defIndex = _rng.nextInt(_shapeDefs.length);
    final def = _shapeDefs[defIndex];
    final cells = def.map((c) => Point<int>(c[1], c[0])).toList();
    final color = _palette[_rng.nextInt(_palette.length)];
    return BlockShape(cells, color, _pieceIdCounter, defIndex);
  }

  BlockShape _shapeFromSaved(int defIndex, int colorIndex) {
    _pieceIdCounter++;
    final def = _shapeDefs[defIndex];
    final cells = def.map((c) => Point<int>(c[1], c[0])).toList();
    return BlockShape(cells, _palette[colorIndex], _pieceIdCounter, defIndex);
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

  /// Devam eden oyunu (skor + tahta + eldeki parçalar) kalıcı olarak kaydeder.
  Future<void> _saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final flatGrid = <int>[];
    for (final row in grid) {
      for (final cell in row) {
        flatGrid.add(cell == null ? -1 : _palette.indexOf(cell));
      }
    }
    final trayData = tray.map((shape) {
      if (shape == null) return null;
      return {'def': shape.defIndex, 'color': _palette.indexOf(shape.color)};
    }).toList();
    final data = jsonEncode({
      'score': score,
      'grid': flatGrid,
      'tray': trayData,
    });
    await prefs.setString(_kSavedGame, data);
  }

  /// Kaydedilmiş bir oyun varsa geri yükler.
  Future<bool> _loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSavedGame);
    if (raw == null) return false;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final flatGrid = (data['grid'] as List).cast<int>();
      if (flatGrid.length != gridSize * gridSize) return false;

      final newGrid = List.generate(gridSize, (r) {
        return List.generate(gridSize, (c) {
          final v = flatGrid[r * gridSize + c];
          return v == -1 ? null : _palette[v];
        });
      });

      final trayRaw = data['tray'] as List;
      final newTray = trayRaw.map<BlockShape?>((item) {
        if (item == null) return null;
        final map = item as Map<String, dynamic>;
        return _shapeFromSaved(map['def'] as int, map['color'] as int);
      }).toList();

      if (!mounted) return false;
      setState(() {
        grid = newGrid;
        tray = newTray;
        score = data['score'] as int? ?? 0;
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSavedGame);
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

  /// Parmağın tam doğru hücreye denk gelmediği durumlarda bile, yakın
  /// çevredeki geçerli bir hücreye "yapışarak" yerleştirmeyi dener. Bu,
  /// dokunma hassasiyeti sorunlarını büyük ölçüde ortadan kaldırır.
  Point<int>? _resolvePlacement(BlockShape shape, Point<int> tl) {
    if (_canPlaceAt(shape, tl.y, tl.x)) return tl;
    const offsets = [
      Point(0, -1), Point(0, 1), Point(-1, 0), Point(1, 0),
      Point(-1, -1), Point(1, -1), Point(-1, 1), Point(1, 1),
    ];
    for (final o in offsets) {
      final t = Point(tl.x + o.x, tl.y + o.y);
      if (_canPlaceAt(shape, t.y, t.x)) return t;
    }
    return null;
  }

  Future<void> _placeAt(BlockShape shape, int row, int col, int trayIndex) async {
    _vibrate(light: true);
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

    unawaited(_saveGameState());
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

    _vibrate();
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
    _vibrate();
    setState(() => gameOver = true);
    _saveHighScoreIfNeeded();
    unawaited(_clearSavedGame());
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
    unawaited(_saveGameState());
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    await BgmPlayer.applySettings();
  }

  Point<int>? _hoverTopLeft(Offset globalOffset) {
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || cellSize == 0) return null;
    final local = box.globalToLocal(globalOffset);
    final col = (local.dx / cellSize).floor();
    final row = (local.dy / cellSize).floor();
    return Point(col, row);
  }

  void _updatePreview(BlockShape shape, Offset globalOffset) {
    final tl = _hoverTopLeft(globalOffset);
    if (tl == null) return;
    final resolved = _resolvePlacement(shape, tl) ?? tl;
    final cells = shape.cells.map((c) => Point(resolved.x + c.x, resolved.y + c.y)).toSet();
    final valid = _canPlaceAt(shape, resolved.y, resolved.x);
    setState(() {
      previewCells = cells;
      previewValid = valid;
    });
  }

  void _clearPreview() {
    if (previewCells.isEmpty) return;
    setState(() => previewCells = {});
  }

  /// Parçayı sürüklerken görünürlüğü ve hassasiyeti artırmak için, parçanın
  /// parmağa göre sabit ve öngörülebilir bir noktada (parmağın hemen
  /// üzerinde) tutulmasını sağlar.
  Offset _dragAnchor(Draggable<Object> draggable, BuildContext context, Offset position) {
    final cs = cellSize > 0 ? cellSize : 32.0;
    return Offset(cs * 0.9, cs * 1.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSide = min(constraints.maxWidth - 24, constraints.maxHeight * 0.55);
            cellSize = boardSide / gridSize;
            return Column(
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const ParazulaLogo(blockSize: 6),
                  const SizedBox(width: 8),
                  Text('PARAZULA',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white.withOpacity(0.6),
                      )),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded, color: Colors.white70),
                onPressed: _openSettings,
                tooltip: 'Ayarlar',
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
    return RepaintBoundary(
      child: Container(
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
        child: DragTarget<_DragData>(
          onMove: (details) => _updatePreview(details.data.shape, details.offset),
          onLeave: (_) => _clearPreview(),
          onAcceptWithDetails: (details) {
            final tl = _hoverTopLeft(details.offset);
            final resolved = tl == null ? null : _resolvePlacement(details.data.shape, tl);
            if (resolved != null) {
              _placeAt(details.data.shape, resolved.y, resolved.x, details.data.trayIndex);
            } else {
              _clearPreview();
            }
          },
          builder: (context, candidate, rejected) {
            return Column(
              children: List.generate(gridSize, (r) {
                return Expanded(
                  child: Row(
                    children: List.generate(gridSize, (c) => Expanded(child: _buildCell(r, c))),
                  ),
                );
              }),
            );
          },
        ),
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
    final pieceWidget = _shapeWidget(shape, cellSize * 0.78);

    return Draggable<_DragData>(
      data: _DragData(shape, index),
      dragAnchorStrategy: _dragAnchor,
      feedback: Material(
        color: Colors.transparent,
        child: _shapeWidget(shape, cellSize, opacity: 0.9),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: pieceWidget),
      onDragStarted: () => _vibrate(light: true),
      onDragEnd: (_) => _clearPreview(),
      child: pieceWidget,
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
