// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poi.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

POI _$POIFromJson(Map<String, dynamic> json) {
  return _POI.fromJson(json);
}

/// @nodoc
mixin _$POI {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'ancient_name')
  String? get ancientName => throw _privateConstructorUsedError;
  @JsonKey(name: 'modern_name')
  String? get modernName => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  double get radius => throw _privateConstructorUsedError;
  @JsonKey(name: 'city_code')
  String? get cityCode => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  List<String>? get categories => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this POI to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of POI
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $POICopyWith<POI> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $POICopyWith<$Res> {
  factory $POICopyWith(POI value, $Res Function(POI) then) =
      _$POICopyWithImpl<$Res, POI>;
  @useResult
  $Res call({
    String id,
    String name,
    @JsonKey(name: 'ancient_name') String? ancientName,
    @JsonKey(name: 'modern_name') String? modernName,
    double latitude,
    double longitude,
    double radius,
    @JsonKey(name: 'city_code') String? cityCode,
    String? description,
    List<String>? categories,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$POICopyWithImpl<$Res, $Val extends POI> implements $POICopyWith<$Res> {
  _$POICopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of POI
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? ancientName = freezed,
    Object? modernName = freezed,
    Object? latitude = null,
    Object? longitude = null,
    Object? radius = null,
    Object? cityCode = freezed,
    Object? description = freezed,
    Object? categories = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            ancientName: freezed == ancientName
                ? _value.ancientName
                : ancientName // ignore: cast_nullable_to_non_nullable
                      as String?,
            modernName: freezed == modernName
                ? _value.modernName
                : modernName // ignore: cast_nullable_to_non_nullable
                      as String?,
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
            radius: null == radius
                ? _value.radius
                : radius // ignore: cast_nullable_to_non_nullable
                      as double,
            cityCode: freezed == cityCode
                ? _value.cityCode
                : cityCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            categories: freezed == categories
                ? _value.categories
                : categories // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
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
abstract class _$$POIImplCopyWith<$Res> implements $POICopyWith<$Res> {
  factory _$$POIImplCopyWith(_$POIImpl value, $Res Function(_$POIImpl) then) =
      __$$POIImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    @JsonKey(name: 'ancient_name') String? ancientName,
    @JsonKey(name: 'modern_name') String? modernName,
    double latitude,
    double longitude,
    double radius,
    @JsonKey(name: 'city_code') String? cityCode,
    String? description,
    List<String>? categories,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$POIImplCopyWithImpl<$Res> extends _$POICopyWithImpl<$Res, _$POIImpl>
    implements _$$POIImplCopyWith<$Res> {
  __$$POIImplCopyWithImpl(_$POIImpl _value, $Res Function(_$POIImpl) _then)
    : super(_value, _then);

  /// Create a copy of POI
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? ancientName = freezed,
    Object? modernName = freezed,
    Object? latitude = null,
    Object? longitude = null,
    Object? radius = null,
    Object? cityCode = freezed,
    Object? description = freezed,
    Object? categories = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$POIImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        ancientName: freezed == ancientName
            ? _value.ancientName
            : ancientName // ignore: cast_nullable_to_non_nullable
                  as String?,
        modernName: freezed == modernName
            ? _value.modernName
            : modernName // ignore: cast_nullable_to_non_nullable
                  as String?,
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
        radius: null == radius
            ? _value.radius
            : radius // ignore: cast_nullable_to_non_nullable
                  as double,
        cityCode: freezed == cityCode
            ? _value.cityCode
            : cityCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        categories: freezed == categories
            ? _value._categories
            : categories // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
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
class _$POIImpl implements _POI {
  const _$POIImpl({
    required this.id,
    required this.name,
    @JsonKey(name: 'ancient_name') this.ancientName,
    @JsonKey(name: 'modern_name') this.modernName,
    required this.latitude,
    required this.longitude,
    this.radius = 100.0,
    @JsonKey(name: 'city_code') this.cityCode,
    this.description,
    final List<String>? categories,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  }) : _categories = categories;

  factory _$POIImpl.fromJson(Map<String, dynamic> json) =>
      _$$POIImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey(name: 'ancient_name')
  final String? ancientName;
  @override
  @JsonKey(name: 'modern_name')
  final String? modernName;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  @JsonKey()
  final double radius;
  @override
  @JsonKey(name: 'city_code')
  final String? cityCode;
  @override
  final String? description;
  final List<String>? _categories;
  @override
  List<String>? get categories {
    final value = _categories;
    if (value == null) return null;
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'POI(id: $id, name: $name, ancientName: $ancientName, modernName: $modernName, latitude: $latitude, longitude: $longitude, radius: $radius, cityCode: $cityCode, description: $description, categories: $categories, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$POIImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.ancientName, ancientName) ||
                other.ancientName == ancientName) &&
            (identical(other.modernName, modernName) ||
                other.modernName == modernName) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.radius, radius) || other.radius == radius) &&
            (identical(other.cityCode, cityCode) ||
                other.cityCode == cityCode) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(
              other._categories,
              _categories,
            ) &&
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
    name,
    ancientName,
    modernName,
    latitude,
    longitude,
    radius,
    cityCode,
    description,
    const DeepCollectionEquality().hash(_categories),
    createdAt,
    updatedAt,
  );

  /// Create a copy of POI
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$POIImplCopyWith<_$POIImpl> get copyWith =>
      __$$POIImplCopyWithImpl<_$POIImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$POIImplToJson(this);
  }
}

abstract class _POI implements POI {
  const factory _POI({
    required final String id,
    required final String name,
    @JsonKey(name: 'ancient_name') final String? ancientName,
    @JsonKey(name: 'modern_name') final String? modernName,
    required final double latitude,
    required final double longitude,
    final double radius,
    @JsonKey(name: 'city_code') final String? cityCode,
    final String? description,
    final List<String>? categories,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$POIImpl;

  factory _POI.fromJson(Map<String, dynamic> json) = _$POIImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'ancient_name')
  String? get ancientName;
  @override
  @JsonKey(name: 'modern_name')
  String? get modernName;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  double get radius;
  @override
  @JsonKey(name: 'city_code')
  String? get cityCode;
  @override
  String? get description;
  @override
  List<String>? get categories;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of POI
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$POIImplCopyWith<_$POIImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
