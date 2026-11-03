// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poem.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Poem _$PoemFromJson(Map<String, dynamic> json) {
  return _Poem.fromJson(json);
}

/// @nodoc
mixin _$Poem {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get author => throw _privateConstructorUsedError;
  String get dynasty => throw _privateConstructorUsedError;
  List<String> get content => throw _privateConstructorUsedError;
  String? get relatedPoiId => throw _privateConstructorUsedError;
  String? get relatedPoiName => throw _privateConstructorUsedError;
  List<String>? get interpretations => throw _privateConstructorUsedError;
  List<String>? get bestSeasons => throw _privateConstructorUsedError;
  bool get hasAudio => throw _privateConstructorUsedError;
  String? get audioUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Poem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Poem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PoemCopyWith<Poem> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PoemCopyWith<$Res> {
  factory $PoemCopyWith(Poem value, $Res Function(Poem) then) =
      _$PoemCopyWithImpl<$Res, Poem>;
  @useResult
  $Res call({
    String id,
    String title,
    String author,
    String dynasty,
    List<String> content,
    String? relatedPoiId,
    String? relatedPoiName,
    List<String>? interpretations,
    List<String>? bestSeasons,
    bool hasAudio,
    String? audioUrl,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$PoemCopyWithImpl<$Res, $Val extends Poem>
    implements $PoemCopyWith<$Res> {
  _$PoemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Poem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? author = null,
    Object? dynasty = null,
    Object? content = null,
    Object? relatedPoiId = freezed,
    Object? relatedPoiName = freezed,
    Object? interpretations = freezed,
    Object? bestSeasons = freezed,
    Object? hasAudio = null,
    Object? audioUrl = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            author: null == author
                ? _value.author
                : author // ignore: cast_nullable_to_non_nullable
                      as String,
            dynasty: null == dynasty
                ? _value.dynasty
                : dynasty // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            relatedPoiId: freezed == relatedPoiId
                ? _value.relatedPoiId
                : relatedPoiId // ignore: cast_nullable_to_non_nullable
                      as String?,
            relatedPoiName: freezed == relatedPoiName
                ? _value.relatedPoiName
                : relatedPoiName // ignore: cast_nullable_to_non_nullable
                      as String?,
            interpretations: freezed == interpretations
                ? _value.interpretations
                : interpretations // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            bestSeasons: freezed == bestSeasons
                ? _value.bestSeasons
                : bestSeasons // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            hasAudio: null == hasAudio
                ? _value.hasAudio
                : hasAudio // ignore: cast_nullable_to_non_nullable
                      as bool,
            audioUrl: freezed == audioUrl
                ? _value.audioUrl
                : audioUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$PoemImplCopyWith<$Res> implements $PoemCopyWith<$Res> {
  factory _$$PoemImplCopyWith(
    _$PoemImpl value,
    $Res Function(_$PoemImpl) then,
  ) = __$$PoemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String author,
    String dynasty,
    List<String> content,
    String? relatedPoiId,
    String? relatedPoiName,
    List<String>? interpretations,
    List<String>? bestSeasons,
    bool hasAudio,
    String? audioUrl,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$PoemImplCopyWithImpl<$Res>
    extends _$PoemCopyWithImpl<$Res, _$PoemImpl>
    implements _$$PoemImplCopyWith<$Res> {
  __$$PoemImplCopyWithImpl(_$PoemImpl _value, $Res Function(_$PoemImpl) _then)
    : super(_value, _then);

  /// Create a copy of Poem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? author = null,
    Object? dynasty = null,
    Object? content = null,
    Object? relatedPoiId = freezed,
    Object? relatedPoiName = freezed,
    Object? interpretations = freezed,
    Object? bestSeasons = freezed,
    Object? hasAudio = null,
    Object? audioUrl = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$PoemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        author: null == author
            ? _value.author
            : author // ignore: cast_nullable_to_non_nullable
                  as String,
        dynasty: null == dynasty
            ? _value.dynasty
            : dynasty // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value._content
            : content // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        relatedPoiId: freezed == relatedPoiId
            ? _value.relatedPoiId
            : relatedPoiId // ignore: cast_nullable_to_non_nullable
                  as String?,
        relatedPoiName: freezed == relatedPoiName
            ? _value.relatedPoiName
            : relatedPoiName // ignore: cast_nullable_to_non_nullable
                  as String?,
        interpretations: freezed == interpretations
            ? _value._interpretations
            : interpretations // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        bestSeasons: freezed == bestSeasons
            ? _value._bestSeasons
            : bestSeasons // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        hasAudio: null == hasAudio
            ? _value.hasAudio
            : hasAudio // ignore: cast_nullable_to_non_nullable
                  as bool,
        audioUrl: freezed == audioUrl
            ? _value.audioUrl
            : audioUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$PoemImpl implements _Poem {
  const _$PoemImpl({
    required this.id,
    required this.title,
    required this.author,
    required this.dynasty,
    required final List<String> content,
    this.relatedPoiId,
    this.relatedPoiName,
    final List<String>? interpretations,
    final List<String>? bestSeasons,
    this.hasAudio = false,
    this.audioUrl,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  }) : _content = content,
       _interpretations = interpretations,
       _bestSeasons = bestSeasons;

  factory _$PoemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PoemImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String author;
  @override
  final String dynasty;
  final List<String> _content;
  @override
  List<String> get content {
    if (_content is EqualUnmodifiableListView) return _content;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_content);
  }

  @override
  final String? relatedPoiId;
  @override
  final String? relatedPoiName;
  final List<String>? _interpretations;
  @override
  List<String>? get interpretations {
    final value = _interpretations;
    if (value == null) return null;
    if (_interpretations is EqualUnmodifiableListView) return _interpretations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _bestSeasons;
  @override
  List<String>? get bestSeasons {
    final value = _bestSeasons;
    if (value == null) return null;
    if (_bestSeasons is EqualUnmodifiableListView) return _bestSeasons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final bool hasAudio;
  @override
  final String? audioUrl;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Poem(id: $id, title: $title, author: $author, dynasty: $dynasty, content: $content, relatedPoiId: $relatedPoiId, relatedPoiName: $relatedPoiName, interpretations: $interpretations, bestSeasons: $bestSeasons, hasAudio: $hasAudio, audioUrl: $audioUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PoemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.dynasty, dynasty) || other.dynasty == dynasty) &&
            const DeepCollectionEquality().equals(other._content, _content) &&
            (identical(other.relatedPoiId, relatedPoiId) ||
                other.relatedPoiId == relatedPoiId) &&
            (identical(other.relatedPoiName, relatedPoiName) ||
                other.relatedPoiName == relatedPoiName) &&
            const DeepCollectionEquality().equals(
              other._interpretations,
              _interpretations,
            ) &&
            const DeepCollectionEquality().equals(
              other._bestSeasons,
              _bestSeasons,
            ) &&
            (identical(other.hasAudio, hasAudio) ||
                other.hasAudio == hasAudio) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
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
    title,
    author,
    dynasty,
    const DeepCollectionEquality().hash(_content),
    relatedPoiId,
    relatedPoiName,
    const DeepCollectionEquality().hash(_interpretations),
    const DeepCollectionEquality().hash(_bestSeasons),
    hasAudio,
    audioUrl,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Poem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PoemImplCopyWith<_$PoemImpl> get copyWith =>
      __$$PoemImplCopyWithImpl<_$PoemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PoemImplToJson(this);
  }
}

abstract class _Poem implements Poem {
  const factory _Poem({
    required final String id,
    required final String title,
    required final String author,
    required final String dynasty,
    required final List<String> content,
    final String? relatedPoiId,
    final String? relatedPoiName,
    final List<String>? interpretations,
    final List<String>? bestSeasons,
    final bool hasAudio,
    final String? audioUrl,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$PoemImpl;

  factory _Poem.fromJson(Map<String, dynamic> json) = _$PoemImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get author;
  @override
  String get dynasty;
  @override
  List<String> get content;
  @override
  String? get relatedPoiId;
  @override
  String? get relatedPoiName;
  @override
  List<String>? get interpretations;
  @override
  List<String>? get bestSeasons;
  @override
  bool get hasAudio;
  @override
  String? get audioUrl;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of Poem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PoemImplCopyWith<_$PoemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
