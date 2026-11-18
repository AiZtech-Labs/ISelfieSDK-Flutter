import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'auth/credentials_store.dart';

void main() {
  runApp(ExampleApp(store: SecureExampleCredentialsStore()));
}
