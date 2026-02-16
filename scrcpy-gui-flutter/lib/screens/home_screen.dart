import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/app_state.dart';
import '../widgets/sidebar.dart';
import '../views/dashboard_view.dart';
import '../views/mirroring_view.dart';
import '../views/file_manager_view.dart';
import '../views/advanced_view.dart';

import '../views/app_management_view.dart';
import '../views/webcam_view.dart';
import '../views/about_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isSidebarCollapsed = false;

  final _views = const [
    DashboardView(),
    AppManagementView(),
    MirroringView(),
    WebcamView(),
    FileManagerView(),
    AdvancedView(),
    AboutView(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.theme;

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: Row(
        children: [
          Sidebar(
            currentIndex: _currentIndex,
            onIndexChanged: (index) => setState(() => _currentIndex = index),
            isCollapsed: _isSidebarCollapsed,
            onToggle: () =>
                setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
          ),
          Expanded(
            child: Column(
              children: [
                // Custom title bar area for drag
                Container(
                  height: 40,
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      // Toggle Button
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: IconButton(
                          onPressed: () => setState(
                            () => _isSidebarCollapsed = !_isSidebarCollapsed,
                          ),
                          icon: Icon(
                            _isSidebarCollapsed
                                ? Icons.view_sidebar_outlined
                                : Icons.view_sidebar,
                            color: theme.textMuted,
                            size: 20,
                          ),
                          tooltip: _isSidebarCollapsed
                              ? 'Expand Sidebar'
                              : 'Collapse Sidebar',
                        ),
                      ),
                      // Drag Area
                      Expanded(
                        child: GestureDetector(
                          onPanStart: (_) => windowManager.startDragging(),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _views[_currentIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
