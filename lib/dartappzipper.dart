import 'dart:io';
import 'package:args/args.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive_io.dart';

const String dotpackages = '.packages';
const String pubcache = 'pub-cache';
final String cacheSep = Platform.isWindows ? '/Pub/Cache/' : '/.$pubcache/';
final String fileScheme = Platform.isWindows ? 'file:///' : 'file://';

class PkgUri {
  PkgUri(this.name, this.uri);
  String name;
  Uri uri;
}

ArgResults getArgResults(List<String> arguments) {
  ArgResults r;
  final parser = ArgParser();
  parser.addOption('target', defaultsTo: '.', help: 'A directory where pubspec.yaml exists.');
  parser.addFlag('dev', defaultsTo: true, help: 'Whether to include dev dependencies.');
  parser.addFlag('help', abbr: 'h', negatable: false, defaultsTo: false);
  try {
    r = parser.parse(arguments);
    if (r['help']) _exit('${parser.usage}');
  } on ArgParserException catch (e) {
    _exit('${e.message}\n${parser.usage}', code: 2);
  }
  return r;
}

Directory getTargetDir(ArgResults argr) {
  final targetdir = Directory(argr['target']);
  final pubspecYaml = _pubspecYaml(targetdir);
  if (!pubspecYaml.existsSync()) _exit('${pubspecYaml.path} is not found.', code: 2);
  return targetdir;
}

Pubspec getPubspec(Directory targetdir) {
  Pubspec pubspec;
  try {
    final yaml = _pubspecYaml(targetdir).readAsStringSync();
    pubspec = Pubspec.parse(yaml);
  } on Exception catch (e) {
    _exit(e.toString(), code: 2);
  }
  return pubspec;
}

List<String> getPkgNames(Directory targetdir, ArgResults argr) {
  final rslt = Process.runSync(
    'pub',
    ['deps', (argr['dev'] ? '--dev' : '--no-dev'), '--style', 'compact'],
    workingDirectory: targetdir.path,
    runInShell: true,
  );
  final deps = rslt.stdout
      .toString()
      .split('\n')
      .where((_) => _.startsWith('- '))
      .map((_) => _.split(' ').elementAt(1));
  return deps.toList();
}

List<PkgUri> getCachedPkgURIs(Directory targetdir, List<String> pkgnames) {
  final pkguris = <PkgUri>[];
  final dpf = File(path.join(targetdir.path, dotpackages)).readAsLinesSync();
  for (final pkgname in pkgnames) {
    final targetline = dpf.firstWhere((_) => _.split(':').first == pkgname);
    final targeturi = Uri.directory(
      targetline.split(fileScheme).last,
    );
    pkguris.add(PkgUri(pkgname, targeturi));
  }
  return pkguris;
}

Future<void> createZipFile(
    String name, Version version, Directory targetdir, List<PkgUri> pkguris) async {
  final encoder = ZipFileEncoder();
  try {
    encoder.create('$name-${version ?? '0.0.0'}.zip');

    // Zip the target package.
    await targetdir.list(recursive: true, followLinks: false).forEach((f) {
      if (f.statSync().type != FileSystemEntityType.file) return;
      if (f.uri.pathSegments.any((_) => _.startsWith('.'))) return;
      if (f.uri.pathSegments.any((_) => _.contains('packages'))) return;
      if (f.uri.pathSegments.any((_) => _.contains('web'))) return;
      if (f.uri.pathSegments.any((_) => _.contains(encoder.zip_path))) return;
      encoder.addFile(f, f.path.replaceFirst('${targetdir.path}${path.separator}', ''));
    });

    // Zip the cached packages.
    for (final pkguri in pkguris) {
      await Directory.fromUri(pkguri.uri).list(recursive: true, followLinks: false).forEach((f) {
        if (f.statSync().type != FileSystemEntityType.file) return;
        final fn = f.path.split(cacheSep).last;
        encoder.addFile(f, '$pubcache/$fn');
      });
    }

    // Zip the .packages file.
    final dotpkg = <String>[];
    for (final pkguri in pkguris) {
      final libpath = pkguri.uri.path.split(cacheSep).last;
      dotpkg.add('${pkguri.name}:$pubcache/$libpath');
    }
    dotpkg.add(File(path.join(targetdir.path, dotpackages)).readAsLinesSync().last);
    final tmpdir = Directory.systemTemp.createTempSync(name);
    final dotpkgf = File(path.join(tmpdir.path, dotpackages));
    dotpkgf.writeAsStringSync(dotpkg.join('\n'));
    encoder.addFile(dotpkgf, dotpackages);
    tmpdir.deleteSync(recursive: true);

    encoder.close();
    print('created ${encoder.zip_path}');
  } on Exception catch (e) {
    File(encoder.zip_path).deleteSync();
    _exit(e.toString(), code: 2);
  }
}

File _pubspecYaml(Directory targetdir) {
  return File(path.join(targetdir.path, 'pubspec.yaml'));
}

void _exit(String msg, {int code = 0}) {
  print(msg);
  exit(code);
}
