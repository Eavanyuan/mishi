// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poem_recommendation_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PoemRecommendationResponse _$PoemRecommendationResponseFromJson(
  Map<String, dynamic> json,
) {
  return _PoemRecommendationResponse.fromJson(json);
}

/// @nodoc
mixin _$PoemRecommendationResponse {
  List<Poem> get items => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_count')
  int get totalCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'limit')
  int get limit => throw _privateConstructorUsedError;
  @JsonKey(name: 'offset')
  int get offset => throw _privateConstructorUsedError;

  /// Serializes this PoemRecommendationResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PoemRecommendationResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PoemRecommendationResponseCopyWith<PoemRecommendationResponse>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PoemRecommendationResponseCopyWith<$Res> {
  factory $PoemRecommendationResponseCopyWith(
    PoemRecommendationResponse value,
    $Res Function(PoemRecommendationResponse) then,
  ) =
      _$PoemRecommendationResponseCopyWithImpl<
        $Res,
        PoemRecommendationResponse
      >;
  @useResult
  $Res call({
    List<Poem> items,
    @JsonKey(name: 'total_count') int totalCount,
    @JsonKey(name: 'limit') int limit,
    @JsonKey(name: 'offset') int offset,
  });
}

/// @nodoc
class _$PoemRecommendationResponseCopyWithImpl<
  $Res,
  $Val extends PoemRecommendationResponse
>
    implements $PoemRecommendationResponseCopyWith<$Res> {
  _$PoemRecommendationResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PoemRecommendationResponse
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
                      as List<Poem>,
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
abstract class _$$PoemRecommendationResponseImplCopyWith<$Res>
    implements $PoemRecommendationResponseCopyWith<$Res> {
  factory _$$PoemRecommendationResponseImplCopyWith(
    _$PoemRecommendationResponseImpl value,
    $Res Function(_$PoemRecommendationResponseImpl) then,
  ) = __$$PoemRecommendationResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Poem> items,
    @JsonKey(name: 'total_count') int totalCount,
    @JsonKey(name: 'limit') int limit,
    @JsonKey(name: 'offset') int offset,
  });
}

/// @nodoc
class __$$PoemRecommendationResponseImplCopyWithImpl<$Res>
    extends
        _$PoemRecommendationResponseCopyWithImpl<
          $Res,
          _$PoemRecommendationResponseImpl
        >
    implements _$$PoemRecommendationResponseImplCopyWith<$Res> {
  __$$PoemRecommendationResponseImplCopyWithImpl(
    _$PoemRecommendationResponseImpl _value,
    $Res Function(_$PoemRecommendationResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PoemRecommendationResponse
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
      _$PoemRecommendationResponseImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<Poem>,
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
class _$PoemRecommendationResponseImpl implements _PoemRecommendationResponse {
  const _$PoemRecommendationResponseImpl({
    required final List<Poem> items,
    @JsonKey(name: 'total_count') required this.totalCount,
    @JsonKey(name: 'limit') required this.limit,
    @JsonKey(name: 'offset') required this.offset,
  }) : _items = items;

  factory _$PoemRecommendationResponseImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$PoemRecommendationResponseImplFromJson(json);

  final List<Poem> _items;
  @override
  List<Poem> get items {
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
    return 'PoemRecommendationResponse(items: $items, totalCount: $totalCount, limit: $limit, offset: $offset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PoemRecommendationResponseImpl &&
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

  /// Create a copy of PoemRecommendationResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PoemRecommendationResponseImplCopyWith<_$PoemRecommendationResponseImpl>
  get copyWith =>
      __$$PoemRecommendationResponseImplCopyWithImpl<
        _$PoemRecommendationResponseImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PoemRecommendationResponseImplToJson(this);
  }
}

abstract class _PoemRecommendationResponse
    implements PoemRecommendationResponse {
  const factory _PoemRecommendationResponse({
    required final List<Poem> items,
    @JsonKey(name: 'total_count') required final int totalCount,
    @JsonKey(name: 'limit') required final int limit,
    @JsonKey(name: 'offset') required final int offset,
  }) = _$PoemRecommendationResponseImpl;

  factory _PoemRecommendationResponse.fromJson(Map<String, dynamic> json) =
      _$PoemRecommendationResponseImpl.fromJson;

  @override
  List<Poem> get items;
  @override
  @JsonKey(name: 'total_count')
  int get totalCount;
  @override
  @JsonKey(name: 'limit')
  int get limit;
  @override
  @JsonKey(name: 'offset')
  int get offset;

  /// Create a copy of PoemRecommendationResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PoemRecommendationResponseImplCopyWith<_$PoemRecommendationResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}
