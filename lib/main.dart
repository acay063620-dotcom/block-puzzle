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
      if (!_started) await start();
      else await _player.resume();
    } else {
      await _player.pause();
    }
  }
}

/// ----------------- AÇILIŞ EKRANI -----------------

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
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();
    Future.delayed(const Duration(milliseconds: 500), () => MusicController.start());
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const MainMenuScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ));
      }
    });
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

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
              const Text('Block Puzzle',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 28),
              const SizedBox(width: 28, height: 28,
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final colors = [
      const Color(0xFFFF6B6B), const Color(0xFF4ECDC4),
      const Color(0xFFFFD93D), const Color(0xFF6C63FF),
    ];
    return SizedBox(
      width: 110, height: 110,
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8, crossAxisSpacing: 8,
        children: List.generate(4, (i) => Container(
          decoration: BoxDecoration(
            color: colors[i], borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: colors[i].withOpacity(0.6), blurRadius: 14, offset: const Offset(0, 5))],
          ),
        )),
      ),
    );
  }
}

/// ----------------- ANA MENÜ -----------------

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int highScore = 0;
  bool musicOn = SettingsService.musicOn;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() { highScore = prefs.getInt('high_score') ?? 0; });
  }

  void _goToGame() {
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => const GameScreen(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    )).then((_) => _load());
  }

  Future<void> _openSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    setState(() => musicOn = SettingsService.musicOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121225),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Column(children: [
                  const Text('EN YÜKSEK SKOR',
                      style: TextStyle(fontSize: 11, color: Colors.white54, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text('$highScore',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFFD93D))),
                ]),
                IconButton(
                  icon: Icon(musicOn ? Icons.volume_up : Icons.volume_off, color: Colors.white70),
                  onPressed: () async {
                    final v = !musicOn;
                    setState(() => musicOn = v);
                    await MusicController.setMusicOn(v);
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildLogo(),
          const SizedBox(height: 12),
          const Text('Block Puzzle',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 48),
          _menuButton('Yeni Oyun', const Color(0xFF6C63FF), Icons.play_arrow_rounded, _goToGame),
          const SizedBox(height: 16),
          _menuButton('Ayarlar', const Color(0xFF26264A), Icons.settings_rounded, _openSettings),
          const Spacer(),
        ]),
      ),
    );
  }

  Widget _menuButton(String label, Color color, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white),
          label: Text(label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 6,
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final colors = [
      const Color(0xFFFF6B6B), const Color(0xFF4ECDC4),
      const Color(0xFFFFD93D), const Color(0xFF6C63FF),
    ];
    return SizedBox(
      width: 90, height: 90,
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6, crossAxisSpacing: 6,
        children: List.generate(4, (i) => Container(
          decoration: BoxDecoration(
            color: colors[i], borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: colors[i].withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))],
          ),
        )),
      ),
    );
  }
}

/// ----------------- AYARLAR -----------------

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool musicOn;
  late bool vibrationOn;
  late int gridSizeSetting;

  @override
  void initState() {
    super.initState();
    musicOn = SettingsService.musicOn;
    vibrationOn = SettingsService.vibrationOn;
    gridSizeSetting = SettingsService.gridSizeSetting;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121225),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121225),
        elevation: 0,
        title: const Text('Ayarlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
          Row(children: [
            Expanded(child: _gridSizeButton(8)),
            const SizedBox(width: 12),
            Expanded(child: _gridSizeButton(10)),
          ]),
          const SizedBox(height: 12),
          const Text('Grid boyutu Yeni Oyun başlatınca uygulanır.',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF1B1B33), borderRadius: BorderRadius.circular(12)),
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
          child: Text('${size}x$size',
              style: TextStyle(color: Colors.white,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }
}

/// ----------------- PARTİKÜL SİSTEMİ -----------------

class _Particle {
  Offset position;
  Offset velocity;
  Color color;
  double radius;
  double opacity;
  double rotation;
  double rotationSpeed;
  bool isSquare;

  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
    this.opacity = 1.0,
    this.rotation = 0,
    this.rotationSpeed = 0,
    this.isSquare = false,
  });
}

class _ExplosionPainter extends CustomPainter {
  final List<_Particle> particles;
  _ExplosionPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.rotation);

      if (p.isSquare) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.radius * 2, height: p.radius * 2),
            const Radius.circular(3),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.radius, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ExplosionPainter old) => true;
}

/// ----------------- MODELLER -----------------

class BlockShape {
  final List<Point<int>> cells;
  final Color color;
  final int id;
  BlockShape(this.cells, this.color, this.id);
  int get width => cells.map((c) => c.x).reduce(max) + 1;
  int get height => cells.map((c) => c.y).reduce(max) + 1;
}

final List<List<List<int>>> _shapeDefs = [
  [[0,0]], [[0,0],[0,1]], [[0,0],[1,0]],
  [[0,0],[0,1],[0,2]], [[0,0],[1,0],[2,0]],
  [[0,0],[0,1],[1,0],[1,1]],
  [[0,0],[0,1],[0,2],[0,3]], [[0,0],[1,0],[2,0],[3,0]],
  [[0,0],[0,1],[0,2],[0,3],[0,4]], [[0,0],[1,0],[2,0],[3,0],[4,0]],
  [[0,0],[1,0],[1,1]], [[0,0],[0,1],[1,0]],
  [[0,1],[1,0],[1,1]], [[0,0],[0,1],[1,1]],
  [[0,0],[0,1],[0,2],[1,0]], [[0,0],[0,1],[0,2],[1,2]],
  [[1,0],[1,1],[1,2],[0,0]], [[1,0],[1,1],[1,2],[0,2]],
  [[0,0],[1,0],[1,1],[2,1]], [[0,1],[1,0],[1,1],[2,0]],
  [[0,0],[0,1],[0,2],[1,1]], [[0,1],[1,0],[1,1],[1,2]],
  [[0,0],[0,1],[1,0],[1,1],[2,0],[2,1]],
  [[0,0],[0,1],[0,2],[1,0],[1,1],[1,2]],
];

final List<Color> _palette = [
  const Color(0xFFFF6B6B), const Color(0xFF4ECDC4),
  const Color(0xFFFFD93D), const Color(0xFF6C63FF),
  const Color(0xFF1AAB7B), const Color(0xFFFF8C42),
  const Color(0xFFC084FC), const Color(0xFF38BDF8),
];

final Random _rng = Random();

/// ----------------- OYUN EKRANI -----------------

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late int gridSize;
  late List<List<Color?>> grid;
  late List<BlockShape?> tray;
  int score = 0;
  int highScore = 0;
  bool gameOver = false;
  int _pieceIdCounter = 0;
  bool _newHighScore = false;
  bool _showNewHighScore = false;

  bool musicOn = SettingsService.musicOn;
  bool vibrationOn = SettingsService.vibrationOn;

  final GlobalKey _gridKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
  double cellSize = 0;

  Set<Point<int>> previewCells = {};
  bool previewValid = false;

  // Patlama sistemi
  Set<Point<int>> _flashCells = {};         // parlama fazı
  Set<Point<int>> _shrinkCells = {};        // küçülme fazı
  bool _showFlash = false;
  List<_Particle> _particles = [];
  late AnimationController _particleAnim;
  Offset _shakeOffset = Offset.zero;
  late AnimationController _shakeAnim;

  BlockShape? _draggingShape;
  int? _draggingIndex;
  Offset? _fingerPos;
  Point<int>? _previewTopLeft;

  late AnimationController _newRecordAnim;
  late Animation<double> _newRecordScale;
  late Animation<double> _newRecordFade;

  late AnimationController _gameOverAnim;

  @override
  void initState() {
    super.initState();
    gridSize = SettingsService.gridSizeSetting;

    _particleAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..addListener(_updateParticles)
      ..addStatusListener((s) { if (s == AnimationStatus.completed) setState(() => _particles = []); });

    _shakeAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))
      ..addListener(_updateShake)
      ..addStatusListener((s) { if (s == AnimationStatus.completed) setState(() => _shakeOffset = Offset.zero); });

    _newRecordAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _newRecordScale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _newRecordAnim, curve: Curves.elasticOut));
    _newRecordFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _newRecordAnim, curve: Curves.easeIn));

    _gameOverAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => null));
    tray = List.generate(3, (_) => _newShape());
    _loadHighScore();
  }

  @override
  void dispose() {
    _particleAnim.dispose();
    _shakeAnim.dispose();
    _newRecordAnim.dispose();
    _gameOverAnim.dispose();
    super.dispose();
  }

  void _updateParticles() {
    final t = _particleAnim.value;
    for (final p in _particles) {
      p.position += p.velocity * 0.016 * 60;
      p.velocity = Offset(p.velocity.dx * 0.92, p.velocity.dy * 0.92 + 0.3);
      p.opacity = (1.0 - t * 1.2).clamp(0.0, 1.0);
      p.radius = p.radius * 0.985;
      p.rotation += p.rotationSpeed;
    }
    setState(() {});
  }

  void _updateShake() {
    final t = _shakeAnim.value;
    final magnitude = (1.0 - t) * 6.0;
    _shakeOffset = Offset(
      sin(t * pi * 8) * magnitude,
      cos(t * pi * 6) * magnitude * 0.5,
    );
    setState(() {});
  }

  void _spawnParticles(Set<Point<int>> cells, List<Color> colors) {
    if (cellSize == 0) return;
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return;
    final gridOffset = stackBox.globalToLocal(box.localToGlobal(Offset.zero));

    final newParticles = <_Particle>[];
    for (final cell in cells) {
      final center = Offset(
        gridOffset.dx + cell.x * cellSize + cellSize / 2,
        gridOffset.dy + cell.y * cellSize + cellSize / 2,
      );
      final color = colors[_rng.nextInt(colors.length)];

      // 8 büyük parçacık
      for (int i = 0; i < 8; i++) {
        final angle = (i / 8) * pi * 2 + _rng.nextDouble() * 0.5;
        final speed = 3.0 + _rng.nextDouble() * 5.0;
        newParticles.add(_Particle(
          position: center,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed - 4),
          color: color,
          radius: 4.0 + _rng.nextDouble() * 4.0,
          rotationSpeed: (_rng.nextDouble() - 0.5) * 0.3,
          isSquare: _rng.nextBool(),
        ));
      }

      // 5 küçük parlak parçacık
      for (int i = 0; i < 5; i++) {
        final angle = _rng.nextDouble() * pi * 2;
        final speed = 1.5 + _rng.nextDouble() * 3.0;
        newParticles.add(_Particle(
          position: center,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed - 2),
          color: Colors.white,
          radius: 2.0 + _rng.nextDouble() * 2.0,
        ));
      }
    }
    setState(() => _particles = newParticles);
    _particleAnim.forward(from: 0);
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
    setState(() { highScore = prefs.getInt('high_score') ?? 0; });
  }

  Future<void> _saveHighScoreIfNeeded() async {
    if (score > highScore) {
      final bool firstTime = !_newHighScore;
      highScore = score;
      _newHighScore = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('high_score', highScore);
      if (mounted && firstTime) {
        setState(() => _showNewHighScore = true);
        _newRecordAnim.forward();
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _newRecordAnim.reverse().then((_) {
              if (mounted) setState(() => _showNewHighScore = false);
            });
          }
        });
      }
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
      setState(() { tray = List.generate(3, (_) => _newShape()); });
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
        if (grid[r][c] == null) { full = false; break; }
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

    // Renkleri topla (parçacık için)
    final Set<Color> usedColors = {};
    for (final p in toClear) {
      final c = grid[p.y][p.x];
      if (c != null) usedColors.add(c);
    }
    final colorList = usedColors.isEmpty ? _palette : usedColors.toList();

    final int linesCleared = fullRows.length + fullCols.length;
    if (vibrationOn) {
      if (linesCleared > 1) HapticFeedback.heavyImpact();
      else HapticFeedback.mediumImpact();
    }

    // --- FLAŞ fazı ---
    setState(() { _flashCells = toClear; _showFlash = true; _shrinkCells = {}; });
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    setState(() { _showFlash = false; });
    await Future.delayed(const Duration(milliseconds: 40));
    if (!mounted) return;
    setState(() { _showFlash = true; });
    await Future.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    setState(() { _showFlash = false; _flashCells = {}; });

    // --- KÜÇÜLME fazı ---
    setState(() { _shrinkCells = toClear; });
    await Future.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;

    // --- PARTİKÜLLER ---
    _spawnParticles(toClear, colorList);

    // --- Sarsıntı ---
    _shakeAnim.forward(from: 0);

    // --- TEMIZLE ---
    setState(() {
      for (final p in toClear) grid[p.y][p.x] = null;
      _shrinkCells = {};
    });

    int gained = linesCleared * gridSize * 2;
    if (linesCleared > 1) gained += (linesCleared - 1) * 30;
    setState(() => score += gained);

    await _saveHighScoreIfNeeded();
  }

  void _checkGameOverState() {
    for (final shape in tray) {
      if (shape != null && _canPlaceAnywhere(shape)) return;
    }
    setState(() => gameOver = true);
    _saveHighScoreIfNeeded();
    _gameOverAnim.forward();
  }

  void _restart() {
    _gameOverAnim.reset();
    _newRecordAnim.reset();
    setState(() {
      grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => null));
      tray = List.generate(3, (_) => _newShape());
      score = 0;
      gameOver = false;
      _newHighScore = false;
      _showNewHighScore = false;
      previewCells = {};
      _flashCells = {};
      _shrinkCells = {};
      _particles = [];
    });
  }

  void _updateDragPosition(Offset globalPos) {
    final shape = _draggingShape;
    if (shape == null) return;
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || cellSize == 0) return;
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
            return Transform.translate(
              offset: _shakeOffset,
              child: Stack(
                key: _stackKey,
                children: [
                  Column(children: [
                    const SizedBox(height: 8),
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildGrid(boardSide),
                    const Spacer(),
                    _buildTray(),
                    const SizedBox(height: 16),
                  ]),
                  // Parçacıklar
                  if (_particles.isNotEmpty)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: _ExplosionPainter(_particles)),
                      ),
                    ),
                  if (floatingPiece != null) floatingPiece,
                  if (_showNewHighScore) _buildNewHighScoreBanner(),
                  if (gameOver) _buildGameOverOverlay(),
                ],
              ),
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
    return Positioned(
      left: local.dx - shape.width * cellSize / 2,
      top: local.dy - shape.height * cellSize / 2,
      child: IgnorePointer(child: _shapeWidget(shape, cellSize, opacity: 0.95)),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Text('Block Puzzle',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
            Row(children: [
              IconButton(
                icon: Icon(musicOn ? Icons.volume_up : Icons.volume_off, color: Colors.white70),
                onPressed: () async {
                  final v = !musicOn;
                  setState(() => musicOn = v);
                  await MusicController.setMusicOn(v);
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  setState(() {
                    musicOn = SettingsService.musicOn;
                    vibrationOn = SettingsService.vibrationOn;
                  });
                },
              ),
            ]),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _scoreCard('SKOR', score, const Color(0xFF6C63FF)),
            _scoreCard('REKOR', highScore, const Color(0xFFFFD93D)),
          ],
        ),
      ]),
    );
  }

  Widget _scoreCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 11, color: color)),
        Text('$value',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ]),
    );
  }

  Widget _buildGrid(double boardSide) {
    return Container(
      key: _gridKey,
      width: boardSide, height: boardSide,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B33),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: List.generate(gridSize, (r) => Expanded(
          child: Row(
            children: List.generate(gridSize, (c) => Expanded(child: _buildCell(r, c))),
          ),
        )),
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    final point = Point(col, row);
    final isFlash = _flashCells.contains(point);
    final isShrink = _shrinkCells.contains(point);
    final isPreview = previewCells.contains(point);
    final baseColor = grid[row][col];

    Color? displayColor = baseColor;
    if (isFlash) displayColor = Colors.white;
    else if (isPreview) {
      displayColor = previewValid
          ? Colors.greenAccent.withOpacity(0.55)
          : Colors.redAccent.withOpacity(0.55);
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: AnimatedScale(
        scale: isShrink ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeIn,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          decoration: BoxDecoration(
            color: displayColor ?? const Color(0xFF26264A),
            borderRadius: BorderRadius.circular(6),
            border: baseColor == null && !isPreview && !isFlash
                ? Border.all(color: Colors.white.withOpacity(0.04))
                : null,
            boxShadow: (baseColor != null && !isShrink)
                ? [BoxShadow(
                    color: isFlash
                        ? Colors.white.withOpacity(0.9)
                        : baseColor.withOpacity(0.5),
                    blurRadius: isFlash ? 12 : 4,
                    offset: const Offset(0, 2))]
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
      onPanStart: (d) {
        setState(() { _draggingShape = shape; _draggingIndex = index; _fingerPos = d.globalPosition; });
        _updateDragPosition(d.globalPosition);
      },
      onPanUpdate: (d) => _updateDragPosition(d.globalPosition),
      onPanEnd: (_) => _onDragEnd(),
      onPanCancel: () {
        setState(() {
          _draggingShape = null; _draggingIndex = null;
          _fingerPos = null; _previewTopLeft = null; previewCells = {};
        });
      },
      child: Opacity(opacity: isDraggingThis ? 0.2 : 1.0, child: pieceWidget),
    );
  }

  Widget _shapeWidget(BlockShape shape, double cs, {double opacity = 1.0}) {
    return SizedBox(
      width: shape.width * cs, height: shape.height * cs,
      child: Stack(
        children: shape.cells.map((c) => Positioned(
          left: c.x * cs, top: c.y * cs, width: cs, height: cs,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Opacity(
              opacity: opacity,
              child: Container(
                decoration: BoxDecoration(
                  color: shape.color,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [BoxShadow(color: shape.color.withOpacity(0.6), blurRadius: 4, offset: const Offset(0, 2))],
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildNewHighScoreBanner() {
    return Positioned(
      top: 120, left: 0, right: 0,
      child: Center(
        child: FadeTransition(
          opacity: _newRecordFade,
          child: ScaleTransition(
            scale: _newRecordScale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFD93D), Color(0xFFFF8C42)]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: const Color(0xFFFFD93D).withOpacity(0.6), blurRadius: 20)],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.star_rounded, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text('YENİ REKOR!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(width: 8),
                Icon(Icons.star_rounded, color: Colors.white, size: 22),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: _gameOverAnim, curve: Curves.easeOut)),
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B33),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('OYUN BİTTİ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent)),
              const SizedBox(height: 16),
              _infoRow('Skor', '$score', const Color(0xFF6C63FF)),
              const SizedBox(height: 8),
              _infoRow('En Yüksek', '$highScore', const Color(0xFFFFD93D)),
              if (_newHighScore) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD93D).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.star_rounded, color: Color(0xFFFFD93D), size: 16),
                    SizedBox(width: 4),
                    Text('Yeni Rekor!',
                        style: TextStyle(color: Color(0xFFFFD93D), fontWeight: FontWeight.bold)),
                  ]),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.replay_rounded, color: Colors.white),
                  label: const Text('Yeniden Oyna',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.home_rounded, color: Colors.white70),
                  label: const Text('Ana Menü',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
