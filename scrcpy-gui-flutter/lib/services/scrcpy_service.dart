import 'dart:convert';
import 'dart:io';

class CameraInfo {
  final String id;
  final String facing; // 'back', 'front', 'external'
  final String nativeSize;
  final List<int> fpsList;
  final List<String> supportedSizes;
  final bool highSpeedSupported;
  final List<String> highSpeedSizes;

  CameraInfo({
    required this.id,
    required this.facing,
    required this.nativeSize,
    required this.fpsList,
    required this.supportedSizes,
    required this.highSpeedSupported,
    required this.highSpeedSizes,
  });
}

class CameraCapabilities {
  final List<CameraInfo> cameras;

  CameraCapabilities({required this.cameras});

  CameraInfo? findCamera({String? id, String? facing}) {
    if (id != null && id.isNotEmpty) {
      return cameras.where((c) => c.id == id).firstOrNull;
    }
    if (facing != null) {
      return cameras.where((c) => c.facing == facing).firstOrNull;
    }
    return cameras.isNotEmpty ? cameras.first : null;
  }

  bool get isEmpty => cameras.isEmpty;

  static CameraCapabilities parse(String output) {
    final cameras = <CameraInfo>[];
    final lines = output.split('\n');

    String? currentId;
    String? currentFacing;
    String currentNativeSize = '';
    List<int> currentFps = [];
    List<String> currentSizes = [];
    bool inHighSpeed = false;
    List<String> currentHighSpeedSizes = [];

    void flushCamera() {
      if (currentId != null) {
        cameras.add(
          CameraInfo(
            id: currentId,
            facing: currentFacing ?? 'back',
            nativeSize: currentNativeSize,
            fpsList: List.from(currentFps),
            supportedSizes: List.from(currentSizes),
            highSpeedSupported: currentHighSpeedSizes.isNotEmpty,
            highSpeedSizes: List.from(currentHighSpeedSizes),
          ),
        );
      }
    }

    for (final line in lines) {
      final trimmed = line.trim();

      // Parse camera header: --camera-id=0    (back, 4096x3072, fps=[10, 15, 24, 30, 60])
      final headerMatch = RegExp(
        r'--camera-id=(\d+)\s+\((\w+),\s*(\d+x\d+),\s*fps=\[([^\]]*)\]\)',
      ).firstMatch(trimmed);
      if (headerMatch != null) {
        flushCamera();
        currentId = headerMatch.group(1);
        currentFacing = headerMatch.group(2);
        currentNativeSize = headerMatch.group(3) ?? '';
        currentFps = (headerMatch.group(4) ?? '')
            .split(',')
            .map((s) => int.tryParse(s.trim()) ?? 0)
            .where((v) => v > 0)
            .toList();
        currentSizes = [];
        currentHighSpeedSizes = [];
        inHighSpeed = false;
        continue;
      }

      // Detect high speed section
      if (trimmed.startsWith('High speed capture')) {
        inHighSpeed = true;
        continue;
      }

      // Parse size line: - 1920x1080 or - 1280x720 (fps=[120, 240, 480])
      final sizeMatch = RegExp(r'^-\s+(\d+x\d+)').firstMatch(trimmed);
      if (sizeMatch != null && currentId != null) {
        final size = sizeMatch.group(1)!;
        if (inHighSpeed) {
          currentHighSpeedSizes.add(size);
        } else {
          currentSizes.add(size);
        }
      }
    }
    flushCamera();

    return CameraCapabilities(cameras: cameras);
  }
}

class ScrcpyService {
  String? _customPath;
  final Map<String, Process> _processes = {};

  void Function(String)? onLog;
  void Function(String deviceId, bool running)? onStatusChange;

  void setCustomPath(String? path) => _customPath = path;
  String? get customPath => _customPath;

  Set<String> get activeSessions => _processes.keys.toSet();

  String _getScrcpyPath() {
    if (_customPath != null && _customPath!.isNotEmpty) {
      final ext = Platform.isWindows ? '.exe' : '';
      final fullPath = '$_customPath${Platform.pathSeparator}scrcpy$ext';
      if (File(fullPath).existsSync()) return fullPath;
    }
    return 'scrcpy';
  }

  String _getAdbPath() {
    if (_customPath != null && _customPath!.isNotEmpty) {
      final ext = Platform.isWindows ? '.exe' : '';
      final fullPath = '$_customPath${Platform.pathSeparator}adb$ext';
      if (File(fullPath).existsSync()) return fullPath;
    }
    return 'adb';
  }

  Future<Map<String, dynamic>> checkScrcpy() async {
    try {
      final result = await Process.run(_getScrcpyPath(), ['--version']);
      if (result.exitCode == 0) {
        return {'found': true, 'message': 'Scrcpy Ready'};
      }
    } catch (_) {}
    return {'found': false, 'message': 'Scrcpy not found'};
  }

  Future<Map<String, dynamic>> getCameraInfo(String deviceId) async {
    try {
      final result = await Process.run(_getScrcpyPath(), [
        '-s',
        deviceId,
        '--list-cameras',
      ]);
      return {'success': true, 'output': '${result.stdout}${result.stderr}'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<CameraCapabilities?> queryCameraCapabilities(
    String deviceId,
    String facing,
  ) async {
    try {
      final result = await Process.run(_getScrcpyPath(), [
        '-s',
        deviceId,
        '--video-source=camera',
        '--camera-facing=$facing',
        '--list-camera-sizes',
      ]);
      final output = '${result.stdout}${result.stderr}';
      return CameraCapabilities.parse(output);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getCameraSizes(
    String deviceId,
    String facing,
  ) async {
    try {
      final result = await Process.run(_getScrcpyPath(), [
        '-s',
        deviceId,
        '--video-source=camera',
        '--camera-facing=$facing',
        '--list-camera-sizes',
      ]);
      return {'success': true, 'output': '${result.stdout}${result.stderr}'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> runScrcpy(Map<String, dynamic> config) async {
    final deviceId = config['device'] as String? ?? '';
    if (deviceId.isEmpty || _processes.containsKey(deviceId)) return;

    final args = <String>[];
    if (deviceId.isNotEmpty) {
      args.addAll(['-s', deviceId]);
    }

    final windowTitle = config['windowTitle'] as String?;
    if (windowTitle != null && windowTitle.isNotEmpty) {
      args.addAll(['--window-title', windowTitle]);
    }

    final sessionMode = config['sessionMode'] as String? ?? 'mirror';

    final otgEnabled = config['otgEnabled'] as bool? ?? false;
    final otgPure = config['otgPure'] as bool? ?? false;

    if (sessionMode == 'mirror' && otgEnabled && otgPure) {
      if (deviceId.contains('.') || deviceId.contains(':')) {
        args.addAll([
          '--no-video',
          '--no-audio',
          '--keyboard=uhid',
          '--mouse=uhid',
        ]);
      } else {
        args.add('--otg');
      }
    } else {
      final bitrate = config['bitrate']?.toString() ?? '8';
      args.addAll(['-b', '${bitrate}M']);

      if (config['audioEnabled'] == false) args.add('--no-audio');

      if (config['alwaysOnTop'] == true) args.add('--always-on-top');
      if (config['fullscreen'] == true) args.add('--fullscreen');
      if (config['borderless'] == true) args.add('--window-borderless');

      final rotation = config['rotation']?.toString() ?? '0';
      if (rotation != '0') args.addAll(['--orientation', rotation]);

      final canControl = sessionMode != 'camera';
      if (canControl && config['stayAwake'] == true) args.add('--stay-awake');
      if (canControl && config['turnOff'] == true) {
        args.addAll(['--turn-screen-off', '--no-power-on']);
      }

      if (sessionMode == 'camera') {
        args.add('--video-source=camera');

        final codec = config['codec'] as String? ?? 'h264';
        if (codec != 'h264') args.add('--video-codec=$codec');

        final camId = config['cameraId'] as String? ?? '';
        if (camId.isNotEmpty) {
          args.add('--camera-id=$camId');
        } else {
          final facing = config['cameraFacing'] as String? ?? 'back';
          args.add('--camera-facing=$facing');
        }

        final res = config['res']?.toString() ?? '0';
        final ar = config['cameraAr']?.toString() ?? '0';

        if (res != '0') {
          String camRes = res;
          if (res == '3840')
            camRes = '3840x2160';
          else if (res == '2560')
            camRes = '2560x1440';
          else if (res == '1920')
            camRes = '1920x1080';
          else if (res == '1280')
            camRes = '1280x720';
          args.add('--camera-size=$camRes');
        } else if (ar != '0') {
          args.add('--camera-ar=$ar');
        }

        if (config['cameraHighSpeed'] == true) args.add('--camera-high-speed');
        final fps = config['cameraFps']?.toString() ?? '30';
        if (fps != '0') args.add('--camera-fps=$fps');
      } else if (sessionMode == 'desktop') {
        final w = config['vdWidth']?.toString() ?? '1920';
        final h = config['vdHeight']?.toString() ?? '1080';
        final dpi = config['vdDpi']?.toString() ?? '420';
        args.add('--new-display=${w}x$h/$dpi');
        args.add('--video-buffer=100');
        final fps = config['fps']?.toString() ?? '60';
        args.addAll(['--max-fps', fps]);
      } else {
        if (otgEnabled) {
          args.addAll(['--keyboard=uhid', '--mouse=uhid']);
        }
        final res = config['res']?.toString() ?? '0';
        if (res != '0') args.addAll(['-m', res]);
        final fps = config['fps']?.toString() ?? '60';
        args.addAll(['--max-fps', fps]);
      }

      if (config['record'] == true) {
        final recPath = config['recordPath'] as String? ?? _defaultVideoPath();
        final safeDev = deviceId.replaceAll(':', '-');
        final ts = DateTime.now().toString().replaceAll(RegExp(r'[:\s.]'), '_');
        final filename = 'scrcpy_${safeDev}_$ts.mkv';
        args.add('--record=${recPath}${Platform.pathSeparator}$filename');
      }
    }

    try {
      final proc = await Process.start(_getScrcpyPath(), args);
      _processes[deviceId] = proc;
      onStatusChange?.call(deviceId, true);

      proc.stdout.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) onLog?.call(line.trim());
        }
      });
      proc.stderr.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) onLog?.call(line.trim());
        }
      });

      proc.exitCode.then((_) {
        _processes.remove(deviceId);
        onStatusChange?.call(deviceId, false);
      });
    } catch (e) {
      onLog?.call('Error starting scrcpy: $e');
    }
  }

  void stopScrcpy(String deviceId) {
    final proc = _processes[deviceId];
    if (proc != null) {
      proc.kill();
    }
  }

  void stopAll() {
    for (final proc in _processes.values) {
      try {
        proc.kill();
      } catch (_) {}
    }
    _processes.clear();
  }

  String _defaultVideoPath() {
    if (Platform.isMacOS) return '${Platform.environment['HOME']}/Movies';
    return '${Platform.environment['USERPROFILE']}\\Videos';
  }
}
