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
          // 1. SESSION BEHAVIOR
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('SESSION BEHAVIOR'),
                const Divider(color: Colors.white10, height: 16),

                // System
                _SubHeader(text: 'SYSTEM'),
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
                const SizedBox(height: 12),

                // Display
                _SubHeader(text: 'DISPLAY & AUDIO'),
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
                  label: 'Borderless Window',
                  value: appState.borderless,
                  onChanged: (v) {
                    appState.borderless = v;
                    appState.saveSettings();
                  },
                ),
                const SizedBox(height: 16),

                // Recording
                _SubHeader(text: 'RECORDING'),
                _BehaviorCheck(
                  label: 'Record Feed',
                  value: appState.recordScreen,
                  onChanged: (v) {
                    appState.recordScreen = v;
                    appState.saveSettings();
                  },
                  isRed: true,
                ),
                const SizedBox(height: 8),
                _RecordPathPanel(appState: appState, theme: theme),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. SHORTCUTS
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionLabel('KEYBOARD SHORTCUTS'),
                    Text(
                      '⌥ ALT + KEY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: theme.accentPrimary,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 16),
                _ShortcutsGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String text;
  const _SubHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white38,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _RecordPathPanel extends StatelessWidget {
  final AppState appState;
  final dynamic theme;

  const _RecordPathPanel({required this.appState, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.folder_open_rounded,
                size: 14,
                color: Colors.white38,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  appState.recordPath ?? 'Videos Folder',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Colors.white60,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _SmallActionBtn(
                icon: Icons.edit_rounded,
                onTap: () async {
                  final path = await FilePicker.platform.getDirectoryPath();
                  if (path != null) {
                    appState.recordPath = path;
                    appState.saveSettings();
                    appState.addLog('Record Path updated', LogType.success);
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

class _SmallActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            height: 18,
            width: 18,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: isRed
                  ? const Color(0xFFEF4444)
                  : theme.accentPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isRed ? const Color(0xFFF87171) : theme.textMain,
                  fontWeight: isRed ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutsGrid extends StatelessWidget {
  static const _shortcuts = [
    ('FULLSCREEN', 'F'),
    ('HOME', 'H'),
    ('BACK', 'B'),
    ('RECENTS', 'S'),
    ('POWER', 'P'),
    ('ROTATE', 'R'),
    ('PASTE', 'V'),
    ('SCREEN OFF', 'O'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _shortcuts
          .map((s) => _KeyCap(label: s.$1, shortcut: s.$2))
          .toList(),
    );
  }
}

class _KeyCap extends StatelessWidget {
  final String label;
  final String shortcut;

  const _KeyCap({required this.label, required this.shortcut});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 125,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF09090B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white38,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
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
