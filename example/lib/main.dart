import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:iselfie_sdk/iselfie_sdk.dart';
import 'package:material_ui/material_ui.dart';

import 'example_config.dart';
import 'example_settings.dart';
import 'example_token_minter.dart';
import 'options_form.dart';
import 'result_card.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iSelfie SDK Flutter example',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      darkTheme: ThemeData(colorSchemeSeed: Colors.deepPurple, brightness: Brightness.dark),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _settings = ExampleSettings();
  bool _isBusy = false;
  bool _isInitialized = false;

  /// Bumped after each test, so the form re-reads what the test may have changed on the device
  /// (e.g. "Don't show this again").
  int _testsRun = 0;
  CardioResult? _result;
  String _status = ExampleConfig.isComplete
      ? 'Tap Initialize'
      : 'Fill in config/example.json (copy config/example.json.template), then run with '
            '--dart-define-from-file=config/example.json';

  @override
  void initState() {
    super.initState();
    if (kDebugMode) ISelfieCardio.setLogLevel(ISelfieLogLevel.verbose);
  }

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    _setBusy('Minting an access token…');

    final environment = ExampleConfig.environment;
    final token = await ExampleTokenMinter.mint(
      environment: environment,
      organizationId: ExampleConfig.organizationId,
      apiKey: ExampleConfig.apiKey,
    );
    if (token == null) {
      _finish('Could not mint an access token — check the org id, API key and environment');
      return;
    }

    _setBusy('Initializing the SDK…');
    try {
      final availability = await ISelfieCardio.initialize(
        accessToken: token,
        organizationId: ExampleConfig.organizationId,
        appUserId: 'flutter-example-user',
        environment: environment,
      );
      _isInitialized = availability.isAvailable;
      _finish(
        availability.isAvailable
            ? 'Available — the SDK is ready to start a test'
            : 'Unavailable: ${availability.error}',
      );
    } on PlatformException catch (error) {
      _finish('Native error: ${error.code} ${error.message}');
    }
  }

  Future<void> _startTest() async {
    _setBusy('Opening the test…');
    _result = null;
    try {
      final outcome = await ISelfieCardio.startCardioTest(
        options: _settings.toOptions(),
        onStatus: (status) => _setBusy('Test: ${status.step.webName}'),
      );
      _testsRun++;
      switch (outcome) {
        case CardioTestCompleted(:final result):
          _result = result;
          _finish('Completed');
        case CardioTestFailed(:final failure):
          _finish(_describe(failure));
      }
    } on PlatformException catch (error) {
      _finish('Native error: ${error.code} ${error.message}');
    }
  }

  String _describe(CardioScanFailure failure) => switch (failure) {
    UnavailableFailure(:final error) => 'Unavailable (nothing was shown): $error',
    ResultErrorFailure(:final error) => 'No result: $error',
    TooManyInvalidFramesFailure() => 'The face was not usable for too long',
    InterruptedFailure() => 'The camera was interrupted',
    CameraPermissionDeniedFailure() => 'Camera permission denied — turn it on in Settings',
    CancelledFailure() => 'The user closed the test',
  };

  void _setBusy(String status) {
    if (!mounted) return;
    setState(() {
      _isBusy = true;
      _status = status;
    });
  }

  void _finish(String status) {
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('iSelfie SDK Flutter example')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Environment: ${ExampleConfig.environment.baseUrl.host}'),
            const SizedBox(height: 16),
            Text(_status, style: Theme.of(context).textTheme.titleMedium),
            if (_result case final result?) ...[
              const SizedBox(height: 16),
              ResultCard(result: result),
            ],
            const SizedBox(height: 16),
            _primaryButton(),
            if (_isInitialized)
              OptionsForm(key: ValueKey(_testsRun), settings: _settings, enabled: !_isBusy),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton() {
    final VoidCallback? onPressed;
    final String label;
    if (_isInitialized) {
      onPressed = _startTest;
      label = 'Start test';
    } else {
      onPressed = ExampleConfig.isComplete ? _initialize : null;
      label = 'Initialize';
    }
    return FilledButton(
      onPressed: _isBusy ? null : onPressed,
      child: _isBusy
          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(label),
    );
  }
}
