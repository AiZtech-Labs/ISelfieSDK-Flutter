import 'package:flutter/services.dart';
import 'package:iselfie_sdk/iselfie_sdk.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/credentials.dart';
import '../auth/token_minter.dart';
import 'options_form.dart';
import 'result_card.dart';
import 'test_settings.dart';

/// Initializes the SDK with the signed-in organization, then shows every option of the test and
/// starts it.
class CardioTestPage extends StatefulWidget {
  const CardioTestPage({super.key, required this.credentials, required this.onSignOut});

  final ExampleCredentials credentials;
  final Future<void> Function() onSignOut;

  @override
  State<CardioTestPage> createState() => _CardioTestPageState();
}

class _CardioTestPageState extends State<CardioTestPage> {
  final _settings = ExampleSettings();
  bool _isBusy = true;
  bool _isInitialized = false;

  /// Bumped after each test, so the form re-reads what the test may have changed on the device
  /// (e.g. "Don't show this again").
  int _testsRun = 0;
  CardioResult? _result;
  String _status = 'Starting…';

  @override
  void initState() {
    super.initState();
    // Signed in: initialize right away, after the first frame (setState isn't allowed in initState).
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'The organization ID and API key are removed from this device. You can sign in with '
          'other credentials.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.onSignOut();
  }

  Future<void> _initialize() async {
    _setBusy('Minting an access token…');

    final credentials = widget.credentials;
    final environment = credentials.environment;
    final token = await ExampleTokenMinter.mint(
      environment: environment,
      organizationId: credentials.organizationId,
      apiKey: credentials.apiKey,
    );
    if (token == null) {
      _finish(
        'Could not mint an access token — check your connection, or sign out and check the credentials',
      );
      return;
    }

    _setBusy('Initializing the SDK…');
    try {
      final availability = await ISelfieCardio.initialize(
        accessToken: token,
        organizationId: credentials.organizationId,
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
      appBar: AppBar(
        title: const Text('iSelfie SDK Flutter example'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _isBusy ? null : _confirmSignOut,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Environment: ${widget.credentials.environment.baseUrl.host}'),
            Text('Organization: ${widget.credentials.organizationId}'),
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
      onPressed = _initialize;
      label = 'Try again';
    }
    return FilledButton(
      onPressed: _isBusy ? null : onPressed,
      child: _isBusy
          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(label),
    );
  }
}
