import 'package:flutter/material.dart';
import '../widgets/engine_panel.dart';
import '../widgets/session_panel.dart';

class MirroringView extends StatelessWidget {
  const MirroringView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mirroring Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: const EnginePanel()),
              const SizedBox(width: 20),
              Expanded(flex: 1, child: const SessionPanel()),
            ],
          ),
        ],
      ),
    );
  }
}
