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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

/// ----------------- TEMA RENK TİERLERİ -----------------

const List<Color> _tierColors = [
  Color(0xFF6C63FF), // 0    — mor
  Color(0xFF4ECDC4), // 1000 — turkuaz
  Color(0xFFFF8C42), // 2000 — turuncu
  Color(0xFF1AAB7B), // 3000 — yeşil
  Color(0xFFC084FC), // 4000 — pembe
  Color(0xFFFF6B6B), // 5000 — kırmızı
  Color(0xFFFFD93D), // 6000 — sarı
  Color(0xFF38BDF8), // 7000 — mavi
];

Color _tierColor(int score) => _tierColors[(score ~/ 1000) % _tierColors.length];
Color _nextTierColor(int score) => _tierColors[((score ~/ 1000) + 1) % _tierColors.length];

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
  static Future<void> setMusicOn(bool v) async { musicOn = v; (await SharedPreferences.getInstance()).setBool('music_on', v); }
  static Future<void> setVibrationOn(bool v) async { vibrationOn = v; (await SharedPreferences.getInstance()).setBool('vibration_on', v); }
  static Future<void> setGridSize(int v) async { gridSizeSetting = v; (await SharedPreferences.getInstance()).setInt('grid_size', v); }
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
    if (SettingsService.musicOn) await _player.play(AssetSource('audio/bgm.wav'));
  }

  static Future<void> setMusicOn(bool value) async {
    await SettingsService.setMusicOn(value);
    if (value) { if (!_started) await start(); else await _player.resume(); }
    else await _player.pause();
  }
}

/// ----------------- AÇILIŞ EKRANI -----------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
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
      if (mounted) Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const MainMenuScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ));
    });
  }

  @override void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF121225),
    body: FadeTransition(opacity: _fade, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _logo(110), const SizedBox(height: 22),
      const Text('Block Puzzle', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 28),
      const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 3)),
    ]))),
  );

  Widget _logo(double size) {
    final colors = [const Color(0xFFFF6B6B), const Color(0xFF4ECDC4), const Color(0xFFFFD93D), const Color(0xFF6C63FF)];
    return SizedBox(width: size, height: size, child: GridView.count(
      crossAxisCount: 2, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: size * 0.07, crossAxisSpacing: size * 0.07,
      children: List.generate(4, (i) => Container(decoration: BoxDecoration(
        color: colors[i], borderRadius: BorderRadius.circular(size * 0.14),
        boxShadow: [BoxShadow(color: colors[i].withOpacity(0.6), blurRadius: 14, offset: const Offset(0, 5))],
      ))),
    ));
  }
}

/// ----------------- ANA MENÜ -----------------

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
  @override State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int highScore = 0;
  bool musicOn = SettingsService.musicOn;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() { highScore = prefs.getInt('high_score') ?? 0; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121225),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const SizedBox(width: 40),
            Column(children: [
              const Text('EN YÜKSEK SKOR', style: TextStyle(fontSize: 11, color: Colors.white54, letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Text('$highScore', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFFD93D))),
            ]),
            IconButton(
              icon: Icon(musicOn ? Icons.volume_up : Icons.volume_off, color: Colors.white70),
              onPressed: () async { final v = !musicOn; setState(() => musicOn = v); await MusicController.setMusicOn(v); },
            ),
          ]),
        ),
        const Spacer(),
        _SplashLogoWidget(),
        const SizedBox(height: 12),
        const Text('Block Puzzle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70)),
        const SizedBox(height: 48),
        _menuBtn('Yeni Oyun', const Color(0xFF6C63FF), Icons.play_arrow_rounded,
            () => Navigator.of(context).push(PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (_, __, ___) => const GameScreen(),
              transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            )).then((_) => _load())),
        const SizedBox(height: 16),
        _menuBtn('Ayarlar', const Color(0xFF26264A), Icons.settings_rounded,
            () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              setState(() => musicOn = SettingsService.musicOn);
            }),
        const Spacer(),
      ])),
    );
  }

  Widget _menuBtn(String label, Color color, IconData icon, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: SizedBox(width: double.infinity, child: ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
      ),
    )),
  );
}

class _SplashLogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = [const Color(0xFFFF6B6B), const Color(0xFF4ECDC4), const Color(0xFFFFD93D), const Color(0xFF6C63FF)];
    return SizedBox(width: 90, height: 90, child: GridView.count(
      crossAxisCount: 2, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6, crossAxisSpacing: 6,
      children: List.generate(4, (i) => Container(decoration: BoxDecoration(
        color: colors[i], borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: colors[i].withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))],
      ))),
    ));
  }
}

/// ----------------- AYARLAR -----------------

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool musicOn = SettingsService.musicOn;
  late bool vibrationOn = SettingsService.vibrationOn;
  late int gridSizeSetting = SettingsService.gridSizeSetting;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF121225),
    appBar: AppBar(backgroundColor: const Color(0xFF121225), elevation: 0, title: const Text('Ayarlar'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      _switchTile('Müzik', musicOn, (v) async { setState(() => musicOn = v); await MusicController.setMusicOn(v); }),
      _switchTile('Titreşim', vibrationOn, (v) async { setState(() => vibrationOn = v); await SettingsService.setVibrationOn(v); }),
      const SizedBox(height: 24),
      const Text('Grid Boyutu', style: TextStyle(color: Colors.white70, fontSize: 14)),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: _gridBtn(8)), const SizedBox(width: 12), Expanded(child: _gridBtn(10))]),
      const SizedBox(height: 12),
      const Text('Grid boyutu Yeni Oyun başlatınca uygulanır.', style: TextStyle(color: Colors.white38, fontSize: 11)),
    ]),
  );

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChange) => Container(
    margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(color: const Color(0xFF1B1B33), borderRadius: BorderRadius.circular(12)),
    child: SwitchListTile(title: Text(label, style: const TextStyle(color: Colors.white)),
        value: value, activeColor: const Color(0xFF6C63FF), onChanged: onChange),
  );

  Widget _gridBtn(int size) {
    final sel = gridSizeSetting == size;
    return GestureDetector(
      onTap: () async { setState(() => gridSizeSetting = size); await SettingsService.setGridSize(size); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF6C63FF) : const Color(0xFF1B1B33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? const Color(0xFF6C63FF) : Colors.white24),
        ),
        child: Center(child: Text('${size}x$size',
            style: TextStyle(color: Colors.white, fontWeight: sel ? FontWeight.bold : FontWeight.normal))),
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
  _Particle({required this.position, required this.velocity, required this.color,
    required this.radius, this.opacity = 1.0, this.rotation = 0, this.rotationSpeed = 0, this.isSquare = false});
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
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.radius * 2, height: p.radius * 2),
          const Radius.circular(3)), paint);
      } else {
        canvas.drawCircle(Offset.zero, p.radius, paint);
      }
      canvas.restore();
    }
  }
  @override bool shouldRepaint(_ExplosionPainter old) => true;
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

final List<Color> _basePalette = [
  const Color(0xFFFF6B6B), const Color(0xFF4ECDC4),
  const Color(0xFFFFD93D), const Color(0xFF6C63FF),
  const Color(0xFF1AAB7B), const Color(0xFFFF8C42),
  const Color(0xFFC084FC), const Color(0xFF38BDF8),
];

final Random _rng = Random();

/// Tier'a göre renk paleti — tier rengi öne çıkar, diğerleri karışır
List<Color> _paletteForTier(int tier) {
  final accent = _tierColors[tier % _tierColors.length];
  return [accent, accent, ..._basePalette]..shuffle(_rng);
}

/// ----------------- OYUN EKRANI -----------------

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override State<GameScreen> createState() => _GameScreenState();
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
  int _currentTier = 0;

  bool musicOn = SettingsService.musicOn;
  bool vibrationOn = SettingsService.vibrationOn;

  final GlobalKey _gridKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
  double cellSize = 0;

  Set<Point<int>> previewCells = {};
  bool previewValid = false;
  Set<Point<int>> _flashCells = {};
  Set<Point<int>> _shrinkCells = {};
  bool _showFlash = false;
  List<_Particle> _particles = [];

  // Combo göstergesi
  int _lastCombo = 0;
  bool _showCombo = false;
  String _comboText = '';
  Color _comboColor = Colors.white;

  // Tier değişim efekti
  bool _showTierUp = false;
  late AnimationController _tierUpAnim;
  late Animation<double> _tierUpScale;
  late Animation<double> _tierUpFade;

  late AnimationController _particleAnim;
  late AnimationController _shakeAnim;
  Offset _shakeOffset = Offset.zero;

  late AnimationController _comboAnim;
  late Animation<double> _comboScale;
  late Animation<double> _comboFade;
  late Animation<Offset> _comboSlide;

  late AnimationController _newRecordAnim;
  late Animation<double> _newRecordScale;
  late Animation<double> _newRecordFade;

  late AnimationController _gameOverAnim;

  // Ekran flaşı (kombo)
  double _screenFlashOpacity = 0.0;

  BlockShape? _draggingShape;
  int? _draggingIndex;
  Offset? _fingerPos;
  Point<int>? _previewTopLeft;

  @override
  void initState() {
    super.initState();
    gridSize = SettingsService.gridSizeSetting;

    _particleAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..addListener(_tickParticles)
      ..addStatusListener((s) { if (s == AnimationStatus.completed) setState(() => _particles = []); });

    _shakeAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))
      ..addListener(() {
        final t = _shakeAnim.value;
        final mag = (1.0 - t) * 8.0;
        setState(() => _shakeOffset = Offset(sin(t * pi * 10) * mag, cos(t * pi * 7) * mag * 0.4));
      })
      ..addStatusListener((s) { if (s == AnimationStatus.completed) setState(() => _shakeOffset = Offset.zero); });

    _comboAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _comboScale = Tween<double>(begin: 0.3, end: 1.2)
        .animate(CurvedAnimation(parent: _comboAnim, curve: const Interval(0, 0.4, curve: Curves.elasticOut)));
    _comboFade = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _comboAnim, curve: const Interval(0.6, 1.0, curve: Curves.easeIn)));
    _comboSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.6))
        .animate(CurvedAnimation(parent: _comboAnim, curve: const Interval(0.3, 1.0, curve: Curves.easeIn)));
    _comboAnim.addStatusListener((s) { if (s == AnimationStatus.completed) setState(() => _showCombo = false); });

    _tierUpAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _tierUpScale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _tierUpAnim, curve: Curves.elasticOut));
    _tierUpFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _tierUpAnim, curve: Curves.easeIn));
    _tierUpAnim.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _tierUpAnim.reverse().then((_) { if (mounted) setState(() => _showTierUp = false); });
        });
      }
    });

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
    _particleAnim.dispose(); _shakeAnim.dispose(); _comboAnim.dispose();
    _tierUpAnim.dispose(); _newRecordAnim.dispose(); _gameOverAnim.dispose();
    super.dispose();
  }

  void _tickParticles() {
    for (final p in _particles) {
      p.position += p.velocity;
      p.velocity = Offset(p.velocity.dx * 0.91, p.velocity.dy * 0.91 + 0.35);
      p.opacity = (1.0 - _particleAnim.value * 1.3).clamp(0.0, 1.0);
      p.radius *= 0.983;
      p.rotation += p.rotationSpeed;
    }
    setState(() {});
  }

  void _spawnParticles(Set<Point<int>> cells, List<Color> colors, {bool mega = false}) {
    if (cellSize == 0) return;
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return;
    final gridOff = stackBox.globalToLocal(box.localToGlobal(Offset.zero));
    final newP = <_Particle>[];
    final bigCount = mega ? 14 : 8;
    final smallCount = mega ? 8 : 4;

    for (final cell in cells) {
      final center = Offset(gridOff.dx + cell.x * cellSize + cellSize / 2,
                            gridOff.dy + cell.y * cellSize + cellSize / 2);
      final color = colors[_rng.nextInt(colors.length)];
      for (int i = 0; i < bigCount; i++) {
        final angle = (i / bigCount) * pi * 2 + _rng.nextDouble() * 0.6;
        final speed = (mega ? 5.0 : 3.0) + _rng.nextDouble() * (mega ? 7.0 : 4.0);
        newP.add(_Particle(
          position: center,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed - (mega ? 6 : 4)),
          color: color, radius: (mega ? 6.0 : 4.0) + _rng.nextDouble() * 4.0,
          rotationSpeed: (_rng.nextDouble() - 0.5) * 0.35, isSquare: _rng.nextBool(),
        ));
      }
      for (int i = 0; i < smallCount; i++) {
        final angle = _rng.nextDouble() * pi * 2;
        final speed = 2.0 + _rng.nextDouble() * 4.0;
        newP.add(_Particle(
          position: center,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed - 3),
          color: Colors.white, radius: 2.0 + _rng.nextDouble() * 3.0,
        ));
      }
    }
    setState(() => _particles = newP);
    _particleAnim.forward(from: 0);
  }

  void _showComboEffect(int linesCleared, Color accent) {
    if (linesCleared < 2) return;
    String text;
    if (linesCleared == 2) text = 'COMBO!';
    else if (linesCleared == 3) text = 'SÜPER COMBO!';
    else text = 'MEGA COMBO!!';

    setState(() {
      _lastCombo = linesCleared;
      _comboText = text;
      _comboColor = accent;
      _showCombo = true;
    });
    _comboAnim.forward(from: 0);

    // Ekran flaşı
    setState(() => _screenFlashOpacity = linesCleared >= 3 ? 0.35 : 0.18);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _screenFlashOpacity = 0.0);
    });
  }

  BlockShape _newShape() {
    _pieceIdCounter++;
    final def = _shapeDefs[_rng.nextInt(_shapeDefs.length)];
    final cells = def.map((c) => Point<int>(c[1], c[0])).toList();
    final palette = _paletteForTier(_currentTier);
    return BlockShape(cells, palette[_rng.nextInt(palette.length)], _pieceIdCounter);
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
      (await SharedPreferences.getInstance()).setInt('high_score', highScore);
      if (mounted && firstTime) {
        setState(() => _showNewHighScore = true);
        _newRecordAnim.forward();
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _newRecordAnim.reverse().then((_) { if (mounted) setState(() => _showNewHighScore = false); });
        });
      }
    }
  }

  void _checkTierUp(int oldScore, int newScore) {
    final oldTier = oldScore ~/ 1000;
    final newTier = newScore ~/ 1000;
    if (newTier > oldTier) {
      setState(() { _currentTier = newTier; _showTierUp = true; });
      _tierUpAnim.forward(from: 0);
      // Tepsideki blokları yeni renklerle yenile
      setState(() {
        tray = tray.map((shape) {
          if (shape == null) return null;
          final palette = _paletteForTier(_currentTier);
          return BlockShape(shape.cells, palette[_rng.nextInt(palette.length)], shape.id);
        }).toList();
      });
    }
  }

  bool _canPlaceAt(BlockShape shape, int row, int col) {
    for (final c in shape.cells) {
      final r = row + c.y; final cc = col + c.x;
      if (r < 0 || r >= gridSize || cc < 0 || cc >= gridSize) return false;
      if (grid[r][cc] != null) return false;
    }
    return true;
  }

  bool _canPlaceAnywhere(BlockShape shape) {
    for (int r = 0; r < gridSize; r++)
      for (int c = 0; c < gridSize; c++)
        if (_canPlaceAt(shape, r, c)) return true;
    return false;
  }

  Future<void> _placeAt(BlockShape shape, int row, int col, int trayIndex) async {
    if (vibrationOn) HapticFeedback.lightImpact();
    final oldScore = score;
    setState(() {
      for (final c in shape.cells) grid[row + c.y][col + c.x] = shape.color;
      score += shape.cells.length;
      tray[trayIndex] = null;
      previewCells = {};
    });
    _checkTierUp(oldScore, score);
    await _checkLines();
    if (tray.every((p) => p == null)) setState(() { tray = List.generate(3, (_) => _newShape()); });
    _checkGameOverState();
  }

  Future<void> _checkLines() async {
    final List<int> fullRows = [], fullCols = [];
    for (int r = 0; r < gridSize; r++) {
      if (grid[r].every((c) => c != null)) fullRows.add(r);
    }
    for (int c = 0; c < gridSize; c++) {
      bool full = true;
      for (int r = 0; r < gridSize; r++) { if (grid[r][c] == null) { full = false; break; } }
      if (full) fullCols.add(c);
    }
    if (fullRows.isEmpty && fullCols.isEmpty) return;

    final Set<Point<int>> toClear = {};
    for (final r in fullRows) for (int c = 0; c < gridSize; c++) toClear.add(Point(c, r));
    for (final c in fullCols) for (int r = 0; r < gridSize; r++) toClear.add(Point(c, r));

    final Set<Color> usedColors = {};
    for (final p in toClear) { final c = grid[p.y][p.x]; if (c != null) usedColors.add(c); }
    final colorList = usedColors.isEmpty ? _basePalette : usedColors.toList();

    final int linesCleared = fullRows.length + fullCols.length;
    final bool isCombo = linesCleared >= 2;
    final accent = _tierColor(score);

    if (vibrationOn) {
      if (linesCleared >= 3) HapticFeedback.heavyImpact();
      else if (linesCleared == 2) HapticFeedback.mediumImpact();
      else HapticFeedback.mediumImpact();
    }

    // Kombo efekti
    if (isCombo) _showComboEffect(linesCleared, accent);

    // Flaş
    setState(() { _flashCells = toClear; _showFlash = true; _shrinkCells = {}; });
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    setState(() => _showFlash = false);
    await Future.delayed(const Duration(milliseconds: 40));
    if (!mounted) return;
    setState(() => _showFlash = true);
    await Future.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    setState(() { _showFlash = false; _flashCells = {}; });

    // Küçülme
    setState(() => _shrinkCells = toClear);
    await Future.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;

    // Parçacıklar — kombo'da mega
    _spawnParticles(toClear, colorList, mega: isCombo);
    _shakeAnim.forward(from: 0);

    // Temizle
    final oldScore = score;
    setState(() {
      for (final p in toClear) grid[p.y][p.x] = null;
      _shrinkCells = {};
    });

    // --- PUANLAMA ---
    // Tek satır: gridSize * 10
    // 2 satır: gridSize * 10 * 2 + 100 (combo)
    // 3 satır: gridSize * 10 * 3 + 300
    // 4+ satır: gridSize * 10 * n + 600 + (n-3)*400
    int gained = linesCleared * gridSize * 10;
    if (linesCleared == 2) gained += 100;
    else if (linesCleared == 3) gained += 300;
    else if (linesCleared >= 4) gained += 600 + (linesCleared - 3) * 400;

    setState(() => score += gained);
    _checkTierUp(oldScore, score);
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
    _gameOverAnim.reset(); _newRecordAnim.reset();
    setState(() {
      grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => null));
      tray = List.generate(3, (_) => _newShape());
      score = 0; gameOver = false; _newHighScore = false;
      _showNewHighScore = false; _currentTier = 0;
      previewCells = {}; _flashCells = {}; _shrinkCells = {}; _particles = [];
      _showCombo = false; _showTierUp = false;
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
    int col = (local.dx / cellSize - shape.width / 2).round().clamp(0, gridSize - shape.width);
    int row = (local.dy / cellSize - shape.height / 2).round().clamp(0, gridSize - shape.height);
    setState(() {
      _fingerPos = globalPos;
      previewCells = shape.cells.map((c) => Point(col + c.x, row + c.y)).toSet();
      previewValid = _canPlaceAt(shape, row, col);
      _previewTopLeft = Point(col, row);
    });
  }

  void _onDragEnd() {
    final shape = _draggingShape; final index = _draggingIndex; final tl = _previewTopLeft;
    if (shape != null && index != null && tl != null && _canPlaceAt(shape, tl.y, tl.x)) {
      _placeAt(shape, tl.y, tl.x, index);
    }
    setState(() { _draggingShape = null; _draggingIndex = null; _fingerPos = null; _previewTopLeft = null; previewCells = {}; });
  }

  Color get _accentColor => _tierColor(score);
  Color get _nextAccentColor => _nextTierColor(score);
  int get _tierProgress => score % 1000; // 0..999

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final boardSide = min(constraints.maxWidth - 24, constraints.maxHeight * 0.55);
          cellSize = boardSide / gridSize;
          final floatingPiece = _buildFloatingPiece();
          return Transform.translate(
            offset: _shakeOffset,
            child: Stack(key: _stackKey, children: [
              // Ekran flaşı
              if (_screenFlashOpacity > 0)
                Positioned.fill(child: IgnorePointer(child: AnimatedOpacity(
                  opacity: _screenFlashOpacity, duration: const Duration(milliseconds: 180),
                  child: Container(color: _accentColor.withOpacity(0.5)),
                ))),
              Column(children: [
                const SizedBox(height: 8),
                _buildHeader(),
                const SizedBox(height: 6),
                _buildTierBar(),
                const SizedBox(height: 8),
                _buildGrid(boardSide),
                const Spacer(),
                _buildTray(),
                const SizedBox(height: 16),
              ]),
              if (_particles.isNotEmpty)
                Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ExplosionPainter(_particles)))),
              if (floatingPiece != null) floatingPiece,
              if (_showCombo) _buildComboWidget(),
              if (_showTierUp) _buildTierUpWidget(),
              if (_showNewHighScore) _buildNewHighScoreBanner(),
              if (gameOver) _buildGameOverOverlay(),
            ]),
          );
        }),
      ),
    );
  }

  // Tier ilerleme çubuğu
  Widget _buildTierBar() {
    final progress = _tierProgress / 1000.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('SEVİYE ${_currentTier + 1}',
              style: TextStyle(fontSize: 10, color: _accentColor, fontWeight: FontWeight.bold, letterSpacing: 1)),
          Text('${_tierProgress}/1000',
              style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
          ),
        ),
      ]),
    );
  }

  Widget? _buildFloatingPiece() {
    final shape = _draggingShape; final pos = _fingerPos;
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
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop()),
        Row(children: [
          _scoreCard('SKOR', score, _accentColor),
          const SizedBox(width: 12),
          _scoreCard('REKOR', highScore, const Color(0xFFFFD93D)),
        ]),
        Row(children: [
          IconButton(
            icon: Icon(musicOn ? Icons.volume_up : Icons.volume_off, color: Colors.white70),
            onPressed: () async { final v = !musicOn; setState(() => musicOn = v); await MusicController.setMusicOn(v); },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              setState(() { musicOn = SettingsService.musicOn; vibrationOn = SettingsService.vibrationOn; });
            },
          ),
        ]),
      ]),
    );
  }

  Widget _scoreCard(String label, int value, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 11, color: color)),
        Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ]),
    );
  }

  Widget _buildGrid(double boardSide) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      key: _gridKey,
      width: boardSide, height: boardSide,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: _accentColor.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: List.generate(gridSize, (r) => Expanded(
        child: Row(children: List.generate(gridSize, (c) => Expanded(child: _buildCell(r, c)))),
      ))),
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
    else if (isPreview) displayColor = previewValid ? Colors.greenAccent.withOpacity(0.55) : Colors.redAccent.withOpacity(0.55);

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
                ? Border.all(color: Colors.white.withOpacity(0.04)) : null,
            boxShadow: (baseColor != null && !isShrink)
                ? [BoxShadow(
                    color: isFlash ? Colors.white.withOpacity(0.9) : baseColor.withOpacity(0.5),
                    blurRadius: isFlash ? 14 : 4, offset: const Offset(0, 2))]
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
          final isDragging = _draggingIndex == i;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) {
              setState(() { _draggingShape = shape; _draggingIndex = i; _fingerPos = d.globalPosition; });
              _updateDragPosition(d.globalPosition);
            },
            onPanUpdate: (d) => _updateDragPosition(d.globalPosition),
            onPanEnd: (_) => _onDragEnd(),
            onPanCancel: () => setState(() { _draggingShape = null; _draggingIndex = null; _fingerPos = null; _previewTopLeft = null; previewCells = {}; }),
            child: Opacity(opacity: isDragging ? 0.2 : 1.0, child: _shapeWidget(shape, cellSize * 0.78)),
          );
        }),
      ),
    );
  }

  Widget _shapeWidget(BlockShape shape, double cs, {double opacity = 1.0}) {
    return SizedBox(
      width: shape.width * cs, height: shape.height * cs,
      child: Stack(children: shape.cells.map((c) => Positioned(
        left: c.x * cs, top: c.y * cs, width: cs, height: cs,
        child: Padding(padding: const EdgeInsets.all(2), child: Opacity(opacity: opacity,
          child: Container(decoration: BoxDecoration(
            color: shape.color, borderRadius: BorderRadius.circular(5),
            boxShadow: [BoxShadow(color: shape.color.withOpacity(0.6), blurRadius: 4, offset: const Offset(0, 2))],
          )),
        )),
      )).toList()),
    );
  }

  // KOMBO Widget
  Widget _buildComboWidget() {
    return Positioned(
      top: 0, bottom: 0, left: 0, right: 0,
      child: IgnorePointer(child: Center(
        child: SlideTransition(
          position: _comboSlide,
          child: FadeTransition(
            opacity: _comboFade,
            child: ScaleTransition(
              scale: _comboScale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    _comboColor, _comboColor.withOpacity(0.7)
                  ]),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(color: _comboColor.withOpacity(0.8), blurRadius: 30, spreadRadius: 4),
                    BoxShadow(color: _comboColor.withOpacity(0.4), blurRadius: 60),
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_comboText,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                        color: Colors.white, letterSpacing: 2,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 8)])),
                  if (_lastCombo >= 3) ...[
                    const SizedBox(height: 4),
                    Row(mainAxisSize: MainAxisSize.min,
                      children: List.generate(_lastCombo, (_) =>
                        const Icon(Icons.star_rounded, color: Colors.white, size: 18))),
                  ],
                ]),
              ),
            ),
          ),
        ),
      )),
    );
  }

  // TİER UP Widget
  Widget _buildTierUpWidget() {
    final tierColor = _tierColor(score);
    return Positioned(
      top: 130, left: 0, right: 0,
      child: Center(child: FadeTransition(
        opacity: _tierUpFade,
        child: ScaleTransition(
          scale: _tierUpScale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [tierColor.withOpacity(0.9), tierColor]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: tierColor.withOpacity(0.7), blurRadius: 24)],
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text('YENİ SEVİYE! ${_currentTier + 1}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: Colors.white, letterSpacing: 1)),
              const SizedBox(width: 6),
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
            ]),
          ),
        ),
      )),
    );
  }

  Widget _buildNewHighScoreBanner() {
    return Positioned(top: 170, left: 0, right: 0, child: Center(
      child: FadeTransition(opacity: _newRecordFade, child: ScaleTransition(scale: _newRecordScale,
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
            Text('YENİ REKOR!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(width: 8),
            Icon(Icons.star_rounded, color: Colors.white, size: 22),
          ]),
        ),
      )),
    ));
  }

  Widget _buildGameOverOverlay() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: _gameOverAnim, curve: Curves.easeOut)),
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(child: Container(
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
            _infoRow('Skor', '$score', _accentColor),
            const SizedBox(height: 8),
            _infoRow('En Yüksek', '$highScore', const Color(0xFFFFD93D)),
            const SizedBox(height: 8),
            _infoRow('Ulaşılan Seviye', '${_currentTier + 1}', _accentColor),
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
                  Text('Yeni Rekor!', style: TextStyle(color: Color(0xFFFFD93D), fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.replay_rounded, color: Colors.white),
              label: const Text('Yeniden Oyna', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            )),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home_rounded, color: Colors.white70),
              label: const Text('Ana Menü', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            )),
          ]),
        )),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color color) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
      Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
    ],
  );
}
