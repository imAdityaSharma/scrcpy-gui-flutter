import 'dart:io';
import 'package:multicast_dns/multicast_dns.dart';

class AdbService {
  String? _customPath;

  void setCustomPath(String? path) => _customPath = path;
  String? get customPath => _customPath;

  String _getAdbPath() {
    if (_customPath != null && _customPath!.isNotEmpty) {
      final ext = Platform.isWindows ? '.exe' : '';
      final fullPath = '$_customPath${Platform.pathSeparator}adb$ext';
      if (File(fullPath).existsSync()) return fullPath;
    }
    return 'adb';
  }

  Future<List<String>> getDevices() async {
    try {
      final result = await Process.run(_getAdbPath(), ['devices']);
      if (result.exitCode != 0) return [];

      final lines = (result.stdout as String).split(RegExp(r'[\r\n]+'));
      return lines
          .skip(1)
          .where((l) => l.contains('\tdevice'))
          .map((l) => l.split('\t')[0].trim())
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> connect(String ip) async {
    try {
      final result = await Process.run(_getAdbPath(), ['connect', ip]);
      final output = '${result.stdout}${result.stderr}'.trim();

      if (result.exitCode != 0 || output.contains('cannot connect')) {
        return {'success': false, 'message': output};
      }
      return {'success': true, 'message': output};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> pair(String ip, String code) async {
    try {
      final result = await Process.run(_getAdbPath(), ['pair', ip, code]);
      return {'success': true, 'message': (result.stdout as String).trim()};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> shell(String deviceId, String command) async {
    try {
      final args = ['-s', deviceId, 'shell', ...command.split(' ')];
      final result = await Process.run(_getAdbPath(), args);
      return {'success': result.exitCode == 0, 'output': result.stdout};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> installApk(
    String deviceId,
    String filePath,
  ) async {
    try {
      final result = await Process.run(_getAdbPath(), [
        '-s',
        deviceId,
        'install',
        filePath,
      ]);
      if (result.exitCode != 0) {
        return {'success': false, 'message': (result.stderr as String).trim()};
      }
      return {'success': true, 'message': (result.stdout as String).trim()};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> pushFile(
    String deviceId,
    String filePath, {
    String destinationPath = '/sdcard/Download/',
  }) async {
    try {
      final result = await Process.run(_getAdbPath(), [
        '-s',
        deviceId,
        'push',
        filePath,
        destinationPath,
      ]);
      return {
        'success': result.exitCode == 0,
        'message': result.exitCode == 0
            ? 'Pushed to $destinationPath'
            : 'Transfer failed',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> takeScreenshot(String deviceId) async {
    try {
      final timestamp = DateTime.now().toString().replaceAll(
        RegExp(r'[:\s.]'),
        '_',
      );
      final picturesDir = Platform.isMacOS
          ? '${Platform.environment['HOME']}/Pictures'
          : '${Platform.environment['USERPROFILE']}\\Pictures';
      final pcPath =
          '$picturesDir${Platform.pathSeparator}scrcpy_shot_$timestamp.png';

      await Process.run(_getAdbPath(), [
        '-s',
        deviceId,
        'shell',
        'screencap',
        '-p',
        '/sdcard/screen.png',
      ]);
      await Process.run(_getAdbPath(), [
        '-s',
        deviceId,
        'pull',
        '/sdcard/screen.png',
        pcPath,
      ]);
      return {'success': true, 'path': pcPath};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> killAdb() async {
    try {
      await Process.run(_getAdbPath(), ['kill-server']);
      if (Platform.isMacOS || Platform.isLinux) {
        await Process.run('killall', ['adb']);
      } else if (Platform.isWindows) {
        await Process.run('taskkill', ['/F', '/IM', 'adb.exe', '/T']);
      }
    } catch (_) {}
  }

  Future<void> openShell(String deviceId) async {
    final adbPath = _getAdbPath();
    try {
      if (Platform.isMacOS) {
        // Use AppleScript to open Terminal and run adb shell
        // Logic to prevent multiple windows: check if window 1 is idle and reuse it if so
        final script =
            '''
tell application "Terminal"
    if not (exists window 1) then
        do script "$adbPath -s $deviceId shell"
        activate
    else
        if (count windows) = 1 and not (busy of window 1) then
             do script "$adbPath -s $deviceId shell" in window 1
             activate
        else
             do script "$adbPath -s $deviceId shell"
             activate
        end if
    end if
end tell
''';
        await Process.run('osascript', ['-e', script]);
      } else if (Platform.isWindows) {
        // Open cmd and run adb shell
        await Process.run('start', [
          'cmd',
          '/k',
          '$adbPath -s $deviceId shell',
        ], runInShell: true);
      } else if (Platform.isLinux) {
        // Try common terminal emulators
        final terminals = [
          'gnome-terminal',
          'xterm',
          'konsole',
          'x-terminal-emulator',
        ];
        for (final term in terminals) {
          try {
            if (term == 'gnome-terminal') {
              await Process.run(term, ['--', adbPath, '-s', deviceId, 'shell']);
            } else {
              await Process.run(term, ['-e', '$adbPath -s $deviceId shell']);
            }
            break;
          } catch (_) {
            continue;
          }
        }
      }
    } catch (e) {
      print('Failed to open shell: $e');
    }
  }

  Stream<Map<String, dynamic>> scanForDevices() async* {
    final MDnsClient client = MDnsClient();
    final serviceTypes = {
      '_adb-tls-connect._tcp.local': 'connect',
      '_adb-tls-pairing._tcp.local': 'pairing',
    };

    try {
      await client.start();

      for (final bgEntry in serviceTypes.entries) {
        final serviceType = bgEntry.key;
        final typeLabel = bgEntry.value;

        await for (final PtrResourceRecord ptr
            in client.lookup<PtrResourceRecord>(
              ResourceRecordQuery.serverPointer(serviceType),
            )) {
          await for (final SrvResourceRecord srv
              in client.lookup<SrvResourceRecord>(
                ResourceRecordQuery.service(ptr.domainName),
              )) {
            final String name = ptr.domainName.split('.').first;

            // Default yield with target (hostname/ip)
            yield {
              'name': name,
              'ip': srv.target,
              'port': srv.port,
              'type': typeLabel,
            };

            // Attempt to resolve IP if target is hostname
            await for (final IPAddressResourceRecord ip
                in client.lookup<IPAddressResourceRecord>(
                  ResourceRecordQuery.addressIPv4(srv.target),
                )) {
              yield {
                'name': name,
                'ip': ip.address.address,
                'port': srv.port,
                'type': typeLabel,
              };
            }
          }
        }
      }
    } finally {
      client.stop();
    }
  }

  Future<Map<String, String>> getDeviceDetails(String deviceId) async {
    try {
      final model = await _runAdbCommand(
        deviceId,
        'shell getprop ro.product.model',
      );
      final manufacturer = await _runAdbCommand(
        deviceId,
        'shell getprop ro.product.manufacturer',
      );
      final androidVer = await _runAdbCommand(
        deviceId,
        'shell getprop ro.build.version.release',
      );
      final sdkVer = await _runAdbCommand(
        deviceId,
        'shell getprop ro.build.version.sdk',
      );
      final kernel = await _runAdbCommand(deviceId, 'shell uname -r');

      final wmSize = await _runAdbCommand(deviceId, 'shell wm size');
      final batteryDump = await _runAdbCommand(
        deviceId,
        'shell dumpsys battery',
      );

      // RAM
      final memInfo = await _runAdbCommand(
        deviceId,
        'shell cat /proc/meminfo | grep MemTotal',
      );
      String ram = '-';
      if (memInfo.isNotEmpty) {
        final kbStr = RegExp(r'\d+').firstMatch(memInfo)?.group(0);
        if (kbStr != null) {
          final gb = (int.parse(kbStr) / 1024 / 1024).ceil();
          ram = '$gb GB';
        }
      }

      // ROM (Storage) - /data partition
      final dfData = await _runAdbCommand(deviceId, 'shell df -h /data');
      String rom = '-';
      if (dfData.isNotEmpty) {
        final lines = dfData.trim().split('\n');
        if (lines.length > 1) {
          // Filesystem Size Used Avail Use% Mounted on
          // split by whitespace
          final parts = lines[1].trim().split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            rom = parts[1]; // Size
          }
        }
      }

      // Packages
      final userApps = await _runAdbCommand(
        deviceId,
        'shell pm list packages -3 | wc -l',
      );
      final sysApps = await _runAdbCommand(
        deviceId,
        'shell pm list packages -s | wc -l',
      );

      String resolution = wmSize.replaceAll('Physical size: ', '').trim();

      String batLvl = '-';
      String batStatus = '';
      if (batteryDump.isNotEmpty) {
        final levelMatch = RegExp(r'level:\s*(\d+)').firstMatch(batteryDump);
        if (levelMatch != null) {
          batLvl = levelMatch.group(1)!;
        }

        final statusMatch = RegExp(r'status:\s*(\d+)').firstMatch(batteryDump);
        if (statusMatch != null) {
          final s = statusMatch.group(1);
          if (s == '2')
            batStatus = ' (Charging)';
          else if (s == '5')
            batStatus = ' (Full)';
        }
      }

      // Refresh Rate
      final displayDump = await _runAdbCommand(
        deviceId,
        'shell dumpsys display',
      );
      String refreshRate = '-';
      if (displayDump.isNotEmpty) {
        // Try to find active mode first
        // activeModeId=1
        final activeModeMatch = RegExp(
          r'activeModeId=(\d+)',
        ).firstMatch(displayDump);
        final activeModeId = activeModeMatch?.group(1);

        if (activeModeId != null) {
          // DisplayModeRecord{id=1, resolution=... fps=60.0 ...}
          // We look for the record with that ID using a simplified regex
          // matching "id=1," and capturing "fps=60.0" later in the same line or block
          // Since regex across lines is tricky in simple dart without multiline,
          // and dumpsys output varies, we can try to find the line with "id=$activeModeId" and "fps="

          // Simplified approach: find "DisplayModeRecord{id=$activeModeId" and extract fps from it
          final modeRegex = RegExp(
            r'DisplayModeRecord\{id=' +
                activeModeId +
                r',[^}]*fps=(\d+\.?\d*)[^}]*\}',
          );
          final modeMatch = modeRegex.firstMatch(displayDump);
          if (modeMatch != null) {
            final fps = double.tryParse(
              modeMatch.group(1) ?? '',
            )?.round().toString();
            if (fps != null) refreshRate = '${fps}Hz';
          }
        }
      }

      // DRM Info
      final features = await _runAdbCommand(deviceId, 'shell pm list features');
      List<String> drmList = [];
      if (features.contains('feature:android.hardware.strongbox_keystore'))
        drmList.add('StrongBox');
      if (features.contains('feature:android.hardware.keystore'))
        drmList.add('Keystore');
      if (features.contains('feature:android.software.ipsec'))
        drmList.add('IPSec');

      String drmInfo = drmList.isNotEmpty ? drmList.join(', ') : 'Standard';

      return {
        'model': model.trim(),
        'manufacturer': manufacturer.trim(),
        'androidVersion': androidVer.trim(),
        'sdkVersion': sdkVer.trim(),
        'kernel': kernel.trim(),
        'ram': ram,
        'rom': rom,
        'resolution': resolution,
        'battery': '$batLvl%$batStatus',
        'apps': '${userApps.trim()} User / ${sysApps.trim()} Sys',
        'refreshRate': refreshRate,
        'drm': drmInfo,
      };
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, String>>> getInstalledApps(String deviceId) async {
    try {
      final List<Map<String, String>> apps = [];

      // Fetch User Apps (3rd party)
      final userOutput = await _runAdbCommand(
        deviceId,
        'shell pm list packages -f -3',
      );
      apps.addAll(_parsePackageOutput(userOutput, 'user'));

      // Fetch System Apps
      final sysOutput = await _runAdbCommand(
        deviceId,
        'shell pm list packages -f -s',
      );
      apps.addAll(_parsePackageOutput(sysOutput, 'system'));

      // Sort alphabetically by package name
      apps.sort(
        (a, b) => (a['package'] ?? '').toLowerCase().compareTo(
          (b['package'] ?? '').toLowerCase(),
        ),
      );

      return apps;
    } catch (e) {
      return [];
    }
  }

  List<Map<String, String>> _parsePackageOutput(String output, String type) {
    // Output format: package:/data/app/~~.../base.apk=com.example.app
    final lines = output.split('\n');
    final List<Map<String, String>> result = [];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Extract package name after '='
      final parts = line.split('=');
      if (parts.length >= 2) {
        final packageName = parts.last;
        // Prettify name: com.google.android.youtube -> Youtube
        String name = packageName;
        if (name.contains('.')) {
          final segments = name.split('.');
          if (segments.isNotEmpty) {
            name = segments.last;
            // Capitalize first letter
            if (name.isNotEmpty) {
              name = name[0].toUpperCase() + name.substring(1);
            }
          }
        }

        result.add({'package': packageName, 'type': type, 'name': name});
      }
    }
    return result;
  }

  Future<bool> uninstallApp(String deviceId, String packageName) async {
    try {
      // Try standard uninstall first
      var result = await Process.run(_getAdbPath(), [
        '-s',
        deviceId,
        'uninstall',
        packageName,
      ]);

      if (result.exitCode == 0) return true;

      // If failed, try user 0 (sometimes needed for system apps updates)
      result = await Process.run(_getAdbPath(), [
        '-s',
        deviceId,
        'uninstall',
        '--user',
        '0',
        packageName,
      ]);

      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listFiles(
    String deviceId,
    String path,
  ) async {
    try {
      // Use -lA to get details and hidden files.
      final output = await _runAdbCommand(deviceId, 'shell ls -lA "$path"');
      final lines = output.split('\n');
      final List<Map<String, dynamic>> files = [];

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;
        if (line.startsWith('total')) continue;

        // [perms] [links] [user] [group] [size] [date] [time] [name]
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length < 7) continue;

        String permissions = parts[0];
        bool isDir = permissions.startsWith('d');

        // Simplified parsing
        String sizeStr = parts[4];
        String date = parts[5];
        String time = parts[6];
        String name = parts.sublist(7).join(' ');

        if (name == '.' || name == '..') continue;

        files.add({
          'name': name,
          'path': path.endsWith('/') ? '$path$name' : '$path/$name',
          'isDirectory': isDir,
          'size': int.tryParse(sizeStr) ?? 0,
          'date': '$date $time',
          'permissions': permissions,
        });
      }

      files.sort((a, b) {
        if (a['isDirectory'] != b['isDirectory']) {
          return a['isDirectory'] ? -1 : 1;
        }
        return (a['name'] as String).toLowerCase().compareTo(
          (b['name'] as String).toLowerCase(),
        );
      });

      return files;
    } catch (e) {
      return [];
    }
  }

  Future<bool> pullFile(
    String deviceId,
    String remotePath,
    String localPath,
  ) async {
    try {
      final result = await Process.run(_getAdbPath(), [
        '-s',
        deviceId,
        'pull',
        remotePath,
        localPath,
      ]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteFile(String deviceId, String path) async {
    try {
      final result = await Process.run(_getAdbPath(), [
        '-s',
        deviceId,
        'shell',
        'rm',
        '-rf',
        path,
      ]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<String> _runAdbCommand(String deviceId, String command) async {
    try {
      final args = ['-s', deviceId, ...command.split(' ')];
      final result = await Process.run(_getAdbPath(), args);
      return (result.stdout as String).trim();
    } catch (_) {
      return '';
    }
  }
}
