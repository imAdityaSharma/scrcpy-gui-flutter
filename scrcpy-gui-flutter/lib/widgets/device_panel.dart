import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import 'shared.dart';

class DevicePanel extends StatefulWidget {
  const DevicePanel({super.key});

  @override
  State<DevicePanel> createState() => _DevicePanelState();
}

class _DevicePanelState extends State<DevicePanel> {
  String _activeTab = 'usb';
  final _pairIpCtrl = TextEditingController();
  final _pairCodeCtrl = TextEditingController();
  final _wirelessIpCtrl = TextEditingController();
  bool _refreshing = false;

  @override
  void dispose() {
    _pairIpCtrl.dispose();
    _pairCodeCtrl.dispose();
    _wirelessIpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    // Sync controller if external change (e.g. Scan)
    if (_wirelessIpCtrl.text != appState.wirelessIp) {
      _wirelessIpCtrl.text = appState.wirelessIp;
    }
    final theme = appState.theme;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Devices card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.phone_android,
                      size: 16,
                      color: theme.accentPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'DEVICES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.accentPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        await appState.killAdb();
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(
                          'Kill ADB',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: theme.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () async {
                        setState(() => _refreshing = true);
                        await appState.scanDevices();
                        setState(() => _refreshing = false);
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Row(
                          children: [
                            AnimatedRotation(
                              turns: _refreshing ? 1 : 0,
                              duration: const Duration(seconds: 1),
                              child: Icon(
                                Icons.refresh,
                                size: 14,
                                color: theme.accentPrimary,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Refresh',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.accentPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(color: Color(0xFF27272A), height: 20),
                // Device selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionLabel('Active Device Selection'),
                    GestureDetector(
                      onTap: () => _renameDevice(context),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(
                          'Set Nickname',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFA1A1AA),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                StyledDropdown(
                  value: appState.selectedDevice ?? '',
                  items: appState.devices.isEmpty
                      ? [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('No devices detected'),
                          ),
                        ]
                      : appState.devices
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(
                                  appState.getDeviceDisplayName(d),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                  onChanged: (v) => appState.setSelectedDevice(v),
                ),
                if (appState.selectedDevice != null) ...[
                  const SizedBox(height: 12),
                  const SectionLabel('Device Details'),
                  const SizedBox(height: 6),
                  _DeviceDetails(deviceId: appState.selectedDevice!),
                ],
                const SizedBox(height: 12),
                Divider(color: Color(0xFF27272A), height: 1),
                const SizedBox(height: 12),

                // Collapsible Connection Section
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: ValueKey(
                      'connection-${appState.selectedDevice == null}',
                    ),
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_link,
                          size: 16,
                          color: theme.accentPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'NEW CONNECTION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.accentPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    initiallyExpanded: appState.selectedDevice == null,
                    iconColor: theme.textMuted,
                    collapsedIconColor: theme.textMuted,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _TabBtn(
                                  label: 'USB',
                                  active: _activeTab == 'usb',
                                  onTap: () =>
                                      setState(() => _activeTab = 'usb'),
                                  theme: theme,
                                ),
                                _TabBtn(
                                  label: 'Wireless',
                                  active: _activeTab == 'wireless',
                                  onTap: () =>
                                      setState(() => _activeTab = 'wireless'),
                                  theme: theme,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            if (_activeTab == 'usb') ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 12,
                                          color: theme.accentPrimary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'USB SETUP TIP',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: theme.accentPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Enable Developer Options and USB Debugging on your phone.',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: theme.textMuted,
                                        fontStyle: FontStyle.italic,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            if (_activeTab == 'wireless') ...[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: const SectionLabel(
                                  '1. Connection',
                                  accent: true,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: StyledTextField(
                                      hintText: '192.168.1.x:5555',
                                      controller: _wirelessIpCtrl,
                                      onChanged: (v) {
                                        appState.wirelessIp = v;
                                        appState.saveSettings();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Scan Button
                                  Container(
                                    height: 32,
                                    width: 32,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF27272A),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Color(0xFF3F3F46),
                                      ),
                                    ),
                                    child: IconButton(
                                      onPressed: () => _showScanDialog(context),
                                      icon: Icon(
                                        Icons.wifi_find,
                                        size: 16,
                                        color: theme.accentPrimary,
                                      ),
                                      padding: EdgeInsets.zero,
                                      tooltip: 'Scan for devices',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 14,
                                        width: 14,
                                        child: Checkbox(
                                          value: appState.autoConnect,
                                          onChanged: (v) {
                                            appState.autoConnect = v ?? false;
                                            appState.saveSettings();
                                          },
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Auto',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: theme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => appState.connectWireless(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF27272A),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  child: const Text(
                                    'CONNECT',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              if (appState.recentIps.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: const SectionLabel('History'),
                                ),
                                const SizedBox(height: 4),
                                ...appState.recentIps.map(
                                  (ip) => GestureDetector(
                                    onTap: () {
                                      appState.wirelessIp = ip;
                                      appState.saveSettings();
                                      setState(() {});
                                    },
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color(
                                            0xFF09090B,
                                          ).withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: theme.accentSoft,
                                          ),
                                        ),
                                        child: Text(
                                          ip,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontFamily: 'monospace',
                                            color: const Color(0xFFA1A1AA),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Divider(color: Color(0xFF27272A)),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: SectionLabel(
                                  '2. Pairing (Android 11+)',
                                  accent: true,
                                ),
                              ),
                              const SizedBox(height: 6),
                              StyledTextField(
                                hintText: 'IP:Port',
                                controller: _pairIpCtrl,
                                onChanged: (v) {}, // Controller handles text
                              ),
                              const SizedBox(height: 6),
                              StyledTextField(
                                hintText: 'Code',
                                controller: _pairCodeCtrl,
                                onChanged: (v) {}, // Controller handles text
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => appState.pairDevice(
                                    _pairIpCtrl.text,
                                    _pairCodeCtrl.text,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Color(0xFF3F3F46)),
                                    foregroundColor: const Color(0xFFA1A1AA),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  child: const Text(
                                    'PAIR',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _renameDevice(BuildContext context) {
    final appState = context.read<AppState>();
    final dev = appState.selectedDevice;
    if (dev == null) return;

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: appState.theme.surfaceColor,
        title: Text(
          'Nickname for $dev',
          style: TextStyle(color: appState.theme.textMain, fontSize: 14),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: appState.theme.textMain),
          decoration: InputDecoration(
            hintText: 'Enter nickname',
            hintStyle: TextStyle(color: appState.theme.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: appState.theme.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              appState.renameDevice(dev, controller.text);
              Navigator.pop(ctx);
            },
            child: Text(
              'Save',
              style: TextStyle(color: appState.theme.accentPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showScanDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final theme = appState.theme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.wifi_find, color: theme.accentPrimary, size: 20),
            const SizedBox(width: 10),
            Text(
              'Scanning for Devices...',
              style: TextStyle(
                color: theme.textMain,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          height: 350,
          child: _ScanResultsList(
            adbService: appState.adbService,
            theme: theme,
            onSelect: (device) {
              final ipPort = '${device['ip']}:${device['port']}';
              final type = device['type'];

              if (type == 'pairing') {
                _pairIpCtrl.text = ipPort;
                setState(() => _activeTab = 'wireless');
              } else {
                appState.wirelessIp = ipPort;
                appState.saveSettings();
                setState(() => _activeTab = 'wireless');
              }
              Navigator.pop(ctx);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: theme.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _DeviceDetails extends StatelessWidget {
  final String deviceId;

  const _DeviceDetails({required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.theme;

    return FutureBuilder<Map<String, String>>(
      future: appState.adbService.getDeviceDetails(deviceId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.accentPrimary,
              ),
            ),
          );
        }

        final details = snapshot.data!;
        if (details.isEmpty) {
          return Text(
            'Could not fetch details',
            style: TextStyle(color: theme.textMuted, fontSize: 11),
          );
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF09090B).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.accentSoft.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              _detailRow('Model', details['model'] ?? '-', theme),
              _detailRow('Kernel', details['kernel'] ?? '-', theme),
              _detailRow('RAM', details['ram'] ?? '-', theme),
              _detailRow('ROM', details['rom'] ?? '-', theme),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Divider(
                  color: theme.accentSoft.withValues(alpha: 0.3),
                  height: 1,
                ),
              ),
              _detailRow(
                'Android',
                '${details['androidVersion']} (SDK ${details['sdkVersion']})',
                theme,
              ),
              _detailRow('DRM', details['drm'] ?? '-', theme),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Divider(
                  color: theme.accentSoft.withValues(alpha: 0.3),
                  height: 1,
                ),
              ),
              _detailRow('Resolution', details['resolution'] ?? '-', theme),
              _detailRow('Refresh Rate', details['refreshRate'] ?? '-', theme),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Divider(
                  color: theme.accentSoft.withValues(alpha: 0.3),
                  height: 1,
                ),
              ),
              _detailRow('Battery', details['battery'] ?? '-', theme),
              _detailRow('Packages', details['apps'] ?? '-', theme),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, dynamic theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.textMuted, fontSize: 11)),
          Text(
            value,
            style: TextStyle(
              color: theme.textMain,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanResultsList extends StatefulWidget {
  final dynamic adbService;
  final dynamic theme;
  final ValueChanged<Map<String, dynamic>> onSelect;

  const _ScanResultsList({
    required this.adbService,
    required this.theme,
    required this.onSelect,
  });

  @override
  State<_ScanResultsList> createState() => _ScanResultsListState();
}

class _ScanResultsListState extends State<_ScanResultsList> {
  final List<Map<String, dynamic>> _devices = [];

  @override
  void initState() {
    super.initState();
    widget.adbService.scanForDevices().listen((device) {
      if (mounted) {
        setState(() {
          // Avoid duplicates
          if (!_devices.any(
            (d) => d['ip'] == device['ip'] && d['port'] == device['port'],
          )) {
            _devices.add(device);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: widget.theme.accentPrimary),
            const SizedBox(height: 16),
            Text(
              'Searching on local network...',
              style: TextStyle(color: widget.theme.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final ipPort = '${device['ip']}:${device['port']}';
        final type = device['type'] ?? 'connect';
        final isPairing = type == 'pairing';

        return ListTile(
          leading: Icon(
            isPairing ? Icons.phonelink_lock : Icons.android,
            color: isPairing ? Colors.orange : widget.theme.accentPrimary,
          ),
          title: Row(
            children: [
              Text(
                device['name'] ?? 'Unknown',
                style: TextStyle(
                  color: widget.theme.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPairing
                      ? Colors.orange.withValues(alpha: 0.2)
                      : widget.theme.accentPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isPairing
                        ? Colors.orange.withValues(alpha: 0.5)
                        : widget.theme.accentPrimary.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  isPairing ? 'PAIRING' : 'CONNECT',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: isPairing
                        ? Colors.orange
                        : widget.theme.accentPrimary,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            ipPort,
            style: TextStyle(
              color: widget.theme.textMuted,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: widget.theme.textMuted,
            size: 16,
          ),
          onTap: () => widget.onSelect(device),
          hoverColor: widget.theme.accentPrimary.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        );
      },
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final dynamic theme;

  const _TabBtn({
    required this.label,
    required this.active,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? theme.accentPrimary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Center(
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: active ? theme.accentPrimary : theme.textMuted,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
