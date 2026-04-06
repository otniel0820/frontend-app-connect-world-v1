// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      id: json['id'] as String,
      username: json['username'] as String,
      token: json['token'] as String,
      subscriptionType: json['subscriptionType'] as String? ?? 'active',
      expiresAt: json['expiresAt'] as String?,
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'token': instance.token,
      'subscriptionType': instance.subscriptionType,
      'expiresAt': instance.expiresAt,
    };
