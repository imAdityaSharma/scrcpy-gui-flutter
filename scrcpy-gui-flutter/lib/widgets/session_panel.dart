import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import 'shared.dart';

class SessionPanel extends StatelessWidget {
  const SessionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.theme;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Session behavior
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SESSION BEHAVIOR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD4D4D8),
                  ),
                ),
                Divider(color: Color(0xFF27272A), height: 20),
                _BehaviorCheck(
                  label: 'Stay Awake',
                  value: appState.stayAwake,
                  onChanged: (v) {
                    appState.stayAwake = v;
                    appState.saveSettings();
                  },
                ),
                _BehaviorCheck(
                  label: 'Screen Off',
                  value: appState.turnOff,
                  onChanged: (v) {
                    appState.turnOff = v;
                    appState.saveSettings();
                  },
                ),
                _BehaviorCheck(
                  label: 'Enable Audio',
                  value: appState.audioEnabled,
                  onChanged: (v) {
                    appState.audioEnabled = v;
                    appState.saveSettings();
                  },
                ),
                _BehaviorCheck(
                  label: 'Always On Top',
                  value: appState.alwaysOnTop,
                  onChanged: (v) {
                    appState.alwaysOnTop = v;
                    appState.saveSettings();
                  },
                ),
                _BehaviorCheck(
                  label: 'Full Screen',
                  value: appState.fullscreen,
                  onChanged: (v) {
                    appState.fullscreen = v;
                    appState.saveSettings();
                  },
                ),
                _BehaviorCheck(
                  label: 'Borderless',
                  value: appState.borderless,
                  onChanged: (v) {
                    appState.borderless = v;
                    appState.saveSettings();
                  },
                ),
                _BehaviorCheck(
                  label: 'Record Feed',
                  value: appState.recordScreen,
                  onChanged: (v) {
                    appState.recordScreen = v;
                    appState.saveSettings();
                  },
                  isRed: true,
                ),
                const SizedBox(height: 12),
                Divider(color: Color(0xFF27272A)),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SAVE RECORDINGS TO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appState.recordPath ?? 'Videos Folder',
                      style: TextStyle(
                        fontSize: 9,
                        fontFamily: 'monospace',
                        color: theme.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final path = await FilePicker.platform
                              .getDirectoryPath();
                          if (path != null) {
                            appState.recordPath = path;
                            appState.saveSettings();
                            appState.addLog(
                              'Record Path updated',
                              LogType.success,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF27272A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text(
                          'CHANGE LOCATION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Shortcuts
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SHORTCUTS (ALT + KEY)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.accentPrimary,
                  ),
                ),
                Divider(color: Color(0xFF27272A), height: 16),
                _ShortcutsGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BehaviorCheck extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isRed;

  const _BehaviorCheck({
    required this.label,
    required this.value,
    required this.onChanged,
    this.isRed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            children: [
              SizedBox(
                height: 16,
                width: 16,
                child: Checkbox(
                  value: value,
                  onChanged: (v) => onChanged(v ?? false),
                  activeColor: isRed ? const Color(0xFFDC2626) : Colors.white,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isRed
                      ? const Color(0xFFF87171)
                      : const Color(0xFFD4D4D8),
                  fontWeight: isRed ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutsGrid extends StatelessWidget {
  static const _shortcuts = [
    ('Full', 'F'),
    ('Home', 'H'),
    ('Back', 'B'),
    ('Recents', 'S'),
    ('Power', 'P'),
    ('Rotate', 'R'),
    ('Paste', 'V'),
    ('Off', 'O'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _shortcuts
          .map(
            (s) => Container(
              width: 105,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Color(0xFF09090B).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Color(0xFF27272A)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.$1,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFD4D4D8),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Color(0xFF27272A)),
                    ),
                    child: Text(
                      s.$2,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Color(0xFFA1A1AA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SocialLink extends StatefulWidget {
  final IconData icon;
  final String label;
  final String url;

  const _SocialLink({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  State<_SocialLink> createState() => _SocialLinkState();
}

class _SocialLinkState extends State<_SocialLink> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(widget.url);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _hovering ? -2 : 0, 0),
          child: Column(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: _hovering ? theme.accentPrimary : theme.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _hovering ? theme.accentPrimary : theme.textMuted,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
