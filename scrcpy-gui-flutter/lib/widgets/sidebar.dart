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
        border: Border(right: BorderSide(color: Color(0xFF27272A))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 50), // Traffic lights spacing

          _NavItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            selected: currentIndex == 0,
            onTap: () => onIndexChanged(0),
            isCollapsed: isCollapsed,
          ),
          _NavItem(
            icon: Icons.apps,
            label: 'App Manager',
            selected: currentIndex == 1,
            onTap: () => onIndexChanged(1),
            isCollapsed: isCollapsed,
          ),
          _NavItem(
            icon: Icons.cast_connected,
            label: 'Mirroring',
            selected: currentIndex == 2,
            onTap: () => onIndexChanged(2),
            isCollapsed: isCollapsed,
          ),
          _NavItem(
            icon: Icons.folder_open,
            label: 'Files',
            selected: currentIndex == 3,
            onTap: () => onIndexChanged(3),
            isCollapsed: isCollapsed,
          ),
          _NavItem(
            icon: Icons.settings,
            label: 'Advanced',
            selected: currentIndex == 4,
            onTap: () => onIndexChanged(4),
            isCollapsed: isCollapsed,
          ),
          const Spacer(),
          _NavItem(
            icon: Icons.info_outline,
            label: 'About',
            selected: currentIndex == 5,
            onTap: () => onIndexChanged(5),
            isCollapsed: isCollapsed,
          ),
          const SizedBox(height: 20),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              vertical: 12,
              horizontal: isCollapsed ? 0 : 16,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? theme.accentPrimary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? theme.accentPrimary.withValues(alpha: 0.2)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? theme.accentPrimary : theme.textMuted,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
