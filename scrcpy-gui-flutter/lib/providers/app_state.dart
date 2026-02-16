import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/adb_service.dart';
import '../services/scrcpy_service.dart';
import '../theme/app_themes.dart';

class AppState extends ChangeNotifier {
  final AdbService adbService = AdbService();
  final ScrcpyService scrcpyService = ScrcpyService();

  // Theme
  AppTheme _theme = AppThemes.ultraviolet;
  String _themeKey = 'ultraviolet';
  AppTheme get theme => _theme;
  String get themeKey => _themeKey;

  // Devices
  List<String> _devices = [];
  String? _selectedDevice;
  Map<String, String> _nicknames = {};
  List<String> get devices => _devices;
  String? get selectedDevice => _selectedDevice;
  Map<String, String> get nicknames => _nicknames;

  // Binary status
  bool _scrcpyFound = false;
  String _binaryStatus = 'Checking...';
  bool get scrcpyFound => _scrcpyFound;
  String get binaryStatus => _binaryStatus;

  // Session
  String _sessionMode = 'mirror';
  String get sessionMode => _sessionMode;

  // Log
  final List<LogEntry> _logs = [LogEntry('SYSTEM READY', LogType.info)];
  List<LogEntry> get logs => _logs;

  // Session settings
  bool otgEnabled = false;
  bool otgPure = false;
  String resolution = '0';
  String fps = '60';
  String cameraFps = '30';
  int bitrate = 8;
  String rotation = '0';

  // Per-camera rotation
  String _cameraRotationBack = '90';
  String _cameraRotationFront = '90';
  String _cameraRotationExternal = '0';

  String get cameraRotation {
    if (cameraFacing == 'front') return _cameraRotationFront;
    if (cameraFacing == 'external') return _cameraRotationExternal;
    return _cameraRotationBack;
  }

  set cameraRotation(String value) {
    if (cameraFacing == 'front')
      _cameraRotationFront = value;
    else if (cameraFacing == 'external')
      _cameraRotationExternal = value;
    else
      _cameraRotationBack = value;
  }

  String cameraFacing = 'back';
  String cameraId = '';
  String codec = 'h264';
  String cameraAr = '0';
  bool cameraHighSpeed = false;
  int vdWidth = 1920;
  int vdHeight = 1080;
  int vdDpi = 420;
  bool stayAwake = true;
  bool turnOff = false;
  bool audioEnabled = true;
  bool alwaysOnTop = false;
  bool fullscreen = false;
  bool borderless = false;
  bool recordScreen = false;
  String? recordPath;
  bool autoConnect = false;
  String wirelessIp = '';

  // Camera capabilities
  CameraCapabilities? _cameraCapabilities;
  bool _queryingCapabilities = false;
  CameraCapabilities? get cameraCapabilities => _cameraCapabilities;
  bool get queryingCapabilities => _queryingCapabilities;

  CameraInfo? get activeCamera {
    if (_cameraCapabilities == null) return null;
    return _cameraCapabilities!.findCamera(id: cameraId, facing: cameraFacing);
  }

  bool get cameraHighSpeedAvailable =>
      activeCamera?.highSpeedSupported ?? false;

  // Wireless history
  List<String> _recentIps = [];
  List<String> get recentIps => _recentIps;

  // OBS Integration
  bool _obsInstalled = false;
  bool get obsInstalled => _obsInstalled;

  AppState() {
    scrcpyService.onLog = (msg) => addLog(msg);
    scrcpyService.onStatusChange = (deviceId, running) {
      notifyListeners();
    };
  }

  Future<void> init() async {
    await _loadSettings();
    await validateScrcpy();
    await _checkObs();
  }

  Future<void> _checkObs() async {
    if (!Platform.isMacOS) return;
    try {
      final res = await Process.run('ls', ['-d', '/Applications/OBS.app']);
      _obsInstalled = res.exitCode == 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> launchWebcamRelay() async {
    if (_selectedDevice == null) return;

    // 1. Launch Scrcpy with specific title
    await scrcpyService.runScrcpy({
      'device': _selectedDevice,
      'sessionMode': 'camera',
      'res': resolution == '0'
          ? '1920'
          : resolution, // default to 1080p for webcam
      'cameraFps': cameraFps,
      'cameraFacing': cameraFacing,
      'alwaysOnTop': true,
      'borderless': true,
      'audioEnabled': false, // Avoid feedback
      'bitrate': bitrate,
      'rotation': cameraRotation,
      'windowTitle': 'Android Webcam',
    });

    // 2. Launch OBS with virtual cam
    if (_obsInstalled) {
      await Process.run('open', ['-a', 'OBS', '--args', '--startvirtualcam']);
      addLog('Launched Scrcpy & OBS Virtual Camera', LogType.success);
    }
  }

  Future<void> launchNativeWebcam() async {
    if (_selectedDevice == null) return;

    addLog('Starting Native Virtual Camera Relay...', LogType.info);

    // Command flow: scrcpy (raw h264) -> ffmpeg (decode to bgra) -> TCP Extension
    // We use a shell script or multiple Process starts to handle the pipe

    final scrcpyPath = scrcpyService.customPath != null
        ? '${scrcpyService.customPath}${Platform.pathSeparator}scrcpy'
        : 'scrcpy';

    final scrcpyArgs = [
      '-s',
      _selectedDevice!,
      '--video-source=camera',
      '--no-window',
      '--no-audio',
      '--camera-facing=$cameraFacing',
      '--camera-size=${resolution == "0"
          ? "1920x1080"
          : resolution == "3840"
          ? "3840x2160"
          : resolution == "1920"
          ? "1920x1080"
          : "1280x720"}',
      '--camera-fps=$cameraFps',
      '--record=pipe:.h264',
    ];

    final ffmpegArgs = [
      '-i',
      'pipe:0',
      '-f',
      'rawvideo',
      '-pix_fmt',
      'bgra',
      'tcp://localhost:5001',
    ];

    try {
      // 0. Check if Extension is listening (i.e. if a camera app is open)
      try {
        final socket = await Socket.connect(
          'localhost',
          5001,
          timeout: const Duration(milliseconds: 500),
        );
        socket.destroy();
      } catch (e) {
        addLog(
          'Error: Camera Extension not active. Please open a camera app (Zoom, QuickTime) and select "Scrcpy Camera" first.',
          LogType.error,
        );
        return;
      }

      final scrcpyProcess = await Process.start(scrcpyPath, scrcpyArgs);
      final ffmpegProcess = await Process.start('ffmpeg', ffmpegArgs);

      // Pipe scrcpy stdout to ffmpeg stdin
      scrcpyProcess.stdout.pipe(ffmpegProcess.stdin);

      // Capture stderr
      scrcpyProcess.stderr
          .transform(utf8.decoder)
          .listen((data) => addLog('Scrcpy: $data', LogType.info));
      ffmpegProcess.stderr
          .transform(utf8.decoder)
          .listen((data) => addLog('FFmpeg: $data', LogType.info));

      addLog(
        'Native Relay Active. Feed is being sent to CoreMedia extension.',
        LogType.success,
      );

      scrcpyProcess.exitCode.then((code) {
        addLog('Scrcpy stream ended (Code $code)', LogType.info);
        ffmpegProcess.kill();
      });
    } catch (e) {
      addLog('Error starting Native Relay: $e', LogType.error);
    }
  }

  // Theme
  void setTheme(String key) {
    _themeKey = key;
    _theme = AppThemes.fromKey(key);
    _saveSettings();
    notifyListeners();
  }

  // Devices
  void setSelectedDevice(String? device) {
    _selectedDevice = device;
    notifyListeners();
    if (_sessionMode == 'camera' && device != null) {
      _refreshCameraCapabilities();
    }
  }

  Future<void> scanDevices({String? targetIp}) async {
    _devices = await adbService.getDevices();
    if (_devices.isNotEmpty) {
      final search = targetIp ?? _selectedDevice;
      if (search != null && search.isNotEmpty) {
        final found = _devices.firstWhere(
          (d) => d.contains(search),
          orElse: () => _devices.first,
        );
        _selectedDevice = found;
      } else {
        _selectedDevice = _devices.first;
      }
    } else {
      _selectedDevice = null;
    }
    notifyListeners();
  }

  void renameDevice(String deviceId, String nickname) {
    _nicknames[deviceId] = nickname;
    _saveSettings();
    notifyListeners();
  }

  String getDeviceDisplayName(String deviceId) {
    final nick = _nicknames[deviceId];
    return nick != null && nick.isNotEmpty ? '$nick ($deviceId)' : deviceId;
  }

  // Session mode
  void setSessionMode(String mode) {
    _sessionMode = mode;
    _saveSettings();
    notifyListeners();
    if (mode == 'camera' && _selectedDevice != null) {
      _refreshCameraCapabilities();
    } else {
      _cameraCapabilities = null;
    }
  }

  Future<void> _refreshCameraCapabilities() async {
    if (_selectedDevice == null || !_scrcpyFound) return;
    _queryingCapabilities = true;
    notifyListeners();
    _cameraCapabilities = await scrcpyService.queryCameraCapabilities(
      _selectedDevice!,
      cameraFacing,
    );
    _queryingCapabilities = false;
    // Disable high speed if not supported by selected camera
    if (!cameraHighSpeedAvailable && cameraHighSpeed) {
      cameraHighSpeed = false;
      _saveSettings();
    }
    notifyListeners();
  }

  void setCameraFacing(String facing) {
    cameraFacing = facing;
    cameraId = ''; // reset specific ID when changing facing
    _saveSettings();
    notifyListeners();
    if (_sessionMode == 'camera' && _selectedDevice != null) {
      _refreshCameraCapabilities();
    }
  }

  void setCameraId(String id) {
    cameraId = id;
    _saveSettings();
    notifyListeners();
    if (_sessionMode == 'camera' && _selectedDevice != null) {
      _refreshCameraCapabilities();
    }
  }

  // Binary
  Future<void> validateScrcpy() async {
    final result = await scrcpyService.checkScrcpy();
    _scrcpyFound = result['found'] as bool;
    _binaryStatus = result['message'] as String;
    notifyListeners();

    if (_scrcpyFound) {
      if (autoConnect && wirelessIp.isNotEmpty) {
        addLog('Auto-connecting to $wirelessIp...');
        final res = await adbService.connect(wirelessIp);
        if (res['success'] == true) {
          addLog(res['message'] ?? 'Connected', LogType.success);
          await Future.delayed(const Duration(seconds: 1));
          await scanDevices(targetIp: wirelessIp);
        } else {
          await scanDevices();
        }
      } else {
        await scanDevices();
      }
    }
  }

  void setCustomPath(String? path) {
    adbService.setCustomPath(path);
    scrcpyService.setCustomPath(path);
    _saveSettings();
    validateScrcpy();
  }

  // Scrcpy session
  bool isSessionActive(String deviceId) =>
      scrcpyService.activeSessions.contains(deviceId);

  Future<void> launchSession() async {
    if (_selectedDevice == null) {
      addLog('Select a device first!', LogType.error);
      return;
    }
    if (isSessionActive(_selectedDevice!)) {
      scrcpyService.stopScrcpy(_selectedDevice!);
      return;
    }
    await scrcpyService.runScrcpy({
      'device': _selectedDevice,
      'sessionMode': _sessionMode,
      'otgEnabled': otgEnabled,
      'otgPure': otgPure,
      'res': resolution,
      'bitrate': bitrate,
      'fps': fps,
      'cameraFps': cameraFps,
      'stayAwake': stayAwake,
      'turnOff': turnOff,
      'audioEnabled': audioEnabled,
      'alwaysOnTop': alwaysOnTop,
      'fullscreen': fullscreen,
      'borderless': borderless,
      'record': recordScreen,
      'cameraFacing': cameraFacing,
      'cameraId': cameraId,
      'codec': codec,
      'cameraAr': cameraAr,
      'cameraHighSpeed': cameraHighSpeed,
      'vdWidth': vdWidth,
      'vdHeight': vdHeight,
      'vdDpi': vdDpi,
      'recordPath': recordPath,
      'rotation': _sessionMode == 'camera' ? cameraRotation : rotation,
    });
  }

  // Wireless
  Future<void> connectWireless() async {
    if (wirelessIp.isEmpty) return;
    addLog('Connecting to $wirelessIp...');
    final res = await adbService.connect(wirelessIp);
    if (res['success'] == true) {
      addLog(res['message'] ?? 'Connected', LogType.success);
      _addToHistory(wirelessIp);
      _saveSettings();
      await Future.delayed(const Duration(seconds: 1));
      await scanDevices(targetIp: wirelessIp);
    } else {
      addLog(res['message'] ?? 'Connection failed', LogType.error);
    }
  }

  Future<void> pairDevice(String ip, String code) async {
    if (ip.isEmpty || code.isEmpty) {
      addLog('IP and Code required', LogType.error);
      return;
    }
    final res = await adbService.pair(ip, code);
    if (res['success'] == true) {
      addLog('Pairing Successful! Connecting...', LogType.success);
      final cleanIp = '${ip.split(':')[0]}:5555';
      wirelessIp = cleanIp;
      _saveSettings();
      await connectWireless();
    } else {
      addLog('Pairing Failed: ${res['message']}', LogType.error);
    }
  }

  Future<void> killAdb() async {
    scrcpyService.stopAll();
    await adbService.killAdb();
    addLog('ADB Cleared', LogType.error);
    await scanDevices();
  }

  // File operations
  Future<Map<String, dynamic>> handleFile(String filePath) async {
    if (_selectedDevice == null) {
      addLog('Select a device first!', LogType.error);
      return {'success': false, 'message': 'Select a device first!'};
    }
    final fileName = filePath.split(Platform.pathSeparator).last;
    if (fileName.toLowerCase().endsWith('.apk')) {
      addLog('Installing $fileName...');
      final res = await adbService.installApk(_selectedDevice!, filePath);
      addLog(
        res['message'] ?? '',
        res['success'] == true ? LogType.success : LogType.error,
      );
      return res;
    } else {
      addLog('Pushing $fileName to Download folder...');
      final res = await adbService.pushFile(_selectedDevice!, filePath);
      addLog(
        res['message'] ?? '',
        res['success'] == true ? LogType.success : LogType.error,
      );
      return res;
    }
  }

  // Log
  void addLog(String message, [LogType type = LogType.info]) {
    _logs.add(LogEntry(message, type));
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    addLog('LOGS CLEARED', LogType.info);
    notifyListeners();
  }

  // History
  void _addToHistory(String ip) {
    _recentIps.remove(ip);
    _recentIps.insert(0, ip);
    if (_recentIps.length > 5) _recentIps = _recentIps.sublist(0, 5);
  }

  // Settings persistence
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _themeKey = prefs.getString('theme') ?? 'ultraviolet';
    _theme = AppThemes.fromKey(_themeKey);

    final path = prefs.getString('scrcpyPath');
    if (path != null) {
      adbService.setCustomPath(path);
      scrcpyService.setCustomPath(path);
    }

    _sessionMode = prefs.getString('sessionMode') ?? 'mirror';
    otgEnabled = prefs.getBool('otgEnabled') ?? false;
    otgPure = prefs.getBool('otgPure') ?? false;
    resolution = prefs.getString('resolution') ?? '0';
    fps = prefs.getString('fps') ?? '60';
    cameraFps = prefs.getString('cameraFps') ?? '30';
    bitrate = prefs.getInt('bitrate') ?? 8;
    rotation = prefs.getString('rotation') ?? '0';
    if (!['0', '90', '180', '270'].contains(rotation)) rotation = '0';

    // Migration for legacy single rotation key
    final oldRot = prefs.getString('cameraRotation') ?? '90';
    _cameraRotationBack = prefs.getString('cameraRotationBack') ?? oldRot;
    _cameraRotationFront = prefs.getString('cameraRotationFront') ?? oldRot;
    _cameraRotationExternal = prefs.getString('cameraRotationExternal') ?? '0';

    // Validate back
    if (_cameraRotationBack == '-90') _cameraRotationBack = '90';
    if (!['0', '90', '180', '270'].contains(_cameraRotationBack))
      _cameraRotationBack = '90';

    // Validate front
    if (_cameraRotationFront == '-90') _cameraRotationFront = '90';
    if (!['0', '90', '180', '270'].contains(_cameraRotationFront))
      _cameraRotationFront = '90';

    cameraFacing = prefs.getString('cameraFacing') ?? 'back';
    cameraId = prefs.getString('cameraId') ?? '';
    codec = prefs.getString('codec') ?? 'h264';
    cameraAr = prefs.getString('cameraAr') ?? '0';
    cameraHighSpeed = prefs.getBool('cameraHighSpeed') ?? false;
    vdWidth = prefs.getInt('vdWidth') ?? 1920;
    vdHeight = prefs.getInt('vdHeight') ?? 1080;
    vdDpi = prefs.getInt('vdDpi') ?? 420;
    stayAwake = prefs.getBool('stayAwake') ?? true;
    turnOff = prefs.getBool('turnOff') ?? false;
    audioEnabled = prefs.getBool('audioEnabled') ?? true;
    alwaysOnTop = prefs.getBool('alwaysOnTop') ?? false;
    fullscreen = prefs.getBool('fullscreen') ?? false;
    borderless = prefs.getBool('borderless') ?? false;
    recordScreen = prefs.getBool('recordScreen') ?? false;
    recordPath = prefs.getString('recordPath');
    autoConnect = prefs.getBool('autoConnect') ?? false;
    wirelessIp = prefs.getString('wirelessIp') ?? '';

    final nicks = prefs.getString('nicknames');
    if (nicks != null) {
      _nicknames = Map<String, String>.from(
        (nicks.split('|').where((e) => e.contains('=')).map((e) {
          final parts = e.split('=');
          return MapEntry(parts[0], parts[1]);
        })).fold<Map<String, String>>({}, (map, e) => map..[e.key] = e.value),
      );
    }

    final ips = prefs.getString('recentIps');
    if (ips != null)
      _recentIps = ips.split('|').where((e) => e.isNotEmpty).toList();

    if (recordPath == null || recordPath!.isEmpty) {
      recordPath = Platform.isMacOS
          ? '${Platform.environment['HOME']}/Movies'
          : '${Platform.environment['USERPROFILE']}\\Videos';
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', _themeKey);
    if (scrcpyService.customPath != null) {
      await prefs.setString('scrcpyPath', scrcpyService.customPath!);
    } else {
      await prefs.remove('scrcpyPath');
    }
    await prefs.setString('sessionMode', _sessionMode);
    await prefs.setBool('otgEnabled', otgEnabled);
    await prefs.setBool('otgPure', otgPure);
    await prefs.setString('resolution', resolution);
    await prefs.setString('fps', fps);
    await prefs.setString('cameraFps', cameraFps);
    await prefs.setInt('bitrate', bitrate);
    await prefs.setString('rotation', rotation);
    await prefs.setString('rotation', rotation);
    await prefs.setString('cameraRotationBack', _cameraRotationBack);
    await prefs.setString('cameraRotationFront', _cameraRotationFront);
    await prefs.setString('cameraRotationExternal', _cameraRotationExternal);
    // Legacy key removal optional or kept for fallback? Let's just overwrite per-camera.
    await prefs.setString('cameraFacing', cameraFacing);
    await prefs.setString('cameraId', cameraId);
    await prefs.setString('codec', codec);
    await prefs.setString('cameraAr', cameraAr);
    await prefs.setBool('cameraHighSpeed', cameraHighSpeed);
    await prefs.setInt('vdWidth', vdWidth);
    await prefs.setInt('vdHeight', vdHeight);
    await prefs.setInt('vdDpi', vdDpi);
    await prefs.setBool('stayAwake', stayAwake);
    await prefs.setBool('turnOff', turnOff);
    await prefs.setBool('audioEnabled', audioEnabled);
    await prefs.setBool('alwaysOnTop', alwaysOnTop);
    await prefs.setBool('fullscreen', fullscreen);
    await prefs.setBool('borderless', borderless);
    await prefs.setBool('recordScreen', recordScreen);
    if (recordPath != null) await prefs.setString('recordPath', recordPath!);
    await prefs.setBool('autoConnect', autoConnect);
    await prefs.setString('wirelessIp', wirelessIp);
    await prefs.setString(
      'nicknames',
      _nicknames.entries.map((e) => '${e.key}=${e.value}').join('|'),
    );
    await prefs.setString('recentIps', _recentIps.join('|'));
  }

  void saveSettings() {
    _saveSettings();
    notifyListeners();
  }
}

enum LogType { info, success, warning, error }

class LogEntry {
  final String message;
  final LogType type;
  final DateTime time;

  LogEntry(this.message, this.type) : time = DateTime.now();
}
