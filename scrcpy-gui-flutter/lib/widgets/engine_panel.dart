import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'shared.dart';

class EnginePanel extends StatelessWidget {
  const EnginePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.theme;
    final mode = appState.sessionMode;
    final isPureOtg =
        mode == 'mirror' && appState.otgEnabled && appState.otgPure;

    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. SOURCE SELECTION
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('SELECT MIRRORING SOURCE'),
                const SizedBox(height: 12),
                StyledDropdown(
                  value: mode,
                  large: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'mirror',
                      child: Text('Screen Mirroring'),
                    ),
                    DropdownMenuItem(
                      value: 'camera',
                      child: Text('Camera Mirroring'),
                    ),
                    DropdownMenuItem(
                      value: 'desktop',
                      child: Text('Desktop Mode (Android 16+)'),
                    ),
                  ],
                  onChanged: (v) => appState.setSessionMode(v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. VIDEO & ENGINE CONFIG
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionLabel('ENGINE CONFIGURATION'),
                    _StatusBadge(
                      active: !isPureOtg,
                      text: isPureOtg ? 'MIRRORING DISABLED' : 'ACTIVE',
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),

                // OTG toggle (mirror only)
                if (mode == 'mirror') ...[
                  _InputGroup(
                    child: Column(
                      children: [
                        _CheckRow(
                          label: 'Enable HID Input (OTG Style)',
                          value: appState.otgEnabled,
                          onChanged: (v) {
                            appState.otgEnabled = v;
                            appState.saveSettings();
                            appState.setSessionMode(mode);
                          },
                        ),
                        if (appState.otgEnabled) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.only(left: 24),
                            child: _CheckRow(
                              label: 'Pure OTG Mode (No Mirroring)',
                              value: appState.otgPure,
                              onChanged: (v) {
                                appState.otgPure = v;
                                appState.saveSettings();
                                appState.setSessionMode(mode);
                              },
                              accent: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Video settings
                AnimatedOpacity(
                  opacity: isPureOtg ? 0.4 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: isPureOtg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (mode == 'camera') ...[
                          _CameraSettings(),
                          const SizedBox(height: 16),
                        ],
                        if (mode == 'desktop') ...[
                          _DesktopSettings(),
                          const SizedBox(height: 16),
                        ],

                        // Main constraints
                        Row(
                          children: [
                            if (mode != 'desktop')
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SectionLabel(
                                      'RESOLUTION LIMIT',
                                      accent: true,
                                    ),
                                    const SizedBox(height: 8),
                                    StyledDropdown(
                                      value: appState.resolution,
                                      items: const [
                                        DropdownMenuItem(
                                          value: '0',
                                          child: Text('Original'),
                                        ),
                                        DropdownMenuItem(
                                          value: '3840',
                                          child: Text('4K'),
                                        ),
                                        DropdownMenuItem(
                                          value: '2560',
                                          child: Text('2K'),
                                        ),
                                        DropdownMenuItem(
                                          value: '1920',
                                          child: Text('1080p'),
                                        ),
                                        DropdownMenuItem(
                                          value: '1280',
                                          child: Text('720p'),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        appState.resolution = v!;
                                        appState.saveSettings();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            if (mode != 'desktop') const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SectionLabel('FPS LIMIT', accent: true),
                                  const SizedBox(height: 8),
                                  StyledDropdown(
                                    value: appState.fps,
                                    items: const [
                                      DropdownMenuItem(
                                        value: '30',
                                        child: Text('30'),
                                      ),
                                      DropdownMenuItem(
                                        value: '60',
                                        child: Text('60'),
                                      ),
                                      DropdownMenuItem(
                                        value: '90',
                                        child: Text('90'),
                                      ),
                                      DropdownMenuItem(
                                        value: '120',
                                        child: Text('120'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      appState.fps = v!;
                                      appState.saveSettings();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Bitrate
                        _BitrateSlider(appState: appState, theme: theme),
                        const SizedBox(height: 16),

                        // Orientation
                        const SectionLabel('ORIENTATION', accent: true),
                        const SizedBox(height: 8),
                        StyledDropdown(
                          value: mode == 'camera'
                              ? appState.cameraRotation
                              : appState.rotation,
                          items: const [
                            DropdownMenuItem(
                              value: '0',
                              child: Text('Default'),
                            ),
                            DropdownMenuItem(
                              value: '90',
                              child: Text('90° CCW'),
                            ),
                            DropdownMenuItem(value: '180', child: Text('180°')),
                            DropdownMenuItem(
                              value: '270',
                              child: Text('90° CW'),
                            ),
                          ],
                          onChanged: (v) {
                            if (mode == 'camera') {
                              appState.cameraRotation = v!;
                            } else {
                              appState.rotation = v!;
                            }
                            appState.saveSettings();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. LAUNCH ACTION
          AccentButton(
            label: _getLaunchLabel(appState),
            isStop:
                appState.selectedDevice != null &&
                appState.isSessionActive(appState.selectedDevice!),
            fullWidth: true,
            verticalPadding: 16,
            fontSize: 14,
            onPressed: () => appState.launchSession(),
          ),
          const SizedBox(height: 12),

          // 4. TERMINAL LOGS
          const _LogTerminal(),
        ],
      ),
    );
  }

  String _getLaunchLabel(AppState appState) {
    if (appState.selectedDevice != null &&
        appState.isSessionActive(appState.selectedDevice!)) {
      return 'STOP SESSION';
    }
    switch (appState.sessionMode) {
      case 'camera':
        return 'LAUNCH CAMERA';
      case 'desktop':
        return 'LAUNCH DESKTOP MODE';
      default:
        if (appState.otgEnabled && appState.otgPure) return 'LAUNCH OTG MODE';
        return 'LAUNCH MIRRORING';
    }
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? accent;

  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: accent ?? Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.theme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFF09090B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel('Camera Facing', accent: true),
                    const SizedBox(height: 4),
                    StyledDropdown(
                      value: appState.cameraFacing,
                      items: const [
                        DropdownMenuItem(
                          value: 'back',
                          child: Text('Back Camera'),
                        ),
                        DropdownMenuItem(
                          value: 'front',
                          child: Text('Front Camera'),
                        ),
                        DropdownMenuItem(
                          value: 'external',
                          child: Text('External (USB)'),
                        ),
                      ],
                      onChanged: (v) => appState.setCameraFacing(v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel('Specific Sensor ID', accent: true),
                    const SizedBox(height: 4),
                    Consumer<AppState>(
                      builder: (context, state, _) {
                        final caps = state.cameraCapabilities;
                        final cameras = caps?.cameras ?? [];

                        // Ensure current cameraId is valid or empty
                        String? selectedId = state.cameraId;
                        if (selectedId.isEmpty) selectedId = null;
                        if (selectedId != null &&
                            !cameras.any((c) => c.id == selectedId)) {
                          selectedId =
                              null; // Reset if not in list (though ideally we keep it if it was manually entered? No, we are listing available)
                          // Actually, let's keep it null if not found to fall back to 'None'
                        }

                        final items = [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('None (Use Facing)'),
                          ),
                          ...cameras.map(
                            (c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(
                                'ID ${c.id} (${c.facing}, ${c.nativeSize})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ];

                        return StyledDropdown(
                          value:
                              selectedId ??
                              'none', // StyledDropdown expects non-null usually, checking implementation
                          items: items.map((i) {
                            // StyledDropdown takes explicit value objects.
                            // If I pass null to value, I need an item with value null?
                            // StyledDropdown implementation check:
                            // It uses DropdownMenuItem.
                            // Let's check StyledDropdown signature.
                            return DropdownMenuItem(
                              value: i.value?.toString() ?? 'none',
                              child: i.child,
                            );
                          }).toList(),
                          onChanged: (v) {
                            state.setCameraId(v == 'none' ? '' : v!);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel('Video Codec', accent: true),
                    const SizedBox(height: 4),
                    StyledDropdown(
                      value: appState.codec,
                      items: const [
                        DropdownMenuItem(
                          value: 'h264',
                          child: Text('H.264 (Default)'),
                        ),
                        DropdownMenuItem(
                          value: 'h265',
                          child: Text('H.265 (HEVC)'),
                        ),
                        DropdownMenuItem(value: 'av1', child: Text('AV1')),
                      ],
                      onChanged: (v) {
                        appState.codec = v!;
                        appState.saveSettings();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel('Aspect Ratio', accent: true),
                    const SizedBox(height: 4),
                    StyledDropdown(
                      value: appState.cameraAr,
                      items: const [
                        DropdownMenuItem(value: '0', child: Text('Default')),
                        DropdownMenuItem(
                          value: '4:3',
                          child: Text('4:3 (Standard)'),
                        ),
                        DropdownMenuItem(
                          value: '16:9',
                          child: Text('16:9 (Widescreen)'),
                        ),
                      ],
                      onChanged: (v) {
                        appState.cameraAr = v!;
                        appState.saveSettings();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Querying capabilities indicator
          if (appState.queryingCapabilities)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Querying camera capabilities...',
                    style: TextStyle(fontSize: 10, color: theme.textMuted),
                  ),
                ],
              ),
            ),

          // Camera FPS and Audio row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel('Camera FPS', accent: true),
                    const SizedBox(height: 4),
                    StyledDropdown(
                      value: appState.cameraFps,
                      items: const [
                        DropdownMenuItem(value: '0', child: Text('Auto')),
                        DropdownMenuItem(value: '60', child: Text('60 FPS')),
                        DropdownMenuItem(value: '30', child: Text('30 FPS')),
                        DropdownMenuItem(value: '24', child: Text('24 FPS')),
                        DropdownMenuItem(value: '15', child: Text('15 FPS')),
                      ],
                      onChanged: (v) {
                        appState.cameraFps = v!;
                        appState.saveSettings();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _CheckRow(
                    label: 'Microphone Audio',
                    value: appState.audioEnabled,
                    onChanged: (v) {
                      appState.audioEnabled = v;
                      appState.saveSettings();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: AnimatedOpacity(
                  opacity: appState.cameraHighSpeedAvailable ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !appState.cameraHighSpeedAvailable,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CheckRow(
                          label: appState.cameraHighSpeedAvailable
                              ? 'High Speed Sensor'
                              : 'High Speed (Not Supported)',
                          value: appState.cameraHighSpeed,
                          onChanged: (v) {
                            appState.cameraHighSpeed = v;
                            if (v) {
                              appState.fps = '120';
                              if (appState.bitrate < 16) appState.bitrate = 20;
                            }
                            appState.saveSettings();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SmallBtn(
                label: 'Cameras',
                onTap: () async {
                  final dev = appState.selectedDevice;
                  if (dev == null)
                    return appState.addLog(
                      'Select a device first!',
                      LogType.error,
                    );
                  final res = await appState.scrcpyService.getCameraInfo(dev);
                  if (res['success'] == true) {
                    for (final l in (res['output'] as String).split('\n')) {
                      if (l.trim().isNotEmpty)
                        appState.addLog(l.trim(), LogType.success);
                    }
                  } else {
                    appState.addLog(res['message'] ?? 'Error', LogType.error);
                  }
                },
              ),
              const SizedBox(width: 4),
              _SmallBtn(
                label: 'Sizes',
                onTap: () async {
                  final dev = appState.selectedDevice;
                  if (dev == null)
                    return appState.addLog(
                      'Select a device first!',
                      LogType.error,
                    );
                  final res = await appState.scrcpyService.getCameraSizes(
                    dev,
                    appState.cameraFacing,
                  );
                  if (res['success'] == true) {
                    for (final l in (res['output'] as String).split('\n')) {
                      if (l.trim().isNotEmpty)
                        appState.addLog(l.trim(), LogType.success);
                    }
                  } else {
                    appState.addLog(res['message'] ?? 'Error', LogType.error);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesktopSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFF09090B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('Virtual Display Resolution', accent: true),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'W',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    StyledTextField(
                      value: appState.vdWidth.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        appState.vdWidth = int.tryParse(v) ?? 1920;
                        appState.saveSettings();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'H',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    StyledTextField(
                      value: appState.vdHeight.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        appState.vdHeight = int.tryParse(v) ?? 1080;
                        appState.saveSettings();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DPI',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    StyledTextField(
                      value: appState.vdDpi.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        appState.vdDpi = int.tryParse(v) ?? 420;
                        appState.saveSettings();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SmallBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Color(0xFF27272A),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Color(0xFF3F3F46)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: theme.accentPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;
  final String text;

  const _StatusBadge({required this.active, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (active ? const Color(0xFF10B981) : const Color(0xFFEF4444))
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (active ? const Color(0xFF10B981) : const Color(0xFFEF4444))
              .withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: active ? const Color(0xFF10B981) : const Color(0xFFF87171),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InputGroup extends StatelessWidget {
  final Widget child;

  const _InputGroup({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF09090B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: child,
    );
  }
}

class _BitrateSlider extends StatelessWidget {
  final AppState appState;
  final dynamic theme;

  const _BitrateSlider({required this.appState, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionLabel('BITRATE', accent: true),
            Text(
              '${appState.bitrate} Mbps',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.textMain,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: theme.accentPrimary,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 6,
              elevation: 4,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: appState.bitrate.toDouble(),
            min: 1,
            max: 64,
            divisions: 63,
            onChanged: (v) {
              appState.bitrate = v.round();
              appState.saveSettings();
            },
          ),
        ),
      ],
    );
  }
}

class _LogTerminal extends StatelessWidget {
  const _LogTerminal();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Terminal Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.terminal_rounded,
                  size: 14,
                  color: Colors.white38,
                ),
                const SizedBox(width: 8),
                Text(
                  'LOG OUTPUT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.4),
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                _TerminalAction(
                  icon: Icons.content_copy_rounded,
                  onTap: () {
                    final logs = appState.logs.map((l) => l.message).join('\n');
                    Clipboard.setData(ClipboardData(text: logs));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logs copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        width: 280,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _TerminalAction(
                  icon: Icons.delete_outline_rounded,
                  onTap: () => appState.clearLogs(),
                ),
              ],
            ),
          ),
          // Terminal Content
          Container(
            height: 160,
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: ListView.builder(
              reverse: true,
              itemCount: appState.logs.length,
              itemBuilder: (context, index) {
                final log = appState.logs.reversed.toList()[index];
                final timeStr =
                    '${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}:${log.time.second.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '[$timeStr] ',
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Expanded(
                        child: Text(
                          log.message,
                          style: TextStyle(
                            color: _getLogColor(log.type),
                            fontSize: 10,
                            fontFamily: 'monospace',
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(LogType type) {
    switch (type) {
      case LogType.error:
        return const Color(0xFFF87171);
      case LogType.success:
        return const Color(0xFF10B981);
      case LogType.warning:
        return const Color(0xFFFBBF24);
      default:
        return Colors.white70;
    }
  }
}

class _TerminalAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TerminalAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 14, color: Colors.white60),
        ),
      ),
    );
  }
}
