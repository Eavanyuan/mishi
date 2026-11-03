// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checkin_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CheckinResponse _$CheckinResponseFromJson(Map<String, dynamic> json) {
  return _CheckinResponse.fromJson(json);
}

/// @nodoc
mixin _$CheckinResponse {
  Checkin get data => throw _privateConstructorUsedError;

  /// Serializes this CheckinResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CheckinResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CheckinResponseCopyWith<CheckinResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CheckinResponseCopyWith<$Res> {
  factory $CheckinResponseCopyWith(
    CheckinResponse value,
    $Res Function(CheckinResponse) then,
  ) = _$CheckinResponseCopyWithImpl<$Res, CheckinResponse>;
  @useResult
  $Res call({Checkin data});

  $CheckinCopyWith<$Res> get data;
}

/// @nodoc
class _$CheckinResponseCopyWithImpl<$Res, $Val extends CheckinResponse>
    implements $CheckinResponseCopyWith<$Res> {
  _$CheckinResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CheckinResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null}) {
    return _then(
      _value.copyWith(
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as Checkin,
          )
          as $Val,
    );
  }

  /// Create a copy of CheckinResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CheckinCopyWith<$Res> get data {
    return $CheckinCopyWith<$Res>(_value.data, (value) {
      return _then(_value.copyWith(data: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CheckinResponseImplCopyWith<$Res>
    implements $CheckinResponseCopyWith<$Res> {
  factory _$$CheckinResponseImplCopyWith(
    _$CheckinResponseImpl value,
    $Res Function(_$CheckinResponseImpl) then,
  ) = __$$CheckinResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Checkin data});

  @override
  $CheckinCopyWith<$Res> get data;
}

/// @nodoc
class __$$CheckinResponseImplCopyWithImpl<$Res>
    extends _$CheckinResponseCopyWithImpl<$Res, _$CheckinResponseImpl>
    implements _$$CheckinResponseImplCopyWith<$Res> {
  __$$CheckinResponseImplCopyWithImpl(
    _$CheckinResponseImpl _value,
    $Res Function(_$CheckinResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CheckinResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null}) {
    return _then(
      _$CheckinResponseImpl(
        data: null == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as Checkin,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CheckinResponseImpl implements _CheckinResponse {
  const _$CheckinResponseImpl({required this.data});

  factory _$CheckinResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$CheckinResponseImplFromJson(json);

  @override
  final Checkin data;

  @override
  String toString() {
    return 'CheckinResponse(data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CheckinResponseImpl &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, data);

  /// Create a copy of CheckinResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CheckinResponseImplCopyWith<_$CheckinResponseImpl> get copyWith =>
      __$$CheckinResponseImplCopyWithImpl<_$CheckinResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CheckinResponseImplToJson(this);
  }
}

abstract class _CheckinResponse implements CheckinResponse {
  const factory _CheckinResponse({required final Checkin data}) =
      _$CheckinResponseImpl;

  factory _CheckinResponse.fromJson(Map<String, dynamic> json) =
      _$CheckinResponseImpl.fromJson;

  @override
  Checkin get data;

  /// Create a copy of CheckinResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CheckinResponseImplCopyWith<_$CheckinResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
