import 'package:material_ui/material_ui.dart';

import '../config/example_config.dart';
import 'credentials.dart';
import 'token_minter.dart';

/// Asks for the test organization's ID and API key, checks them by minting an access token, and
/// hands them to [onSignedIn].
class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.onSignedIn});

  final Future<void> Function(ExampleCredentials credentials) onSignedIn;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _organizationId = TextEditingController(text: ExampleConfig.organizationId);
  final _apiKey = TextEditingController(text: ExampleConfig.apiKey);
  bool _isProduction = ExampleConfig.isProduction;
  bool _showApiKey = false;
  bool _isBusy = false;
  String? _error;

  @override
  void dispose() {
    _organizationId.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isBusy = true;
      _error = null;
    });

    final credentials = ExampleCredentials(
      organizationId: _organizationId.text.trim(),
      apiKey: _apiKey.text.trim(),
      isProduction: _isProduction,
    );
    final token = await ExampleTokenMinter.mint(
      environment: credentials.environment,
      organizationId: credentials.organizationId,
      apiKey: credentials.apiKey,
    );
    if (!mounted) return;
    if (token == null) {
      setState(() {
        _isBusy = false;
        _error =
            'These credentials were refused — check the organization ID, the API key and '
            'the environment.';
      });
      return;
    }
    await widget.onSignedIn(credentials);
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('iSelfie SDK Flutter example')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Sign in with a test organization',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Your organization ID and API key are in the Developer Console, under Settings. '
                'They are kept on this device until you sign out.',
              ),
              const SizedBox(height: 24),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Development')),
                  ButtonSegment(value: true, label: Text('Production')),
                ],
                selected: {_isProduction},
                onSelectionChanged: _isBusy
                    ? null
                    : (selection) => setState(() => _isProduction = selection.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _organizationId,
                enabled: !_isBusy,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Organization ID'),
                validator: _required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apiKey,
                enabled: !_isBusy,
                autocorrect: false,
                enableSuggestions: false,
                obscureText: !_showApiKey,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _signIn(),
                decoration: InputDecoration(
                  labelText: 'API key',
                  suffixIcon: IconButton(
                    tooltip: _showApiKey ? 'Hide API key' : 'Show API key',
                    icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showApiKey = !_showApiKey),
                  ),
                ),
                validator: _required,
              ),
              if (_error case final error?) ...[
                const SizedBox(height: 16),
                Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isBusy ? null : _signIn,
                child: _isBusy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in'),
              ),
              const SizedBox(height: 24),
              Text(
                'Example app only: it creates the access token itself with the API key. In a real '
                'app your backend creates the token, and the API key never ships in the app.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
