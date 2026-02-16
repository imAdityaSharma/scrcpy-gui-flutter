import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'package:file_picker/file_picker.dart';

class AppManagementView extends StatelessWidget {
  const AppManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Icon(Icons.apps, size: 48, color: theme.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'App Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Install, Uninstall, and Manage Apps',
                    style: TextStyle(fontSize: 12, color: theme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // DropZone centered
              Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: ApkDropZone(theme: theme),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(child: _AppList(theme: theme)),
            ],
          ),
        ),
      ),
    );
  }
}

class ApkDropZone extends StatefulWidget {
  final dynamic theme;
  const ApkDropZone({required this.theme});

  @override
  State<ApkDropZone> createState() => _ApkDropZoneState();
}

class _ApkDropZoneState extends State<ApkDropZone> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return GestureDetector(
      onTap: () async {
        final result = await FilePicker.platform.pickFiles(type: FileType.any);
        if (result != null && result.files.isNotEmpty) {
          final path = result.files.first.path;
          if (path != null) {
            // Show loading or just wait
            final res = await context.read<AppState>().handleFile(path);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(res['message'] ?? 'Operation completed'),
                  backgroundColor: res['success'] == true
                      ? Colors.green
                      : Colors.red,
                  behavior: SnackBarBehavior.floating,
                  width: 400,
                ),
              );
            }
          }
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.glassBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _dragging ? theme.accentPrimary : theme.accentSoft,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.cloud_download_outlined,
                size: 28,
                color: theme.accentPrimary,
              ),
              const SizedBox(height: 8),
              Text(
                'QUICK PUSH / INSTALL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE4E4E7),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Click to select any file or APK to push to phone',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.textMuted,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppList extends StatefulWidget {
  final dynamic theme;
  const _AppList({required this.theme});

  @override
  State<_AppList> createState() => _AppListState();
}

class _AppListState extends State<_AppList> {
  List<Map<String, String>> _apps = [];
  bool _loading = false;
  String? _deviceId;
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, String>> _filteredApps = [];
  String _filterType = 'all'; // all, user, system

  @override
  void initState() {
    super.initState();
    _loadApps();
    _searchCtrl.addListener(_filterApps);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    final appState = context.read<AppState>();
    final deviceId = appState.selectedDevice;

    if (deviceId == null) {
      if (mounted) setState(() => _apps = []);
      return;
    }

    if (mounted) setState(() => _loading = true);

    final apps = await appState.adbService.getInstalledApps(deviceId);

    if (mounted) {
      setState(() {
        _apps = apps;
        _deviceId = deviceId;
        _loading = false;
        _filterApps();
      });
    }
  }

  void _filterApps() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredApps = _apps.where((app) {
        final matchesQuery =
            (app['name'] ?? '').toLowerCase().contains(query) ||
            (app['package'] ?? '').toLowerCase().contains(query);
        final matchesType = _filterType == 'all' || app['type'] == _filterType;
        return matchesQuery && matchesType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // If device changed, reload
    final currentDevice = context.select<AppState, String?>(
      (s) => s.selectedDevice,
    );
    if (currentDevice != _deviceId &&
        !_loading &&
        currentDevice != null &&
        _deviceId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadApps());
    }

    final theme = widget.theme;

    if (currentDevice == null) {
      return Center(
        child: Text(
          'Connect a device to view apps',
          style: TextStyle(color: theme.textMuted),
        ),
      );
    }

    return Column(
      children: [
        // Controls
        Row(
          children: [
            Expanded(
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF09090B).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.accentSoft.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 16, color: theme.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: TextStyle(color: theme.textMain, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search packages...',
                          hintStyle: TextStyle(color: theme.textMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          _filterApps();
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: theme.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Refresh Button
            _IconBtn(
              icon: Icons.refresh,
              onTap: _loadApps,
              theme: theme,
              tooltip: 'Refresh App List',
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Filter tabs
        Row(
          children: [
            _FilterTab(
              label: 'All',
              active: _filterType == 'all',
              onTap: () => setState(() {
                _filterType = 'all';
                _filterApps();
              }),
              theme: theme,
            ),
            const SizedBox(width: 4),
            _FilterTab(
              label: 'User',
              active: _filterType == 'user',
              onTap: () => setState(() {
                _filterType = 'user';
                _filterApps();
              }),
              theme: theme,
            ),
            const SizedBox(width: 4),
            _FilterTab(
              label: 'System',
              active: _filterType == 'system',
              onTap: () => setState(() {
                _filterType = 'system';
                _filterApps();
              }),
              theme: theme,
            ),
            const Spacer(),
            Text(
              '${_filteredApps.length} Apps',
              style: TextStyle(
                fontSize: 10,
                color: theme.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // List
        Expanded(
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(color: theme.accentPrimary),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF09090B).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.accentSoft.withValues(alpha: 0.1),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: _filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = _filteredApps[index];
                      final isUser = app['type'] == 'user';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: GestureDetector(
                          onSecondaryTapUp: (details) {
                            _showContextMenu(
                              context,
                              details.globalPosition,
                              app,
                            );
                          },
                          child: ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.android,
                                size: 18,
                                color: isUser ? Colors.green : Colors.grey,
                              ),
                            ),
                            title: Text(
                              app['name'] ?? 'Unknown',
                              style: TextStyle(
                                color: theme.textMain,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              app['package'] ?? '',
                              style: TextStyle(
                                color: theme.textMuted,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? theme.accentPrimary.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (app['type'] ?? 'system').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: isUser
                                      ? theme.accentPrimary
                                      : theme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    Map<String, String> app,
  ) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      color: const Color(0xFF1E1E1E),
      items: [
        PopupMenuItem(
          height: 32,
          onTap: () {
            // Delay to allow menu to close before showing dialog
            Future.delayed(Duration.zero, () {
              _confirmUninstall(app);
            });
          },
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(
                'Uninstall',
                style: TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmUninstall(Map<String, String> app) async {
    final theme = widget.theme;
    final isSystem = app['type'] == 'system';
    final packageName = app['package'] ?? '';

    if (isSystem) {
      // Step 1: Warning for System App
      final step1 = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            'System App Warning',
            style: TextStyle(color: theme.textMain),
          ),
          content: Text(
            'This is a SYSTEM application ($packageName).\nUninstalling it may cause system instability or boot loops.\n\nAre you sure you want to proceed?',
            style: TextStyle(color: theme.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('I Understand', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (step1 != true) return;
    }

    // Final Confirmation
    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Confirm Uninstall',
          style: TextStyle(color: theme.textMain),
        ),
        content: Text(
          'Are you sure you want to uninstall ${app['name']} ($packageName)?',
          style: TextStyle(color: theme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Uninstall', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (step2 == true) {
      _performUninstall(packageName);
    }
  }

  Future<void> _performUninstall(String packageName) async {
    if (mounted) setState(() => _loading = true);

    final appState = context.read<AppState>();
    final deviceId = appState.selectedDevice;
    if (deviceId == null) return;

    final success = await appState.adbService.uninstallApp(
      deviceId,
      packageName,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Uninstalled $packageName'
                : 'Failed to uninstall $packageName',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          width: 400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadApps(); // Refresh list
    }
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final dynamic theme;

  const _FilterTab({
    required this.label,
    required this.active,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: active ? theme.accentPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? theme.accentPrimary
                  : theme.accentSoft.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: active ? Colors.black : theme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final dynamic theme;
  final String? tooltip;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.theme,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: tooltip ?? '',
          child: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF09090B).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.accentSoft.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon, size: 16, color: theme.textMuted),
          ),
        ),
      ),
    );
  }
}
