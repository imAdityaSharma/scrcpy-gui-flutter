import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:filesize/filesize.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_state.dart';
import '../widgets/shared.dart';
import 'dart:io';

class FileManagerView extends StatefulWidget {
  const FileManagerView({super.key});

  @override
  State<FileManagerView> createState() => _FileManagerViewState();
}

class _FileManagerViewState extends State<FileManagerView> {
  String _currentPath = '/storage/emulated/0';
  List<Map<String, dynamic>> _files = [];
  bool _loading = false;
  String? _deviceId;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final appState = context.read<AppState>();
    final deviceId = appState.selectedDevice;

    if (deviceId == null) {
      if (mounted) setState(() => _files = []);
      return;
    }

    if (mounted) setState(() => _loading = true);

    final files = await appState.adbService.listFiles(deviceId, _currentPath);

    if (mounted) {
      setState(() {
        _files = files;
        _deviceId = deviceId;
        _loading = false;
      });
    }
  }

  void _navigateTo(String path) {
    setState(() {
      _currentPath = path;
    });
    _loadFiles();
  }

  void _navigateUp() {
    if (_currentPath == '/' ||
        _currentPath.isEmpty ||
        _currentPath == '/storage/emulated/0')
      return;
    final parent = Directory(_currentPath).parent.path;
    _navigateTo(parent);
  }

  Future<void> _downloadFile(Map<String, dynamic> file) async {
    final deviceId = _deviceId;
    if (deviceId == null) return;

    final fileName = file['name'];
    String? savePath;

    if (file['isDirectory'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder download not supported yet')),
      );
      return;
    }

    savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save $fileName',
      fileName: fileName,
    );

    if (savePath != null) {
      final success = await context.read<AppState>().adbService.pullFile(
        deviceId,
        file['path'],
        savePath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Saved to $savePath' : 'Failed to download',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            width: 400,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if device changed
    final currentDevice = context.select<AppState, String?>(
      (s) => s.selectedDevice,
    );
    if (currentDevice != _deviceId &&
        !_loading &&
        currentDevice != null &&
        _deviceId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadFiles());
    }

    final theme = context.watch<AppState>().theme;

    if (currentDevice == null) {
      return Center(
        child: Text(
          'Connect a device',
          style: TextStyle(color: theme.textMuted),
        ),
      );
    }

    return DropTarget(
      onDragDone: (detail) async {
        final deviceId = _deviceId;
        if (deviceId == null) return;

        setState(() => _loading = true);

        final adbService = context.read<AppState>().adbService;

        int success = 0;
        for (final xfile in detail.files) {
          await adbService.pushFile(
            deviceId,
            xfile.path,
            destinationPath: _currentPath.endsWith('/')
                ? _currentPath
                : '$_currentPath/',
          );
          success++;
        }

        setState(() => _loading = false);
        _loadFiles();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pushed $success files to $_currentPath'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            width: 400,
          ),
        );
      },
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      child: Container(
        color: _dragging
            ? theme.accentPrimary.withValues(alpha: 0.1)
            : Colors.transparent,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Breadcrumbs
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_upward,
                    size: 20,
                    color: theme.textMain,
                  ),
                  onPressed: _navigateUp,
                  tooltip: 'Up',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: _buildBreadcrumbs(theme)),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, size: 20, color: theme.textMain),
                  onPressed: _loadFiles,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.glassBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 40), // Icon space
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Name',
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Size',
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Date',
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // File List
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.accentPrimary,
                      ),
                    )
                  : _files.isEmpty
                  ? Center(
                      child: Text(
                        'Empty folder',
                        style: TextStyle(color: theme.textMuted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _files.length,
                      itemBuilder: (context, index) {
                        final file = _files[index];
                        return _buildFileItem(file, theme);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBreadcrumbs(dynamic theme) {
    final parts = _currentPath.split('/').where((s) => s.isNotEmpty).toList();
    List<Widget> widgets = [
      InkWell(
        onTap: () => _navigateTo('/'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.storage, size: 16, color: theme.accentPrimary),
        ),
      ),
      Text('/', style: TextStyle(color: theme.textMuted)),
    ];

    String runningPath = '';
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      runningPath += '/$part';
      final thisPath = runningPath; // capture for closure

      widgets.add(
        InkWell(
          onTap: () => _navigateTo(thisPath),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              part,
              style: TextStyle(
                color: i == parts.length - 1 ? theme.textMain : theme.textMuted,
                fontWeight: i == parts.length - 1
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
      if (i < parts.length - 1) {
        widgets.add(Text('/', style: TextStyle(color: theme.textMuted)));
      }
    }
    return widgets;
  }

  Widget _buildFileItem(Map<String, dynamic> file, dynamic theme) {
    final isDir = file['isDirectory'] == true;
    final name = file['name'];
    final size = isDir ? '-' : filesize(file['size']);
    final date = file['date'];

    return GestureDetector(
      onDoubleTap: isDir ? () => _navigateTo(file['path']) : null,
      onSecondaryTapUp: (details) {
        _showContextMenu(details.globalPosition, file);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.accentSoft.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isDir ? Icons.folder : Icons.insert_drive_file,
              size: 20,
              color: isDir ? Colors.amber : theme.textMuted,
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Text(
                name,
                style: TextStyle(color: theme.textMain, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                size,
                style: TextStyle(color: theme.textMuted, fontSize: 12),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                date,
                style: TextStyle(color: theme.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(Offset position, Map<String, dynamic> file) {
    final isDir = file['isDirectory'] == true;
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
        if (!isDir)
          PopupMenuItem(
            height: 32,
            onTap: () {
              Future.delayed(Duration.zero, () => _downloadFile(file));
            },
            child: Row(
              children: [
                const Icon(Icons.download, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Download',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        if (isDir)
          PopupMenuItem(
            height: 32,
            onTap: () =>
                Future.delayed(Duration.zero, () => _navigateTo(file['path'])),
            child: const Text(
              'Open',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
