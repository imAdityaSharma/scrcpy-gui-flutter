import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class Sidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final bool isCollapsed;
  final VoidCallback onToggle;

  const Sidebar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isCollapsed ? 70 : 250,
      decoration: BoxDecoration(
        color: theme.glassBg,
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use current width to decide when to show labels to prevent overflow during animation
          final isWidening = constraints.maxWidth > 100;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50), // Traffic lights spacing

              if (isWidening) _buildSectionHeader(theme, 'SESSIONS'),
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                selected: currentIndex == 0,
                onTap: () => onIndexChanged(0),
                isCollapsed: !isWidening,
              ),
              _NavItem(
                icon: Icons.cast_connected_rounded,
                label: 'Mirroring',
                selected: currentIndex == 2,
                onTap: () => onIndexChanged(2),
                isCollapsed: !isWidening,
              ),
              _NavItem(
                icon: Icons.videocam_rounded,
                label: 'Virtual Webcam',
                selected: currentIndex == 3,
                onTap: () => onIndexChanged(3),
                isCollapsed: !isWidening,
              ),

              const SizedBox(height: 16),
              if (isWidening) _buildSectionHeader(theme, 'MANAGEMENT'),
              _NavItem(
                icon: Icons.apps_rounded,
                label: 'App Manager',
                selected: currentIndex == 1,
                onTap: () => onIndexChanged(1),
                isCollapsed: !isWidening,
              ),
              _NavItem(
                icon: Icons.folder_rounded,
                label: 'Files',
                selected: currentIndex == 4,
                onTap: () => onIndexChanged(4),
                isCollapsed: !isWidening,
              ),
              _NavItem(
                icon: Icons.terminal_rounded,
                label: 'Advanced',
                selected: currentIndex == 5,
                onTap: () => onIndexChanged(5),
                isCollapsed: !isWidening,
              ),

              const Spacer(),
              _NavItem(
                icon: Icons.info_rounded,
                label: 'About',
                selected: currentIndex == 6,
                onTap: () => onIndexChanged(6),
                isCollapsed: !isWidening,
              ),

              if (isWidening) ...[
                const Divider(height: 1, color: Colors.white10),
              ],
              if (!isWidening) const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(dynamic theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: theme.textMuted.withValues(alpha: 0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isCollapsed;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              vertical: 8,
              horizontal: isCollapsed ? 0 : 12,
            ),
            decoration: BoxDecoration(
              color: selected ? theme.accentPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: theme.accentPrimary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : theme.textMuted,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? Colors.white : theme.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
