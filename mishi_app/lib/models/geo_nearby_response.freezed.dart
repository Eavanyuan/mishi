// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'geo_nearby_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GeoNearbyResponse _$GeoNearbyResponseFromJson(Map<String, dynamic> json) {
  return _GeoNearbyResponse.fromJson(json);
}

/// @nodoc
mixin _$GeoNearbyResponse {
  List<POI> get items => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_count')
  int get totalCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'limit')
  int get limit => throw _privateConstructorUsedError;
  @JsonKey(name: 'offset')
  int get offset => throw _privateConstructorUsedError;

  /// Serializes this GeoNearbyResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GeoNearbyResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GeoNearbyResponseCopyWith<GeoNearbyResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GeoNearbyResponseCopyWith<$Res> {
  factory $GeoNearbyResponseCopyWith(
    GeoNearbyResponse value,
    $Res Function(GeoNearbyResponse) then,
  ) = _$GeoNearbyResponseCopyWithImpl<$Res, GeoNearbyResponse>;
  @useResult
  $Res call({
    List<POI> items,
    @JsonKey(name: 'total_count') int totalCount,
    @JsonKey(name: 'limit') int limit,
    @JsonKey(name: 'offset') int offset,
  });
}

/// @nodoc
class _$GeoNearbyResponseCopyWithImpl<$Res, $Val extends GeoNearbyResponse>
    implements $GeoNearbyResponseCopyWith<$Res> {
  _$GeoNearbyResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GeoNearbyResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? totalCount = null,
    Object? limit = null,
    Object? offset = null,
  }) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<POI>,
            totalCount: null == totalCount
                ? _value.totalCount
                : totalCount // ignore: cast_nullable_to_non_nullable
                      as int,
            limit: null == limit
                ? _value.limit
                : limit // ignore: cast_nullable_to_non_nullable
                      as int,
            offset: null == offset
                ? _value.offset
                : offset // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GeoNearbyResponseImplCopyWith<$Res>
    implements $GeoNearbyResponseCopyWith<$Res> {
  factory _$$GeoNearbyResponseImplCopyWith(
    _$GeoNearbyResponseImpl value,
    $Res Function(_$GeoNearbyResponseImpl) then,
  ) = __$$GeoNearbyResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<POI> items,
    @JsonKey(name: 'total_count') int totalCount,
    @JsonKey(name: 'limit') int limit,
    @JsonKey(name: 'offset') int offset,
  });
}

/// @nodoc
class __$$GeoNearbyResponseImplCopyWithImpl<$Res>
    extends _$GeoNearbyResponseCopyWithImpl<$Res, _$GeoNearbyResponseImpl>
    implements _$$GeoNearbyResponseImplCopyWith<$Res> {
  __$$GeoNearbyResponseImplCopyWithImpl(
    _$GeoNearbyResponseImpl _value,
    $Res Function(_$GeoNearbyResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GeoNearbyResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? totalCount = null,
    Object? limit = null,
    Object? offset = null,
  }) {
    return _then(
      _$GeoNearbyResponseImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<POI>,
        totalCount: null == totalCount
            ? _value.totalCount
            : totalCount // ignore: cast_nullable_to_non_nullable
                  as int,
        limit: null == limit
            ? _value.limit
            : limit // ignore: cast_nullable_to_non_nullable
                  as int,
        offset: null == offset
            ? _value.offset
            : offset // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GeoNearbyResponseImpl implements _GeoNearbyResponse {
  const _$GeoNearbyResponseImpl({
    required final List<POI> items,
    @JsonKey(name: 'total_count') required this.totalCount,
    @JsonKey(name: 'limit') required this.limit,
    @JsonKey(name: 'offset') required this.offset,
  }) : _items = items;

  factory _$GeoNearbyResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$GeoNearbyResponseImplFromJson(json);

  final List<POI> _items;
  @override
  List<POI> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey(name: 'total_count')
  final int totalCount;
  @override
  @JsonKey(name: 'limit')
  final int limit;
  @override
  @JsonKey(name: 'offset')
  final int offset;

  @override
  String toString() {
    return 'GeoNearbyResponse(items: $items, totalCount: $totalCount, limit: $limit, offset: $offset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GeoNearbyResponseImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.offset, offset) || other.offset == offset));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    totalCount,
    limit,
    offset,
  );

  /// Create a copy of GeoNearbyResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GeoNearbyResponseImplCopyWith<_$GeoNearbyResponseImpl> get copyWith =>
      __$$GeoNearbyResponseImplCopyWithImpl<_$GeoNearbyResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GeoNearbyResponseImplToJson(this);
  }
}

abstract class _GeoNearbyResponse implements GeoNearbyResponse {
  const factory _GeoNearbyResponse({
    required final List<POI> items,
    @JsonKey(name: 'total_count') required final int totalCount,
    @JsonKey(name: 'limit') required final int limit,
    @JsonKey(name: 'offset') required final int offset,
  }) = _$GeoNearbyResponseImpl;

  factory _GeoNearbyResponse.fromJson(Map<String, dynamic> json) =
      _$GeoNearbyResponseImpl.fromJson;

  @override
  List<POI> get items;
  @override
  @JsonKey(name: 'total_count')
  int get totalCount;
  @override
  @JsonKey(name: 'limit')
  int get limit;
  @override
  @JsonKey(name: 'offset')
  int get offset;

  /// Create a copy of GeoNearbyResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GeoNearbyResponseImplCopyWith<_$GeoNearbyResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
