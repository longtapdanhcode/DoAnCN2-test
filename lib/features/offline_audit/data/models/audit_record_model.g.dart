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
      IsarPropertySchema(name: 'assetName', type: IsarType.string),
      IsarPropertySchema(name: 'quantity', type: IsarType.long),
      IsarPropertySchema(name: 'area', type: IsarType.string),
      IsarPropertySchema(name: 'location', type: IsarType.string),
      IsarPropertySchema(name: 'condition', type: IsarType.string),
      IsarPropertySchema(name: 'notes', type: IsarType.string),
      IsarPropertySchema(name: 'signatureBytes', type: IsarType.longList),
      IsarPropertySchema(name: 'signerName', type: IsarType.string),
      IsarPropertySchema(name: 'signerRole', type: IsarType.string),
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
  {
    final value = object.assetName;
    if (value == null) {
      IsarCore.writeNull(writer, 3);
    } else {
      IsarCore.writeString(writer, 3, value);
    }
  }
  IsarCore.writeLong(writer, 4, object.quantity);
  {
    final value = object.area;
    if (value == null) {
      IsarCore.writeNull(writer, 5);
    } else {
      IsarCore.writeString(writer, 5, value);
    }
  }
  {
    final value = object.location;
    if (value == null) {
      IsarCore.writeNull(writer, 6);
    } else {
      IsarCore.writeString(writer, 6, value);
    }
  }
  {
    final value = object.condition;
    if (value == null) {
      IsarCore.writeNull(writer, 7);
    } else {
      IsarCore.writeString(writer, 7, value);
    }
  }
  {
    final value = object.notes;
    if (value == null) {
      IsarCore.writeNull(writer, 8);
    } else {
      IsarCore.writeString(writer, 8, value);
    }
  }
  {
    final list = object.signatureBytes;
    if (list == null) {
      IsarCore.writeNull(writer, 9);
    } else {
      final listWriter = IsarCore.beginList(writer, 9, list.length);
      for (var i = 0; i < list.length; i++) {
        IsarCore.writeLong(listWriter, i, list[i]);
      }
      IsarCore.endList(writer, listWriter);
    }
  }
  {
    final value = object.signerName;
    if (value == null) {
      IsarCore.writeNull(writer, 10);
    } else {
      IsarCore.writeString(writer, 10, value);
    }
  }
  {
    final value = object.signerRole;
    if (value == null) {
      IsarCore.writeNull(writer, 11);
    } else {
      IsarCore.writeString(writer, 11, value);
    }
  }
  IsarCore.writeLong(
    writer,
    12,
    object.timestamp?.toUtc().microsecondsSinceEpoch ?? -9223372036854775808,
  );
  IsarCore.writeBool(writer, 13, value: object.isSynced);
  return object.id;
}

@isarProtected
AuditRecordModel deserializeAuditRecordModel(IsarReader reader) {
  final int _id;
  _id = IsarCore.readId(reader);
  final List<int>? _signatureBytes;
  {
    final length = IsarCore.readList(reader, 9, IsarCore.readerPtrPtr);
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
  object.assetName = IsarCore.readString(reader, 3);
  object.quantity = IsarCore.readLong(reader, 4);
  object.area = IsarCore.readString(reader, 5);
  object.location = IsarCore.readString(reader, 6);
  object.condition = IsarCore.readString(reader, 7);
  object.notes = IsarCore.readString(reader, 8);
  object.signerName = IsarCore.readString(reader, 10);
  object.signerRole = IsarCore.readString(reader, 11);
  {
    final value = IsarCore.readLong(reader, 12);
    if (value == -9223372036854775808) {
      object.timestamp = null;
    } else {
      object.timestamp = DateTime.fromMicrosecondsSinceEpoch(
        value,
        isUtc: true,
      ).toLocal();
    }
  }
  object.isSynced = IsarCore.readBool(reader, 13);
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
      return IsarCore.readString(reader, 3);
    case 4:
      return IsarCore.readLong(reader, 4);
    case 5:
      return IsarCore.readString(reader, 5);
    case 6:
      return IsarCore.readString(reader, 6);
    case 7:
      return IsarCore.readString(reader, 7);
    case 8:
      return IsarCore.readString(reader, 8);
    case 9:
      {
        final length = IsarCore.readList(reader, 9, IsarCore.readerPtrPtr);
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
    case 10:
      return IsarCore.readString(reader, 10);
    case 11:
      return IsarCore.readString(reader, 11);
    case 12:
      {
        final value = IsarCore.readLong(reader, 12);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(
            value,
            isUtc: true,
          ).toLocal();
        }
      }
    case 13:
      return IsarCore.readBool(reader, 13);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _AuditRecordModelUpdate {
  bool call({
    required int id,
    String? scanCode,
    String? aiDetectedLabel,
    String? assetName,
    int? quantity,
    String? area,
    String? location,
    String? condition,
    String? notes,
    String? signerName,
    String? signerRole,
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
    Object? assetName = ignore,
    Object? quantity = ignore,
    Object? area = ignore,
    Object? location = ignore,
    Object? condition = ignore,
    Object? notes = ignore,
    Object? signerName = ignore,
    Object? signerRole = ignore,
    Object? timestamp = ignore,
    Object? isSynced = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (scanCode != ignore) 1: scanCode as String?,
            if (aiDetectedLabel != ignore) 2: aiDetectedLabel as String?,
            if (assetName != ignore) 3: assetName as String?,
            if (quantity != ignore) 4: quantity as int?,
            if (area != ignore) 5: area as String?,
            if (location != ignore) 6: location as String?,
            if (condition != ignore) 7: condition as String?,
            if (notes != ignore) 8: notes as String?,
            if (signerName != ignore) 10: signerName as String?,
            if (signerRole != ignore) 11: signerRole as String?,
            if (timestamp != ignore) 12: timestamp as DateTime?,
            if (isSynced != ignore) 13: isSynced as bool?,
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
    String? assetName,
    int? quantity,
    String? area,
    String? location,
    String? condition,
    String? notes,
    String? signerName,
    String? signerRole,
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
    Object? assetName = ignore,
    Object? quantity = ignore,
    Object? area = ignore,
    Object? location = ignore,
    Object? condition = ignore,
    Object? notes = ignore,
    Object? signerName = ignore,
    Object? signerRole = ignore,
    Object? timestamp = ignore,
    Object? isSynced = ignore,
  }) {
    return collection.updateProperties(id, {
      if (scanCode != ignore) 1: scanCode as String?,
      if (aiDetectedLabel != ignore) 2: aiDetectedLabel as String?,
      if (assetName != ignore) 3: assetName as String?,
      if (quantity != ignore) 4: quantity as int?,
      if (area != ignore) 5: area as String?,
      if (location != ignore) 6: location as String?,
      if (condition != ignore) 7: condition as String?,
      if (notes != ignore) 8: notes as String?,
      if (signerName != ignore) 10: signerName as String?,
      if (signerRole != ignore) 11: signerRole as String?,
      if (timestamp != ignore) 12: timestamp as DateTime?,
      if (isSynced != ignore) 13: isSynced as bool?,
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
    String? assetName,
    int? quantity,
    String? area,
    String? location,
    String? condition,
    String? notes,
    String? signerName,
    String? signerRole,
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
    Object? assetName = ignore,
    Object? quantity = ignore,
    Object? area = ignore,
    Object? location = ignore,
    Object? condition = ignore,
    Object? notes = ignore,
    Object? signerName = ignore,
    Object? signerRole = ignore,
    Object? timestamp = ignore,
    Object? isSynced = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (scanCode != ignore) 1: scanCode as String?,
      if (aiDetectedLabel != ignore) 2: aiDetectedLabel as String?,
      if (assetName != ignore) 3: assetName as String?,
      if (quantity != ignore) 4: quantity as int?,
      if (area != ignore) 5: area as String?,
      if (location != ignore) 6: location as String?,
      if (condition != ignore) 7: condition as String?,
      if (notes != ignore) 8: notes as String?,
      if (signerName != ignore) 10: signerName as String?,
      if (signerRole != ignore) 11: signerRole as String?,
      if (timestamp != ignore) 12: timestamp as DateTime?,
      if (isSynced != ignore) 13: isSynced as bool?,
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
    Object? assetName = ignore,
    Object? quantity = ignore,
    Object? area = ignore,
    Object? location = ignore,
    Object? condition = ignore,
    Object? notes = ignore,
    Object? signerName = ignore,
    Object? signerRole = ignore,
    Object? timestamp = ignore,
    Object? isSynced = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (scanCode != ignore) 1: scanCode as String?,
        if (aiDetectedLabel != ignore) 2: aiDetectedLabel as String?,
        if (assetName != ignore) 3: assetName as String?,
        if (quantity != ignore) 4: quantity as int?,
        if (area != ignore) 5: area as String?,
        if (location != ignore) 6: location as String?,
        if (condition != ignore) 7: condition as String?,
        if (notes != ignore) 8: notes as String?,
        if (signerName != ignore) 10: signerName as String?,
        if (signerRole != ignore) 11: signerRole as String?,
        if (timestamp != ignore) 12: timestamp as DateTime?,
        if (isSynced != ignore) 13: isSynced as bool?,
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
  assetNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  assetNameIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 3));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  assetNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  assetNameGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  assetNameGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  assetNameLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 3, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  assetNameLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  assetNameBetween(String? lower, String? upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 3,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  assetNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  assetNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  assetNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  assetNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 3,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  assetNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  assetNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 3, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  quantityEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  quantityGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  quantityGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  quantityLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 4, value: value));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  quantityLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  quantityBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 4, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  areaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  areaIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  areaEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 5, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  areaGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  areaGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  areaLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 5, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  areaLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  areaBetween(String? lower, String? upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 5,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  areaStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  areaEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  areaContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  areaMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 5,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  areaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 5, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  areaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 5, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  locationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 6));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  locationIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 6));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  locationEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 6, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  locationGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  locationGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  locationLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 6, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  locationLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  locationBetween(String? lower, String? upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 6,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  locationStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  locationEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  locationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 6,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  locationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 6,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  locationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 6, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  locationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 6, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  conditionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 7));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  conditionIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 7));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  conditionEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 7, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  conditionGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  conditionGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  conditionLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 7, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  conditionLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  conditionBetween(String? lower, String? upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 7,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  conditionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  conditionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  conditionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 7,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  conditionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 7,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  conditionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 7, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  conditionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 7, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 8));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  notesIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 8));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  notesEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 8, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  notesGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  notesGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  notesLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 8, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  notesLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  notesBetween(String? lower, String? upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 8,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  notesStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  notesEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 8,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 8, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 8, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 9));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 9));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 9, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesElementGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 9, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesElementGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 9, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesElementLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 9, value: value));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesElementLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 9, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signatureBytesElementBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 9, lower: lower, upper: upper),
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
        const GreaterOrEqualCondition(property: 9, value: null),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 10));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerNameIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 10));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 10,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerNameGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 10,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerNameGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 10,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerNameLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 10, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerNameLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 10,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerNameBetween(String? lower, String? upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 10,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 10,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 10,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 10,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 10,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 10, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 10, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerRoleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 11));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerRoleIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 11));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerRoleEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 11,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerRoleGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 11,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerRoleGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 11,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerRoleLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 11, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerRoleLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 11,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerRoleBetween(String? lower, String? upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 11,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerRoleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 11,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerRoleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 11,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerRoleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 11,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerRoleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 11,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerRoleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 11, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  signerRoleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 11, value: ''),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  timestampIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 12));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  timestampIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 12));
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  timestampEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 12, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  timestampGreaterThan(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 12, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  timestampGreaterThanOrEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 12, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  timestampLessThan(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 12, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  timestampLessThanOrEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 12, value: value),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  timestampBetween(DateTime? lower, DateTime? upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 12, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterFilterCondition>
  isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 13, value: value),
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
  sortByAssetName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByAssetNameDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy> sortByArea({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByAreaDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByLocation({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByLocationDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByCondition({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByConditionDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy> sortByNotes({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByNotesDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortBySignerName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortBySignerNameDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortBySignerRole({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortBySignerRoleDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12, sort: Sort.desc);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(13);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(13, sort: Sort.desc);
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
  thenByAssetName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByAssetNameDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy> thenByArea({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByAreaDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByLocation({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByLocationDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByCondition({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByConditionDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy> thenByNotes({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByNotesDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenBySignerName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenBySignerNameDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenBySignerRole({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenBySignerRoleDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12, sort: Sort.desc);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(13);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterSortBy>
  thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(13, sort: Sort.desc);
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
  distinctByAssetName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterDistinct>
  distinctByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterDistinct>
  distinctByArea({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterDistinct>
  distinctByLocation({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(6, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterDistinct>
  distinctByCondition({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(7, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterDistinct>
  distinctByNotes({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(8, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterDistinct>
  distinctBySignatureBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(9);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterDistinct>
  distinctBySignerName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(10, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterDistinct>
  distinctBySignerRole({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(11, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterDistinct>
  distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(12);
    });
  }

  QueryBuilder<AuditRecordModel, AuditRecordModel, QAfterDistinct>
  distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(13);
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

  QueryBuilder<AuditRecordModel, String?, QAfterProperty> assetNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<AuditRecordModel, int, QAfterProperty> quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<AuditRecordModel, String?, QAfterProperty> areaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<AuditRecordModel, String?, QAfterProperty> locationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<AuditRecordModel, String?, QAfterProperty> conditionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<AuditRecordModel, String?, QAfterProperty> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<AuditRecordModel, List<int>?, QAfterProperty>
  signatureBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<AuditRecordModel, String?, QAfterProperty> signerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<AuditRecordModel, String?, QAfterProperty> signerRoleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<AuditRecordModel, DateTime?, QAfterProperty>
  timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }

  QueryBuilder<AuditRecordModel, bool, QAfterProperty> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(13);
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

  QueryBuilder<AuditRecordModel, (R, String?), QAfterProperty>
  assetNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<AuditRecordModel, (R, int), QAfterProperty> quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<AuditRecordModel, (R, String?), QAfterProperty> areaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<AuditRecordModel, (R, String?), QAfterProperty>
  locationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<AuditRecordModel, (R, String?), QAfterProperty>
  conditionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<AuditRecordModel, (R, String?), QAfterProperty> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<AuditRecordModel, (R, List<int>?), QAfterProperty>
  signatureBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<AuditRecordModel, (R, String?), QAfterProperty>
  signerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<AuditRecordModel, (R, String?), QAfterProperty>
  signerRoleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<AuditRecordModel, (R, DateTime?), QAfterProperty>
  timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }

  QueryBuilder<AuditRecordModel, (R, bool), QAfterProperty> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(13);
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

  QueryBuilder<AuditRecordModel, (R1, R2, String?), QOperations>
  assetNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<AuditRecordModel, (R1, R2, int), QOperations>
  quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<AuditRecordModel, (R1, R2, String?), QOperations>
  areaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<AuditRecordModel, (R1, R2, String?), QOperations>
  locationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<AuditRecordModel, (R1, R2, String?), QOperations>
  conditionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<AuditRecordModel, (R1, R2, String?), QOperations>
  notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<AuditRecordModel, (R1, R2, List<int>?), QOperations>
  signatureBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<AuditRecordModel, (R1, R2, String?), QOperations>
  signerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<AuditRecordModel, (R1, R2, String?), QOperations>
  signerRoleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<AuditRecordModel, (R1, R2, DateTime?), QOperations>
  timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }

  QueryBuilder<AuditRecordModel, (R1, R2, bool), QOperations>
  isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(13);
    });
  }
}
