import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:iselfie_sdk/iselfie_sdk.dart';
import 'package:material_ui/material_ui.dart';

import 'auth/credentials.dart';
import 'auth/credentials_store.dart';
import 'auth/sign_in_page.dart';
import 'cardio_test/cardio_test_page.dart';

/// Opens on the sign-in screen, or straight on the test screen when credentials were saved.
class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key, required this.store});

  final ExampleCredentialsStore store;

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  bool _isLoading = true;
  ExampleCredentials? _credentials;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) ISelfieCardio.setLogLevel(ISelfieLogLevel.verbose);
    _load();
  }

  Future<void> _load() async {
    ExampleCredentials? credentials;
    try {
      credentials = await widget.store.load();
    } on PlatformException {
      credentials = null; // unreadable storage: sign in again
    }
    if (!mounted) return;
    setState(() {
      _credentials = credentials;
      _isLoading = false;
    });
  }

  Future<void> _signIn(ExampleCredentials credentials) async {
    await widget.store.save(credentials);
    if (!mounted) return;
    setState(() => _credentials = credentials);
  }

  Future<void> _signOut() async {
    await widget.store.clear();
    if (!mounted) return;
    setState(() => _credentials = null);
  }

  @override
  Widget build(BuildContext context) {
    final credentials = _credentials;
    return MaterialApp(
      title: 'iSelfie SDK Flutter example',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      darkTheme: ThemeData(colorSchemeSeed: Colors.deepPurple, brightness: Brightness.dark),
      home: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : credentials == null
          ? SignInPage(onSignedIn: _signIn)
          : CardioTestPage(
              key: ValueKey(credentials),
              credentials: credentials,
              onSignOut: _signOut,
            ),
    );
  }
}
