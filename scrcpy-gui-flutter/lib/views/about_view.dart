import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../widgets/shared.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // About Me Section
              GlassCard(
                child: Column(
                  children: [
                    Text(
                      'ABOUT ME',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.accentPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.transparent,
                      backgroundImage: NetworkImage(
                        'https://github.com/imAdityaSharma.png',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aditya Sharma',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Full Stack Developer & UI/UX Enthusiast',
                      style: TextStyle(fontSize: 13, color: theme.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialLink(
                          icon: Icons.code,
                          label: 'GitHub',
                          url: 'https://github.com/imAdityaSharma',
                        ),
                        const SizedBox(width: 20),
                        // _SocialLink(
                        //   icon: Icons.link,
                        //   label: 'Portfolio',
                        //   url: 'https://adityasharma.dev', // Placeholder
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // About App Section
              GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ABOUT SCRCPY GUI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.accentPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'A premium, modern desktop client for scrcpy, designed to make Android device management effortless and beautiful.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialLink(
                          icon: Icons.code,
                          label: 'Source',
                          url:
                              'https://github.com/imAdityaSharma/scrcpy-gui-flutter',
                        ),
                        const SizedBox(width: 20),
                        _SocialLink(
                          icon: Icons.bug_report,
                          label: 'Issues',
                          url:
                              'https://github.com/imAdityaSharma/scrcpy-gui-flutter/issues',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Credits Section
              GlassCard(
                child: Column(
                  children: [
                    Text(
                      'CREDITS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CreditItem(
                      name: 'Genymobile/scrcpy',
                      role: 'Core Engine',
                      url: 'https://github.com/Genymobile/scrcpy',
                    ),
                    _CreditItem(
                      name: 'Flutter',
                      role: 'UI Framework',
                      url: 'https://flutter.dev',
                    ),
                    _CreditItem(
                      name: 'kil0bit',
                      role: 'Original Inspiration',
                      url: 'https://github.com/kil0bit-kb',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'v3.1.0 • Built with Flutter',
                style: TextStyle(fontSize: 10, color: theme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditItem extends StatelessWidget {
  final String name;
  final String role;
  final String url;

  const _CreditItem({
    required this.name,
    required this.role,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                color: theme.textMain,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(role, style: TextStyle(color: theme.textMuted, fontSize: 12)),
          ],
        ),
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
                size: 24,
                color: _hovering ? theme.accentPrimary : theme.textMuted,
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 10,
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
