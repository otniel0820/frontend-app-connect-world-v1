// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epg_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EpgItemImpl _$$EpgItemImplFromJson(Map<String, dynamic> json) =>
    _$EpgItemImpl(
      channelId: json['channelId'] as String,
      title: json['title'] as String,
      start: DateTime.parse(json['start'] as String),
      stop: DateTime.parse(json['stop'] as String),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$EpgItemImplToJson(_$EpgItemImpl instance) =>
    <String, dynamic>{
      'channelId': instance.channelId,
      'title': instance.title,
      'start': instance.start.toIso8601String(),
      'stop': instance.stop.toIso8601String(),
      'description': instance.description,
    };
