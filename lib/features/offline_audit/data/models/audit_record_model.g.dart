// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_record_model.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetAuditRecordModelCollection on Isar {
  IsarCollection<int, AuditRecordModel> get auditRecordModels =>
      this.collection();
}

final AuditRecordModelSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'AuditRecordModel',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'scanCode', type: IsarType.string),
      IsarPropertySchema(name: 'aiDetectedLabel', type: IsarType.string),
      IsarPropertySchema(name: 'quantity', type: IsarType.long),
      IsarPropertySchema(name: 'signatureBytes', type: IsarType.longList),
      IsarPropertySchema(name: 'timestamp', type: IsarType.dateTime),
      IsarPropertySchema(name: 'isSynced', type: IsarType.bool),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<int, AuditRecordModel>(
    serialize: serializeAuditRecordModel,
    deserialize: deserializeAuditRecordModel,
    deserializeProperty: deserializeAuditRecordModelProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeAuditRecordModel(IsarWriter writer, AuditRecordModel object) {
  {
    final value = object.scanCode;
    if (value == null) {
      IsarCore.writeNull(writer, 1);
    } else {
      IsarCore.writeString(writer, 1, value);
    }
  }
  {
    final value = object.aiDetectedLabel;
    if (value == null) {
      IsarCore.writeNull(writer, 2);
    } else {
      IsarCore.writeString(writer, 2, value);
    }
  }
  IsarCore.writeLong(writer, 3, object.quantity);
  {
    final list = object.signatureBytes;
    if (list == null) {
      IsarCore.writeNull(writer, 4);
    } else {
      final listWriter = IsarCore.beginList(writer, 4, list.length);
      for (var i = 0; i < list.length; i++) {
        IsarCore.writeLong(listWriter, i, list[i]);
      }
      IsarCore.endList(writer, listWriter);
    }
  }
  IsarCore.writeLong(
    writer,
    5,
    object.timestamp?.toUtc().microsecondsSinceEpoch ?? -9223372036854775808,
  );
  IsarCore.writeBool(writer, 6, value: object.isSynced);
  return object.id;
}

@isarProtected
AuditRecordModel deserializeAuditRecordModel(IsarReader reader) {
  final int _id;
  _id = IsarCore.readId(reader);
  final List<int>? _signatureBytes;
  {
    final length = IsarCore.readList(reader, 4, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _signatureBytes = null;
      } else {
        final list = List<int>.filled(
          length,
          -9223372036854775808,
          growable: true,
        );
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readLong(reader, i);
        }
        IsarCore.freeReader(reader);
        _signatureBytes = list;
      }
    }
  }
  final object = AuditRecordModel(_id, signatureBytes: _signatureBytes);
  object.scanCode = IsarCore.readString(reader, 1);
  object.aiDetectedLabel = IsarCore.readString(reader, 2);
  object.quantity = IsarCore.readLong(reader, 3);
  {
    final value = IsarCore.readLong(reader, 5);
    if (value == -9223372036854775808) {
      object.timestamp = null;
    } else {
      object.timestamp = DateTime.fromMicrosecondsSinceEpoch(
        value,
        isUtc: true,
      ).toLocal();
    }
  }
  object.isSynced = IsarCore.readBool(reader, 6);
  return object;
}

@isarProtected
dynamic deserializeAuditRecordModelProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1);
    case 2:
      return IsarCore.readString(reader, 2);
    case 3:
      return IsarCore.readLong(reader, 3);
    case 4:
      {
        final length = IsarCore.readList(reader, 4, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            return null;
          } else {
            final list = List<int>.filled(
              length,
              -9223372036854775808,
              growable: true,
            );
            for (var i = 0; i < length; i++) {
              list[i] = IsarCore.readLong(reader, i);
            }
            IsarCore.freeReader(reader);
            return list;
          }
        }
      }
    case 5:
      {
        final value = IsarCore.readLong(reader, 5);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(
            value,
            isUtc: true,
          ).toLocal();
        }
      }
    case 6:
      return IsarCore.readBool(reader, 6);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _AuditRecordModelUpdate {
  bool call({
    required int id,
    String? scanCode,
    String? aiDetectedLabel,
    int? quantity,
    DateTime? timestamp,
    bool? isSynced,
  });
}

class _AuditRecordModelUpdateImpl implements _AuditRecordModelUpdate {
  const _AuditRecordModelUpdateImpl(this.collection);

  final IsarCollection<int, AuditRecordModel> collection;

  @override
  bool call({
    required int id,
    Object? scanCode = ignore,
    Object? aiDetectedLabel = ignore,
    Object? quantity = ignore,
    Object? timestamp = ignore,
    Object? isSynced = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (scanCode != ignore) 1: scanCode as String?,
            if (aiDetectedLabel != ignore) 2: aiDetectedLabel as String?,
            if (quantity != ignore) 3: quantity as int?,
            if (timestamp != ignore) 5: timestamp as DateTime?,
            if (isSynced != ignore) 6: isSynced as bool?,
          },
        ) >
        0;
  }
}

sealed class _AuditRecordModelUpdateAll {
  int call({
    required List<int> id,
    String? scanCode,
    String? aiDetectedLabel,
    int? quantity,
    DateTime? timestamp,
    bool? isSynced,
  });
}

class _AuditRecordModelUpdateAllImpl implements _AuditRecordModelUpdateAll {
  const _AuditRecordModelUpdateAllImpl(this.collection);

  final IsarCollection<int, AuditRecordModel> collection;

  @override
  int call({
    required List<int> id,
    Object? scanCode = ignore,
    Object? aiDetectedLabel = ignore,
    Object? quantity = ignore,
    Object? timestamp = ignore,
    Object? isSynced = ignore,
  }) {
    return collection.updateProperties(id, {
      if (scanCode != ignore) 1: scanCode as String?,
      if (aiDetectedLabel != ignore) 2: aiDetectedLabel as String?,
      if (quantity != ignore) 3: quantity as int?,
      if (timestamp != ignore) 5: timestamp as DateTime?,
      if (isSynced != ignore) 6: isSynced as bool?,
    });
  }
}

extension AuditRecordModelUpdate on IsarCollection<int, AuditRecordModel> {
  _AuditRecordModelUpdate get update => _AuditRecordModelUpdateImpl(this);

  _AuditRecordModelUpdateAll get updateAll =>
      _AuditRecordModelUpdateAllImpl(this);
}

sealed class _AuditRecordModelQueryUpdate {
  int call({
    String? scanCode,
    String? aiDetectedLabel,
    int? quantity,
    DateTime? timestamp,
    bool? isSynced,
  });
}

class _AuditRecordModelQueryUpdateImpl implements _AuditRecordModelQueryUpdate {
  const _AuditRecordModelQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<AuditRecordModel> query;
  final int? limit;

  @override
  int call({
    Object? scanCode = ignore,
    Object? aiDetectedLabel = ignore,
    Object? quantity = ignore,
    Object? timestamp = ignore,
    Object? isSynced = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (scanCode != ignore) 1: scanCode as String?,
      if (aiDetectedLabel != ignore) 2: aiDetectedLabel as String?,
      if (quantity != ignore) 3: quantity as int?,
      if (timestamp != ignore) 5: timestamp as DateTime?,
      if (isSynced != ignore) 6: isSynced as bool?,
    });
  }
}

extension AuditRecordModelQueryUpdate on IsarQuery<AuditRecordModel> {
  _AuditRecordModelQueryUpdate get updateFirst =>
      _AuditRecordModelQueryUpdateImpl(this, limit: 1);

  _AuditRecordModelQueryUpdate get updateAll =>
      _AuditRecordModelQueryUpdateImpl(this);
}

class _AuditRecordModelQueryBuilderUpdateImpl
    implements _AuditRecordModelQueryUpdate {
  const _AuditRecordModelQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<AuditRecordModel, AuditRecordModel, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? scanCode = ignore,
    Object? aiDetectedLabel = ignore,
    Object? quantity = ignore,
    Object? timestamp = ignore,
    Object? isSynced = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (scanCode != ignore) 1: scanCode as String?,
        if (aiDetectedLabel != ignore) 2: aiDetectedLabel as String?,
        if (quantity != ignore) 3: quantity as int?,
        if (timestamp != ignore) 5: timestamp as DateTime?,
        if (isSynced != ignore) 6: isSynced as bool?,
      });
    } finally {
      q.close();
    }
  }
}

extension AuditRecordModelQueryBuilderUpdate
    on QueryBuilder<AuditRecordModel, AuditRecordModel, QOperations> {
  _AuditRecordModelQueryUpdate get updateFirst =>
      _AuditRecordModelQueryBuilderUpdateImpl(this, limit: 1);

  _AuditRecordModelQueryUpdate get updateAll =>
      _AuditRecordModelQueryBuilderUpdateImpl(this);
}

extension AuditRecordModelQueryFilter
    on QueryBuilder<AuditRecordModel, AuditRecordModel, QFilterCondition> {
  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  idEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  idGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  idGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  idLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  idLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  idBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 0, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  scanCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 1));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  scanCodeIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 1));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  scanCodeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  scanCodeGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  scanCodeGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  scanCodeLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  scanCodeLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  scanCodeBetween(String? lower, String? upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  scanCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  scanCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  scanCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  scanCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  scanCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  scanCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  aiDetectedLabelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  aiDetectedLabelIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  aiDetectedLabelEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  aiDetectedLabelGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  aiDetectedLabelGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  aiDetectedLabelLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  aiDetectedLabelLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  aiDetectedLabelBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  aiDetectedLabelStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  aiDetectedLabelEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  aiDetectedLabelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  aiDetectedLabelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  aiDetectedLabelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  aiDetectedLabelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  quantityEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  quantityGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  quantityGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  quantityLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 3, value: value));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  quantityLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  quantityBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 3, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesElementGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesElementGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesElementLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 4, value: value));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesElementLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesElementBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 4, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesIsEmpty() {
    return not().group(
      (q) => q.signatureBytesIsNull().or().signatureBytesIsNotEmpty(),
    );
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 4, value: null),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  timestampIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  timestampIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  timestampEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 5, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  timestampGreaterThan(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 5, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  timestampGreaterThanOrEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 5, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  timestampLessThan(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 5, value: value));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  timestampLessThanOrEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 5, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  timestampBetween(DateTime? lower, DateTime? upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 5, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 6, value: value),
      );
    });
  }
}

extension AuditRecordModelQueryObject
    on QueryBuilder<AuditRecordModel, AuditRecordModel, QFilterCondition> {}

extension AuditRecordModelQuerySortBy
    on QueryBuilder<AuditRecordModel, AuditRecordModel, QSortBy> {
  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByScanCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByScanCodeDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByAiDetectedLabel({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByAiDetectedLabelDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }
}

extension AuditRecordModelQuerySortThenBy
    on QueryBuilder<AuditRecordModel, AuditRecordModel, QSortThenBy> {
  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByScanCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByScanCodeDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByAiDetectedLabel({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByAiDetectedLabelDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }
}

extension AuditRecordModelQueryWhereDistinct
    on QueryBuilder<AuditRecordModel, AuditRecordModel, QDistinct> {
  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterDistinct>
  distinctByScanCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterDistinct>
  distinctByAiDetectedLabel({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterDistinct>
  distinctByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterDistinct>
  distinctBySignatureBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterDistinct>
  distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterDistinct>
  distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(6);
    });
  }
}

extension AuditRecordModelQueryProperty1
    on QueryBuilder<AuditRecordModel, AuditRecordModel, QProperty> {
  QueryBuilder<AuditRecordModel, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<AuditRecordModel, String?, QAfterProperty> scanCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<AuditRecordModel, String?, QAfterProperty>
  aiDetectedLabelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<AuditRecordModel, int, QAfterProperty> quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<AuditRecordModel, List<int>?, QAfterProperty>
  signatureBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<AuditRecordModel, DateTime?, QAfterProperty>
  timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<AuditRecordModel, bool, QAfterProperty> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }
}

extension AuditRecordModelQueryProperty2<R>
    on QueryBuilder<AuditRecordModel, R, QAfterProperty> {
  QueryBuilder<AuditRecordModel, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<AuditRecordModel, (R, String?), QAfterProperty>
  scanCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<AuditRecordModel, (R, String?), QAfterProperty>
  aiDetectedLabelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<AuditRecordModel, (R, int), QAfterProperty> quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<AuditRecordModel, (R, List<int>?), QAfterProperty>
  signatureBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<AuditRecordModel, (R, DateTime?), QAfterProperty>
  timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<AuditRecordModel, (R, bool), QAfterProperty> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }
}

extension AuditRecordModelQueryProperty3<R1, R2>
    on QueryBuilder<AuditRecordModel, (R1, R2), QAfterProperty> {
  QueryBuilder<AuditRecordModel, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<AuditRecordModel, (R1, R2, String?), QOperations>
  scanCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<AuditRecordModel, (R1, R2, String?), QOperations>
  aiDetectedLabelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<AuditRecordModel, (R1, R2, int), QOperations>
  quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<AuditRecordModel, (R1, R2, List<int>?), QOperations>
  signatureBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<AuditRecordModel, (R1, R2, DateTime?), QOperations>
  timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<AuditRecordModel, (R1, R2, bool), QOperations>
  isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }
}
