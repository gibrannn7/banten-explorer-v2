import 'dart:async';
import 'dart:math' as math;
import 'dart:ui'; // Ditambahkan untuk efek blur Aurora/Cloud
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:banten_explorer/presentation/providers/chat_provider.dart';

enum S2SMode { listening, processing, speaking, idle }

class SpeechToSpeechScreen extends StatefulWidget {
  const SpeechToSpeechScreen({Key? key}) : super(key: key);

  @override
  State<SpeechToSpeechScreen> createState() => _SpeechToSpeechScreenState();
}

class _SpeechToSpeechScreenState extends State<SpeechToSpeechScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Amplitude>? _ampSubscription;

  S2SMode _currentMode = S2SMode.idle;
  bool _isMuted = false;
  String? _currentAudioPath;
  bool _isInitializingMic = false;

  // Logic VAD & Noise Filter
  double _visualAmplitude = 0.0;
  bool _hasSpoken = false;
  int _silenceFrames = 0;

  static const double _noiseThreshold = -35.0;

  late Timer _animationTimer;
  Timer? _idleTimer; // Timer untuk mendeteksi idle 15 detik
  bool _isIdleState = false; // Flag untuk status teks Idle

  @override
  void initState() {
    super.initState();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (mounted) setState(() {});
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _startListening();
    });

    Provider.of<ChatProvider>(
      context,
      listen: false,
    ).addListener(_chatProviderListener);
  }

  void _chatProviderListener() {
    if (!mounted) return;
    final provider = Provider.of<ChatProvider>(context, listen: false);

    if (_currentMode == S2SMode.processing && !provider.isS2SProcessing) {
      if (provider.playingMessageId != null) {
        setState(() {
          _currentMode = S2SMode.speaking;
          _visualAmplitude = 0.0;
          _cancelIdleTimer(); // Matikan idle saat AI bicara
        });
      } else {
        _startListening();
      }
    }

    if (_currentMode == S2SMode.speaking && provider.playingMessageId == null) {
      _startListening();
    }
  }

  // LOGIC IDLE 15 DETIK
  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (mounted) setState(() => _isIdleState = false);
    
    _idleTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _currentMode == S2SMode.listening) {
        setState(() => _isIdleState = true);
      }
    });
  }

  void _cancelIdleTimer() {
    _idleTimer?.cancel();
    if (mounted) setState(() => _isIdleState = false);
  }

  Future<void> _startListening() async {
    if (_isMuted || !mounted || _isInitializingMic) return;
    _isInitializingMic = true;

    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }

      if (await _audioRecorder.hasPermission()) {
        setState(() {
          _currentMode = S2SMode.listening;
          _hasSpoken = false;
          _silenceFrames = 0;
          _visualAmplitude = 0.0;
        });

        _resetIdleTimer(); // Mulai hitung idle saat mic aktif

        final dir = await getApplicationDocumentsDirectory();
        _currentAudioPath =
            '${dir.path}/s2s_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
          path: _currentAudioPath!,
        );

        _ampSubscription?.cancel();
        _ampSubscription = _audioRecorder
            .onAmplitudeChanged(const Duration(milliseconds: 80))
            .listen((amp) {
              if (!mounted) return;

              setState(() {
                double rawAmplitude = (amp.current + 50) / 50;
                _visualAmplitude = math.max(0.0, rawAmplitude.clamp(0.0, 1.0));
              });

              if (amp.current > _noiseThreshold) {
                _hasSpoken = true;
                _silenceFrames = 0;
                _resetIdleTimer(); // Jika ada suara, reset idle timer
              } else if (_hasSpoken) {
                _silenceFrames++;
                if (_silenceFrames > 18) _stopAndProcess();
              }
            });
      }
    } finally {
      _isInitializingMic = false;
    }
  }

  Future<void> _stopAndProcess() async {
    _ampSubscription?.cancel();
    _cancelIdleTimer(); // Matikan idle saat proses API
    if (await _audioRecorder.isRecording()) await _audioRecorder.stop();
    if (!mounted) return;

    setState(() {
      _currentMode = S2SMode.processing;
      _visualAmplitude = 0.0;
    });

    if (_currentAudioPath != null) {
      await Provider.of<ChatProvider>(
        context,
        listen: false,
      ).processS2SAudio(_currentAudioPath!);
    }
  }

  void _toggleMute() async {
    HapticFeedback.mediumImpact();
    setState(() => _isMuted = !_isMuted);

    if (_isMuted) {
      _ampSubscription?.cancel();
      _cancelIdleTimer();
      if (await _audioRecorder.isRecording()) await _audioRecorder.stop();
      setState(() {
        _currentMode = S2SMode.idle;
        _visualAmplitude = 0.0;
      });
    } else {
      _startListening();
    }
  }

  void _endSession() async {
    HapticFeedback.lightImpact();
    _ampSubscription?.cancel();
    _cancelIdleTimer();
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
    }

    try {
      Provider.of<ChatProvider>(context, listen: false).stopAudio();
    } catch (e) {
      // Fallback
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _animationTimer.cancel();
    _idleTimer?.cancel();
    _ampSubscription?.cancel();
    _audioRecorder.dispose();
    Provider.of<ChatProvider>(
      context,
      listen: false,
    ).removeListener(_chatProviderListener);
    super.dispose();
  }

  // FUNGSI UNTUK STATUS TEKS AI
  String _getStatusText() {
    if (_isMuted) return "Mic Dibisukan";
    
    switch (_currentMode) {
      case S2SMode.listening:
        return _isIdleState ? "Idle (Menunggu input suara...)" : "Mendengarkan...";
      case S2SMode.processing:
        return "Memproses informasi...";
      case S2SMode.speaking:
        return "AI Sedang Berbicara...";
      case S2SMode.idle:
        return "Menunggu...";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Waktu berjalan untuk animasi gelombang awan (berputar santai)
    double time = DateTime.now().millisecondsSinceEpoch / 2000;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: Stack(
        children: [
          // TASK 1: BACKGROUND AURORA / CLOUDY WAVE DINAMIS
          // Blob 1: Biru (Bergerak melingkar)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            left: (MediaQuery.of(context).size.width / 2) - 150 + (math.sin(time) * 50),
            top: (MediaQuery.of(context).size.height / 2) - 150 + (math.cos(time) * 50),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 300 + (_visualAmplitude * 150),
              height: 300 + (_visualAmplitude * 150),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isMuted ? Colors.transparent : Colors.blue.shade900.withOpacity(0.5 + (_visualAmplitude * 0.3)),
              ),
            ),
          ),
          
          // Blob 2: Ungu/Cyan (Bergerak berlawanan)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            right: (MediaQuery.of(context).size.width / 2) - 150 + (math.cos(time) * 40),
            bottom: 200 + (math.sin(time) * 40),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 250 + (_visualAmplitude * 100),
              height: 250 + (_visualAmplitude * 100),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isMuted ? Colors.transparent : Colors.purple.shade900.withOpacity(0.4 + (_visualAmplitude * 0.2)),
              ),
            ),
          ),

          // Efek Kaca / Blur Super Kuat untuk mencampur blob menjadi seperti "Awan/Aurora"
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // KONTEN UI UTAMA
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // LOGO DINPAR
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                      image: const DecorationImage(
                        image: AssetImage('assets/logodinpar.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // TASK 2: KETERANGAN STATUS AI
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _getStatusText(),
                    key: ValueKey<String>(_getStatusText()),
                    style: TextStyle(
                      color: _isIdleState ? Colors.white54 : Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      fontStyle: _isIdleState ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),

                const Spacer(),

                // 7 DYNAMIC BARS (LOGIC ORIGINAL UTUH)
                SizedBox(
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(7, (index) {
                      double multiplier = [
                        0.3,
                        0.6,
                        0.9,
                        1.2,
                        0.9,
                        0.6,
                        0.3,
                      ][index];
                      double barHeight = 8.0;

                      if (_currentMode == S2SMode.listening && !_isMuted) {
                        barHeight = 8.0 + (_visualAmplitude * 80 * multiplier);
                      } else if (_currentMode == S2SMode.speaking) {
                        barHeight =
                            15.0 + (math.Random().nextDouble() * 50 * multiplier);
                      } else if (_currentMode == S2SMode.processing) {
                        barHeight =
                            20.0 +
                            math.sin(
                                  DateTime.now().millisecondsSinceEpoch * 0.01 +
                                      index,
                                ) *
                                10;
                      }

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 80),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: _isMuted
                              ? Colors.white24
                              : Colors.blueAccent.shade200,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            if (!_isMuted && _visualAmplitude > 0.1)
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.3),
                                blurRadius: 10,
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),

                const Spacer(flex: 2),

                // CONTROLS (Tengah Bawah)
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Button End Session (Flat Design)
                      _buildFlatButton(
                        icon: Icons.close_rounded,
                        color: const Color(0xFF1E1E1E),
                        iconColor: Colors.white,
                        onTap: _endSession,
                      ),

                      const SizedBox(width: 40),

                      // Button Mute/Unmute (Flat Design)
                      _buildFlatButton(
                        icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        color: _isMuted
                            ? const Color(0xFF3A1A1A)
                            : const Color(0xFF1E1E1E),
                        iconColor: _isMuted
                            ? Colors.redAccent.shade200
                            : Colors.blueAccent.shade200,
                        onTap: _toggleMute,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi Builder Button Flat 
  Widget _buildFlatButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: Icon(icon, color: iconColor, size: 30),
      ),
    );
  }
}