import 'package:freezed_annotation/freezed_annotation.dart';

part 'epg_item.freezed.dart';
part 'epg_item.g.dart';

@freezed
class EpgItem with _$EpgItem {
  const factory EpgItem({
    required String channelId,
    required String title,
    required DateTime start,
    required DateTime stop,
    String? description,
  }) = _EpgItem;

  factory EpgItem.fromJson(Map<String, dynamic> json) => _$EpgItemFromJson(json);
}
