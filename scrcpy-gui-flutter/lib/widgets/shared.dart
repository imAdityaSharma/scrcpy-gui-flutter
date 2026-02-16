import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_themes.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GlassCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.glassBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: child,
    );
  }
}

class AccentButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isStop;
  final bool fullWidth;
  final double verticalPadding;
  final double fontSize;

  const AccentButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isStop = false,
    this.fullWidth = false,
    this.verticalPadding = 12,
    this.fontSize = 12,
  });

  @override
  State<AccentButton> createState() => _AccentButtonState();
}

class _AccentButtonState extends State<AccentButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    final gradient = widget.isStop
        ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
        : LinearGradient(colors: [theme.accentPrimary, theme.accentSecondary]);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.fullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: widget.verticalPadding,
          ),
          transform: Matrix4.translationValues(0, _hovering ? -1 : 0, 0),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: theme.accentGlow,
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: widget.fontSize,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StyledDropdown extends StatelessWidget {
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final bool large;

  const StyledDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: large ? 4 : 2),
      decoration: BoxDecoration(
        color: Color(0xFF09090B),
        border: Border.all(
          color: large ? Color(0xFF27272A) : Color(0xFF27272A),
          width: large ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(large ? 12 : 6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: Color(0xFF18181B),
          style: TextStyle(
            color: theme.textMain,
            fontWeight: large ? FontWeight.w700 : FontWeight.w400,
            fontSize: large ? 16 : 13,
          ),
          icon: Icon(Icons.expand_more, color: theme.textMuted, size: 18),
        ),
      ),
    );
  }
}

class StyledTextField extends StatelessWidget {
  final String? hintText;
  final String? value;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final double? width;
  final TextEditingController? controller;

  const StyledTextField({
    super.key,
    this.hintText,
    this.value,
    this.onChanged,
    this.keyboardType,
    this.width,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return SizedBox(
      width: width,
      child: TextField(
        controller:
            controller ??
            (value != null
                ? (TextEditingController(text: value)
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: value!.length),
                    ))
                : null),
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: TextStyle(color: theme.textMain, fontSize: 13),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: theme.textMuted),
          filled: true,
          fillColor: theme.inputBg,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Color(0xFF27272A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Color(0xFF27272A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: theme.accentPrimary),
          ),
          isDense: true,
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final bool accent;

  const SectionLabel(this.text, {super.key, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: accent ? theme.accentPrimary : theme.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}
