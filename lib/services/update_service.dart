import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_release.dart';

const _githubRepo = 'otniel0820/frontend-app-connect-world-v1';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(Dio());
});

class UpdateService {
  final Dio _dio;

  UpdateService(this._dio);

  Future<UpdateInfo?> checkForUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return null;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final current = packageInfo.version;

      final response = await _dio.get(
        'https://api.github.com/repos/$_githubRepo/releases/latest',
        options: Options(
          headers: {'Accept': 'application/vnd.github+json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final data = response.data;
      if (data is! Map) return null;

      final release = AppRelease.fromGithubJson(Map<String, dynamic>.from(data));
      if (release.apkUrl == null) return null;
      if (!_isNewer(release.version, current)) return null;

      final forced = release.minSupportedVersion != null &&
          _isNewer(release.minSupportedVersion!, current);

      return UpdateInfo(
        release: release,
        currentVersion: current,
        isForced: forced,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> downloadAndInstall(
    AppRelease release, {
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    final url = release.apkUrl;
    if (url == null) {
      throw StateError('La release no incluye un APK.');
    }

    final dir = await getExternalStorageDirectory() ??
        await getApplicationSupportDirectory();
    final path = '${dir.path}/connect-world-${release.version}.apk';

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    await _dio.download(
      url,
      path,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress(received / total);
      },
    );

    final result = await OpenFilex.open(
      path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw StateError(result.message);
    }
  }

  bool _isNewer(String candidate, String base) {
    final c = _parts(candidate);
    final b = _parts(base);
    for (var i = 0; i < 3; i++) {
      if (c[i] > b[i]) return true;
      if (c[i] < b[i]) return false;
    }
    return false;
  }

  List<int> _parts(String version) {
    final parts = version
        .split('+')
        .first
        .split('.')
        .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts;
  }
}
