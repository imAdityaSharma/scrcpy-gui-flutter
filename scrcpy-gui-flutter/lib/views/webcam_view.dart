import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/shared.dart';

class WebcamView extends StatelessWidget {
  const WebcamView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.theme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.accentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.videocam_rounded,
                  color: theme.accentPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Virtual Webcam',
                    style: TextStyle(
                      color: theme.textMain,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Use your phone as a high-quality camera for your Mac',
                    style: TextStyle(color: theme.textMuted, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Configuration
                  Expanded(
                    flex: isWide ? 3 : 0,
                    child: Column(
                      children: [
                        _buildConfigCard(context, appState, theme),
                        const SizedBox(height: 20),
                        _buildOptimizationCard(context, appState, theme),
                      ],
                    ),
                  ),
                  if (isWide) const SizedBox(width: 24),
                  if (!isWide) const SizedBox(height: 24),
                  // Right Column: Instructions/Guide
                  Expanded(
                    flex: isWide ? 2 : 0,
                    child: _buildGuideCard(context, theme),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(
    BuildContext context,
    AppState appState,
    dynamic theme,
  ) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('CAMERA CONFIGURATION'),
          const SizedBox(height: 16),

          _SettingsRow(
            label: 'Camera Facing',
            child: StyledDropdown(
              value:
                  ['back', 'front', 'external'].contains(appState.cameraFacing)
                  ? appState.cameraFacing
                  : 'back',
              items: const [
                DropdownMenuItem(value: 'back', child: Text('Back Camera')),
                DropdownMenuItem(value: 'front', child: Text('Front Camera')),
                DropdownMenuItem(value: 'external', child: Text('External')),
              ],
              onChanged: (v) => appState.setCameraFacing(v!),
            ),
          ),
          const SizedBox(height: 16),

          _SettingsRow(
            label: 'Resolution',
            child: StyledDropdown(
              value: ['0', '3840', '1920', '1280'].contains(appState.resolution)
                  ? appState.resolution
                  : '0',
              items: const [
                DropdownMenuItem(value: '0', child: Text('Original')),
                DropdownMenuItem(value: '3840', child: Text('4K (2160p)')),
                DropdownMenuItem(value: '1920', child: Text('Full HD (1080p)')),
                DropdownMenuItem(value: '1280', child: Text('HD (720p)')),
              ],
              onChanged: (v) {
                appState.resolution = v!;
                appState.saveSettings();
              },
            ),
          ),
          const SizedBox(height: 16),

          _SettingsRow(
            label: 'Frame Rate',
            child: StyledDropdown(
              value: ['60', '30', '24'].contains(appState.cameraFps)
                  ? appState.cameraFps
                  : '30',
              items: const [
                DropdownMenuItem(value: '60', child: Text('60 FPS')),
                DropdownMenuItem(value: '30', child: Text('30 FPS')),
                DropdownMenuItem(value: '24', child: Text('24 FPS')),
              ],
              onChanged: (v) {
                appState.cameraFps = v!;
                appState.saveSettings();
              },
            ),
          ),

          const Divider(height: 32, color: Colors.white10),

          SizedBox(
            width: double.infinity,
            child: AccentButton(
              onPressed:
                  null, // Disabled for now (requires signed native extension)
              label: 'Native System Camera (Coming Soon)',
              icon: Icons.camera_enhance_rounded,
            ),
          ),
          const SizedBox(height: 12),

          if (appState.obsInstalled) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: appState.selectedDevice != null
                    ? () => appState.launchWebcamRelay()
                    : null,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Relay via OBS Studio'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white10),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: appState.selectedDevice != null
                  ? () => _launchWebcam(context, appState)
                  : null,
              icon: const Icon(Icons.rocket_launch_rounded, size: 16),
              label: const Text('Launch Preview Only'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          if (appState.obsInstalled)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green.shade400,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'OBS Studio Detected & Ready',
                    style: TextStyle(
                      color: Colors.green.shade400,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptimizationCard(
    BuildContext context,
    AppState appState,
    dynamic theme,
  ) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('STREAM OPTIMIZATIONS'),
          const SizedBox(height: 16),

          _SwitchRow(
            label: 'Always on Top',
            description: 'Keep the camera window above all others',
            value: appState.alwaysOnTop,
            onChanged: (v) {
              appState.alwaysOnTop = v;
              appState.saveSettings();
            },
          ),
          const SizedBox(height: 12),
          _SwitchRow(
            label: 'Borderless Window',
            description: 'Remove macOS window decorations',
            value: appState.borderless,
            onChanged: (v) {
              appState.borderless = v;
              appState.saveSettings();
            },
          ),
          const SizedBox(height: 12),
          _SwitchRow(
            label: 'Mute Audio',
            description: 'Disable phone microphone to avoid feedback',
            value: !appState.audioEnabled,
            onChanged: (v) {
              appState.audioEnabled = !v;
              appState.saveSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(BuildContext context, dynamic theme) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('HOW TO USE ON MAC'),
          const SizedBox(height: 16),

          _GuideStep(
            number: '1',
            title: 'Launch the Stream',
            description:
                'Connect your phone and click the launch button to open the camera feed.',
          ),
          _GuideStep(
            number: '2',
            title: 'Use OBS Studio',
            description:
                'Open OBS, add a "Window Capture" source, and select the window titled "Android Webcam".',
          ),
          _GuideStep(
            number: '3',
            title: 'Start Virtual Camera',
            description:
                'In OBS, click "Start Virtual Camera". Your phone is now a webcam in Zoom, Teams, and more!',
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pro Tip: Use a 1080p resolution and a wired connection for the lowest latency.',
                    style: TextStyle(
                      color: Colors.amber.shade200,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _launchWebcam(BuildContext context, AppState appState) {
    appState.setSessionMode('camera');
    final config = {
      'device': appState.selectedDevice,
      'sessionMode': 'camera',
      'res': appState.resolution,
      'cameraFps': appState.cameraFps,
      'cameraFacing': appState.cameraFacing,
      'alwaysOnTop': appState.alwaysOnTop,
      'borderless': appState.borderless,
      'audioEnabled': appState.audioEnabled,
      'bitrate': appState.bitrate,
      'rotation': appState.cameraRotation,
    };
    appState.scrcpyService.runScrcpy(config);
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingsRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Expanded(flex: 3, child: child),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                description,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _GuideStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
