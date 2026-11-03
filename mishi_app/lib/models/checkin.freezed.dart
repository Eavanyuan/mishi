// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checkin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Checkin _$CheckinFromJson(Map<String, dynamic> json) {
  return _Checkin.fromJson(json);
}

/// @nodoc
mixin _$Checkin {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'poi_id')
  String get poiId => throw _privateConstructorUsedError;
  @JsonKey(name: 'poem_id')
  String get poemId => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'checkin_time')
  DateTime get checkinTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'device_info')
  Map<String, dynamic>? get deviceInfo => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_score')
  double get riskScore => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Checkin to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Checkin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CheckinCopyWith<Checkin> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CheckinCopyWith<$Res> {
  factory $CheckinCopyWith(Checkin value, $Res Function(Checkin) then) =
      _$CheckinCopyWithImpl<$Res, Checkin>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'poi_id') String poiId,
    @JsonKey(name: 'poem_id') String poemId,
    double latitude,
    double longitude,
    @JsonKey(name: 'checkin_time') DateTime checkinTime,
    @JsonKey(name: 'device_info') Map<String, dynamic>? deviceInfo,
    @JsonKey(name: 'risk_score') double riskScore,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$CheckinCopyWithImpl<$Res, $Val extends Checkin>
    implements $CheckinCopyWith<$Res> {
  _$CheckinCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Checkin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? poiId = null,
    Object? poemId = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? checkinTime = null,
    Object? deviceInfo = freezed,
    Object? riskScore = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            poiId: null == poiId
                ? _value.poiId
                : poiId // ignore: cast_nullable_to_non_nullable
                      as String,
            poemId: null == poemId
                ? _value.poemId
                : poemId // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
            checkinTime: null == checkinTime
                ? _value.checkinTime
                : checkinTime // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            deviceInfo: freezed == deviceInfo
                ? _value.deviceInfo
                : deviceInfo // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            riskScore: null == riskScore
                ? _value.riskScore
                : riskScore // ignore: cast_nullable_to_non_nullable
                      as double,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CheckinImplCopyWith<$Res> implements $CheckinCopyWith<$Res> {
  factory _$$CheckinImplCopyWith(
    _$CheckinImpl value,
    $Res Function(_$CheckinImpl) then,
  ) = __$$CheckinImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'poi_id') String poiId,
    @JsonKey(name: 'poem_id') String poemId,
    double latitude,
    double longitude,
    @JsonKey(name: 'checkin_time') DateTime checkinTime,
    @JsonKey(name: 'device_info') Map<String, dynamic>? deviceInfo,
    @JsonKey(name: 'risk_score') double riskScore,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$CheckinImplCopyWithImpl<$Res>
    extends _$CheckinCopyWithImpl<$Res, _$CheckinImpl>
    implements _$$CheckinImplCopyWith<$Res> {
  __$$CheckinImplCopyWithImpl(
    _$CheckinImpl _value,
    $Res Function(_$CheckinImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Checkin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? poiId = null,
    Object? poemId = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? checkinTime = null,
    Object? deviceInfo = freezed,
    Object? riskScore = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$CheckinImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        poiId: null == poiId
            ? _value.poiId
            : poiId // ignore: cast_nullable_to_non_nullable
                  as String,
        poemId: null == poemId
            ? _value.poemId
            : poemId // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
        checkinTime: null == checkinTime
            ? _value.checkinTime
            : checkinTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        deviceInfo: freezed == deviceInfo
            ? _value._deviceInfo
            : deviceInfo // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        riskScore: null == riskScore
            ? _value.riskScore
            : riskScore // ignore: cast_nullable_to_non_nullable
                  as double,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CheckinImpl implements _Checkin {
  const _$CheckinImpl({
    required this.id,
    @JsonKey(name: 'user_id') required this.userId,
    @JsonKey(name: 'poi_id') required this.poiId,
    @JsonKey(name: 'poem_id') required this.poemId,
    required this.latitude,
    required this.longitude,
    @JsonKey(name: 'checkin_time') required this.checkinTime,
    @JsonKey(name: 'device_info') final Map<String, dynamic>? deviceInfo,
    @JsonKey(name: 'risk_score') this.riskScore = 0.0,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  }) : _deviceInfo = deviceInfo;

  factory _$CheckinImpl.fromJson(Map<String, dynamic> json) =>
      _$$CheckinImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'poi_id')
  final String poiId;
  @override
  @JsonKey(name: 'poem_id')
  final String poemId;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  @JsonKey(name: 'checkin_time')
  final DateTime checkinTime;
  final Map<String, dynamic>? _deviceInfo;
  @override
  @JsonKey(name: 'device_info')
  Map<String, dynamic>? get deviceInfo {
    final value = _deviceInfo;
    if (value == null) return null;
    if (_deviceInfo is EqualUnmodifiableMapView) return _deviceInfo;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'risk_score')
  final double riskScore;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Checkin(id: $id, userId: $userId, poiId: $poiId, poemId: $poemId, latitude: $latitude, longitude: $longitude, checkinTime: $checkinTime, deviceInfo: $deviceInfo, riskScore: $riskScore, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CheckinImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.poiId, poiId) || other.poiId == poiId) &&
            (identical(other.poemId, poemId) || other.poemId == poemId) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.checkinTime, checkinTime) ||
                other.checkinTime == checkinTime) &&
            const DeepCollectionEquality().equals(
              other._deviceInfo,
              _deviceInfo,
            ) &&
            (identical(other.riskScore, riskScore) ||
                other.riskScore == riskScore) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    poiId,
    poemId,
    latitude,
    longitude,
    checkinTime,
    const DeepCollectionEquality().hash(_deviceInfo),
    riskScore,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Checkin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CheckinImplCopyWith<_$CheckinImpl> get copyWith =>
      __$$CheckinImplCopyWithImpl<_$CheckinImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CheckinImplToJson(this);
  }
}

abstract class _Checkin implements Checkin {
  const factory _Checkin({
    required final String id,
    @JsonKey(name: 'user_id') required final String userId,
    @JsonKey(name: 'poi_id') required final String poiId,
    @JsonKey(name: 'poem_id') required final String poemId,
    required final double latitude,
    required final double longitude,
    @JsonKey(name: 'checkin_time') required final DateTime checkinTime,
    @JsonKey(name: 'device_info') final Map<String, dynamic>? deviceInfo,
    @JsonKey(name: 'risk_score') final double riskScore,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$CheckinImpl;

  factory _Checkin.fromJson(Map<String, dynamic> json) = _$CheckinImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'poi_id')
  String get poiId;
  @override
  @JsonKey(name: 'poem_id')
  String get poemId;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  @JsonKey(name: 'checkin_time')
  DateTime get checkinTime;
  @override
  @JsonKey(name: 'device_info')
  Map<String, dynamic>? get deviceInfo;
  @override
  @JsonKey(name: 'risk_score')
  double get riskScore;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of Checkin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CheckinImplCopyWith<_$CheckinImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
