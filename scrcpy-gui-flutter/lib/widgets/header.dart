import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_state.dart';
import '../theme/app_themes.dart';
import 'shared.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.theme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('scrcpy ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: theme.textMain)),
                  Text('GUI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: theme.accentPrimary)),
                  const SizedBox(width: 4),
                  Text('by KB', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
              Text(
                'MIRROR & CONTROL ANDROID DEVICES EASILY',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: theme.textMuted, letterSpacing: 3),
              ),
            ],
          ),
        ),
        // Theme switcher
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('THEME', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: theme.textMuted, letterSpacing: -0.5)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: appState.themeKey,
                    items: AppThemes.keys.map((key) {
                      final t = AppThemes.fromKey(key);
                      return DropdownMenuItem(value: key, child: Text(t.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)));
                    }).toList(),
                    onChanged: (v) => appState.setTheme(v!),
                    dropdownColor: Color(0xFF18181B),
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    icon: const SizedBox.shrink(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Binary status
        Expanded(
          flex: 4,
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BINARY STATUS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: theme.textMuted)),
                      const SizedBox(height: 4),
                      Text(
                        appState.binaryStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          color: appState.scrcpyFound ? theme.textMain : const Color(0xFFF87171),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(border: Border(left: BorderSide(color: Color(0xFF27272A)))),
                  child: Row(
                    children: [
                      if (!appState.scrcpyFound)
                        _MiniButton(
                          label: 'INSTALL',
                          onTap: () => _showInstallInstructions(context),
                        ),
                      const SizedBox(width: 6),
                      _IconBtn(
                        icon: Icons.folder_outlined,
                        tooltip: 'Select Folder',
                        onTap: () => _selectFolder(context),
                      ),
                      const SizedBox(width: 4),
                      _IconBtn(
                        icon: Icons.refresh,
                        tooltip: 'Reset Path',
                        onTap: () => appState.setCustomPath(null),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _selectFolder(BuildContext context) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      context.read<AppState>().setCustomPath(result);
    }
  }

  void _showInstallInstructions(BuildContext context) {
    final theme = context.read<AppState>().theme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text('Install scrcpy', style: TextStyle(color: theme.textMain)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Install via Homebrew:', style: TextStyle(color: theme.textMain, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                'brew install scrcpy',
                style: TextStyle(fontFamily: 'monospace', color: theme.accentPrimary, fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This installs both scrcpy and adb.\nAfter installing, click the refresh icon.',
              style: TextStyle(color: theme.textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: theme.accentPrimary)),
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _MiniButton({required this.label, required this.onTap});

  @override
  State<_MiniButton> createState() => _MiniButtonState();
}

class _MiniButtonState extends State<_MiniButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _hovering ? Colors.white : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: _hovering ? Colors.black : const Color(0xFFE4E4E7),
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: theme.textMuted),
        ),
      ),
    );
  }
}
