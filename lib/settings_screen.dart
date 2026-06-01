import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to settings state
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.brown),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Settings", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 2,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Sound", style: TextStyle(color: Colors.brown)),
                  secondary: const Icon(Icons.volume_up_outlined, color: Colors.brown),
                  activeTrackColor: const Color(0xFFC07B46),
                  value: settings.isSoundOn,
                  onChanged: (val) => notifier.toggleSound(val),
                ),
                SwitchListTile(
                  title: const Text("Vibration", style: TextStyle(color: Colors.brown)),
                  secondary: const Icon(Icons.vibration, color: Colors.brown),
                  activeTrackColor: const Color(0xFFC07B46),
                  value: settings.isVibrationOn,
                  onChanged: (val) => notifier.toggleVibration(val),
                ),
                SwitchListTile(
                  title: const Text("Guideline", style: TextStyle(color: Colors.brown)),
                  secondary: const Icon(Icons.grid_on, color: Colors.brown),
                  activeTrackColor: const Color(0xFFC07B46),
                  value: settings.isGuidelineOn,
                  onChanged: (val) => notifier.toggleGuideline(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.thumb_up_alt_outlined, color: Colors.brown),
                  title: const Text("Rate Us", style: TextStyle(color: Colors.brown)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline, color: Colors.brown),
                  title: const Text("Feedback", style: TextStyle(color: Colors.brown)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
