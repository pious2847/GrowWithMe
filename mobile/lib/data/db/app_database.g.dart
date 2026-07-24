// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ChildrenTable extends Children with TableInfo<$ChildrenTable, ChildRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChildrenTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientUpdatedAtMeta = const VerificationMeta(
    'clientUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> clientUpdatedAt = GeneratedColumn<int>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateOfBirthMeta = const VerificationMeta(
    'dateOfBirth',
  );
  @override
  late final GeneratedColumn<DateTime> dateOfBirth = GeneratedColumn<DateTime>(
    'date_of_birth',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _birthWeightKgMeta = const VerificationMeta(
    'birthWeightKg',
  );
  @override
  late final GeneratedColumn<double> birthWeightKg = GeneratedColumn<double>(
    'birth_weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientUpdatedAt,
    deleted,
    synced,
    name,
    sex,
    dateOfBirth,
    photoUrl,
    birthWeightKg,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'children';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChildRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
        _clientUpdatedAtMeta,
        clientUpdatedAt.isAcceptableOrUnknown(
          data['client_updated_at']!,
          _clientUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
        _dateOfBirthMeta,
        dateOfBirth.isAcceptableOrUnknown(
          data['date_of_birth']!,
          _dateOfBirthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateOfBirthMeta);
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('birth_weight_kg')) {
      context.handle(
        _birthWeightKgMeta,
        birthWeightKg.isAcceptableOrUnknown(
          data['birth_weight_kg']!,
          _birthWeightKgMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChildRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChildRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      ),
      dateOfBirth: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_of_birth'],
      )!,
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      birthWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}birth_weight_kg'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $ChildrenTable createAlias(String alias) {
    return $ChildrenTable(attachedDatabase, alias);
  }
}

class ChildRow extends DataClass implements Insertable<ChildRow> {
  final String id;
  final int clientUpdatedAt;
  final bool deleted;
  final bool synced;
  final String name;
  final String? sex;
  final DateTime dateOfBirth;
  final String? photoUrl;
  final double? birthWeightKg;
  final String? notes;
  const ChildRow({
    required this.id,
    required this.clientUpdatedAt,
    required this.deleted,
    required this.synced,
    required this.name,
    this.sex,
    required this.dateOfBirth,
    this.photoUrl,
    this.birthWeightKg,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_updated_at'] = Variable<int>(clientUpdatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['synced'] = Variable<bool>(synced);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sex != null) {
      map['sex'] = Variable<String>(sex);
    }
    map['date_of_birth'] = Variable<DateTime>(dateOfBirth);
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    if (!nullToAbsent || birthWeightKg != null) {
      map['birth_weight_kg'] = Variable<double>(birthWeightKg);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  ChildrenCompanion toCompanion(bool nullToAbsent) {
    return ChildrenCompanion(
      id: Value(id),
      clientUpdatedAt: Value(clientUpdatedAt),
      deleted: Value(deleted),
      synced: Value(synced),
      name: Value(name),
      sex: sex == null && nullToAbsent ? const Value.absent() : Value(sex),
      dateOfBirth: Value(dateOfBirth),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      birthWeightKg: birthWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(birthWeightKg),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory ChildRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChildRow(
      id: serializer.fromJson<String>(json['id']),
      clientUpdatedAt: serializer.fromJson<int>(json['clientUpdatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      synced: serializer.fromJson<bool>(json['synced']),
      name: serializer.fromJson<String>(json['name']),
      sex: serializer.fromJson<String?>(json['sex']),
      dateOfBirth: serializer.fromJson<DateTime>(json['dateOfBirth']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      birthWeightKg: serializer.fromJson<double?>(json['birthWeightKg']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientUpdatedAt': serializer.toJson<int>(clientUpdatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'synced': serializer.toJson<bool>(synced),
      'name': serializer.toJson<String>(name),
      'sex': serializer.toJson<String?>(sex),
      'dateOfBirth': serializer.toJson<DateTime>(dateOfBirth),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'birthWeightKg': serializer.toJson<double?>(birthWeightKg),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  ChildRow copyWith({
    String? id,
    int? clientUpdatedAt,
    bool? deleted,
    bool? synced,
    String? name,
    Value<String?> sex = const Value.absent(),
    DateTime? dateOfBirth,
    Value<String?> photoUrl = const Value.absent(),
    Value<double?> birthWeightKg = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => ChildRow(
    id: id ?? this.id,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deleted: deleted ?? this.deleted,
    synced: synced ?? this.synced,
    name: name ?? this.name,
    sex: sex.present ? sex.value : this.sex,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    birthWeightKg: birthWeightKg.present
        ? birthWeightKg.value
        : this.birthWeightKg,
    notes: notes.present ? notes.value : this.notes,
  );
  ChildRow copyWithCompanion(ChildrenCompanion data) {
    return ChildRow(
      id: data.id.present ? data.id.value : this.id,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      synced: data.synced.present ? data.synced.value : this.synced,
      name: data.name.present ? data.name.value : this.name,
      sex: data.sex.present ? data.sex.value : this.sex,
      dateOfBirth: data.dateOfBirth.present
          ? data.dateOfBirth.value
          : this.dateOfBirth,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      birthWeightKg: data.birthWeightKg.present
          ? data.birthWeightKg.value
          : this.birthWeightKg,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChildRow(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('name: $name, ')
          ..write('sex: $sex, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('birthWeightKg: $birthWeightKg, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientUpdatedAt,
    deleted,
    synced,
    name,
    sex,
    dateOfBirth,
    photoUrl,
    birthWeightKg,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChildRow &&
          other.id == this.id &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deleted == this.deleted &&
          other.synced == this.synced &&
          other.name == this.name &&
          other.sex == this.sex &&
          other.dateOfBirth == this.dateOfBirth &&
          other.photoUrl == this.photoUrl &&
          other.birthWeightKg == this.birthWeightKg &&
          other.notes == this.notes);
}

class ChildrenCompanion extends UpdateCompanion<ChildRow> {
  final Value<String> id;
  final Value<int> clientUpdatedAt;
  final Value<bool> deleted;
  final Value<bool> synced;
  final Value<String> name;
  final Value<String?> sex;
  final Value<DateTime> dateOfBirth;
  final Value<String?> photoUrl;
  final Value<double?> birthWeightKg;
  final Value<String?> notes;
  final Value<int> rowid;
  const ChildrenCompanion({
    this.id = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    this.name = const Value.absent(),
    this.sex = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.birthWeightKg = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChildrenCompanion.insert({
    required String id,
    required int clientUpdatedAt,
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    required String name,
    this.sex = const Value.absent(),
    required DateTime dateOfBirth,
    this.photoUrl = const Value.absent(),
    this.birthWeightKg = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clientUpdatedAt = Value(clientUpdatedAt),
       name = Value(name),
       dateOfBirth = Value(dateOfBirth);
  static Insertable<ChildRow> custom({
    Expression<String>? id,
    Expression<int>? clientUpdatedAt,
    Expression<bool>? deleted,
    Expression<bool>? synced,
    Expression<String>? name,
    Expression<String>? sex,
    Expression<DateTime>? dateOfBirth,
    Expression<String>? photoUrl,
    Expression<double>? birthWeightKg,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deleted != null) 'deleted': deleted,
      if (synced != null) 'synced': synced,
      if (name != null) 'name': name,
      if (sex != null) 'sex': sex,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (birthWeightKg != null) 'birth_weight_kg': birthWeightKg,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChildrenCompanion copyWith({
    Value<String>? id,
    Value<int>? clientUpdatedAt,
    Value<bool>? deleted,
    Value<bool>? synced,
    Value<String>? name,
    Value<String?>? sex,
    Value<DateTime>? dateOfBirth,
    Value<String?>? photoUrl,
    Value<double?>? birthWeightKg,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return ChildrenCompanion(
      id: id ?? this.id,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deleted: deleted ?? this.deleted,
      synced: synced ?? this.synced,
      name: name ?? this.name,
      sex: sex ?? this.sex,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      photoUrl: photoUrl ?? this.photoUrl,
      birthWeightKg: birthWeightKg ?? this.birthWeightKg,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<int>(clientUpdatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<DateTime>(dateOfBirth.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (birthWeightKg.present) {
      map['birth_weight_kg'] = Variable<double>(birthWeightKg.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChildrenCompanion(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('name: $name, ')
          ..write('sex: $sex, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('birthWeightKg: $birthWeightKg, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PregnanciesTable extends Pregnancies
    with TableInfo<$PregnanciesTable, PregnancyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PregnanciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientUpdatedAtMeta = const VerificationMeta(
    'clientUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> clientUpdatedAt = GeneratedColumn<int>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastMenstrualPeriodMeta =
      const VerificationMeta('lastMenstrualPeriod');
  @override
  late final GeneratedColumn<DateTime> lastMenstrualPeriod =
      GeneratedColumn<DateTime>(
        'last_menstrual_period',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _expectedDueDateMeta = const VerificationMeta(
    'expectedDueDate',
  );
  @override
  late final GeneratedColumn<DateTime> expectedDueDate =
      GeneratedColumn<DateTime>(
        'expected_due_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _deliveredAtMeta = const VerificationMeta(
    'deliveredAt',
  );
  @override
  late final GeneratedColumn<DateTime> deliveredAt = GeneratedColumn<DateTime>(
    'delivered_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hospitalNameMeta = const VerificationMeta(
    'hospitalName',
  );
  @override
  late final GeneratedColumn<String> hospitalName = GeneratedColumn<String>(
    'hospital_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hospitalPhoneMeta = const VerificationMeta(
    'hospitalPhone',
  );
  @override
  late final GeneratedColumn<String> hospitalPhone = GeneratedColumn<String>(
    'hospital_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastCheckinAtMeta = const VerificationMeta(
    'lastCheckinAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastCheckinAt =
      GeneratedColumn<DateTime>(
        'last_checkin_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastRiskLevelMeta = const VerificationMeta(
    'lastRiskLevel',
  );
  @override
  late final GeneratedColumn<String> lastRiskLevel = GeneratedColumn<String>(
    'last_risk_level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientUpdatedAt,
    deleted,
    synced,
    lastMenstrualPeriod,
    expectedDueDate,
    status,
    deliveredAt,
    notes,
    hospitalName,
    hospitalPhone,
    lastCheckinAt,
    lastRiskLevel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pregnancies';
  @override
  VerificationContext validateIntegrity(
    Insertable<PregnancyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
        _clientUpdatedAtMeta,
        clientUpdatedAt.isAcceptableOrUnknown(
          data['client_updated_at']!,
          _clientUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('last_menstrual_period')) {
      context.handle(
        _lastMenstrualPeriodMeta,
        lastMenstrualPeriod.isAcceptableOrUnknown(
          data['last_menstrual_period']!,
          _lastMenstrualPeriodMeta,
        ),
      );
    }
    if (data.containsKey('expected_due_date')) {
      context.handle(
        _expectedDueDateMeta,
        expectedDueDate.isAcceptableOrUnknown(
          data['expected_due_date']!,
          _expectedDueDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expectedDueDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('delivered_at')) {
      context.handle(
        _deliveredAtMeta,
        deliveredAt.isAcceptableOrUnknown(
          data['delivered_at']!,
          _deliveredAtMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('hospital_name')) {
      context.handle(
        _hospitalNameMeta,
        hospitalName.isAcceptableOrUnknown(
          data['hospital_name']!,
          _hospitalNameMeta,
        ),
      );
    }
    if (data.containsKey('hospital_phone')) {
      context.handle(
        _hospitalPhoneMeta,
        hospitalPhone.isAcceptableOrUnknown(
          data['hospital_phone']!,
          _hospitalPhoneMeta,
        ),
      );
    }
    if (data.containsKey('last_checkin_at')) {
      context.handle(
        _lastCheckinAtMeta,
        lastCheckinAt.isAcceptableOrUnknown(
          data['last_checkin_at']!,
          _lastCheckinAtMeta,
        ),
      );
    }
    if (data.containsKey('last_risk_level')) {
      context.handle(
        _lastRiskLevelMeta,
        lastRiskLevel.isAcceptableOrUnknown(
          data['last_risk_level']!,
          _lastRiskLevelMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PregnancyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PregnancyRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      lastMenstrualPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_menstrual_period'],
      ),
      expectedDueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expected_due_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      deliveredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}delivered_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      hospitalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hospital_name'],
      ),
      hospitalPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hospital_phone'],
      ),
      lastCheckinAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_checkin_at'],
      ),
      lastRiskLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_risk_level'],
      ),
    );
  }

  @override
  $PregnanciesTable createAlias(String alias) {
    return $PregnanciesTable(attachedDatabase, alias);
  }
}

class PregnancyRow extends DataClass implements Insertable<PregnancyRow> {
  final String id;
  final int clientUpdatedAt;
  final bool deleted;
  final bool synced;
  final DateTime? lastMenstrualPeriod;
  final DateTime expectedDueDate;
  final String status;
  final DateTime? deliveredAt;
  final String? notes;
  final String? hospitalName;
  final String? hospitalPhone;
  final DateTime? lastCheckinAt;
  final String? lastRiskLevel;
  const PregnancyRow({
    required this.id,
    required this.clientUpdatedAt,
    required this.deleted,
    required this.synced,
    this.lastMenstrualPeriod,
    required this.expectedDueDate,
    required this.status,
    this.deliveredAt,
    this.notes,
    this.hospitalName,
    this.hospitalPhone,
    this.lastCheckinAt,
    this.lastRiskLevel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_updated_at'] = Variable<int>(clientUpdatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || lastMenstrualPeriod != null) {
      map['last_menstrual_period'] = Variable<DateTime>(lastMenstrualPeriod);
    }
    map['expected_due_date'] = Variable<DateTime>(expectedDueDate);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || deliveredAt != null) {
      map['delivered_at'] = Variable<DateTime>(deliveredAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || hospitalName != null) {
      map['hospital_name'] = Variable<String>(hospitalName);
    }
    if (!nullToAbsent || hospitalPhone != null) {
      map['hospital_phone'] = Variable<String>(hospitalPhone);
    }
    if (!nullToAbsent || lastCheckinAt != null) {
      map['last_checkin_at'] = Variable<DateTime>(lastCheckinAt);
    }
    if (!nullToAbsent || lastRiskLevel != null) {
      map['last_risk_level'] = Variable<String>(lastRiskLevel);
    }
    return map;
  }

  PregnanciesCompanion toCompanion(bool nullToAbsent) {
    return PregnanciesCompanion(
      id: Value(id),
      clientUpdatedAt: Value(clientUpdatedAt),
      deleted: Value(deleted),
      synced: Value(synced),
      lastMenstrualPeriod: lastMenstrualPeriod == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMenstrualPeriod),
      expectedDueDate: Value(expectedDueDate),
      status: Value(status),
      deliveredAt: deliveredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveredAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      hospitalName: hospitalName == null && nullToAbsent
          ? const Value.absent()
          : Value(hospitalName),
      hospitalPhone: hospitalPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(hospitalPhone),
      lastCheckinAt: lastCheckinAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCheckinAt),
      lastRiskLevel: lastRiskLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRiskLevel),
    );
  }

  factory PregnancyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PregnancyRow(
      id: serializer.fromJson<String>(json['id']),
      clientUpdatedAt: serializer.fromJson<int>(json['clientUpdatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      synced: serializer.fromJson<bool>(json['synced']),
      lastMenstrualPeriod: serializer.fromJson<DateTime?>(
        json['lastMenstrualPeriod'],
      ),
      expectedDueDate: serializer.fromJson<DateTime>(json['expectedDueDate']),
      status: serializer.fromJson<String>(json['status']),
      deliveredAt: serializer.fromJson<DateTime?>(json['deliveredAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      hospitalName: serializer.fromJson<String?>(json['hospitalName']),
      hospitalPhone: serializer.fromJson<String?>(json['hospitalPhone']),
      lastCheckinAt: serializer.fromJson<DateTime?>(json['lastCheckinAt']),
      lastRiskLevel: serializer.fromJson<String?>(json['lastRiskLevel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientUpdatedAt': serializer.toJson<int>(clientUpdatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'synced': serializer.toJson<bool>(synced),
      'lastMenstrualPeriod': serializer.toJson<DateTime?>(lastMenstrualPeriod),
      'expectedDueDate': serializer.toJson<DateTime>(expectedDueDate),
      'status': serializer.toJson<String>(status),
      'deliveredAt': serializer.toJson<DateTime?>(deliveredAt),
      'notes': serializer.toJson<String?>(notes),
      'hospitalName': serializer.toJson<String?>(hospitalName),
      'hospitalPhone': serializer.toJson<String?>(hospitalPhone),
      'lastCheckinAt': serializer.toJson<DateTime?>(lastCheckinAt),
      'lastRiskLevel': serializer.toJson<String?>(lastRiskLevel),
    };
  }

  PregnancyRow copyWith({
    String? id,
    int? clientUpdatedAt,
    bool? deleted,
    bool? synced,
    Value<DateTime?> lastMenstrualPeriod = const Value.absent(),
    DateTime? expectedDueDate,
    String? status,
    Value<DateTime?> deliveredAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> hospitalName = const Value.absent(),
    Value<String?> hospitalPhone = const Value.absent(),
    Value<DateTime?> lastCheckinAt = const Value.absent(),
    Value<String?> lastRiskLevel = const Value.absent(),
  }) => PregnancyRow(
    id: id ?? this.id,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deleted: deleted ?? this.deleted,
    synced: synced ?? this.synced,
    lastMenstrualPeriod: lastMenstrualPeriod.present
        ? lastMenstrualPeriod.value
        : this.lastMenstrualPeriod,
    expectedDueDate: expectedDueDate ?? this.expectedDueDate,
    status: status ?? this.status,
    deliveredAt: deliveredAt.present ? deliveredAt.value : this.deliveredAt,
    notes: notes.present ? notes.value : this.notes,
    hospitalName: hospitalName.present ? hospitalName.value : this.hospitalName,
    hospitalPhone: hospitalPhone.present
        ? hospitalPhone.value
        : this.hospitalPhone,
    lastCheckinAt: lastCheckinAt.present
        ? lastCheckinAt.value
        : this.lastCheckinAt,
    lastRiskLevel: lastRiskLevel.present
        ? lastRiskLevel.value
        : this.lastRiskLevel,
  );
  PregnancyRow copyWithCompanion(PregnanciesCompanion data) {
    return PregnancyRow(
      id: data.id.present ? data.id.value : this.id,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      synced: data.synced.present ? data.synced.value : this.synced,
      lastMenstrualPeriod: data.lastMenstrualPeriod.present
          ? data.lastMenstrualPeriod.value
          : this.lastMenstrualPeriod,
      expectedDueDate: data.expectedDueDate.present
          ? data.expectedDueDate.value
          : this.expectedDueDate,
      status: data.status.present ? data.status.value : this.status,
      deliveredAt: data.deliveredAt.present
          ? data.deliveredAt.value
          : this.deliveredAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      hospitalName: data.hospitalName.present
          ? data.hospitalName.value
          : this.hospitalName,
      hospitalPhone: data.hospitalPhone.present
          ? data.hospitalPhone.value
          : this.hospitalPhone,
      lastCheckinAt: data.lastCheckinAt.present
          ? data.lastCheckinAt.value
          : this.lastCheckinAt,
      lastRiskLevel: data.lastRiskLevel.present
          ? data.lastRiskLevel.value
          : this.lastRiskLevel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PregnancyRow(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('lastMenstrualPeriod: $lastMenstrualPeriod, ')
          ..write('expectedDueDate: $expectedDueDate, ')
          ..write('status: $status, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('notes: $notes, ')
          ..write('hospitalName: $hospitalName, ')
          ..write('hospitalPhone: $hospitalPhone, ')
          ..write('lastCheckinAt: $lastCheckinAt, ')
          ..write('lastRiskLevel: $lastRiskLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientUpdatedAt,
    deleted,
    synced,
    lastMenstrualPeriod,
    expectedDueDate,
    status,
    deliveredAt,
    notes,
    hospitalName,
    hospitalPhone,
    lastCheckinAt,
    lastRiskLevel,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PregnancyRow &&
          other.id == this.id &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deleted == this.deleted &&
          other.synced == this.synced &&
          other.lastMenstrualPeriod == this.lastMenstrualPeriod &&
          other.expectedDueDate == this.expectedDueDate &&
          other.status == this.status &&
          other.deliveredAt == this.deliveredAt &&
          other.notes == this.notes &&
          other.hospitalName == this.hospitalName &&
          other.hospitalPhone == this.hospitalPhone &&
          other.lastCheckinAt == this.lastCheckinAt &&
          other.lastRiskLevel == this.lastRiskLevel);
}

class PregnanciesCompanion extends UpdateCompanion<PregnancyRow> {
  final Value<String> id;
  final Value<int> clientUpdatedAt;
  final Value<bool> deleted;
  final Value<bool> synced;
  final Value<DateTime?> lastMenstrualPeriod;
  final Value<DateTime> expectedDueDate;
  final Value<String> status;
  final Value<DateTime?> deliveredAt;
  final Value<String?> notes;
  final Value<String?> hospitalName;
  final Value<String?> hospitalPhone;
  final Value<DateTime?> lastCheckinAt;
  final Value<String?> lastRiskLevel;
  final Value<int> rowid;
  const PregnanciesCompanion({
    this.id = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    this.lastMenstrualPeriod = const Value.absent(),
    this.expectedDueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.deliveredAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.hospitalName = const Value.absent(),
    this.hospitalPhone = const Value.absent(),
    this.lastCheckinAt = const Value.absent(),
    this.lastRiskLevel = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PregnanciesCompanion.insert({
    required String id,
    required int clientUpdatedAt,
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    this.lastMenstrualPeriod = const Value.absent(),
    required DateTime expectedDueDate,
    this.status = const Value.absent(),
    this.deliveredAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.hospitalName = const Value.absent(),
    this.hospitalPhone = const Value.absent(),
    this.lastCheckinAt = const Value.absent(),
    this.lastRiskLevel = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clientUpdatedAt = Value(clientUpdatedAt),
       expectedDueDate = Value(expectedDueDate);
  static Insertable<PregnancyRow> custom({
    Expression<String>? id,
    Expression<int>? clientUpdatedAt,
    Expression<bool>? deleted,
    Expression<bool>? synced,
    Expression<DateTime>? lastMenstrualPeriod,
    Expression<DateTime>? expectedDueDate,
    Expression<String>? status,
    Expression<DateTime>? deliveredAt,
    Expression<String>? notes,
    Expression<String>? hospitalName,
    Expression<String>? hospitalPhone,
    Expression<DateTime>? lastCheckinAt,
    Expression<String>? lastRiskLevel,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deleted != null) 'deleted': deleted,
      if (synced != null) 'synced': synced,
      if (lastMenstrualPeriod != null)
        'last_menstrual_period': lastMenstrualPeriod,
      if (expectedDueDate != null) 'expected_due_date': expectedDueDate,
      if (status != null) 'status': status,
      if (deliveredAt != null) 'delivered_at': deliveredAt,
      if (notes != null) 'notes': notes,
      if (hospitalName != null) 'hospital_name': hospitalName,
      if (hospitalPhone != null) 'hospital_phone': hospitalPhone,
      if (lastCheckinAt != null) 'last_checkin_at': lastCheckinAt,
      if (lastRiskLevel != null) 'last_risk_level': lastRiskLevel,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PregnanciesCompanion copyWith({
    Value<String>? id,
    Value<int>? clientUpdatedAt,
    Value<bool>? deleted,
    Value<bool>? synced,
    Value<DateTime?>? lastMenstrualPeriod,
    Value<DateTime>? expectedDueDate,
    Value<String>? status,
    Value<DateTime?>? deliveredAt,
    Value<String?>? notes,
    Value<String?>? hospitalName,
    Value<String?>? hospitalPhone,
    Value<DateTime?>? lastCheckinAt,
    Value<String?>? lastRiskLevel,
    Value<int>? rowid,
  }) {
    return PregnanciesCompanion(
      id: id ?? this.id,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deleted: deleted ?? this.deleted,
      synced: synced ?? this.synced,
      lastMenstrualPeriod: lastMenstrualPeriod ?? this.lastMenstrualPeriod,
      expectedDueDate: expectedDueDate ?? this.expectedDueDate,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      notes: notes ?? this.notes,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalPhone: hospitalPhone ?? this.hospitalPhone,
      lastCheckinAt: lastCheckinAt ?? this.lastCheckinAt,
      lastRiskLevel: lastRiskLevel ?? this.lastRiskLevel,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<int>(clientUpdatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (lastMenstrualPeriod.present) {
      map['last_menstrual_period'] = Variable<DateTime>(
        lastMenstrualPeriod.value,
      );
    }
    if (expectedDueDate.present) {
      map['expected_due_date'] = Variable<DateTime>(expectedDueDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (deliveredAt.present) {
      map['delivered_at'] = Variable<DateTime>(deliveredAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (hospitalName.present) {
      map['hospital_name'] = Variable<String>(hospitalName.value);
    }
    if (hospitalPhone.present) {
      map['hospital_phone'] = Variable<String>(hospitalPhone.value);
    }
    if (lastCheckinAt.present) {
      map['last_checkin_at'] = Variable<DateTime>(lastCheckinAt.value);
    }
    if (lastRiskLevel.present) {
      map['last_risk_level'] = Variable<String>(lastRiskLevel.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PregnanciesCompanion(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('lastMenstrualPeriod: $lastMenstrualPeriod, ')
          ..write('expectedDueDate: $expectedDueDate, ')
          ..write('status: $status, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('notes: $notes, ')
          ..write('hospitalName: $hospitalName, ')
          ..write('hospitalPhone: $hospitalPhone, ')
          ..write('lastCheckinAt: $lastCheckinAt, ')
          ..write('lastRiskLevel: $lastRiskLevel, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssessmentsTable extends Assessments
    with TableInfo<$AssessmentsTable, AssessmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssessmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientUpdatedAtMeta = const VerificationMeta(
    'clientUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> clientUpdatedAt = GeneratedColumn<int>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _subjectTypeMeta = const VerificationMeta(
    'subjectType',
  );
  @override
  late final GeneratedColumn<String> subjectType = GeneratedColumn<String>(
    'subject_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pregnancyIdMeta = const VerificationMeta(
    'pregnancyId',
  );
  @override
  late final GeneratedColumn<String> pregnancyId = GeneratedColumn<String>(
    'pregnancy_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _answersJsonMeta = const VerificationMeta(
    'answersJson',
  );
  @override
  late final GeneratedColumn<String> answersJson = GeneratedColumn<String>(
    'answers_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _dangerSignsJsonMeta = const VerificationMeta(
    'dangerSignsJson',
  );
  @override
  late final GeneratedColumn<String> dangerSignsJson = GeneratedColumn<String>(
    'danger_signs_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _riskLevelMeta = const VerificationMeta(
    'riskLevel',
  );
  @override
  late final GeneratedColumn<String> riskLevel = GeneratedColumn<String>(
    'risk_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _guidanceMeta = const VerificationMeta(
    'guidance',
  );
  @override
  late final GeneratedColumn<String> guidance = GeneratedColumn<String>(
    'guidance',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientUpdatedAt,
    deleted,
    synced,
    subjectType,
    childId,
    pregnancyId,
    answersJson,
    dangerSignsJson,
    riskLevel,
    guidance,
    lng,
    lat,
    startedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assessments';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssessmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
        _clientUpdatedAtMeta,
        clientUpdatedAt.isAcceptableOrUnknown(
          data['client_updated_at']!,
          _clientUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('subject_type')) {
      context.handle(
        _subjectTypeMeta,
        subjectType.isAcceptableOrUnknown(
          data['subject_type']!,
          _subjectTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subjectTypeMeta);
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    }
    if (data.containsKey('pregnancy_id')) {
      context.handle(
        _pregnancyIdMeta,
        pregnancyId.isAcceptableOrUnknown(
          data['pregnancy_id']!,
          _pregnancyIdMeta,
        ),
      );
    }
    if (data.containsKey('answers_json')) {
      context.handle(
        _answersJsonMeta,
        answersJson.isAcceptableOrUnknown(
          data['answers_json']!,
          _answersJsonMeta,
        ),
      );
    }
    if (data.containsKey('danger_signs_json')) {
      context.handle(
        _dangerSignsJsonMeta,
        dangerSignsJson.isAcceptableOrUnknown(
          data['danger_signs_json']!,
          _dangerSignsJsonMeta,
        ),
      );
    }
    if (data.containsKey('risk_level')) {
      context.handle(
        _riskLevelMeta,
        riskLevel.isAcceptableOrUnknown(data['risk_level']!, _riskLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_riskLevelMeta);
    }
    if (data.containsKey('guidance')) {
      context.handle(
        _guidanceMeta,
        guidance.isAcceptableOrUnknown(data['guidance']!, _guidanceMeta),
      );
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssessmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssessmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      subjectType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_type'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      ),
      pregnancyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pregnancy_id'],
      ),
      answersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answers_json'],
      )!,
      dangerSignsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}danger_signs_json'],
      )!,
      riskLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}risk_level'],
      )!,
      guidance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guidance'],
      ),
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      ),
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $AssessmentsTable createAlias(String alias) {
    return $AssessmentsTable(attachedDatabase, alias);
  }
}

class AssessmentRow extends DataClass implements Insertable<AssessmentRow> {
  final String id;
  final int clientUpdatedAt;
  final bool deleted;
  final bool synced;
  final String subjectType;
  final String? childId;
  final String? pregnancyId;
  final String answersJson;
  final String dangerSignsJson;
  final String riskLevel;
  final String? guidance;
  final double? lng;
  final double? lat;
  final DateTime? startedAt;
  final DateTime completedAt;
  const AssessmentRow({
    required this.id,
    required this.clientUpdatedAt,
    required this.deleted,
    required this.synced,
    required this.subjectType,
    this.childId,
    this.pregnancyId,
    required this.answersJson,
    required this.dangerSignsJson,
    required this.riskLevel,
    this.guidance,
    this.lng,
    this.lat,
    this.startedAt,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_updated_at'] = Variable<int>(clientUpdatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['synced'] = Variable<bool>(synced);
    map['subject_type'] = Variable<String>(subjectType);
    if (!nullToAbsent || childId != null) {
      map['child_id'] = Variable<String>(childId);
    }
    if (!nullToAbsent || pregnancyId != null) {
      map['pregnancy_id'] = Variable<String>(pregnancyId);
    }
    map['answers_json'] = Variable<String>(answersJson);
    map['danger_signs_json'] = Variable<String>(dangerSignsJson);
    map['risk_level'] = Variable<String>(riskLevel);
    if (!nullToAbsent || guidance != null) {
      map['guidance'] = Variable<String>(guidance);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  AssessmentsCompanion toCompanion(bool nullToAbsent) {
    return AssessmentsCompanion(
      id: Value(id),
      clientUpdatedAt: Value(clientUpdatedAt),
      deleted: Value(deleted),
      synced: Value(synced),
      subjectType: Value(subjectType),
      childId: childId == null && nullToAbsent
          ? const Value.absent()
          : Value(childId),
      pregnancyId: pregnancyId == null && nullToAbsent
          ? const Value.absent()
          : Value(pregnancyId),
      answersJson: Value(answersJson),
      dangerSignsJson: Value(dangerSignsJson),
      riskLevel: Value(riskLevel),
      guidance: guidance == null && nullToAbsent
          ? const Value.absent()
          : Value(guidance),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: Value(completedAt),
    );
  }

  factory AssessmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssessmentRow(
      id: serializer.fromJson<String>(json['id']),
      clientUpdatedAt: serializer.fromJson<int>(json['clientUpdatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      synced: serializer.fromJson<bool>(json['synced']),
      subjectType: serializer.fromJson<String>(json['subjectType']),
      childId: serializer.fromJson<String?>(json['childId']),
      pregnancyId: serializer.fromJson<String?>(json['pregnancyId']),
      answersJson: serializer.fromJson<String>(json['answersJson']),
      dangerSignsJson: serializer.fromJson<String>(json['dangerSignsJson']),
      riskLevel: serializer.fromJson<String>(json['riskLevel']),
      guidance: serializer.fromJson<String?>(json['guidance']),
      lng: serializer.fromJson<double?>(json['lng']),
      lat: serializer.fromJson<double?>(json['lat']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientUpdatedAt': serializer.toJson<int>(clientUpdatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'synced': serializer.toJson<bool>(synced),
      'subjectType': serializer.toJson<String>(subjectType),
      'childId': serializer.toJson<String?>(childId),
      'pregnancyId': serializer.toJson<String?>(pregnancyId),
      'answersJson': serializer.toJson<String>(answersJson),
      'dangerSignsJson': serializer.toJson<String>(dangerSignsJson),
      'riskLevel': serializer.toJson<String>(riskLevel),
      'guidance': serializer.toJson<String?>(guidance),
      'lng': serializer.toJson<double?>(lng),
      'lat': serializer.toJson<double?>(lat),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  AssessmentRow copyWith({
    String? id,
    int? clientUpdatedAt,
    bool? deleted,
    bool? synced,
    String? subjectType,
    Value<String?> childId = const Value.absent(),
    Value<String?> pregnancyId = const Value.absent(),
    String? answersJson,
    String? dangerSignsJson,
    String? riskLevel,
    Value<String?> guidance = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    Value<double?> lat = const Value.absent(),
    Value<DateTime?> startedAt = const Value.absent(),
    DateTime? completedAt,
  }) => AssessmentRow(
    id: id ?? this.id,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deleted: deleted ?? this.deleted,
    synced: synced ?? this.synced,
    subjectType: subjectType ?? this.subjectType,
    childId: childId.present ? childId.value : this.childId,
    pregnancyId: pregnancyId.present ? pregnancyId.value : this.pregnancyId,
    answersJson: answersJson ?? this.answersJson,
    dangerSignsJson: dangerSignsJson ?? this.dangerSignsJson,
    riskLevel: riskLevel ?? this.riskLevel,
    guidance: guidance.present ? guidance.value : this.guidance,
    lng: lng.present ? lng.value : this.lng,
    lat: lat.present ? lat.value : this.lat,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    completedAt: completedAt ?? this.completedAt,
  );
  AssessmentRow copyWithCompanion(AssessmentsCompanion data) {
    return AssessmentRow(
      id: data.id.present ? data.id.value : this.id,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      synced: data.synced.present ? data.synced.value : this.synced,
      subjectType: data.subjectType.present
          ? data.subjectType.value
          : this.subjectType,
      childId: data.childId.present ? data.childId.value : this.childId,
      pregnancyId: data.pregnancyId.present
          ? data.pregnancyId.value
          : this.pregnancyId,
      answersJson: data.answersJson.present
          ? data.answersJson.value
          : this.answersJson,
      dangerSignsJson: data.dangerSignsJson.present
          ? data.dangerSignsJson.value
          : this.dangerSignsJson,
      riskLevel: data.riskLevel.present ? data.riskLevel.value : this.riskLevel,
      guidance: data.guidance.present ? data.guidance.value : this.guidance,
      lng: data.lng.present ? data.lng.value : this.lng,
      lat: data.lat.present ? data.lat.value : this.lat,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssessmentRow(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('subjectType: $subjectType, ')
          ..write('childId: $childId, ')
          ..write('pregnancyId: $pregnancyId, ')
          ..write('answersJson: $answersJson, ')
          ..write('dangerSignsJson: $dangerSignsJson, ')
          ..write('riskLevel: $riskLevel, ')
          ..write('guidance: $guidance, ')
          ..write('lng: $lng, ')
          ..write('lat: $lat, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientUpdatedAt,
    deleted,
    synced,
    subjectType,
    childId,
    pregnancyId,
    answersJson,
    dangerSignsJson,
    riskLevel,
    guidance,
    lng,
    lat,
    startedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssessmentRow &&
          other.id == this.id &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deleted == this.deleted &&
          other.synced == this.synced &&
          other.subjectType == this.subjectType &&
          other.childId == this.childId &&
          other.pregnancyId == this.pregnancyId &&
          other.answersJson == this.answersJson &&
          other.dangerSignsJson == this.dangerSignsJson &&
          other.riskLevel == this.riskLevel &&
          other.guidance == this.guidance &&
          other.lng == this.lng &&
          other.lat == this.lat &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class AssessmentsCompanion extends UpdateCompanion<AssessmentRow> {
  final Value<String> id;
  final Value<int> clientUpdatedAt;
  final Value<bool> deleted;
  final Value<bool> synced;
  final Value<String> subjectType;
  final Value<String?> childId;
  final Value<String?> pregnancyId;
  final Value<String> answersJson;
  final Value<String> dangerSignsJson;
  final Value<String> riskLevel;
  final Value<String?> guidance;
  final Value<double?> lng;
  final Value<double?> lat;
  final Value<DateTime?> startedAt;
  final Value<DateTime> completedAt;
  final Value<int> rowid;
  const AssessmentsCompanion({
    this.id = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    this.subjectType = const Value.absent(),
    this.childId = const Value.absent(),
    this.pregnancyId = const Value.absent(),
    this.answersJson = const Value.absent(),
    this.dangerSignsJson = const Value.absent(),
    this.riskLevel = const Value.absent(),
    this.guidance = const Value.absent(),
    this.lng = const Value.absent(),
    this.lat = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssessmentsCompanion.insert({
    required String id,
    required int clientUpdatedAt,
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    required String subjectType,
    this.childId = const Value.absent(),
    this.pregnancyId = const Value.absent(),
    this.answersJson = const Value.absent(),
    this.dangerSignsJson = const Value.absent(),
    required String riskLevel,
    this.guidance = const Value.absent(),
    this.lng = const Value.absent(),
    this.lat = const Value.absent(),
    this.startedAt = const Value.absent(),
    required DateTime completedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clientUpdatedAt = Value(clientUpdatedAt),
       subjectType = Value(subjectType),
       riskLevel = Value(riskLevel),
       completedAt = Value(completedAt);
  static Insertable<AssessmentRow> custom({
    Expression<String>? id,
    Expression<int>? clientUpdatedAt,
    Expression<bool>? deleted,
    Expression<bool>? synced,
    Expression<String>? subjectType,
    Expression<String>? childId,
    Expression<String>? pregnancyId,
    Expression<String>? answersJson,
    Expression<String>? dangerSignsJson,
    Expression<String>? riskLevel,
    Expression<String>? guidance,
    Expression<double>? lng,
    Expression<double>? lat,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deleted != null) 'deleted': deleted,
      if (synced != null) 'synced': synced,
      if (subjectType != null) 'subject_type': subjectType,
      if (childId != null) 'child_id': childId,
      if (pregnancyId != null) 'pregnancy_id': pregnancyId,
      if (answersJson != null) 'answers_json': answersJson,
      if (dangerSignsJson != null) 'danger_signs_json': dangerSignsJson,
      if (riskLevel != null) 'risk_level': riskLevel,
      if (guidance != null) 'guidance': guidance,
      if (lng != null) 'lng': lng,
      if (lat != null) 'lat': lat,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssessmentsCompanion copyWith({
    Value<String>? id,
    Value<int>? clientUpdatedAt,
    Value<bool>? deleted,
    Value<bool>? synced,
    Value<String>? subjectType,
    Value<String?>? childId,
    Value<String?>? pregnancyId,
    Value<String>? answersJson,
    Value<String>? dangerSignsJson,
    Value<String>? riskLevel,
    Value<String?>? guidance,
    Value<double?>? lng,
    Value<double?>? lat,
    Value<DateTime?>? startedAt,
    Value<DateTime>? completedAt,
    Value<int>? rowid,
  }) {
    return AssessmentsCompanion(
      id: id ?? this.id,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deleted: deleted ?? this.deleted,
      synced: synced ?? this.synced,
      subjectType: subjectType ?? this.subjectType,
      childId: childId ?? this.childId,
      pregnancyId: pregnancyId ?? this.pregnancyId,
      answersJson: answersJson ?? this.answersJson,
      dangerSignsJson: dangerSignsJson ?? this.dangerSignsJson,
      riskLevel: riskLevel ?? this.riskLevel,
      guidance: guidance ?? this.guidance,
      lng: lng ?? this.lng,
      lat: lat ?? this.lat,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<int>(clientUpdatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (subjectType.present) {
      map['subject_type'] = Variable<String>(subjectType.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (pregnancyId.present) {
      map['pregnancy_id'] = Variable<String>(pregnancyId.value);
    }
    if (answersJson.present) {
      map['answers_json'] = Variable<String>(answersJson.value);
    }
    if (dangerSignsJson.present) {
      map['danger_signs_json'] = Variable<String>(dangerSignsJson.value);
    }
    if (riskLevel.present) {
      map['risk_level'] = Variable<String>(riskLevel.value);
    }
    if (guidance.present) {
      map['guidance'] = Variable<String>(guidance.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssessmentsCompanion(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('subjectType: $subjectType, ')
          ..write('childId: $childId, ')
          ..write('pregnancyId: $pregnancyId, ')
          ..write('answersJson: $answersJson, ')
          ..write('dangerSignsJson: $dangerSignsJson, ')
          ..write('riskLevel: $riskLevel, ')
          ..write('guidance: $guidance, ')
          ..write('lng: $lng, ')
          ..write('lat: $lat, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, ReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientUpdatedAtMeta = const VerificationMeta(
    'clientUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> clientUpdatedAt = GeneratedColumn<int>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pregnancyIdMeta = const VerificationMeta(
    'pregnancyId',
  );
  @override
  late final GeneratedColumn<String> pregnancyId = GeneratedColumn<String>(
    'pregnancy_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('upcoming'),
  );
  static const VerificationMeta _snoozedUntilMeta = const VerificationMeta(
    'snoozedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> snoozedUntil = GeneratedColumn<DateTime>(
    'snoozed_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientUpdatedAt,
    deleted,
    synced,
    childId,
    pregnancyId,
    type,
    title,
    description,
    dueDate,
    status,
    snoozedUntil,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
        _clientUpdatedAtMeta,
        clientUpdatedAt.isAcceptableOrUnknown(
          data['client_updated_at']!,
          _clientUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    }
    if (data.containsKey('pregnancy_id')) {
      context.handle(
        _pregnancyIdMeta,
        pregnancyId.isAcceptableOrUnknown(
          data['pregnancy_id']!,
          _pregnancyIdMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(
        _snoozedUntilMeta,
        snoozedUntil.isAcceptableOrUnknown(
          data['snoozed_until']!,
          _snoozedUntilMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      ),
      pregnancyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pregnancy_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      snoozedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}snoozed_until'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  final String id;
  final int clientUpdatedAt;
  final bool deleted;
  final bool synced;
  final String? childId;
  final String? pregnancyId;
  final String type;
  final String title;
  final String? description;
  final DateTime dueDate;
  final String status;
  final DateTime? snoozedUntil;
  final DateTime? completedAt;
  const ReminderRow({
    required this.id,
    required this.clientUpdatedAt,
    required this.deleted,
    required this.synced,
    this.childId,
    this.pregnancyId,
    required this.type,
    required this.title,
    this.description,
    required this.dueDate,
    required this.status,
    this.snoozedUntil,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_updated_at'] = Variable<int>(clientUpdatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || childId != null) {
      map['child_id'] = Variable<String>(childId);
    }
    if (!nullToAbsent || pregnancyId != null) {
      map['pregnancy_id'] = Variable<String>(pregnancyId);
    }
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['due_date'] = Variable<DateTime>(dueDate);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      clientUpdatedAt: Value(clientUpdatedAt),
      deleted: Value(deleted),
      synced: Value(synced),
      childId: childId == null && nullToAbsent
          ? const Value.absent()
          : Value(childId),
      pregnancyId: pregnancyId == null && nullToAbsent
          ? const Value.absent()
          : Value(pregnancyId),
      type: Value(type),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      dueDate: Value(dueDate),
      status: Value(status),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory ReminderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRow(
      id: serializer.fromJson<String>(json['id']),
      clientUpdatedAt: serializer.fromJson<int>(json['clientUpdatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      synced: serializer.fromJson<bool>(json['synced']),
      childId: serializer.fromJson<String?>(json['childId']),
      pregnancyId: serializer.fromJson<String?>(json['pregnancyId']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      status: serializer.fromJson<String>(json['status']),
      snoozedUntil: serializer.fromJson<DateTime?>(json['snoozedUntil']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientUpdatedAt': serializer.toJson<int>(clientUpdatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'synced': serializer.toJson<bool>(synced),
      'childId': serializer.toJson<String?>(childId),
      'pregnancyId': serializer.toJson<String?>(pregnancyId),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'status': serializer.toJson<String>(status),
      'snoozedUntil': serializer.toJson<DateTime?>(snoozedUntil),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  ReminderRow copyWith({
    String? id,
    int? clientUpdatedAt,
    bool? deleted,
    bool? synced,
    Value<String?> childId = const Value.absent(),
    Value<String?> pregnancyId = const Value.absent(),
    String? type,
    String? title,
    Value<String?> description = const Value.absent(),
    DateTime? dueDate,
    String? status,
    Value<DateTime?> snoozedUntil = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
  }) => ReminderRow(
    id: id ?? this.id,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deleted: deleted ?? this.deleted,
    synced: synced ?? this.synced,
    childId: childId.present ? childId.value : this.childId,
    pregnancyId: pregnancyId.present ? pregnancyId.value : this.pregnancyId,
    type: type ?? this.type,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    dueDate: dueDate ?? this.dueDate,
    status: status ?? this.status,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  ReminderRow copyWithCompanion(RemindersCompanion data) {
    return ReminderRow(
      id: data.id.present ? data.id.value : this.id,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      synced: data.synced.present ? data.synced.value : this.synced,
      childId: data.childId.present ? data.childId.value : this.childId,
      pregnancyId: data.pregnancyId.present
          ? data.pregnancyId.value
          : this.pregnancyId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      status: data.status.present ? data.status.value : this.status,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRow(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('childId: $childId, ')
          ..write('pregnancyId: $pregnancyId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientUpdatedAt,
    deleted,
    synced,
    childId,
    pregnancyId,
    type,
    title,
    description,
    dueDate,
    status,
    snoozedUntil,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRow &&
          other.id == this.id &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deleted == this.deleted &&
          other.synced == this.synced &&
          other.childId == this.childId &&
          other.pregnancyId == this.pregnancyId &&
          other.type == this.type &&
          other.title == this.title &&
          other.description == this.description &&
          other.dueDate == this.dueDate &&
          other.status == this.status &&
          other.snoozedUntil == this.snoozedUntil &&
          other.completedAt == this.completedAt);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<String> id;
  final Value<int> clientUpdatedAt;
  final Value<bool> deleted;
  final Value<bool> synced;
  final Value<String?> childId;
  final Value<String?> pregnancyId;
  final Value<String> type;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime> dueDate;
  final Value<String> status;
  final Value<DateTime?> snoozedUntil;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    this.childId = const Value.absent(),
    this.pregnancyId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required int clientUpdatedAt,
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    this.childId = const Value.absent(),
    this.pregnancyId = const Value.absent(),
    required String type,
    required String title,
    this.description = const Value.absent(),
    required DateTime dueDate,
    this.status = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clientUpdatedAt = Value(clientUpdatedAt),
       type = Value(type),
       title = Value(title),
       dueDate = Value(dueDate);
  static Insertable<ReminderRow> custom({
    Expression<String>? id,
    Expression<int>? clientUpdatedAt,
    Expression<bool>? deleted,
    Expression<bool>? synced,
    Expression<String>? childId,
    Expression<String>? pregnancyId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? dueDate,
    Expression<String>? status,
    Expression<DateTime>? snoozedUntil,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deleted != null) 'deleted': deleted,
      if (synced != null) 'synced': synced,
      if (childId != null) 'child_id': childId,
      if (pregnancyId != null) 'pregnancy_id': pregnancyId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (dueDate != null) 'due_date': dueDate,
      if (status != null) 'status': status,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith({
    Value<String>? id,
    Value<int>? clientUpdatedAt,
    Value<bool>? deleted,
    Value<bool>? synced,
    Value<String?>? childId,
    Value<String?>? pregnancyId,
    Value<String>? type,
    Value<String>? title,
    Value<String?>? description,
    Value<DateTime>? dueDate,
    Value<String>? status,
    Value<DateTime?>? snoozedUntil,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deleted: deleted ?? this.deleted,
      synced: synced ?? this.synced,
      childId: childId ?? this.childId,
      pregnancyId: pregnancyId ?? this.pregnancyId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<int>(clientUpdatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (pregnancyId.present) {
      map['pregnancy_id'] = Variable<String>(pregnancyId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('childId: $childId, ')
          ..write('pregnancyId: $pregnancyId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GrowthRecordsTable extends GrowthRecords
    with TableInfo<$GrowthRecordsTable, GrowthRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrowthRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientUpdatedAtMeta = const VerificationMeta(
    'clientUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> clientUpdatedAt = GeneratedColumn<int>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measuredAtMeta = const VerificationMeta(
    'measuredAt',
  );
  @override
  late final GeneratedColumn<DateTime> measuredAt = GeneratedColumn<DateTime>(
    'measured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientUpdatedAt,
    deleted,
    synced,
    childId,
    weightKg,
    measuredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'growth_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<GrowthRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
        _clientUpdatedAtMeta,
        clientUpdatedAt.isAcceptableOrUnknown(
          data['client_updated_at']!,
          _clientUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('measured_at')) {
      context.handle(
        _measuredAtMeta,
        measuredAt.isAcceptableOrUnknown(data['measured_at']!, _measuredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_measuredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GrowthRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GrowthRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      measuredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}measured_at'],
      )!,
    );
  }

  @override
  $GrowthRecordsTable createAlias(String alias) {
    return $GrowthRecordsTable(attachedDatabase, alias);
  }
}

class GrowthRecordRow extends DataClass implements Insertable<GrowthRecordRow> {
  final String id;
  final int clientUpdatedAt;
  final bool deleted;
  final bool synced;
  final String childId;
  final double weightKg;
  final DateTime measuredAt;
  const GrowthRecordRow({
    required this.id,
    required this.clientUpdatedAt,
    required this.deleted,
    required this.synced,
    required this.childId,
    required this.weightKg,
    required this.measuredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_updated_at'] = Variable<int>(clientUpdatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['synced'] = Variable<bool>(synced);
    map['child_id'] = Variable<String>(childId);
    map['weight_kg'] = Variable<double>(weightKg);
    map['measured_at'] = Variable<DateTime>(measuredAt);
    return map;
  }

  GrowthRecordsCompanion toCompanion(bool nullToAbsent) {
    return GrowthRecordsCompanion(
      id: Value(id),
      clientUpdatedAt: Value(clientUpdatedAt),
      deleted: Value(deleted),
      synced: Value(synced),
      childId: Value(childId),
      weightKg: Value(weightKg),
      measuredAt: Value(measuredAt),
    );
  }

  factory GrowthRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GrowthRecordRow(
      id: serializer.fromJson<String>(json['id']),
      clientUpdatedAt: serializer.fromJson<int>(json['clientUpdatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      synced: serializer.fromJson<bool>(json['synced']),
      childId: serializer.fromJson<String>(json['childId']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      measuredAt: serializer.fromJson<DateTime>(json['measuredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientUpdatedAt': serializer.toJson<int>(clientUpdatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'synced': serializer.toJson<bool>(synced),
      'childId': serializer.toJson<String>(childId),
      'weightKg': serializer.toJson<double>(weightKg),
      'measuredAt': serializer.toJson<DateTime>(measuredAt),
    };
  }

  GrowthRecordRow copyWith({
    String? id,
    int? clientUpdatedAt,
    bool? deleted,
    bool? synced,
    String? childId,
    double? weightKg,
    DateTime? measuredAt,
  }) => GrowthRecordRow(
    id: id ?? this.id,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deleted: deleted ?? this.deleted,
    synced: synced ?? this.synced,
    childId: childId ?? this.childId,
    weightKg: weightKg ?? this.weightKg,
    measuredAt: measuredAt ?? this.measuredAt,
  );
  GrowthRecordRow copyWithCompanion(GrowthRecordsCompanion data) {
    return GrowthRecordRow(
      id: data.id.present ? data.id.value : this.id,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      synced: data.synced.present ? data.synced.value : this.synced,
      childId: data.childId.present ? data.childId.value : this.childId,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      measuredAt: data.measuredAt.present
          ? data.measuredAt.value
          : this.measuredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GrowthRecordRow(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('childId: $childId, ')
          ..write('weightKg: $weightKg, ')
          ..write('measuredAt: $measuredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientUpdatedAt,
    deleted,
    synced,
    childId,
    weightKg,
    measuredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GrowthRecordRow &&
          other.id == this.id &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deleted == this.deleted &&
          other.synced == this.synced &&
          other.childId == this.childId &&
          other.weightKg == this.weightKg &&
          other.measuredAt == this.measuredAt);
}

class GrowthRecordsCompanion extends UpdateCompanion<GrowthRecordRow> {
  final Value<String> id;
  final Value<int> clientUpdatedAt;
  final Value<bool> deleted;
  final Value<bool> synced;
  final Value<String> childId;
  final Value<double> weightKg;
  final Value<DateTime> measuredAt;
  final Value<int> rowid;
  const GrowthRecordsCompanion({
    this.id = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    this.childId = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.measuredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GrowthRecordsCompanion.insert({
    required String id,
    required int clientUpdatedAt,
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    required String childId,
    required double weightKg,
    required DateTime measuredAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clientUpdatedAt = Value(clientUpdatedAt),
       childId = Value(childId),
       weightKg = Value(weightKg),
       measuredAt = Value(measuredAt);
  static Insertable<GrowthRecordRow> custom({
    Expression<String>? id,
    Expression<int>? clientUpdatedAt,
    Expression<bool>? deleted,
    Expression<bool>? synced,
    Expression<String>? childId,
    Expression<double>? weightKg,
    Expression<DateTime>? measuredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deleted != null) 'deleted': deleted,
      if (synced != null) 'synced': synced,
      if (childId != null) 'child_id': childId,
      if (weightKg != null) 'weight_kg': weightKg,
      if (measuredAt != null) 'measured_at': measuredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GrowthRecordsCompanion copyWith({
    Value<String>? id,
    Value<int>? clientUpdatedAt,
    Value<bool>? deleted,
    Value<bool>? synced,
    Value<String>? childId,
    Value<double>? weightKg,
    Value<DateTime>? measuredAt,
    Value<int>? rowid,
  }) {
    return GrowthRecordsCompanion(
      id: id ?? this.id,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deleted: deleted ?? this.deleted,
      synced: synced ?? this.synced,
      childId: childId ?? this.childId,
      weightKg: weightKg ?? this.weightKg,
      measuredAt: measuredAt ?? this.measuredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<int>(clientUpdatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (measuredAt.present) {
      map['measured_at'] = Variable<DateTime>(measuredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrowthRecordsCompanion(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('childId: $childId, ')
          ..write('weightKg: $weightKg, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientUpdatedAtMeta = const VerificationMeta(
    'clientUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> clientUpdatedAt = GeneratedColumn<int>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientUpdatedAt,
    deleted,
    synced,
    role,
    content,
    sentAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
        _clientUpdatedAtMeta,
        clientUpdatedAt.isAcceptableOrUnknown(
          data['client_updated_at']!,
          _clientUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      )!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class ChatMessageRow extends DataClass implements Insertable<ChatMessageRow> {
  final String id;
  final int clientUpdatedAt;
  final bool deleted;
  final bool synced;
  final String role;
  final String content;
  final DateTime sentAt;
  const ChatMessageRow({
    required this.id,
    required this.clientUpdatedAt,
    required this.deleted,
    required this.synced,
    required this.role,
    required this.content,
    required this.sentAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_updated_at'] = Variable<int>(clientUpdatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['synced'] = Variable<bool>(synced);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['sent_at'] = Variable<DateTime>(sentAt);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      clientUpdatedAt: Value(clientUpdatedAt),
      deleted: Value(deleted),
      synced: Value(synced),
      role: Value(role),
      content: Value(content),
      sentAt: Value(sentAt),
    );
  }

  factory ChatMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessageRow(
      id: serializer.fromJson<String>(json['id']),
      clientUpdatedAt: serializer.fromJson<int>(json['clientUpdatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      synced: serializer.fromJson<bool>(json['synced']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientUpdatedAt': serializer.toJson<int>(clientUpdatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'synced': serializer.toJson<bool>(synced),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'sentAt': serializer.toJson<DateTime>(sentAt),
    };
  }

  ChatMessageRow copyWith({
    String? id,
    int? clientUpdatedAt,
    bool? deleted,
    bool? synced,
    String? role,
    String? content,
    DateTime? sentAt,
  }) => ChatMessageRow(
    id: id ?? this.id,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deleted: deleted ?? this.deleted,
    synced: synced ?? this.synced,
    role: role ?? this.role,
    content: content ?? this.content,
    sentAt: sentAt ?? this.sentAt,
  );
  ChatMessageRow copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessageRow(
      id: data.id.present ? data.id.value : this.id,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      synced: data.synced.present ? data.synced.value : this.synced,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessageRow(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('sentAt: $sentAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, clientUpdatedAt, deleted, synced, role, content, sentAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessageRow &&
          other.id == this.id &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deleted == this.deleted &&
          other.synced == this.synced &&
          other.role == this.role &&
          other.content == this.content &&
          other.sentAt == this.sentAt);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessageRow> {
  final Value<String> id;
  final Value<int> clientUpdatedAt;
  final Value<bool> deleted;
  final Value<bool> synced;
  final Value<String> role;
  final Value<String> content;
  final Value<DateTime> sentAt;
  final Value<int> rowid;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    required String id,
    required int clientUpdatedAt,
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    required String role,
    required String content,
    required DateTime sentAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clientUpdatedAt = Value(clientUpdatedAt),
       role = Value(role),
       content = Value(content),
       sentAt = Value(sentAt);
  static Insertable<ChatMessageRow> custom({
    Expression<String>? id,
    Expression<int>? clientUpdatedAt,
    Expression<bool>? deleted,
    Expression<bool>? synced,
    Expression<String>? role,
    Expression<String>? content,
    Expression<DateTime>? sentAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deleted != null) 'deleted': deleted,
      if (synced != null) 'synced': synced,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (sentAt != null) 'sent_at': sentAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatMessagesCompanion copyWith({
    Value<String>? id,
    Value<int>? clientUpdatedAt,
    Value<bool>? deleted,
    Value<bool>? synced,
    Value<String>? role,
    Value<String>? content,
    Value<DateTime>? sentAt,
    Value<int>? rowid,
  }) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deleted: deleted ?? this.deleted,
      synced: synced ?? this.synced,
      role: role ?? this.role,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<int>(clientUpdatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('sentAt: $sentAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DietPlansTable extends DietPlans
    with TableInfo<$DietPlansTable, DietPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DietPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientUpdatedAtMeta = const VerificationMeta(
    'clientUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> clientUpdatedAt = GeneratedColumn<int>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _audienceMeta = const VerificationMeta(
    'audience',
  );
  @override
  late final GeneratedColumn<String> audience = GeneratedColumn<String>(
    'audience',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<String> season = GeneratedColumn<String>(
    'season',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _budgetMeta = const VerificationMeta('budget');
  @override
  late final GeneratedColumn<String> budget = GeneratedColumn<String>(
    'budget',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pantryMeta = const VerificationMeta('pantry');
  @override
  late final GeneratedColumn<String> pantry = GeneratedColumn<String>(
    'pantry',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spokenTextMeta = const VerificationMeta(
    'spokenText',
  );
  @override
  late final GeneratedColumn<String> spokenText = GeneratedColumn<String>(
    'spoken_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planJsonMeta = const VerificationMeta(
    'planJson',
  );
  @override
  late final GeneratedColumn<String> planJson = GeneratedColumn<String>(
    'plan_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('offline'),
  );
  static const VerificationMeta _plannedForMeta = const VerificationMeta(
    'plannedFor',
  );
  @override
  late final GeneratedColumn<DateTime> plannedFor = GeneratedColumn<DateTime>(
    'planned_for',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientUpdatedAt,
    deleted,
    synced,
    audience,
    season,
    budget,
    pantry,
    spokenText,
    planJson,
    source,
    plannedFor,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diet_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<DietPlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
        _clientUpdatedAtMeta,
        clientUpdatedAt.isAcceptableOrUnknown(
          data['client_updated_at']!,
          _clientUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('audience')) {
      context.handle(
        _audienceMeta,
        audience.isAcceptableOrUnknown(data['audience']!, _audienceMeta),
      );
    } else if (isInserting) {
      context.missing(_audienceMeta);
    }
    if (data.containsKey('season')) {
      context.handle(
        _seasonMeta,
        season.isAcceptableOrUnknown(data['season']!, _seasonMeta),
      );
    }
    if (data.containsKey('budget')) {
      context.handle(
        _budgetMeta,
        budget.isAcceptableOrUnknown(data['budget']!, _budgetMeta),
      );
    }
    if (data.containsKey('pantry')) {
      context.handle(
        _pantryMeta,
        pantry.isAcceptableOrUnknown(data['pantry']!, _pantryMeta),
      );
    }
    if (data.containsKey('spoken_text')) {
      context.handle(
        _spokenTextMeta,
        spokenText.isAcceptableOrUnknown(data['spoken_text']!, _spokenTextMeta),
      );
    }
    if (data.containsKey('plan_json')) {
      context.handle(
        _planJsonMeta,
        planJson.isAcceptableOrUnknown(data['plan_json']!, _planJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_planJsonMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('planned_for')) {
      context.handle(
        _plannedForMeta,
        plannedFor.isAcceptableOrUnknown(data['planned_for']!, _plannedForMeta),
      );
    } else if (isInserting) {
      context.missing(_plannedForMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DietPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DietPlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      audience: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audience'],
      )!,
      season: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}season'],
      ),
      budget: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}budget'],
      ),
      pantry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pantry'],
      ),
      spokenText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spoken_text'],
      ),
      planJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_json'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      plannedFor: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}planned_for'],
      )!,
    );
  }

  @override
  $DietPlansTable createAlias(String alias) {
    return $DietPlansTable(attachedDatabase, alias);
  }
}

class DietPlanRow extends DataClass implements Insertable<DietPlanRow> {
  final String id;
  final int clientUpdatedAt;
  final bool deleted;
  final bool synced;
  final String audience;
  final String? season;
  final String? budget;
  final String? pantry;
  final String? spokenText;
  final String planJson;
  final String source;
  final DateTime plannedFor;
  const DietPlanRow({
    required this.id,
    required this.clientUpdatedAt,
    required this.deleted,
    required this.synced,
    required this.audience,
    this.season,
    this.budget,
    this.pantry,
    this.spokenText,
    required this.planJson,
    required this.source,
    required this.plannedFor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_updated_at'] = Variable<int>(clientUpdatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['synced'] = Variable<bool>(synced);
    map['audience'] = Variable<String>(audience);
    if (!nullToAbsent || season != null) {
      map['season'] = Variable<String>(season);
    }
    if (!nullToAbsent || budget != null) {
      map['budget'] = Variable<String>(budget);
    }
    if (!nullToAbsent || pantry != null) {
      map['pantry'] = Variable<String>(pantry);
    }
    if (!nullToAbsent || spokenText != null) {
      map['spoken_text'] = Variable<String>(spokenText);
    }
    map['plan_json'] = Variable<String>(planJson);
    map['source'] = Variable<String>(source);
    map['planned_for'] = Variable<DateTime>(plannedFor);
    return map;
  }

  DietPlansCompanion toCompanion(bool nullToAbsent) {
    return DietPlansCompanion(
      id: Value(id),
      clientUpdatedAt: Value(clientUpdatedAt),
      deleted: Value(deleted),
      synced: Value(synced),
      audience: Value(audience),
      season: season == null && nullToAbsent
          ? const Value.absent()
          : Value(season),
      budget: budget == null && nullToAbsent
          ? const Value.absent()
          : Value(budget),
      pantry: pantry == null && nullToAbsent
          ? const Value.absent()
          : Value(pantry),
      spokenText: spokenText == null && nullToAbsent
          ? const Value.absent()
          : Value(spokenText),
      planJson: Value(planJson),
      source: Value(source),
      plannedFor: Value(plannedFor),
    );
  }

  factory DietPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DietPlanRow(
      id: serializer.fromJson<String>(json['id']),
      clientUpdatedAt: serializer.fromJson<int>(json['clientUpdatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      synced: serializer.fromJson<bool>(json['synced']),
      audience: serializer.fromJson<String>(json['audience']),
      season: serializer.fromJson<String?>(json['season']),
      budget: serializer.fromJson<String?>(json['budget']),
      pantry: serializer.fromJson<String?>(json['pantry']),
      spokenText: serializer.fromJson<String?>(json['spokenText']),
      planJson: serializer.fromJson<String>(json['planJson']),
      source: serializer.fromJson<String>(json['source']),
      plannedFor: serializer.fromJson<DateTime>(json['plannedFor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientUpdatedAt': serializer.toJson<int>(clientUpdatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'synced': serializer.toJson<bool>(synced),
      'audience': serializer.toJson<String>(audience),
      'season': serializer.toJson<String?>(season),
      'budget': serializer.toJson<String?>(budget),
      'pantry': serializer.toJson<String?>(pantry),
      'spokenText': serializer.toJson<String?>(spokenText),
      'planJson': serializer.toJson<String>(planJson),
      'source': serializer.toJson<String>(source),
      'plannedFor': serializer.toJson<DateTime>(plannedFor),
    };
  }

  DietPlanRow copyWith({
    String? id,
    int? clientUpdatedAt,
    bool? deleted,
    bool? synced,
    String? audience,
    Value<String?> season = const Value.absent(),
    Value<String?> budget = const Value.absent(),
    Value<String?> pantry = const Value.absent(),
    Value<String?> spokenText = const Value.absent(),
    String? planJson,
    String? source,
    DateTime? plannedFor,
  }) => DietPlanRow(
    id: id ?? this.id,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deleted: deleted ?? this.deleted,
    synced: synced ?? this.synced,
    audience: audience ?? this.audience,
    season: season.present ? season.value : this.season,
    budget: budget.present ? budget.value : this.budget,
    pantry: pantry.present ? pantry.value : this.pantry,
    spokenText: spokenText.present ? spokenText.value : this.spokenText,
    planJson: planJson ?? this.planJson,
    source: source ?? this.source,
    plannedFor: plannedFor ?? this.plannedFor,
  );
  DietPlanRow copyWithCompanion(DietPlansCompanion data) {
    return DietPlanRow(
      id: data.id.present ? data.id.value : this.id,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      synced: data.synced.present ? data.synced.value : this.synced,
      audience: data.audience.present ? data.audience.value : this.audience,
      season: data.season.present ? data.season.value : this.season,
      budget: data.budget.present ? data.budget.value : this.budget,
      pantry: data.pantry.present ? data.pantry.value : this.pantry,
      spokenText: data.spokenText.present
          ? data.spokenText.value
          : this.spokenText,
      planJson: data.planJson.present ? data.planJson.value : this.planJson,
      source: data.source.present ? data.source.value : this.source,
      plannedFor: data.plannedFor.present
          ? data.plannedFor.value
          : this.plannedFor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DietPlanRow(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('audience: $audience, ')
          ..write('season: $season, ')
          ..write('budget: $budget, ')
          ..write('pantry: $pantry, ')
          ..write('spokenText: $spokenText, ')
          ..write('planJson: $planJson, ')
          ..write('source: $source, ')
          ..write('plannedFor: $plannedFor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientUpdatedAt,
    deleted,
    synced,
    audience,
    season,
    budget,
    pantry,
    spokenText,
    planJson,
    source,
    plannedFor,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DietPlanRow &&
          other.id == this.id &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deleted == this.deleted &&
          other.synced == this.synced &&
          other.audience == this.audience &&
          other.season == this.season &&
          other.budget == this.budget &&
          other.pantry == this.pantry &&
          other.spokenText == this.spokenText &&
          other.planJson == this.planJson &&
          other.source == this.source &&
          other.plannedFor == this.plannedFor);
}

class DietPlansCompanion extends UpdateCompanion<DietPlanRow> {
  final Value<String> id;
  final Value<int> clientUpdatedAt;
  final Value<bool> deleted;
  final Value<bool> synced;
  final Value<String> audience;
  final Value<String?> season;
  final Value<String?> budget;
  final Value<String?> pantry;
  final Value<String?> spokenText;
  final Value<String> planJson;
  final Value<String> source;
  final Value<DateTime> plannedFor;
  final Value<int> rowid;
  const DietPlansCompanion({
    this.id = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    this.audience = const Value.absent(),
    this.season = const Value.absent(),
    this.budget = const Value.absent(),
    this.pantry = const Value.absent(),
    this.spokenText = const Value.absent(),
    this.planJson = const Value.absent(),
    this.source = const Value.absent(),
    this.plannedFor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DietPlansCompanion.insert({
    required String id,
    required int clientUpdatedAt,
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    required String audience,
    this.season = const Value.absent(),
    this.budget = const Value.absent(),
    this.pantry = const Value.absent(),
    this.spokenText = const Value.absent(),
    required String planJson,
    this.source = const Value.absent(),
    required DateTime plannedFor,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clientUpdatedAt = Value(clientUpdatedAt),
       audience = Value(audience),
       planJson = Value(planJson),
       plannedFor = Value(plannedFor);
  static Insertable<DietPlanRow> custom({
    Expression<String>? id,
    Expression<int>? clientUpdatedAt,
    Expression<bool>? deleted,
    Expression<bool>? synced,
    Expression<String>? audience,
    Expression<String>? season,
    Expression<String>? budget,
    Expression<String>? pantry,
    Expression<String>? spokenText,
    Expression<String>? planJson,
    Expression<String>? source,
    Expression<DateTime>? plannedFor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deleted != null) 'deleted': deleted,
      if (synced != null) 'synced': synced,
      if (audience != null) 'audience': audience,
      if (season != null) 'season': season,
      if (budget != null) 'budget': budget,
      if (pantry != null) 'pantry': pantry,
      if (spokenText != null) 'spoken_text': spokenText,
      if (planJson != null) 'plan_json': planJson,
      if (source != null) 'source': source,
      if (plannedFor != null) 'planned_for': plannedFor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DietPlansCompanion copyWith({
    Value<String>? id,
    Value<int>? clientUpdatedAt,
    Value<bool>? deleted,
    Value<bool>? synced,
    Value<String>? audience,
    Value<String?>? season,
    Value<String?>? budget,
    Value<String?>? pantry,
    Value<String?>? spokenText,
    Value<String>? planJson,
    Value<String>? source,
    Value<DateTime>? plannedFor,
    Value<int>? rowid,
  }) {
    return DietPlansCompanion(
      id: id ?? this.id,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deleted: deleted ?? this.deleted,
      synced: synced ?? this.synced,
      audience: audience ?? this.audience,
      season: season ?? this.season,
      budget: budget ?? this.budget,
      pantry: pantry ?? this.pantry,
      spokenText: spokenText ?? this.spokenText,
      planJson: planJson ?? this.planJson,
      source: source ?? this.source,
      plannedFor: plannedFor ?? this.plannedFor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<int>(clientUpdatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (audience.present) {
      map['audience'] = Variable<String>(audience.value);
    }
    if (season.present) {
      map['season'] = Variable<String>(season.value);
    }
    if (budget.present) {
      map['budget'] = Variable<String>(budget.value);
    }
    if (pantry.present) {
      map['pantry'] = Variable<String>(pantry.value);
    }
    if (spokenText.present) {
      map['spoken_text'] = Variable<String>(spokenText.value);
    }
    if (planJson.present) {
      map['plan_json'] = Variable<String>(planJson.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (plannedFor.present) {
      map['planned_for'] = Variable<DateTime>(plannedFor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DietPlansCompanion(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('audience: $audience, ')
          ..write('season: $season, ')
          ..write('budget: $budget, ')
          ..write('pantry: $pantry, ')
          ..write('spokenText: $spokenText, ')
          ..write('planJson: $planJson, ')
          ..write('source: $source, ')
          ..write('plannedFor: $plannedFor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DietLogsTable extends DietLogs
    with TableInfo<$DietLogsTable, DietLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DietLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientUpdatedAtMeta = const VerificationMeta(
    'clientUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> clientUpdatedAt = GeneratedColumn<int>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupsJsonMeta = const VerificationMeta(
    'groupsJson',
  );
  @override
  late final GeneratedColumn<String> groupsJson = GeneratedColumn<String>(
    'groups_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eatenMealsJsonMeta = const VerificationMeta(
    'eatenMealsJson',
  );
  @override
  late final GeneratedColumn<String> eatenMealsJson = GeneratedColumn<String>(
    'eaten_meals_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientUpdatedAt,
    deleted,
    synced,
    day,
    groupsJson,
    score,
    eatenMealsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diet_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DietLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
        _clientUpdatedAtMeta,
        clientUpdatedAt.isAcceptableOrUnknown(
          data['client_updated_at']!,
          _clientUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('groups_json')) {
      context.handle(
        _groupsJsonMeta,
        groupsJson.isAcceptableOrUnknown(data['groups_json']!, _groupsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_groupsJsonMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('eaten_meals_json')) {
      context.handle(
        _eatenMealsJsonMeta,
        eatenMealsJson.isAcceptableOrUnknown(
          data['eaten_meals_json']!,
          _eatenMealsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DietLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DietLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      groupsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}groups_json'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      eatenMealsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}eaten_meals_json'],
      ),
    );
  }

  @override
  $DietLogsTable createAlias(String alias) {
    return $DietLogsTable(attachedDatabase, alias);
  }
}

class DietLogRow extends DataClass implements Insertable<DietLogRow> {
  final String id;
  final int clientUpdatedAt;
  final bool deleted;
  final bool synced;
  final String day;
  final String groupsJson;
  final int score;
  final String? eatenMealsJson;
  const DietLogRow({
    required this.id,
    required this.clientUpdatedAt,
    required this.deleted,
    required this.synced,
    required this.day,
    required this.groupsJson,
    required this.score,
    this.eatenMealsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_updated_at'] = Variable<int>(clientUpdatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['synced'] = Variable<bool>(synced);
    map['day'] = Variable<String>(day);
    map['groups_json'] = Variable<String>(groupsJson);
    map['score'] = Variable<int>(score);
    if (!nullToAbsent || eatenMealsJson != null) {
      map['eaten_meals_json'] = Variable<String>(eatenMealsJson);
    }
    return map;
  }

  DietLogsCompanion toCompanion(bool nullToAbsent) {
    return DietLogsCompanion(
      id: Value(id),
      clientUpdatedAt: Value(clientUpdatedAt),
      deleted: Value(deleted),
      synced: Value(synced),
      day: Value(day),
      groupsJson: Value(groupsJson),
      score: Value(score),
      eatenMealsJson: eatenMealsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(eatenMealsJson),
    );
  }

  factory DietLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DietLogRow(
      id: serializer.fromJson<String>(json['id']),
      clientUpdatedAt: serializer.fromJson<int>(json['clientUpdatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      synced: serializer.fromJson<bool>(json['synced']),
      day: serializer.fromJson<String>(json['day']),
      groupsJson: serializer.fromJson<String>(json['groupsJson']),
      score: serializer.fromJson<int>(json['score']),
      eatenMealsJson: serializer.fromJson<String?>(json['eatenMealsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientUpdatedAt': serializer.toJson<int>(clientUpdatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'synced': serializer.toJson<bool>(synced),
      'day': serializer.toJson<String>(day),
      'groupsJson': serializer.toJson<String>(groupsJson),
      'score': serializer.toJson<int>(score),
      'eatenMealsJson': serializer.toJson<String?>(eatenMealsJson),
    };
  }

  DietLogRow copyWith({
    String? id,
    int? clientUpdatedAt,
    bool? deleted,
    bool? synced,
    String? day,
    String? groupsJson,
    int? score,
    Value<String?> eatenMealsJson = const Value.absent(),
  }) => DietLogRow(
    id: id ?? this.id,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deleted: deleted ?? this.deleted,
    synced: synced ?? this.synced,
    day: day ?? this.day,
    groupsJson: groupsJson ?? this.groupsJson,
    score: score ?? this.score,
    eatenMealsJson: eatenMealsJson.present
        ? eatenMealsJson.value
        : this.eatenMealsJson,
  );
  DietLogRow copyWithCompanion(DietLogsCompanion data) {
    return DietLogRow(
      id: data.id.present ? data.id.value : this.id,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      synced: data.synced.present ? data.synced.value : this.synced,
      day: data.day.present ? data.day.value : this.day,
      groupsJson: data.groupsJson.present
          ? data.groupsJson.value
          : this.groupsJson,
      score: data.score.present ? data.score.value : this.score,
      eatenMealsJson: data.eatenMealsJson.present
          ? data.eatenMealsJson.value
          : this.eatenMealsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DietLogRow(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('day: $day, ')
          ..write('groupsJson: $groupsJson, ')
          ..write('score: $score, ')
          ..write('eatenMealsJson: $eatenMealsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientUpdatedAt,
    deleted,
    synced,
    day,
    groupsJson,
    score,
    eatenMealsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DietLogRow &&
          other.id == this.id &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deleted == this.deleted &&
          other.synced == this.synced &&
          other.day == this.day &&
          other.groupsJson == this.groupsJson &&
          other.score == this.score &&
          other.eatenMealsJson == this.eatenMealsJson);
}

class DietLogsCompanion extends UpdateCompanion<DietLogRow> {
  final Value<String> id;
  final Value<int> clientUpdatedAt;
  final Value<bool> deleted;
  final Value<bool> synced;
  final Value<String> day;
  final Value<String> groupsJson;
  final Value<int> score;
  final Value<String?> eatenMealsJson;
  final Value<int> rowid;
  const DietLogsCompanion({
    this.id = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    this.day = const Value.absent(),
    this.groupsJson = const Value.absent(),
    this.score = const Value.absent(),
    this.eatenMealsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DietLogsCompanion.insert({
    required String id,
    required int clientUpdatedAt,
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    required String day,
    required String groupsJson,
    required int score,
    this.eatenMealsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clientUpdatedAt = Value(clientUpdatedAt),
       day = Value(day),
       groupsJson = Value(groupsJson),
       score = Value(score);
  static Insertable<DietLogRow> custom({
    Expression<String>? id,
    Expression<int>? clientUpdatedAt,
    Expression<bool>? deleted,
    Expression<bool>? synced,
    Expression<String>? day,
    Expression<String>? groupsJson,
    Expression<int>? score,
    Expression<String>? eatenMealsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deleted != null) 'deleted': deleted,
      if (synced != null) 'synced': synced,
      if (day != null) 'day': day,
      if (groupsJson != null) 'groups_json': groupsJson,
      if (score != null) 'score': score,
      if (eatenMealsJson != null) 'eaten_meals_json': eatenMealsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DietLogsCompanion copyWith({
    Value<String>? id,
    Value<int>? clientUpdatedAt,
    Value<bool>? deleted,
    Value<bool>? synced,
    Value<String>? day,
    Value<String>? groupsJson,
    Value<int>? score,
    Value<String?>? eatenMealsJson,
    Value<int>? rowid,
  }) {
    return DietLogsCompanion(
      id: id ?? this.id,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deleted: deleted ?? this.deleted,
      synced: synced ?? this.synced,
      day: day ?? this.day,
      groupsJson: groupsJson ?? this.groupsJson,
      score: score ?? this.score,
      eatenMealsJson: eatenMealsJson ?? this.eatenMealsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<int>(clientUpdatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (groupsJson.present) {
      map['groups_json'] = Variable<String>(groupsJson.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (eatenMealsJson.present) {
      map['eaten_meals_json'] = Variable<String>(eatenMealsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DietLogsCompanion(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('day: $day, ')
          ..write('groupsJson: $groupsJson, ')
          ..write('score: $score, ')
          ..write('eatenMealsJson: $eatenMealsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyTipsTable extends DailyTips
    with TableInfo<$DailyTipsTable, DailyTipRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyTipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientUpdatedAtMeta = const VerificationMeta(
    'clientUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> clientUpdatedAt = GeneratedColumn<int>(
    'client_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _audienceMeta = const VerificationMeta(
    'audience',
  );
  @override
  late final GeneratedColumn<String> audience = GeneratedColumn<String>(
    'audience',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _forDayMeta = const VerificationMeta('forDay');
  @override
  late final GeneratedColumn<String> forDay = GeneratedColumn<String>(
    'for_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('offline'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientUpdatedAt,
    deleted,
    synced,
    audience,
    title,
    body,
    forDay,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_tips';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyTipRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
        _clientUpdatedAtMeta,
        clientUpdatedAt.isAcceptableOrUnknown(
          data['client_updated_at']!,
          _clientUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('audience')) {
      context.handle(
        _audienceMeta,
        audience.isAcceptableOrUnknown(data['audience']!, _audienceMeta),
      );
    } else if (isInserting) {
      context.missing(_audienceMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('for_day')) {
      context.handle(
        _forDayMeta,
        forDay.isAcceptableOrUnknown(data['for_day']!, _forDayMeta),
      );
    } else if (isInserting) {
      context.missing(_forDayMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyTipRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyTipRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      audience: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audience'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      forDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}for_day'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $DailyTipsTable createAlias(String alias) {
    return $DailyTipsTable(attachedDatabase, alias);
  }
}

class DailyTipRow extends DataClass implements Insertable<DailyTipRow> {
  final String id;
  final int clientUpdatedAt;
  final bool deleted;
  final bool synced;
  final String audience;
  final String title;
  final String body;
  final String forDay;
  final String source;
  const DailyTipRow({
    required this.id,
    required this.clientUpdatedAt,
    required this.deleted,
    required this.synced,
    required this.audience,
    required this.title,
    required this.body,
    required this.forDay,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_updated_at'] = Variable<int>(clientUpdatedAt);
    map['deleted'] = Variable<bool>(deleted);
    map['synced'] = Variable<bool>(synced);
    map['audience'] = Variable<String>(audience);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['for_day'] = Variable<String>(forDay);
    map['source'] = Variable<String>(source);
    return map;
  }

  DailyTipsCompanion toCompanion(bool nullToAbsent) {
    return DailyTipsCompanion(
      id: Value(id),
      clientUpdatedAt: Value(clientUpdatedAt),
      deleted: Value(deleted),
      synced: Value(synced),
      audience: Value(audience),
      title: Value(title),
      body: Value(body),
      forDay: Value(forDay),
      source: Value(source),
    );
  }

  factory DailyTipRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyTipRow(
      id: serializer.fromJson<String>(json['id']),
      clientUpdatedAt: serializer.fromJson<int>(json['clientUpdatedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      synced: serializer.fromJson<bool>(json['synced']),
      audience: serializer.fromJson<String>(json['audience']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      forDay: serializer.fromJson<String>(json['forDay']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientUpdatedAt': serializer.toJson<int>(clientUpdatedAt),
      'deleted': serializer.toJson<bool>(deleted),
      'synced': serializer.toJson<bool>(synced),
      'audience': serializer.toJson<String>(audience),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'forDay': serializer.toJson<String>(forDay),
      'source': serializer.toJson<String>(source),
    };
  }

  DailyTipRow copyWith({
    String? id,
    int? clientUpdatedAt,
    bool? deleted,
    bool? synced,
    String? audience,
    String? title,
    String? body,
    String? forDay,
    String? source,
  }) => DailyTipRow(
    id: id ?? this.id,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    deleted: deleted ?? this.deleted,
    synced: synced ?? this.synced,
    audience: audience ?? this.audience,
    title: title ?? this.title,
    body: body ?? this.body,
    forDay: forDay ?? this.forDay,
    source: source ?? this.source,
  );
  DailyTipRow copyWithCompanion(DailyTipsCompanion data) {
    return DailyTipRow(
      id: data.id.present ? data.id.value : this.id,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      synced: data.synced.present ? data.synced.value : this.synced,
      audience: data.audience.present ? data.audience.value : this.audience,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      forDay: data.forDay.present ? data.forDay.value : this.forDay,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyTipRow(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('audience: $audience, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('forDay: $forDay, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientUpdatedAt,
    deleted,
    synced,
    audience,
    title,
    body,
    forDay,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyTipRow &&
          other.id == this.id &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.deleted == this.deleted &&
          other.synced == this.synced &&
          other.audience == this.audience &&
          other.title == this.title &&
          other.body == this.body &&
          other.forDay == this.forDay &&
          other.source == this.source);
}

class DailyTipsCompanion extends UpdateCompanion<DailyTipRow> {
  final Value<String> id;
  final Value<int> clientUpdatedAt;
  final Value<bool> deleted;
  final Value<bool> synced;
  final Value<String> audience;
  final Value<String> title;
  final Value<String> body;
  final Value<String> forDay;
  final Value<String> source;
  final Value<int> rowid;
  const DailyTipsCompanion({
    this.id = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    this.audience = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.forDay = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyTipsCompanion.insert({
    required String id,
    required int clientUpdatedAt,
    this.deleted = const Value.absent(),
    this.synced = const Value.absent(),
    required String audience,
    required String title,
    required String body,
    required String forDay,
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clientUpdatedAt = Value(clientUpdatedAt),
       audience = Value(audience),
       title = Value(title),
       body = Value(body),
       forDay = Value(forDay);
  static Insertable<DailyTipRow> custom({
    Expression<String>? id,
    Expression<int>? clientUpdatedAt,
    Expression<bool>? deleted,
    Expression<bool>? synced,
    Expression<String>? audience,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? forDay,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (deleted != null) 'deleted': deleted,
      if (synced != null) 'synced': synced,
      if (audience != null) 'audience': audience,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (forDay != null) 'for_day': forDay,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyTipsCompanion copyWith({
    Value<String>? id,
    Value<int>? clientUpdatedAt,
    Value<bool>? deleted,
    Value<bool>? synced,
    Value<String>? audience,
    Value<String>? title,
    Value<String>? body,
    Value<String>? forDay,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return DailyTipsCompanion(
      id: id ?? this.id,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      deleted: deleted ?? this.deleted,
      synced: synced ?? this.synced,
      audience: audience ?? this.audience,
      title: title ?? this.title,
      body: body ?? this.body,
      forDay: forDay ?? this.forDay,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<int>(clientUpdatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (audience.present) {
      map['audience'] = Variable<String>(audience.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (forDay.present) {
      map['for_day'] = Variable<String>(forDay.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyTipsCompanion(')
          ..write('id: $id, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('synced: $synced, ')
          ..write('audience: $audience, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('forDay: $forDay, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlertsCacheTable extends AlertsCache
    with TableInfo<$AlertsCacheTable, AlertRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assessmentIdMeta = const VerificationMeta(
    'assessmentId',
  );
  @override
  late final GeneratedColumn<String> assessmentId = GeneratedColumn<String>(
    'assessment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _volunteerNameMeta = const VerificationMeta(
    'volunteerName',
  );
  @override
  late final GeneratedColumn<String> volunteerName = GeneratedColumn<String>(
    'volunteer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _volunteerPhoneMeta = const VerificationMeta(
    'volunteerPhone',
  );
  @override
  late final GeneratedColumn<String> volunteerPhone = GeneratedColumn<String>(
    'volunteer_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _facilityNameMeta = const VerificationMeta(
    'facilityName',
  );
  @override
  late final GeneratedColumn<String> facilityName = GeneratedColumn<String>(
    'facility_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _facilityPhoneMeta = const VerificationMeta(
    'facilityPhone',
  );
  @override
  late final GeneratedColumn<String> facilityPhone = GeneratedColumn<String>(
    'facility_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    status,
    summary,
    assessmentId,
    volunteerName,
    volunteerPhone,
    facilityName,
    facilityPhone,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alerts_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlertRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('assessment_id')) {
      context.handle(
        _assessmentIdMeta,
        assessmentId.isAcceptableOrUnknown(
          data['assessment_id']!,
          _assessmentIdMeta,
        ),
      );
    }
    if (data.containsKey('volunteer_name')) {
      context.handle(
        _volunteerNameMeta,
        volunteerName.isAcceptableOrUnknown(
          data['volunteer_name']!,
          _volunteerNameMeta,
        ),
      );
    }
    if (data.containsKey('volunteer_phone')) {
      context.handle(
        _volunteerPhoneMeta,
        volunteerPhone.isAcceptableOrUnknown(
          data['volunteer_phone']!,
          _volunteerPhoneMeta,
        ),
      );
    }
    if (data.containsKey('facility_name')) {
      context.handle(
        _facilityNameMeta,
        facilityName.isAcceptableOrUnknown(
          data['facility_name']!,
          _facilityNameMeta,
        ),
      );
    }
    if (data.containsKey('facility_phone')) {
      context.handle(
        _facilityPhoneMeta,
        facilityPhone.isAcceptableOrUnknown(
          data['facility_phone']!,
          _facilityPhoneMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlertRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlertRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      assessmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assessment_id'],
      ),
      volunteerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}volunteer_name'],
      ),
      volunteerPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}volunteer_phone'],
      ),
      facilityName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}facility_name'],
      ),
      facilityPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}facility_phone'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $AlertsCacheTable createAlias(String alias) {
    return $AlertsCacheTable(attachedDatabase, alias);
  }
}

class AlertRow extends DataClass implements Insertable<AlertRow> {
  final String id;
  final String status;
  final String summary;
  final String? assessmentId;
  final String? volunteerName;
  final String? volunteerPhone;
  final String? facilityName;
  final String? facilityPhone;
  final DateTime? createdAt;
  const AlertRow({
    required this.id,
    required this.status,
    required this.summary,
    this.assessmentId,
    this.volunteerName,
    this.volunteerPhone,
    this.facilityName,
    this.facilityPhone,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['status'] = Variable<String>(status);
    map['summary'] = Variable<String>(summary);
    if (!nullToAbsent || assessmentId != null) {
      map['assessment_id'] = Variable<String>(assessmentId);
    }
    if (!nullToAbsent || volunteerName != null) {
      map['volunteer_name'] = Variable<String>(volunteerName);
    }
    if (!nullToAbsent || volunteerPhone != null) {
      map['volunteer_phone'] = Variable<String>(volunteerPhone);
    }
    if (!nullToAbsent || facilityName != null) {
      map['facility_name'] = Variable<String>(facilityName);
    }
    if (!nullToAbsent || facilityPhone != null) {
      map['facility_phone'] = Variable<String>(facilityPhone);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  AlertsCacheCompanion toCompanion(bool nullToAbsent) {
    return AlertsCacheCompanion(
      id: Value(id),
      status: Value(status),
      summary: Value(summary),
      assessmentId: assessmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(assessmentId),
      volunteerName: volunteerName == null && nullToAbsent
          ? const Value.absent()
          : Value(volunteerName),
      volunteerPhone: volunteerPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(volunteerPhone),
      facilityName: facilityName == null && nullToAbsent
          ? const Value.absent()
          : Value(facilityName),
      facilityPhone: facilityPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(facilityPhone),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory AlertRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlertRow(
      id: serializer.fromJson<String>(json['id']),
      status: serializer.fromJson<String>(json['status']),
      summary: serializer.fromJson<String>(json['summary']),
      assessmentId: serializer.fromJson<String?>(json['assessmentId']),
      volunteerName: serializer.fromJson<String?>(json['volunteerName']),
      volunteerPhone: serializer.fromJson<String?>(json['volunteerPhone']),
      facilityName: serializer.fromJson<String?>(json['facilityName']),
      facilityPhone: serializer.fromJson<String?>(json['facilityPhone']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'status': serializer.toJson<String>(status),
      'summary': serializer.toJson<String>(summary),
      'assessmentId': serializer.toJson<String?>(assessmentId),
      'volunteerName': serializer.toJson<String?>(volunteerName),
      'volunteerPhone': serializer.toJson<String?>(volunteerPhone),
      'facilityName': serializer.toJson<String?>(facilityName),
      'facilityPhone': serializer.toJson<String?>(facilityPhone),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  AlertRow copyWith({
    String? id,
    String? status,
    String? summary,
    Value<String?> assessmentId = const Value.absent(),
    Value<String?> volunteerName = const Value.absent(),
    Value<String?> volunteerPhone = const Value.absent(),
    Value<String?> facilityName = const Value.absent(),
    Value<String?> facilityPhone = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
  }) => AlertRow(
    id: id ?? this.id,
    status: status ?? this.status,
    summary: summary ?? this.summary,
    assessmentId: assessmentId.present ? assessmentId.value : this.assessmentId,
    volunteerName: volunteerName.present
        ? volunteerName.value
        : this.volunteerName,
    volunteerPhone: volunteerPhone.present
        ? volunteerPhone.value
        : this.volunteerPhone,
    facilityName: facilityName.present ? facilityName.value : this.facilityName,
    facilityPhone: facilityPhone.present
        ? facilityPhone.value
        : this.facilityPhone,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  AlertRow copyWithCompanion(AlertsCacheCompanion data) {
    return AlertRow(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      summary: data.summary.present ? data.summary.value : this.summary,
      assessmentId: data.assessmentId.present
          ? data.assessmentId.value
          : this.assessmentId,
      volunteerName: data.volunteerName.present
          ? data.volunteerName.value
          : this.volunteerName,
      volunteerPhone: data.volunteerPhone.present
          ? data.volunteerPhone.value
          : this.volunteerPhone,
      facilityName: data.facilityName.present
          ? data.facilityName.value
          : this.facilityName,
      facilityPhone: data.facilityPhone.present
          ? data.facilityPhone.value
          : this.facilityPhone,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlertRow(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('summary: $summary, ')
          ..write('assessmentId: $assessmentId, ')
          ..write('volunteerName: $volunteerName, ')
          ..write('volunteerPhone: $volunteerPhone, ')
          ..write('facilityName: $facilityName, ')
          ..write('facilityPhone: $facilityPhone, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    status,
    summary,
    assessmentId,
    volunteerName,
    volunteerPhone,
    facilityName,
    facilityPhone,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlertRow &&
          other.id == this.id &&
          other.status == this.status &&
          other.summary == this.summary &&
          other.assessmentId == this.assessmentId &&
          other.volunteerName == this.volunteerName &&
          other.volunteerPhone == this.volunteerPhone &&
          other.facilityName == this.facilityName &&
          other.facilityPhone == this.facilityPhone &&
          other.createdAt == this.createdAt);
}

class AlertsCacheCompanion extends UpdateCompanion<AlertRow> {
  final Value<String> id;
  final Value<String> status;
  final Value<String> summary;
  final Value<String?> assessmentId;
  final Value<String?> volunteerName;
  final Value<String?> volunteerPhone;
  final Value<String?> facilityName;
  final Value<String?> facilityPhone;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const AlertsCacheCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.summary = const Value.absent(),
    this.assessmentId = const Value.absent(),
    this.volunteerName = const Value.absent(),
    this.volunteerPhone = const Value.absent(),
    this.facilityName = const Value.absent(),
    this.facilityPhone = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlertsCacheCompanion.insert({
    required String id,
    required String status,
    required String summary,
    this.assessmentId = const Value.absent(),
    this.volunteerName = const Value.absent(),
    this.volunteerPhone = const Value.absent(),
    this.facilityName = const Value.absent(),
    this.facilityPhone = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       summary = Value(summary);
  static Insertable<AlertRow> custom({
    Expression<String>? id,
    Expression<String>? status,
    Expression<String>? summary,
    Expression<String>? assessmentId,
    Expression<String>? volunteerName,
    Expression<String>? volunteerPhone,
    Expression<String>? facilityName,
    Expression<String>? facilityPhone,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (summary != null) 'summary': summary,
      if (assessmentId != null) 'assessment_id': assessmentId,
      if (volunteerName != null) 'volunteer_name': volunteerName,
      if (volunteerPhone != null) 'volunteer_phone': volunteerPhone,
      if (facilityName != null) 'facility_name': facilityName,
      if (facilityPhone != null) 'facility_phone': facilityPhone,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlertsCacheCompanion copyWith({
    Value<String>? id,
    Value<String>? status,
    Value<String>? summary,
    Value<String?>? assessmentId,
    Value<String?>? volunteerName,
    Value<String?>? volunteerPhone,
    Value<String?>? facilityName,
    Value<String?>? facilityPhone,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return AlertsCacheCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      assessmentId: assessmentId ?? this.assessmentId,
      volunteerName: volunteerName ?? this.volunteerName,
      volunteerPhone: volunteerPhone ?? this.volunteerPhone,
      facilityName: facilityName ?? this.facilityName,
      facilityPhone: facilityPhone ?? this.facilityPhone,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (assessmentId.present) {
      map['assessment_id'] = Variable<String>(assessmentId.value);
    }
    if (volunteerName.present) {
      map['volunteer_name'] = Variable<String>(volunteerName.value);
    }
    if (volunteerPhone.present) {
      map['volunteer_phone'] = Variable<String>(volunteerPhone.value);
    }
    if (facilityName.present) {
      map['facility_name'] = Variable<String>(facilityName.value);
    }
    if (facilityPhone.present) {
      map['facility_phone'] = Variable<String>(facilityPhone.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertsCacheCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('summary: $summary, ')
          ..write('assessmentId: $assessmentId, ')
          ..write('volunteerName: $volunteerName, ')
          ..write('volunteerPhone: $volunteerPhone, ')
          ..write('facilityName: $facilityName, ')
          ..write('facilityPhone: $facilityPhone, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChildrenTable children = $ChildrenTable(this);
  late final $PregnanciesTable pregnancies = $PregnanciesTable(this);
  late final $AssessmentsTable assessments = $AssessmentsTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $GrowthRecordsTable growthRecords = $GrowthRecordsTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $DietPlansTable dietPlans = $DietPlansTable(this);
  late final $DietLogsTable dietLogs = $DietLogsTable(this);
  late final $DailyTipsTable dailyTips = $DailyTipsTable(this);
  late final $AlertsCacheTable alertsCache = $AlertsCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    children,
    pregnancies,
    assessments,
    reminders,
    growthRecords,
    chatMessages,
    dietPlans,
    dietLogs,
    dailyTips,
    alertsCache,
  ];
}

typedef $$ChildrenTableCreateCompanionBuilder =
    ChildrenCompanion Function({
      required String id,
      required int clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      required String name,
      Value<String?> sex,
      required DateTime dateOfBirth,
      Value<String?> photoUrl,
      Value<double?> birthWeightKg,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$ChildrenTableUpdateCompanionBuilder =
    ChildrenCompanion Function({
      Value<String> id,
      Value<int> clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      Value<String> name,
      Value<String?> sex,
      Value<DateTime> dateOfBirth,
      Value<String?> photoUrl,
      Value<double?> birthWeightKg,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$ChildrenTableFilterComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get birthWeightKg => $composableBuilder(
    column: $table.birthWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChildrenTableOrderingComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get birthWeightKg => $composableBuilder(
    column: $table.birthWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChildrenTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChildrenTable> {
  $$ChildrenTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<DateTime> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<double> get birthWeightKg => $composableBuilder(
    column: $table.birthWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$ChildrenTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChildrenTable,
          ChildRow,
          $$ChildrenTableFilterComposer,
          $$ChildrenTableOrderingComposer,
          $$ChildrenTableAnnotationComposer,
          $$ChildrenTableCreateCompanionBuilder,
          $$ChildrenTableUpdateCompanionBuilder,
          (ChildRow, BaseReferences<_$AppDatabase, $ChildrenTable, ChildRow>),
          ChildRow,
          PrefetchHooks Function()
        > {
  $$ChildrenTableTableManager(_$AppDatabase db, $ChildrenTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChildrenTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChildrenTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChildrenTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> clientUpdatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<DateTime> dateOfBirth = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<double?> birthWeightKg = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChildrenCompanion(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                name: name,
                sex: sex,
                dateOfBirth: dateOfBirth,
                photoUrl: photoUrl,
                birthWeightKg: birthWeightKg,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int clientUpdatedAt,
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                required String name,
                Value<String?> sex = const Value.absent(),
                required DateTime dateOfBirth,
                Value<String?> photoUrl = const Value.absent(),
                Value<double?> birthWeightKg = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChildrenCompanion.insert(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                name: name,
                sex: sex,
                dateOfBirth: dateOfBirth,
                photoUrl: photoUrl,
                birthWeightKg: birthWeightKg,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChildrenTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChildrenTable,
      ChildRow,
      $$ChildrenTableFilterComposer,
      $$ChildrenTableOrderingComposer,
      $$ChildrenTableAnnotationComposer,
      $$ChildrenTableCreateCompanionBuilder,
      $$ChildrenTableUpdateCompanionBuilder,
      (ChildRow, BaseReferences<_$AppDatabase, $ChildrenTable, ChildRow>),
      ChildRow,
      PrefetchHooks Function()
    >;
typedef $$PregnanciesTableCreateCompanionBuilder =
    PregnanciesCompanion Function({
      required String id,
      required int clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      Value<DateTime?> lastMenstrualPeriod,
      required DateTime expectedDueDate,
      Value<String> status,
      Value<DateTime?> deliveredAt,
      Value<String?> notes,
      Value<String?> hospitalName,
      Value<String?> hospitalPhone,
      Value<DateTime?> lastCheckinAt,
      Value<String?> lastRiskLevel,
      Value<int> rowid,
    });
typedef $$PregnanciesTableUpdateCompanionBuilder =
    PregnanciesCompanion Function({
      Value<String> id,
      Value<int> clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      Value<DateTime?> lastMenstrualPeriod,
      Value<DateTime> expectedDueDate,
      Value<String> status,
      Value<DateTime?> deliveredAt,
      Value<String?> notes,
      Value<String?> hospitalName,
      Value<String?> hospitalPhone,
      Value<DateTime?> lastCheckinAt,
      Value<String?> lastRiskLevel,
      Value<int> rowid,
    });

class $$PregnanciesTableFilterComposer
    extends Composer<_$AppDatabase, $PregnanciesTable> {
  $$PregnanciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastMenstrualPeriod => $composableBuilder(
    column: $table.lastMenstrualPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expectedDueDate => $composableBuilder(
    column: $table.expectedDueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hospitalName => $composableBuilder(
    column: $table.hospitalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hospitalPhone => $composableBuilder(
    column: $table.hospitalPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCheckinAt => $composableBuilder(
    column: $table.lastCheckinAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastRiskLevel => $composableBuilder(
    column: $table.lastRiskLevel,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PregnanciesTableOrderingComposer
    extends Composer<_$AppDatabase, $PregnanciesTable> {
  $$PregnanciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastMenstrualPeriod => $composableBuilder(
    column: $table.lastMenstrualPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expectedDueDate => $composableBuilder(
    column: $table.expectedDueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hospitalName => $composableBuilder(
    column: $table.hospitalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hospitalPhone => $composableBuilder(
    column: $table.hospitalPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCheckinAt => $composableBuilder(
    column: $table.lastCheckinAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastRiskLevel => $composableBuilder(
    column: $table.lastRiskLevel,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PregnanciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PregnanciesTable> {
  $$PregnanciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMenstrualPeriod => $composableBuilder(
    column: $table.lastMenstrualPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expectedDueDate => $composableBuilder(
    column: $table.expectedDueDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get hospitalName => $composableBuilder(
    column: $table.hospitalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hospitalPhone => $composableBuilder(
    column: $table.hospitalPhone,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastCheckinAt => $composableBuilder(
    column: $table.lastCheckinAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastRiskLevel => $composableBuilder(
    column: $table.lastRiskLevel,
    builder: (column) => column,
  );
}

class $$PregnanciesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PregnanciesTable,
          PregnancyRow,
          $$PregnanciesTableFilterComposer,
          $$PregnanciesTableOrderingComposer,
          $$PregnanciesTableAnnotationComposer,
          $$PregnanciesTableCreateCompanionBuilder,
          $$PregnanciesTableUpdateCompanionBuilder,
          (
            PregnancyRow,
            BaseReferences<_$AppDatabase, $PregnanciesTable, PregnancyRow>,
          ),
          PregnancyRow,
          PrefetchHooks Function()
        > {
  $$PregnanciesTableTableManager(_$AppDatabase db, $PregnanciesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PregnanciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PregnanciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PregnanciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> clientUpdatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<DateTime?> lastMenstrualPeriod = const Value.absent(),
                Value<DateTime> expectedDueDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> deliveredAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> hospitalName = const Value.absent(),
                Value<String?> hospitalPhone = const Value.absent(),
                Value<DateTime?> lastCheckinAt = const Value.absent(),
                Value<String?> lastRiskLevel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PregnanciesCompanion(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                lastMenstrualPeriod: lastMenstrualPeriod,
                expectedDueDate: expectedDueDate,
                status: status,
                deliveredAt: deliveredAt,
                notes: notes,
                hospitalName: hospitalName,
                hospitalPhone: hospitalPhone,
                lastCheckinAt: lastCheckinAt,
                lastRiskLevel: lastRiskLevel,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int clientUpdatedAt,
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<DateTime?> lastMenstrualPeriod = const Value.absent(),
                required DateTime expectedDueDate,
                Value<String> status = const Value.absent(),
                Value<DateTime?> deliveredAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> hospitalName = const Value.absent(),
                Value<String?> hospitalPhone = const Value.absent(),
                Value<DateTime?> lastCheckinAt = const Value.absent(),
                Value<String?> lastRiskLevel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PregnanciesCompanion.insert(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                lastMenstrualPeriod: lastMenstrualPeriod,
                expectedDueDate: expectedDueDate,
                status: status,
                deliveredAt: deliveredAt,
                notes: notes,
                hospitalName: hospitalName,
                hospitalPhone: hospitalPhone,
                lastCheckinAt: lastCheckinAt,
                lastRiskLevel: lastRiskLevel,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PregnanciesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PregnanciesTable,
      PregnancyRow,
      $$PregnanciesTableFilterComposer,
      $$PregnanciesTableOrderingComposer,
      $$PregnanciesTableAnnotationComposer,
      $$PregnanciesTableCreateCompanionBuilder,
      $$PregnanciesTableUpdateCompanionBuilder,
      (
        PregnancyRow,
        BaseReferences<_$AppDatabase, $PregnanciesTable, PregnancyRow>,
      ),
      PregnancyRow,
      PrefetchHooks Function()
    >;
typedef $$AssessmentsTableCreateCompanionBuilder =
    AssessmentsCompanion Function({
      required String id,
      required int clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      required String subjectType,
      Value<String?> childId,
      Value<String?> pregnancyId,
      Value<String> answersJson,
      Value<String> dangerSignsJson,
      required String riskLevel,
      Value<String?> guidance,
      Value<double?> lng,
      Value<double?> lat,
      Value<DateTime?> startedAt,
      required DateTime completedAt,
      Value<int> rowid,
    });
typedef $$AssessmentsTableUpdateCompanionBuilder =
    AssessmentsCompanion Function({
      Value<String> id,
      Value<int> clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      Value<String> subjectType,
      Value<String?> childId,
      Value<String?> pregnancyId,
      Value<String> answersJson,
      Value<String> dangerSignsJson,
      Value<String> riskLevel,
      Value<String?> guidance,
      Value<double?> lng,
      Value<double?> lat,
      Value<DateTime?> startedAt,
      Value<DateTime> completedAt,
      Value<int> rowid,
    });

class $$AssessmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AssessmentsTable> {
  $$AssessmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectType => $composableBuilder(
    column: $table.subjectType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dangerSignsJson => $composableBuilder(
    column: $table.dangerSignsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get riskLevel => $composableBuilder(
    column: $table.riskLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guidance => $composableBuilder(
    column: $table.guidance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssessmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssessmentsTable> {
  $$AssessmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectType => $composableBuilder(
    column: $table.subjectType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dangerSignsJson => $composableBuilder(
    column: $table.dangerSignsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get riskLevel => $composableBuilder(
    column: $table.riskLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guidance => $composableBuilder(
    column: $table.guidance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssessmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssessmentsTable> {
  $$AssessmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get subjectType => $composableBuilder(
    column: $table.subjectType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get childId =>
      $composableBuilder(column: $table.childId, builder: (column) => column);

  GeneratedColumn<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dangerSignsJson => $composableBuilder(
    column: $table.dangerSignsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get riskLevel =>
      $composableBuilder(column: $table.riskLevel, builder: (column) => column);

  GeneratedColumn<String> get guidance =>
      $composableBuilder(column: $table.guidance, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$AssessmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssessmentsTable,
          AssessmentRow,
          $$AssessmentsTableFilterComposer,
          $$AssessmentsTableOrderingComposer,
          $$AssessmentsTableAnnotationComposer,
          $$AssessmentsTableCreateCompanionBuilder,
          $$AssessmentsTableUpdateCompanionBuilder,
          (
            AssessmentRow,
            BaseReferences<_$AppDatabase, $AssessmentsTable, AssessmentRow>,
          ),
          AssessmentRow,
          PrefetchHooks Function()
        > {
  $$AssessmentsTableTableManager(_$AppDatabase db, $AssessmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssessmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssessmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssessmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> clientUpdatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<String> subjectType = const Value.absent(),
                Value<String?> childId = const Value.absent(),
                Value<String?> pregnancyId = const Value.absent(),
                Value<String> answersJson = const Value.absent(),
                Value<String> dangerSignsJson = const Value.absent(),
                Value<String> riskLevel = const Value.absent(),
                Value<String?> guidance = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssessmentsCompanion(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                subjectType: subjectType,
                childId: childId,
                pregnancyId: pregnancyId,
                answersJson: answersJson,
                dangerSignsJson: dangerSignsJson,
                riskLevel: riskLevel,
                guidance: guidance,
                lng: lng,
                lat: lat,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int clientUpdatedAt,
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                required String subjectType,
                Value<String?> childId = const Value.absent(),
                Value<String?> pregnancyId = const Value.absent(),
                Value<String> answersJson = const Value.absent(),
                Value<String> dangerSignsJson = const Value.absent(),
                required String riskLevel,
                Value<String?> guidance = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                required DateTime completedAt,
                Value<int> rowid = const Value.absent(),
              }) => AssessmentsCompanion.insert(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                subjectType: subjectType,
                childId: childId,
                pregnancyId: pregnancyId,
                answersJson: answersJson,
                dangerSignsJson: dangerSignsJson,
                riskLevel: riskLevel,
                guidance: guidance,
                lng: lng,
                lat: lat,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssessmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssessmentsTable,
      AssessmentRow,
      $$AssessmentsTableFilterComposer,
      $$AssessmentsTableOrderingComposer,
      $$AssessmentsTableAnnotationComposer,
      $$AssessmentsTableCreateCompanionBuilder,
      $$AssessmentsTableUpdateCompanionBuilder,
      (
        AssessmentRow,
        BaseReferences<_$AppDatabase, $AssessmentsTable, AssessmentRow>,
      ),
      AssessmentRow,
      PrefetchHooks Function()
    >;
typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      required String id,
      required int clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      Value<String?> childId,
      Value<String?> pregnancyId,
      required String type,
      required String title,
      Value<String?> description,
      required DateTime dueDate,
      Value<String> status,
      Value<DateTime?> snoozedUntil,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<String> id,
      Value<int> clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      Value<String?> childId,
      Value<String?> pregnancyId,
      Value<String> type,
      Value<String> title,
      Value<String?> description,
      Value<DateTime> dueDate,
      Value<String> status,
      Value<DateTime?> snoozedUntil,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get childId =>
      $composableBuilder(column: $table.childId, builder: (column) => column);

  GeneratedColumn<String> get pregnancyId => $composableBuilder(
    column: $table.pregnancyId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          ReminderRow,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (
            ReminderRow,
            BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow>,
          ),
          ReminderRow,
          PrefetchHooks Function()
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> clientUpdatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<String?> childId = const Value.absent(),
                Value<String?> pregnancyId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> dueDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                childId: childId,
                pregnancyId: pregnancyId,
                type: type,
                title: title,
                description: description,
                dueDate: dueDate,
                status: status,
                snoozedUntil: snoozedUntil,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int clientUpdatedAt,
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<String?> childId = const Value.absent(),
                Value<String?> pregnancyId = const Value.absent(),
                required String type,
                required String title,
                Value<String?> description = const Value.absent(),
                required DateTime dueDate,
                Value<String> status = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                childId: childId,
                pregnancyId: pregnancyId,
                type: type,
                title: title,
                description: description,
                dueDate: dueDate,
                status: status,
                snoozedUntil: snoozedUntil,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      ReminderRow,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (
        ReminderRow,
        BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow>,
      ),
      ReminderRow,
      PrefetchHooks Function()
    >;
typedef $$GrowthRecordsTableCreateCompanionBuilder =
    GrowthRecordsCompanion Function({
      required String id,
      required int clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      required String childId,
      required double weightKg,
      required DateTime measuredAt,
      Value<int> rowid,
    });
typedef $$GrowthRecordsTableUpdateCompanionBuilder =
    GrowthRecordsCompanion Function({
      Value<String> id,
      Value<int> clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      Value<String> childId,
      Value<double> weightKg,
      Value<DateTime> measuredAt,
      Value<int> rowid,
    });

class $$GrowthRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $GrowthRecordsTable> {
  $$GrowthRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GrowthRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $GrowthRecordsTable> {
  $$GrowthRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GrowthRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GrowthRecordsTable> {
  $$GrowthRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get childId =>
      $composableBuilder(column: $table.childId, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => column,
  );
}

class $$GrowthRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GrowthRecordsTable,
          GrowthRecordRow,
          $$GrowthRecordsTableFilterComposer,
          $$GrowthRecordsTableOrderingComposer,
          $$GrowthRecordsTableAnnotationComposer,
          $$GrowthRecordsTableCreateCompanionBuilder,
          $$GrowthRecordsTableUpdateCompanionBuilder,
          (
            GrowthRecordRow,
            BaseReferences<_$AppDatabase, $GrowthRecordsTable, GrowthRecordRow>,
          ),
          GrowthRecordRow,
          PrefetchHooks Function()
        > {
  $$GrowthRecordsTableTableManager(_$AppDatabase db, $GrowthRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GrowthRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GrowthRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GrowthRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> clientUpdatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<String> childId = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<DateTime> measuredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrowthRecordsCompanion(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                childId: childId,
                weightKg: weightKg,
                measuredAt: measuredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int clientUpdatedAt,
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                required String childId,
                required double weightKg,
                required DateTime measuredAt,
                Value<int> rowid = const Value.absent(),
              }) => GrowthRecordsCompanion.insert(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                childId: childId,
                weightKg: weightKg,
                measuredAt: measuredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GrowthRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GrowthRecordsTable,
      GrowthRecordRow,
      $$GrowthRecordsTableFilterComposer,
      $$GrowthRecordsTableOrderingComposer,
      $$GrowthRecordsTableAnnotationComposer,
      $$GrowthRecordsTableCreateCompanionBuilder,
      $$GrowthRecordsTableUpdateCompanionBuilder,
      (
        GrowthRecordRow,
        BaseReferences<_$AppDatabase, $GrowthRecordsTable, GrowthRecordRow>,
      ),
      GrowthRecordRow,
      PrefetchHooks Function()
    >;
typedef $$ChatMessagesTableCreateCompanionBuilder =
    ChatMessagesCompanion Function({
      required String id,
      required int clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      required String role,
      required String content,
      required DateTime sentAt,
      Value<int> rowid,
    });
typedef $$ChatMessagesTableUpdateCompanionBuilder =
    ChatMessagesCompanion Function({
      Value<String> id,
      Value<int> clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      Value<String> role,
      Value<String> content,
      Value<DateTime> sentAt,
      Value<int> rowid,
    });

class $$ChatMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);
}

class $$ChatMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatMessagesTable,
          ChatMessageRow,
          $$ChatMessagesTableFilterComposer,
          $$ChatMessagesTableOrderingComposer,
          $$ChatMessagesTableAnnotationComposer,
          $$ChatMessagesTableCreateCompanionBuilder,
          $$ChatMessagesTableUpdateCompanionBuilder,
          (
            ChatMessageRow,
            BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessageRow>,
          ),
          ChatMessageRow,
          PrefetchHooks Function()
        > {
  $$ChatMessagesTableTableManager(_$AppDatabase db, $ChatMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> clientUpdatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> sentAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesCompanion(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                role: role,
                content: content,
                sentAt: sentAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int clientUpdatedAt,
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                required String role,
                required String content,
                required DateTime sentAt,
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesCompanion.insert(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                role: role,
                content: content,
                sentAt: sentAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatMessagesTable,
      ChatMessageRow,
      $$ChatMessagesTableFilterComposer,
      $$ChatMessagesTableOrderingComposer,
      $$ChatMessagesTableAnnotationComposer,
      $$ChatMessagesTableCreateCompanionBuilder,
      $$ChatMessagesTableUpdateCompanionBuilder,
      (
        ChatMessageRow,
        BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessageRow>,
      ),
      ChatMessageRow,
      PrefetchHooks Function()
    >;
typedef $$DietPlansTableCreateCompanionBuilder =
    DietPlansCompanion Function({
      required String id,
      required int clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      required String audience,
      Value<String?> season,
      Value<String?> budget,
      Value<String?> pantry,
      Value<String?> spokenText,
      required String planJson,
      Value<String> source,
      required DateTime plannedFor,
      Value<int> rowid,
    });
typedef $$DietPlansTableUpdateCompanionBuilder =
    DietPlansCompanion Function({
      Value<String> id,
      Value<int> clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      Value<String> audience,
      Value<String?> season,
      Value<String?> budget,
      Value<String?> pantry,
      Value<String?> spokenText,
      Value<String> planJson,
      Value<String> source,
      Value<DateTime> plannedFor,
      Value<int> rowid,
    });

class $$DietPlansTableFilterComposer
    extends Composer<_$AppDatabase, $DietPlansTable> {
  $$DietPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audience => $composableBuilder(
    column: $table.audience,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get budget => $composableBuilder(
    column: $table.budget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pantry => $composableBuilder(
    column: $table.pantry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spokenText => $composableBuilder(
    column: $table.spokenText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planJson => $composableBuilder(
    column: $table.planJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get plannedFor => $composableBuilder(
    column: $table.plannedFor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DietPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $DietPlansTable> {
  $$DietPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audience => $composableBuilder(
    column: $table.audience,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get budget => $composableBuilder(
    column: $table.budget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pantry => $composableBuilder(
    column: $table.pantry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spokenText => $composableBuilder(
    column: $table.spokenText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planJson => $composableBuilder(
    column: $table.planJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get plannedFor => $composableBuilder(
    column: $table.plannedFor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DietPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $DietPlansTable> {
  $$DietPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get audience =>
      $composableBuilder(column: $table.audience, builder: (column) => column);

  GeneratedColumn<String> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<String> get budget =>
      $composableBuilder(column: $table.budget, builder: (column) => column);

  GeneratedColumn<String> get pantry =>
      $composableBuilder(column: $table.pantry, builder: (column) => column);

  GeneratedColumn<String> get spokenText => $composableBuilder(
    column: $table.spokenText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get planJson =>
      $composableBuilder(column: $table.planJson, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get plannedFor => $composableBuilder(
    column: $table.plannedFor,
    builder: (column) => column,
  );
}

class $$DietPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DietPlansTable,
          DietPlanRow,
          $$DietPlansTableFilterComposer,
          $$DietPlansTableOrderingComposer,
          $$DietPlansTableAnnotationComposer,
          $$DietPlansTableCreateCompanionBuilder,
          $$DietPlansTableUpdateCompanionBuilder,
          (
            DietPlanRow,
            BaseReferences<_$AppDatabase, $DietPlansTable, DietPlanRow>,
          ),
          DietPlanRow,
          PrefetchHooks Function()
        > {
  $$DietPlansTableTableManager(_$AppDatabase db, $DietPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DietPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DietPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DietPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> clientUpdatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<String> audience = const Value.absent(),
                Value<String?> season = const Value.absent(),
                Value<String?> budget = const Value.absent(),
                Value<String?> pantry = const Value.absent(),
                Value<String?> spokenText = const Value.absent(),
                Value<String> planJson = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> plannedFor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DietPlansCompanion(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                audience: audience,
                season: season,
                budget: budget,
                pantry: pantry,
                spokenText: spokenText,
                planJson: planJson,
                source: source,
                plannedFor: plannedFor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int clientUpdatedAt,
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                required String audience,
                Value<String?> season = const Value.absent(),
                Value<String?> budget = const Value.absent(),
                Value<String?> pantry = const Value.absent(),
                Value<String?> spokenText = const Value.absent(),
                required String planJson,
                Value<String> source = const Value.absent(),
                required DateTime plannedFor,
                Value<int> rowid = const Value.absent(),
              }) => DietPlansCompanion.insert(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                audience: audience,
                season: season,
                budget: budget,
                pantry: pantry,
                spokenText: spokenText,
                planJson: planJson,
                source: source,
                plannedFor: plannedFor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DietPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DietPlansTable,
      DietPlanRow,
      $$DietPlansTableFilterComposer,
      $$DietPlansTableOrderingComposer,
      $$DietPlansTableAnnotationComposer,
      $$DietPlansTableCreateCompanionBuilder,
      $$DietPlansTableUpdateCompanionBuilder,
      (
        DietPlanRow,
        BaseReferences<_$AppDatabase, $DietPlansTable, DietPlanRow>,
      ),
      DietPlanRow,
      PrefetchHooks Function()
    >;
typedef $$DietLogsTableCreateCompanionBuilder =
    DietLogsCompanion Function({
      required String id,
      required int clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      required String day,
      required String groupsJson,
      required int score,
      Value<String?> eatenMealsJson,
      Value<int> rowid,
    });
typedef $$DietLogsTableUpdateCompanionBuilder =
    DietLogsCompanion Function({
      Value<String> id,
      Value<int> clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      Value<String> day,
      Value<String> groupsJson,
      Value<int> score,
      Value<String?> eatenMealsJson,
      Value<int> rowid,
    });

class $$DietLogsTableFilterComposer
    extends Composer<_$AppDatabase, $DietLogsTable> {
  $$DietLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupsJson => $composableBuilder(
    column: $table.groupsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eatenMealsJson => $composableBuilder(
    column: $table.eatenMealsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DietLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $DietLogsTable> {
  $$DietLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupsJson => $composableBuilder(
    column: $table.groupsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eatenMealsJson => $composableBuilder(
    column: $table.eatenMealsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DietLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DietLogsTable> {
  $$DietLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get groupsJson => $composableBuilder(
    column: $table.groupsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get eatenMealsJson => $composableBuilder(
    column: $table.eatenMealsJson,
    builder: (column) => column,
  );
}

class $$DietLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DietLogsTable,
          DietLogRow,
          $$DietLogsTableFilterComposer,
          $$DietLogsTableOrderingComposer,
          $$DietLogsTableAnnotationComposer,
          $$DietLogsTableCreateCompanionBuilder,
          $$DietLogsTableUpdateCompanionBuilder,
          (
            DietLogRow,
            BaseReferences<_$AppDatabase, $DietLogsTable, DietLogRow>,
          ),
          DietLogRow,
          PrefetchHooks Function()
        > {
  $$DietLogsTableTableManager(_$AppDatabase db, $DietLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DietLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DietLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DietLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> clientUpdatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> groupsJson = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<String?> eatenMealsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DietLogsCompanion(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                day: day,
                groupsJson: groupsJson,
                score: score,
                eatenMealsJson: eatenMealsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int clientUpdatedAt,
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                required String day,
                required String groupsJson,
                required int score,
                Value<String?> eatenMealsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DietLogsCompanion.insert(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                day: day,
                groupsJson: groupsJson,
                score: score,
                eatenMealsJson: eatenMealsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DietLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DietLogsTable,
      DietLogRow,
      $$DietLogsTableFilterComposer,
      $$DietLogsTableOrderingComposer,
      $$DietLogsTableAnnotationComposer,
      $$DietLogsTableCreateCompanionBuilder,
      $$DietLogsTableUpdateCompanionBuilder,
      (DietLogRow, BaseReferences<_$AppDatabase, $DietLogsTable, DietLogRow>),
      DietLogRow,
      PrefetchHooks Function()
    >;
typedef $$DailyTipsTableCreateCompanionBuilder =
    DailyTipsCompanion Function({
      required String id,
      required int clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      required String audience,
      required String title,
      required String body,
      required String forDay,
      Value<String> source,
      Value<int> rowid,
    });
typedef $$DailyTipsTableUpdateCompanionBuilder =
    DailyTipsCompanion Function({
      Value<String> id,
      Value<int> clientUpdatedAt,
      Value<bool> deleted,
      Value<bool> synced,
      Value<String> audience,
      Value<String> title,
      Value<String> body,
      Value<String> forDay,
      Value<String> source,
      Value<int> rowid,
    });

class $$DailyTipsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyTipsTable> {
  $$DailyTipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audience => $composableBuilder(
    column: $table.audience,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get forDay => $composableBuilder(
    column: $table.forDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyTipsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyTipsTable> {
  $$DailyTipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audience => $composableBuilder(
    column: $table.audience,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get forDay => $composableBuilder(
    column: $table.forDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyTipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyTipsTable> {
  $$DailyTipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get audience =>
      $composableBuilder(column: $table.audience, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get forDay =>
      $composableBuilder(column: $table.forDay, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$DailyTipsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyTipsTable,
          DailyTipRow,
          $$DailyTipsTableFilterComposer,
          $$DailyTipsTableOrderingComposer,
          $$DailyTipsTableAnnotationComposer,
          $$DailyTipsTableCreateCompanionBuilder,
          $$DailyTipsTableUpdateCompanionBuilder,
          (
            DailyTipRow,
            BaseReferences<_$AppDatabase, $DailyTipsTable, DailyTipRow>,
          ),
          DailyTipRow,
          PrefetchHooks Function()
        > {
  $$DailyTipsTableTableManager(_$AppDatabase db, $DailyTipsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyTipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyTipsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyTipsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> clientUpdatedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<String> audience = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> forDay = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyTipsCompanion(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                audience: audience,
                title: title,
                body: body,
                forDay: forDay,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int clientUpdatedAt,
                Value<bool> deleted = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                required String audience,
                required String title,
                required String body,
                required String forDay,
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyTipsCompanion.insert(
                id: id,
                clientUpdatedAt: clientUpdatedAt,
                deleted: deleted,
                synced: synced,
                audience: audience,
                title: title,
                body: body,
                forDay: forDay,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyTipsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyTipsTable,
      DailyTipRow,
      $$DailyTipsTableFilterComposer,
      $$DailyTipsTableOrderingComposer,
      $$DailyTipsTableAnnotationComposer,
      $$DailyTipsTableCreateCompanionBuilder,
      $$DailyTipsTableUpdateCompanionBuilder,
      (
        DailyTipRow,
        BaseReferences<_$AppDatabase, $DailyTipsTable, DailyTipRow>,
      ),
      DailyTipRow,
      PrefetchHooks Function()
    >;
typedef $$AlertsCacheTableCreateCompanionBuilder =
    AlertsCacheCompanion Function({
      required String id,
      required String status,
      required String summary,
      Value<String?> assessmentId,
      Value<String?> volunteerName,
      Value<String?> volunteerPhone,
      Value<String?> facilityName,
      Value<String?> facilityPhone,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });
typedef $$AlertsCacheTableUpdateCompanionBuilder =
    AlertsCacheCompanion Function({
      Value<String> id,
      Value<String> status,
      Value<String> summary,
      Value<String?> assessmentId,
      Value<String?> volunteerName,
      Value<String?> volunteerPhone,
      Value<String?> facilityName,
      Value<String?> facilityPhone,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });

class $$AlertsCacheTableFilterComposer
    extends Composer<_$AppDatabase, $AlertsCacheTable> {
  $$AlertsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assessmentId => $composableBuilder(
    column: $table.assessmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get volunteerName => $composableBuilder(
    column: $table.volunteerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get volunteerPhone => $composableBuilder(
    column: $table.volunteerPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get facilityName => $composableBuilder(
    column: $table.facilityName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get facilityPhone => $composableBuilder(
    column: $table.facilityPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlertsCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $AlertsCacheTable> {
  $$AlertsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assessmentId => $composableBuilder(
    column: $table.assessmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get volunteerName => $composableBuilder(
    column: $table.volunteerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get volunteerPhone => $composableBuilder(
    column: $table.volunteerPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get facilityName => $composableBuilder(
    column: $table.facilityName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get facilityPhone => $composableBuilder(
    column: $table.facilityPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlertsCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlertsCacheTable> {
  $$AlertsCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get assessmentId => $composableBuilder(
    column: $table.assessmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get volunteerName => $composableBuilder(
    column: $table.volunteerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get volunteerPhone => $composableBuilder(
    column: $table.volunteerPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get facilityName => $composableBuilder(
    column: $table.facilityName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get facilityPhone => $composableBuilder(
    column: $table.facilityPhone,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AlertsCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlertsCacheTable,
          AlertRow,
          $$AlertsCacheTableFilterComposer,
          $$AlertsCacheTableOrderingComposer,
          $$AlertsCacheTableAnnotationComposer,
          $$AlertsCacheTableCreateCompanionBuilder,
          $$AlertsCacheTableUpdateCompanionBuilder,
          (
            AlertRow,
            BaseReferences<_$AppDatabase, $AlertsCacheTable, AlertRow>,
          ),
          AlertRow,
          PrefetchHooks Function()
        > {
  $$AlertsCacheTableTableManager(_$AppDatabase db, $AlertsCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlertsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlertsCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String?> assessmentId = const Value.absent(),
                Value<String?> volunteerName = const Value.absent(),
                Value<String?> volunteerPhone = const Value.absent(),
                Value<String?> facilityName = const Value.absent(),
                Value<String?> facilityPhone = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertsCacheCompanion(
                id: id,
                status: status,
                summary: summary,
                assessmentId: assessmentId,
                volunteerName: volunteerName,
                volunteerPhone: volunteerPhone,
                facilityName: facilityName,
                facilityPhone: facilityPhone,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String status,
                required String summary,
                Value<String?> assessmentId = const Value.absent(),
                Value<String?> volunteerName = const Value.absent(),
                Value<String?> volunteerPhone = const Value.absent(),
                Value<String?> facilityName = const Value.absent(),
                Value<String?> facilityPhone = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertsCacheCompanion.insert(
                id: id,
                status: status,
                summary: summary,
                assessmentId: assessmentId,
                volunteerName: volunteerName,
                volunteerPhone: volunteerPhone,
                facilityName: facilityName,
                facilityPhone: facilityPhone,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlertsCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlertsCacheTable,
      AlertRow,
      $$AlertsCacheTableFilterComposer,
      $$AlertsCacheTableOrderingComposer,
      $$AlertsCacheTableAnnotationComposer,
      $$AlertsCacheTableCreateCompanionBuilder,
      $$AlertsCacheTableUpdateCompanionBuilder,
      (AlertRow, BaseReferences<_$AppDatabase, $AlertsCacheTable, AlertRow>),
      AlertRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChildrenTableTableManager get children =>
      $$ChildrenTableTableManager(_db, _db.children);
  $$PregnanciesTableTableManager get pregnancies =>
      $$PregnanciesTableTableManager(_db, _db.pregnancies);
  $$AssessmentsTableTableManager get assessments =>
      $$AssessmentsTableTableManager(_db, _db.assessments);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$GrowthRecordsTableTableManager get growthRecords =>
      $$GrowthRecordsTableTableManager(_db, _db.growthRecords);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
  $$DietPlansTableTableManager get dietPlans =>
      $$DietPlansTableTableManager(_db, _db.dietPlans);
  $$DietLogsTableTableManager get dietLogs =>
      $$DietLogsTableTableManager(_db, _db.dietLogs);
  $$DailyTipsTableTableManager get dailyTips =>
      $$DailyTipsTableTableManager(_db, _db.dailyTips);
  $$AlertsCacheTableTableManager get alertsCache =>
      $$AlertsCacheTableTableManager(_db, _db.alertsCache);
}
