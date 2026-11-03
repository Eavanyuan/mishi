// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poem_detail_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PoemDetailResponse _$PoemDetailResponseFromJson(Map<String, dynamic> json) {
  return _PoemDetailResponse.fromJson(json);
}

/// @nodoc
mixin _$PoemDetailResponse {
  Poem get data => throw _privateConstructorUsedError;

  /// Serializes this PoemDetailResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PoemDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PoemDetailResponseCopyWith<PoemDetailResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PoemDetailResponseCopyWith<$Res> {
  factory $PoemDetailResponseCopyWith(
    PoemDetailResponse value,
    $Res Function(PoemDetailResponse) then,
  ) = _$PoemDetailResponseCopyWithImpl<$Res, PoemDetailResponse>;
  @useResult
  $Res call({Poem data});

  $PoemCopyWith<$Res> get data;
}

/// @nodoc
class _$PoemDetailResponseCopyWithImpl<$Res, $Val extends PoemDetailResponse>
    implements $PoemDetailResponseCopyWith<$Res> {
  _$PoemDetailResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PoemDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null}) {
    return _then(
      _value.copyWith(
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as Poem,
          )
          as $Val,
    );
  }

  /// Create a copy of PoemDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PoemCopyWith<$Res> get data {
    return $PoemCopyWith<$Res>(_value.data, (value) {
      return _then(_value.copyWith(data: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PoemDetailResponseImplCopyWith<$Res>
    implements $PoemDetailResponseCopyWith<$Res> {
  factory _$$PoemDetailResponseImplCopyWith(
    _$PoemDetailResponseImpl value,
    $Res Function(_$PoemDetailResponseImpl) then,
  ) = __$$PoemDetailResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Poem data});

  @override
  $PoemCopyWith<$Res> get data;
}

/// @nodoc
class __$$PoemDetailResponseImplCopyWithImpl<$Res>
    extends _$PoemDetailResponseCopyWithImpl<$Res, _$PoemDetailResponseImpl>
    implements _$$PoemDetailResponseImplCopyWith<$Res> {
  __$$PoemDetailResponseImplCopyWithImpl(
    _$PoemDetailResponseImpl _value,
    $Res Function(_$PoemDetailResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PoemDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null}) {
    return _then(
      _$PoemDetailResponseImpl(
        data: null == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as Poem,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PoemDetailResponseImpl implements _PoemDetailResponse {
  const _$PoemDetailResponseImpl({required this.data});

  factory _$PoemDetailResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$PoemDetailResponseImplFromJson(json);

  @override
  final Poem data;

  @override
  String toString() {
    return 'PoemDetailResponse(data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PoemDetailResponseImpl &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, data);

  /// Create a copy of PoemDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PoemDetailResponseImplCopyWith<_$PoemDetailResponseImpl> get copyWith =>
      __$$PoemDetailResponseImplCopyWithImpl<_$PoemDetailResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PoemDetailResponseImplToJson(this);
  }
}

abstract class _PoemDetailResponse implements PoemDetailResponse {
  const factory _PoemDetailResponse({required final Poem data}) =
      _$PoemDetailResponseImpl;

  factory _PoemDetailResponse.fromJson(Map<String, dynamic> json) =
      _$PoemDetailResponseImpl.fromJson;

  @override
  Poem get data;

  /// Create a copy of PoemDetailResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PoemDetailResponseImplCopyWith<_$PoemDetailResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
