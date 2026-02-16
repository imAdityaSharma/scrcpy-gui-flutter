import 'package:flutter/material.dart';
import '../widgets/device_panel.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          // We will refactor DevicePanel to fit here nicely
          // For now, wrapping in constrained box to respect layout
          Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 600),
              child: const DevicePanel(),
            ),
          ),
        ],
      ),
    );
  }
}
