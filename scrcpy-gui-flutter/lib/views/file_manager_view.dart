import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:filesize/filesize.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_state.dart';
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
  bool _isListView = true;
  String _sortOption = 'name'; // name, size, type, date
  bool _sortAscending = true;
  bool _isEditingPath = false;
  final TextEditingController _pathController = TextEditingController();
  final FocusNode _pathFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _pathController.text = _currentPath;
    _loadFiles();
  }

  @override
  void dispose() {
    _pathController.dispose();
    _pathFocus.dispose();
    super.dispose();
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
      _sortFiles();
    }
  }

  void _sortFiles() {
    setState(() {
      _files.sort((a, b) {
        // Always keep directories on top for 'name' sort,
        // generally good practice to keep them separate.
        // Let's stick to: Directories always first, then files sorted.
        final isDirA = a['isDirectory'] == true;
        final isDirB = b['isDirectory'] == true;

        if (isDirA != isDirB) {
          return isDirA ? -1 : 1;
        }

        int result = 0;
        switch (_sortOption) {
          case 'name':
            result = (a['name'] ?? '').toString().toLowerCase().compareTo(
              (b['name'] ?? '').toString().toLowerCase(),
            );
            break;
          case 'size':
            final sizeA = a['size'] is int ? a['size'] : 0;
            final sizeB = b['size'] is int ? b['size'] : 0;
            result = sizeA.compareTo(sizeB);
            break;
          case 'type':
            final nameA = (a['name'] ?? '').toString();
            final nameB = (b['name'] ?? '').toString();
            final extA = nameA.contains('.')
                ? nameA.split('.').last.toLowerCase()
                : '';
            final extB = nameB.contains('.')
                ? nameB.split('.').last.toLowerCase()
                : '';
            result = extA.compareTo(extB);
            break;
          case 'date':
            result = (a['date'] ?? '').toString().compareTo(
              (b['date'] ?? '').toString(),
            );
            break;
        }
        return _sortAscending ? result : -result;
      });
    });
  }

  void _handleSort(String option) {
    if (_sortOption == option) {
      setState(() => _sortAscending = !_sortAscending);
    } else {
      setState(() {
        _sortOption = option;
        _sortAscending = true;
      });
    }
    _sortFiles();
  }

  void _navigateTo(String path) {
    // Basic cleanup
    if (path.isEmpty) path = '/';
    // Remove trailing slash if not root
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    setState(() {
      _currentPath = path;
      _pathController.text = path;
      _isEditingPath = false;
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

  // ... (download/delete methods) ...

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

  Future<void> _deleteFile(Map<String, dynamic> file) async {
    final deviceId = _deviceId;
    if (deviceId == null) return;

    final name = file['name'];
    final isDir = file['isDirectory'] == true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Delete ${isDir ? 'Folder' : 'File'}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "$name"?\nThis action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) setState(() => _loading = true);
      final adbService = context.read<AppState>().adbService;
      final success = await adbService.deleteFile(deviceId, file['path']);

      if (mounted) {
        setState(() => _loading = false);
        _loadFiles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Deleted $name' : 'Failed to delete $name'),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            width: 400,
          ),
        );
      }
    }
  }

  Future<Iterable<String>> _suggestPaths(
    TextEditingValue textEditingValue,
  ) async {
    final query = textEditingValue.text;
    final deviceId = _deviceId;
    if (deviceId == null) return const [];

    String parentPath;
    String filter;

    if (query.endsWith('/')) {
      parentPath = query;
      filter = '';
    } else {
      final lastSlash = query.lastIndexOf('/');
      if (lastSlash == -1) {
        parentPath = '/';
        filter = query.toLowerCase();
      } else {
        parentPath = query.substring(0, lastSlash + 1);
        filter = query.substring(lastSlash + 1).toLowerCase();
      }
    }

    if (parentPath.isEmpty) parentPath = '/';

    try {
      final files = await context.read<AppState>().adbService.listFiles(
        deviceId,
        parentPath,
      );

      return files
          .where(
            (f) =>
                f['isDirectory'] == true &&
                (f['name'] as String).toLowerCase().startsWith(filter),
          )
          .map((f) => f['path'] as String);
    } catch (e) {
      return const [];
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
            // Breadcrumbs & Tools
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
                  child: _isEditingPath
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            return Autocomplete<String>(
                              initialValue: TextEditingValue(
                                text: _pathController.text,
                              ),
                              optionsBuilder: _suggestPaths,
                              onSelected: (String selection) {
                                _navigateTo(selection);
                              },
                              fieldViewBuilder:
                                  (
                                    context,
                                    controller,
                                    focusNode,
                                    onEditingComplete,
                                  ) {
                                    // Hack to autofocus when switching
                                    if (_isEditingPath && !focusNode.hasFocus) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            if (mounted)
                                              focusNode.requestFocus();
                                          });
                                    }
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      style: TextStyle(
                                        color: theme.textMain,
                                        fontSize: 13,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Enter path...',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          borderSide: BorderSide(
                                            color: theme.accentPrimary,
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            Icons.check,
                                            size: 16,
                                            color: theme.accentPrimary,
                                          ),
                                          onPressed: () =>
                                              _navigateTo(controller.text),
                                        ),
                                      ),
                                      onSubmitted: (value) =>
                                          _navigateTo(value),
                                    );
                                  },
                              optionsViewBuilder:
                                  (context, onSelected, options) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 4,
                                        borderRadius: BorderRadius.circular(4),
                                        color: const Color(0xFF1E1E1E),
                                        child: SizedBox(
                                          width: constraints.maxWidth,
                                          height: 200,
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            itemCount: options.length,
                                            itemBuilder:
                                                (
                                                  BuildContext context,
                                                  int index,
                                                ) {
                                                  final String option = options
                                                      .elementAt(index);
                                                  return ListTile(
                                                    dense: true,
                                                    title: Text(
                                                      option,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    onTap: () {
                                                      onSelected(option);
                                                    },
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                            );
                          },
                        )
                      : GestureDetector(
                          onTap: () {
                            setState(() {
                              _isEditingPath = true;
                              // Ensure controller is synced before editing
                              _pathController.text = _currentPath;
                            });
                          },
                          child: Container(
                            color: Colors.transparent,
                            height: 36,
                            alignment: Alignment.centerLeft,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(children: _buildBreadcrumbs(theme)),
                            ),
                          ),
                        ),
                ),
                if (_isEditingPath)
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: theme.textMuted),
                    onPressed: () => setState(() => _isEditingPath = false),
                    tooltip: 'Cancel Edit',
                  ),
                if (!_isEditingPath) ...[
                  // Sort Menu
                  PopupMenuButton<String>(
                    icon: Icon(Icons.sort, size: 20, color: theme.textMain),
                    tooltip: 'Sort By',
                    color: const Color(0xFF1E1E1E),
                    onSelected: _handleSort,
                    itemBuilder: (context) => [
                      _buildSortItem('name', 'Name'),
                      _buildSortItem('size', 'Size'),
                      _buildSortItem('type', 'Type'),
                      _buildSortItem('date', 'Date'),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, size: 20, color: theme.textMain),
                    onPressed: _loadFiles,
                    tooltip: 'Refresh',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _isListView
                          ? Icons.grid_view_rounded
                          : Icons.list_rounded,
                      size: 20,
                      color: theme.textMain,
                    ),
                    onPressed: () => setState(() => _isListView = !_isListView),
                    tooltip: _isListView ? 'Icon View' : 'List View',
                  ),
                ],
              ],
            ),
            if (_isListView) ...[
              const SizedBox(height: 10),
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.glassBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 40), // Icon space
                    _buildHeaderCell('Name', 'name', 2, theme),
                    _buildHeaderCell('Size', 'size', 1, theme),
                    _buildHeaderCell('Date', 'date', 1, theme),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: 10),
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
                  ? _buildEmptyState(theme)
                  : _isListView
                  ? ListView.builder(
                      itemCount: _files.length,
                      itemBuilder: (context, index) {
                        final file = _files[index];
                        return _buildFileItem(file, theme);
                      },
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.only(top: 10),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: _files.length,
                      itemBuilder: (context, index) {
                        final file = _files[index];
                        return _buildIconItem(file, theme);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      height: 32,
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          if (_sortOption == value) ...[
            const SizedBox(width: 8),
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: Colors.blueAccent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String label,
    String sortKey,
    int flex,
    dynamic theme,
  ) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _handleSort(sortKey),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: _sortOption == sortKey
                    ? theme.accentPrimary
                    : theme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_sortOption == sortKey) ...[
              const SizedBox(width: 4),
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: theme.accentPrimary,
              ),
            ],
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

  Widget _getFileIcon(String name, bool isDir, double size, dynamic theme) {
    if (isDir) {
      return Icon(Icons.folder, size: size, color: Colors.amber);
    }

    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    IconData icon;
    Color color;

    switch (ext) {
      case 'apk':
        icon = Icons.android;
        color = Colors.green;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        icon = Icons.image;
        color = Colors.purpleAccent;
        break;
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
      case 'webm':
        icon = Icons.video_file;
        color = Colors.orange;
        break;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'flac':
      case 'ogg':
      case 'm4a':
        icon = Icons.audio_file;
        color = Colors.blue;
        break;
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'md':
      case 'rtf':
        icon = Icons.description;
        color = Colors.blueGrey;
        break;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        icon = Icons.folder_zip;
        color = Colors.amberAccent;
        break;
      case 'xml':
      case 'json':
      case 'html':
      case 'css':
      case 'js':
      case 'dart':
        icon = Icons.code;
        color = theme.accentPrimary;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = theme.textMuted;
    }

    return Icon(icon, size: size, color: color);
  }

  Widget _buildEmptyState(dynamic theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 64,
            color: theme.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Folder is empty',
            style: TextStyle(color: theme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(Map<String, dynamic> file, dynamic theme) {
    final isDir = file['isDirectory'] == true;
    final name = file['name'];
    final size = isDir
        ? '-'
        : (file['size'] is int ? filesize(file['size']) : '0 B');
    final date = file['date'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onDoubleTap: isDir ? () => _navigateTo(file['path']) : null,
        onSecondaryTapUp: (details) {
          _showContextMenu(details.globalPosition, file);
        },
        hoverColor: theme.accentPrimary.withValues(alpha: 0.1),
        splashColor: theme.accentPrimary.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.accentSoft.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: Row(
            children: [
              _getFileIcon(name, isDir, 24, theme),
              const SizedBox(width: 16),
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
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 13,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  date,
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 13,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ),
            ],
          ),
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
        PopupMenuItem(
          height: 32,
          onTap: () {
            Future.delayed(Duration.zero, () => _deleteFile(file));
          },
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline,
                size: 16,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(width: 8),
              const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFF87171), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconItem(Map<String, dynamic> file, dynamic theme) {
    final isDir = file['isDirectory'] == true;
    final name = file['name'];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onDoubleTap: isDir ? () => _navigateTo(file['path']) : null,
        onSecondaryTapUp: (details) {
          _showContextMenu(details.globalPosition, file);
        },
        hoverColor: theme.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _getFileIcon(name, isDir, 48, theme),
              const SizedBox(height: 12),
              Text(
                name,
                style: TextStyle(color: theme.textMain, fontSize: 11),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
