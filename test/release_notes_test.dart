import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/app_release_store.dart';

/// Guards `assets/release_notes.json`: every APK must ship notes for its own version.
void main() {
  final raw = jsonDecode(File('assets/release_notes.json').readAsStringSync()) as List;
  final releases = raw.map((e) => AppVersion.fromJson(e as Map<String, dynamic>)).toList();

  test('pubspec version has a release-notes entry', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final m = RegExp(r'^version:\s*([\d.]+)\+(\d+)', multiLine: true).firstMatch(pubspec)!;
    final version = m.group(1)!;
    final build = int.parse(m.group(2)!);

    final entry = releases.where((r) => r.version == version);
    expect(entry, isNotEmpty,
        reason: 'pubspec.yaml is at $version but assets/release_notes.json has no entry for it — '
            'add an "AQPConnect-$version-release" entry before building the APK.');
    expect(entry.first.buildNumber, build, reason: 'buildNumber must match pubspec.yaml (+$build)');
  });

  test('every entry is well-formed', () {
    final versions = <String>{};
    for (final r in releases) {
      expect(versions.add(r.version), isTrue, reason: 'duplicate version ${r.version}');
      expect(r.name, 'AQPConnect-${r.version}-release');
      expect(r.teaser.vi, isNotEmpty, reason: '${r.name} needs a teaser');
      expect(r.sections, isNotEmpty, reason: '${r.name} needs at least one section');
      for (final s in r.sections) {
        for (final item in s.items) {
          expect(item.vi, isNotEmpty);
        }
      }
    }
  });

  test('versions sort numerically, newest first', () {
    AppVersion v(String version) => AppVersion.fromJson({'version': version});
    final sorted = [v('1.9.0'), v('1.10.0'), v('1.0.8')]..sort(compareReleases);
    expect(sorted.map((r) => r.version).toList(), ['1.10.0', '1.9.0', '1.0.8']);
  });
}
