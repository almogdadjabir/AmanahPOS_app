import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final config = ScannerConfig.fromArgs(args);

  if (config.showHelp) {
    print(ScannerConfig.help);
    return;
  }

  final root = Directory.current;
  final pubspec = File('${root.path}/pubspec.yaml');

  if (!pubspec.existsSync()) {
    _fail('pubspec.yaml not found. Run this script from your Flutter project root.');
  }

  final packageName = _readPackageName(pubspec);
  final scanDir = Directory('${root.path}/${config.scanDir}');

  if (!scanDir.existsSync()) {
    _fail('Scan directory not found: ${config.scanDir}');
  }

  final allDartFiles = _collectDartFiles(scanDir)
      .where((file) => !_isGeneratedOrIgnored(file.path))
      .toSet();

  final rootFiles = _resolveRootFiles(
    projectRoot: root,
    packageName: packageName,
    customRoots: config.roots,
  );

  if (rootFiles.isEmpty) {
    _fail(
      'No root files found. Expected lib/main.dart or lib/main_*.dart.\n'
          'You can pass roots manually:\n'
          'dart run tool/dev/find_unused_dart_files.dart --roots=lib/main_dev.dart,lib/main_prod.dart',
    );
  }

  final reachableFiles = _findReachableFiles(
    packageName: packageName,
    rootFiles: rootFiles,
  );

  final unusedFiles = allDartFiles
      .where((file) => !reachableFiles.contains(file.path))
      .map((file) => file.path)
      .toList()
    ..sort();

  if (config.jsonOutput) {
    print(jsonEncode({
      'package': packageName,
      'scanDir': config.scanDir,
      'rootFiles': rootFiles.toList()..sort(),
      'unusedCount': unusedFiles.length,
      'unusedFiles': unusedFiles,
    }));
    return;
  }

  _printReport(
    packageName: packageName,
    scanDir: config.scanDir,
    rootFiles: rootFiles,
    unusedFiles: unusedFiles,
  );

  if (config.delete) {
    _confirmAndDelete(unusedFiles);
  }
}

class ScannerConfig {
  final String scanDir;
  final List<String> roots;
  final bool delete;
  final bool jsonOutput;
  final bool showHelp;

  const ScannerConfig({
    required this.scanDir,
    required this.roots,
    required this.delete,
    required this.jsonOutput,
    required this.showHelp,
  });

  factory ScannerConfig.fromArgs(List<String> args) {
    String scanDir = 'lib';
    List<String> roots = [];
    bool delete = false;
    bool jsonOutput = false;
    bool showHelp = false;

    for (final arg in args) {
      if (arg == '--help' || arg == '-h') {
        showHelp = true;
      } else if (arg == '--delete') {
        delete = true;
      } else if (arg == '--json') {
        jsonOutput = true;
      } else if (arg.startsWith('--dir=')) {
        scanDir = arg.substring('--dir='.length).trim();
      } else if (arg.startsWith('--roots=')) {
        roots = arg
            .substring('--roots='.length)
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    return ScannerConfig(
      scanDir: scanDir,
      roots: roots,
      delete: delete,
      jsonOutput: jsonOutput,
      showHelp: showHelp,
    );
  }

  static const help = '''
Find unused Dart files in a Flutter project.

Usage:
  dart run tool/dev/find_unused_dart_files.dart

Options:
  --dir=lib
      Directory to scan. Default: lib

  --roots=lib/main.dart,lib/main_dev.dart,lib/main_prod.dart
      Entry files. If not provided, the script uses lib/main.dart and lib/main_*.dart.

  --json
      Output JSON.

  --delete
      Delete unused files, but only after typing DELETE to confirm.

Examples:
  dart run tool/dev/find_unused_dart_files.dart

  dart run tool/dev/find_unused_dart_files.dart --roots=lib/main_dev.dart,lib/main_prod.dart

  dart run tool/dev/find_unused_dart_files.dart --delete
''';
}

String _readPackageName(File pubspec) {
  final content = pubspec.readAsStringSync();
  final match = RegExp(r'^name:\s*([a-zA-Z0-9_]+)\s*$', multiLine: true)
      .firstMatch(content);

  if (match == null) {
    _fail('Could not read package name from pubspec.yaml.');
  }

  return match.group(1)!;
}

Set<File> _collectDartFiles(Directory dir) {
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toSet();
}

Set<String> _resolveRootFiles({
  required Directory projectRoot,
  required String packageName,
  required List<String> customRoots,
}) {
  final roots = <String>{};

  if (customRoots.isNotEmpty) {
    for (final path in customRoots) {
      final file = File(_normalizePath('${projectRoot.path}/$path'));
      if (file.existsSync()) {
        roots.add(file.path);
      } else {
        stderr.writeln('Warning: root file not found: $path');
      }
    }

    return roots;
  }

  final libDir = Directory('${projectRoot.path}/lib');
  if (!libDir.existsSync()) return roots;

  for (final entity in libDir.listSync(recursive: false)) {
    if (entity is! File) continue;

    final name = _fileName(entity.path);
    final isMainFile = name == 'main.dart' ||
        RegExp(r'^main_.+\.dart$').hasMatch(name);

    if (isMainFile) {
      roots.add(entity.path);
    }
  }

  return roots;
}

Set<String> _findReachableFiles({
  required String packageName,
  required Set<String> rootFiles,
}) {
  final reachable = <String>{};
  final queue = <String>[...rootFiles];

  while (queue.isNotEmpty) {
    final currentPath = queue.removeLast();
    final currentFile = File(currentPath);

    if (!currentFile.existsSync()) continue;
    if (reachable.contains(currentPath)) continue;

    reachable.add(currentPath);

    final content = _stripComments(currentFile.readAsStringSync());
    final imports = _extractDirectiveUris(content);

    for (final uri in imports) {
      final resolved = _resolveDartUri(
        currentFile: currentFile,
        uri: uri,
        packageName: packageName,
      );

      if (resolved == null) continue;
      if (!resolved.endsWith('.dart')) continue;

      final file = File(resolved);
      if (!file.existsSync()) continue;

      if (!reachable.contains(file.path)) {
        queue.add(file.path);
      }
    }
  }

  return reachable;
}

List<String> _extractDirectiveUris(String content) {
  final uris = <String>[];

  final directiveRegex = RegExp(
    r'\b(import|export|part)\b[\s\S]*?;',
    multiLine: true,
  );

  final quotedUriRegex = RegExp(r'''['"]([^'"]+\.dart)['"]''');

  for (final directive in directiveRegex.allMatches(content)) {
    final statement = directive.group(0)!;

    for (final match in quotedUriRegex.allMatches(statement)) {
      final uri = match.group(1);
      if (uri != null && uri.isNotEmpty) {
        uris.add(uri);
      }
    }
  }

  return uris;
}

String? _resolveDartUri({
  required File currentFile,
  required String uri,
  required String packageName,
}) {
  if (uri.startsWith('dart:')) return null;

  final projectRoot = Directory.current.path;

  if (uri.startsWith('package:')) {
    final packagePrefix = 'package:$packageName/';
    if (!uri.startsWith(packagePrefix)) {
      return null;
    }

    final relativeLibPath = uri.substring(packagePrefix.length);
    return _normalizePath('$projectRoot/lib/$relativeLibPath');
  }

  if (uri.startsWith('http:') || uri.startsWith('https:')) {
    return null;
  }

  final currentDir = _dirName(currentFile.path);
  return _normalizePath('$currentDir/$uri');
}

bool _isGeneratedOrIgnored(String path) {
  final name = _fileName(path);

  const ignoredSuffixes = [
    '.g.dart',
    '.freezed.dart',
    '.mocks.dart',
    '.mock.dart',
    '.gen.dart',
    '.config.dart',
    '.reflectable.dart',
  ];

  if (ignoredSuffixes.any(name.endsWith)) return true;

  const ignoredNames = {
    'generated_plugin_registrant.dart',
  };

  return ignoredNames.contains(name);
}

String _stripComments(String input) {
  final buffer = StringBuffer();

  var inSingleQuote = false;
  var inDoubleQuote = false;
  var inLineComment = false;
  var inBlockComment = false;
  var escaped = false;

  for (var i = 0; i < input.length; i++) {
    final current = input[i];
    final next = i + 1 < input.length ? input[i + 1] : '';

    if (inLineComment) {
      if (current == '\n') {
        inLineComment = false;
        buffer.write(current);
      }
      continue;
    }

    if (inBlockComment) {
      if (current == '*' && next == '/') {
        inBlockComment = false;
        i++;
      }
      continue;
    }

    if (!inSingleQuote && !inDoubleQuote) {
      if (current == '/' && next == '/') {
        inLineComment = true;
        i++;
        continue;
      }

      if (current == '/' && next == '*') {
        inBlockComment = true;
        i++;
        continue;
      }
    }

    buffer.write(current);

    if (escaped) {
      escaped = false;
      continue;
    }

    if (current == r'\') {
      escaped = true;
      continue;
    }

    if (!inDoubleQuote && current == "'") {
      inSingleQuote = !inSingleQuote;
    } else if (!inSingleQuote && current == '"') {
      inDoubleQuote = !inDoubleQuote;
    }
  }

  return buffer.toString();
}

void _printReport({
  required String packageName,
  required String scanDir,
  required Set<String> rootFiles,
  required List<String> unusedFiles,
}) {
  print('');
  print('Package: $packageName');
  print('Scan dir: $scanDir');
  print('');
  print('Root files used:');

  final sortedRoots = rootFiles.toList()..sort();
  for (final root in sortedRoots) {
    print('  - ${_relativeToProject(root)}');
  }

  print('');
  print('Unused Dart files found: ${unusedFiles.length}');
  print('');

  if (unusedFiles.isEmpty) {
    print('No unused Dart files found.');
    return;
  }

  for (var i = 0; i < unusedFiles.length; i++) {
    print('${i + 1}. ${_relativeToProject(unusedFiles[i])}');
  }

  print('');
  print('Safe by default: no files were deleted.');
  print('To delete after review, run:');
  print('dart run tool/dev/find_unused_dart_files.dart --delete');
}

void _confirmAndDelete(List<String> unusedFiles) {
  if (unusedFiles.isEmpty) return;

  print('');
  print('Delete mode enabled.');
  print('This will delete ${unusedFiles.length} files.');
  print('Type DELETE to confirm:');

  final input = stdin.readLineSync();

  if (input != 'DELETE') {
    print('Cancelled. No files deleted.');
    return;
  }

  var deletedCount = 0;

  for (final path in unusedFiles) {
    final file = File(path);

    if (!file.existsSync()) continue;

    file.deleteSync();
    deletedCount++;
    print('Deleted: ${_relativeToProject(path)}');
  }

  print('');
  print('Done. Deleted $deletedCount files.');
  print('Now run:');
  print('flutter analyze');
  print('flutter test');
}

String _normalizePath(String path) {
  final uri = Uri.file(path).normalizePath();
  return File.fromUri(uri).absolute.path;
}

String _relativeToProject(String path) {
  final root = Directory.current.absolute.path;
  final absolute = File(path).absolute.path;

  if (absolute.startsWith(root)) {
    return absolute.substring(root.length + 1);
  }

  return path;
}

String _fileName(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.split('/').last;
}

String _dirName(String path) {
  final normalized = path.replaceAll('\\', '/');
  final parts = normalized.split('/');
  parts.removeLast();
  return parts.join('/');
}

Never _fail(String message) {
  stderr.writeln('Error: $message');
  exit(1);
}