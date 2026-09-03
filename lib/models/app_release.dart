class AppRelease {
  final String version;
  final String notes;
  final String? apkUrl;
  final String htmlUrl;
  final String? minSupportedVersion;

  const AppRelease({
    required this.version,
    required this.notes,
    required this.apkUrl,
    required this.htmlUrl,
    required this.minSupportedVersion,
  });

  factory AppRelease.fromGithubJson(Map<String, dynamic> json) {
    final tag = (json['tag_name'] ?? '').toString();
    final body = (json['body'] ?? '').toString();
    final assets = (json['assets'] as List?) ?? const [];

    String? apkUrl;
    for (final asset in assets) {
      if (asset is! Map) continue;
      final name = (asset['name'] ?? '').toString().toLowerCase();
      if (name.endsWith('.apk')) {
        final url = (asset['browser_download_url'] ?? '').toString();
        if (url.isNotEmpty) apkUrl = url;
        break;
      }
    }

    final minMatch = RegExp(
      r'min[_-]?supported\s*[:=]\s*v?(\d+\.\d+\.\d+)',
      caseSensitive: false,
    ).firstMatch(body);

    return AppRelease(
      version: _stripV(tag),
      notes: _cleanNotes(body),
      apkUrl: apkUrl,
      htmlUrl: (json['html_url'] ?? '').toString(),
      minSupportedVersion: minMatch?.group(1),
    );
  }

  static String _stripV(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('v') || trimmed.startsWith('V')) {
      return trimmed.substring(1);
    }
    return trimmed;
  }

  static String _cleanNotes(String body) {
    return body
        .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
        .trim();
  }
}

class UpdateInfo {
  final AppRelease release;
  final String currentVersion;
  final bool isForced;

  const UpdateInfo({
    required this.release,
    required this.currentVersion,
    required this.isForced,
  });
}
