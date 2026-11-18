import 'package:iselfie_sdk/iselfie_sdk.dart';
import 'package:material_ui/material_ui.dart';

import 'samples.dart';
import 'test_settings.dart';

/// Every option of the ready-made test, grouped like the SDK's docs.
class OptionsForm extends StatelessWidget {
  const OptionsForm({super.key, required this.settings, required this.enabled});

  final ExampleSettings settings;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _section(context, 'Screens', _screens()),
          _section(context, 'Instructions page', _instructions()),
          _section(context, 'Result page', _results()),
          _section(context, 'Scan', _scan()),
        ],
      ),
    );
  }

  List<Widget> _screens() => [
    _dropdown<CardioLanguage>(
      label: 'Language',
      value: settings.language,
      values: CardioLanguage.values,
      name: (language) => language.displayName,
      onChanged: (value) => settings.language = value,
    ),
    _switch('Language selector', settings.showLanguageSelector, (value) {
      settings.showLanguageSelector = value;
    }),
    _dropdown<ExampleStyle>(
      label: 'Style',
      value: settings.style,
      values: ExampleStyle.values,
      name: (style) => switch (style) {
        ExampleStyle.system => 'System (follows the device)',
        ExampleStyle.light => 'Light',
        ExampleStyle.dark => 'Dark',
        ExampleStyle.brand => 'Custom brand colors',
      },
      onChanged: (value) => settings.style = value,
    ),
    TextFormField(
      initialValue: settings.fontFamily,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'Font family (optional)',
        helperText: 'e.g. "Avenir Next" (iOS), "serif" (Android)',
      ),
      onChanged: (value) => settings.update((s) => s.fontFamily = value),
    ),
  ];

  List<Widget> _instructions() => [
    _switch('Hide the page', settings.instructionsHidden, (value) {
      settings.instructionsHidden = value;
    }),
    _dropdown<ExampleInstructions>(
      label: 'Content',
      value: settings.instructions,
      values: ExampleInstructions.values,
      name: (instructions) => switch (instructions) {
        ExampleInstructions.defaultTips => 'Default tips',
        ExampleInstructions.customItems => 'Custom items (en/es/ar)',
        ExampleInstructions.customHtml => 'Custom HTML (web JSON)',
      },
      onChanged: (value) => settings.instructions = value,
    ),
    _switch('"Don\'t show this again" checkbox', settings.allowsDontShowAgain, (value) {
      settings.allowsDontShowAgain = value;
    }),
    const _DontShowAgainStatus(),
  ];

  List<Widget> _results() => [
    _switch('Show the result page', settings.displayResults, (value) {
      settings.displayResults = value;
    }),
    _switch('Share button', settings.enableResultSharing, (value) {
      settings.enableResultSharing = value;
    }),
    _dropdown<String?>(
      label: 'Time zone of the date',
      value: settings.timeZoneId,
      values: ExampleSamples.timeZones,
      name: (zone) => zone ?? "Device's",
      onChanged: (value) => settings.timeZoneId = value,
    ),
  ];

  List<Widget> _scan() => [
    _switch('Disable audio', settings.disableAudio, (value) => settings.disableAudio = value),
    _switch('Disable motion detection', settings.disableMotionDetection, (value) {
      settings.disableMotionDetection = value;
    }),
    _switch('Disable light check', settings.disableLightCheck, (value) {
      settings.disableLightCheck = value;
    }),
    _switch('Disable distance check', settings.disableDistanceCheck, (value) {
      settings.disableDistanceCheck = value;
    }),
    _switch(
      'End the test if a bad condition persists',
      settings.terminateTestIfConditionPersisted,
      (value) {
        settings.terminateTestIfConditionPersisted = value;
      },
    ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Timeout: ${settings.testTerminationTimeOutSeconds} s'),
      subtitle: Slider(
        value: settings.testTerminationTimeOutSeconds.toDouble(),
        min: 3,
        max: 15,
        divisions: 12,
        onChanged: enabled
            ? (value) => settings.update((s) => s.testTerminationTimeOutSeconds = value.round())
            : null,
      ),
    ),
    _dropdown<CardioProgressBarPosition>(
      label: 'Progress bar',
      value: settings.progressBarPosition,
      values: CardioProgressBarPosition.values,
      name: (position) => position.name,
      onChanged: (value) => settings.progressBarPosition = value,
    ),
    _switch('Camera swap button', settings.enableMobileCameraSwap, (value) {
      settings.enableMobileCameraSwap = value;
    }),
  ];

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          ...children,
        ],
      ),
    );
  }

  Widget _switch(String title, bool value, void Function(bool value) change) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title),
      value: value,
      onChanged: enabled ? (value) => settings.update((_) => change(value)) : null,
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> values,
    required String Function(T value) name,
    required void Function(T value) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      // Rebuilt with the settings, so the field follows them.
      key: ValueKey('$label-$value'),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [for (final item in values) DropdownMenuItem(value: item, child: Text(name(item)))],
      onChanged: enabled ? (value) => settings.update((_) => onChanged(value as T)) : null,
    );
  }
}

/// Whether the user ticked "Don't show this again", with a button to undo it.
class _DontShowAgainStatus extends StatefulWidget {
  const _DontShowAgainStatus();

  @override
  State<_DontShowAgainStatus> createState() => _DontShowAgainStatusState();
}

class _DontShowAgainStatusState extends State<_DontShowAgainStatus> {
  bool? _isDismissed;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final isDismissed = await ISelfieCardio.isInstructionPageDismissedByUser();
    if (mounted) setState(() => _isDismissed = isDismissed);
  }

  Future<void> _reset() async {
    await ISelfieCardio.resetInstructionPageDontShowAgain();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(switch (_isDismissed) {
        true => 'Dismissed by the user on this device',
        false => 'Not dismissed on this device',
        null => 'Checking…',
      }),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Check again', onPressed: _refresh),
          TextButton(onPressed: _isDismissed == true ? _reset : null, child: const Text('Reset')),
        ],
      ),
    );
  }
}
