import 'package:amana_pos/app.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);

  final prefs = await SharedPreferences.getInstance();
  CacheStorage.preloadPrefs(prefs);

  DependenciesProvider.build();

  runApp(const App());
}