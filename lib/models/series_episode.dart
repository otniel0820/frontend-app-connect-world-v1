/// A single streamable episode within a series.
class SeriesEpisode {
  final String id; // stream ID — use this with /stream/{id}
  final String title;
  final int season;
  final int episode;
  final String? overview;
  final String? coverUrl;
  final int? durationSecs;

  const SeriesEpisode({
    required this.id,
    required this.title,
    required this.season,
    required this.episode,
    this.overview,
    this.coverUrl,
    this.durationSecs,
  });

  factory SeriesEpisode.fromJson(Map<String, dynamic> json) {
    return SeriesEpisode(
      id: json['id']?.toString() ??
          json['streamId']?.toString() ??
          json['stream_id']?.toString() ??
          json['episodeId']?.toString() ??
          json['episode_id']?.toString() ??
          json['vid']?.toString() ??
          json['num']?.toString() ??
          '',
      title: json['title']?.toString() ??
          json['name']?.toString() ??
          json['ep_title']?.toString() ??
          json['episode_title']?.toString() ??
          'Episodio',
      season: (json['season'] as num?)?.toInt() ??
          (json['seasonNum'] as num?)?.toInt() ??
          (json['season_num'] as num?)?.toInt() ??
          (json['season_number'] as num?)?.toInt() ??
          _parseIntField(json['s']) ??
          1,
      episode: (json['episode'] as num?)?.toInt() ??
          (json['episodeNum'] as num?)?.toInt() ??
          (json['episode_num'] as num?)?.toInt() ??
          (json['episode_number'] as num?)?.toInt() ??
          _parseIntField(json['e']) ??
          _parseIntField(json['ep']) ??
          1,
      overview: json['overview']?.toString() ??
          json['plot']?.toString() ??
          json['info']?.toString() ??
          json['description']?.toString() ??
          json['desc']?.toString(),
      coverUrl: json['coverUrl']?.toString() ??
          json['cover']?.toString() ??
          json['posterUrl']?.toString() ??
          json['still_path']?.toString() ??
          json['img']?.toString() ??
          json['image']?.toString() ??
          json['thumbnail']?.toString(),
      durationSecs: (json['durationSecs'] as num?)?.toInt() ??
          (json['duration_secs'] as num?)?.toInt() ??
          (json['duration'] != null
              ? int.tryParse(json['duration'].toString())
              : null),
    );
  }

  /// Parses a value that may be an [int], [double], or numeric [String].
  static int? _parseIntField(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  String get durationLabel {
    if (durationSecs == null || durationSecs! <= 0) return '';
    final m = (durationSecs! ~/ 60).toString().padLeft(2, '0');
    final s = (durationSecs! % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
