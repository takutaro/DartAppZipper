import 'package:dartappzipper/dartappzipper.dart';

Future<void> main(List<String> arguments) async {
  final argr = getArgResults(arguments);
  final targetdir = getTargetDir(argr);
  final pubspec = getPubspec(targetdir);
  final pkgnames = getPkgNames(targetdir, argr);
  final uris = getCachedPkgURIs(targetdir, pkgnames);
  await createZipFile(pubspec.name, pubspec.version, targetdir, uris);
}
