// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AreasTable extends Areas with TableInfo<$AreasTable, Area> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AreasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BaseCategory, String>
  baseCategory = GeneratedColumn<String>(
    'base_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<BaseCategory>($AreasTable.$converterbaseCategory);
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purposeStatementMeta = const VerificationMeta(
    'purposeStatement',
  );
  @override
  late final GeneratedColumn<String> purposeStatement = GeneratedColumn<String>(
    'purpose_statement',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    baseCategory,
    displayName,
    icon,
    color,
    purposeStatement,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'areas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Area> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('purpose_statement')) {
      context.handle(
        _purposeStatementMeta,
        purposeStatement.isAcceptableOrUnknown(
          data['purpose_statement']!,
          _purposeStatementMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Area map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Area(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      baseCategory: $AreasTable.$converterbaseCategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}base_category'],
        )!,
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      purposeStatement: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purpose_statement'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AreasTable createAlias(String alias) {
    return $AreasTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BaseCategory, String, String>
  $converterbaseCategory = const EnumNameConverter<BaseCategory>(
    BaseCategory.values,
  );
}

class Area extends DataClass implements Insertable<Area> {
  final String id;
  final BaseCategory baseCategory;
  final String displayName;
  final String? icon;
  final String? color;
  final String? purposeStatement;
  final int sortOrder;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Area({
    required this.id,
    required this.baseCategory,
    required this.displayName,
    this.icon,
    this.color,
    this.purposeStatement,
    required this.sortOrder,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['base_category'] = Variable<String>(
        $AreasTable.$converterbaseCategory.toSql(baseCategory),
      );
    }
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || purposeStatement != null) {
      map['purpose_statement'] = Variable<String>(purposeStatement);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AreasCompanion toCompanion(bool nullToAbsent) {
    return AreasCompanion(
      id: Value(id),
      baseCategory: Value(baseCategory),
      displayName: Value(displayName),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      purposeStatement: purposeStatement == null && nullToAbsent
          ? const Value.absent()
          : Value(purposeStatement),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Area.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Area(
      id: serializer.fromJson<String>(json['id']),
      baseCategory: $AreasTable.$converterbaseCategory.fromJson(
        serializer.fromJson<String>(json['baseCategory']),
      ),
      displayName: serializer.fromJson<String>(json['displayName']),
      icon: serializer.fromJson<String?>(json['icon']),
      color: serializer.fromJson<String?>(json['color']),
      purposeStatement: serializer.fromJson<String?>(json['purposeStatement']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'baseCategory': serializer.toJson<String>(
        $AreasTable.$converterbaseCategory.toJson(baseCategory),
      ),
      'displayName': serializer.toJson<String>(displayName),
      'icon': serializer.toJson<String?>(icon),
      'color': serializer.toJson<String?>(color),
      'purposeStatement': serializer.toJson<String?>(purposeStatement),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Area copyWith({
    String? id,
    BaseCategory? baseCategory,
    String? displayName,
    Value<String?> icon = const Value.absent(),
    Value<String?> color = const Value.absent(),
    Value<String?> purposeStatement = const Value.absent(),
    int? sortOrder,
    bool? archived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Area(
    id: id ?? this.id,
    baseCategory: baseCategory ?? this.baseCategory,
    displayName: displayName ?? this.displayName,
    icon: icon.present ? icon.value : this.icon,
    color: color.present ? color.value : this.color,
    purposeStatement: purposeStatement.present
        ? purposeStatement.value
        : this.purposeStatement,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Area copyWithCompanion(AreasCompanion data) {
    return Area(
      id: data.id.present ? data.id.value : this.id,
      baseCategory: data.baseCategory.present
          ? data.baseCategory.value
          : this.baseCategory,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      purposeStatement: data.purposeStatement.present
          ? data.purposeStatement.value
          : this.purposeStatement,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Area(')
          ..write('id: $id, ')
          ..write('baseCategory: $baseCategory, ')
          ..write('displayName: $displayName, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('purposeStatement: $purposeStatement, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    baseCategory,
    displayName,
    icon,
    color,
    purposeStatement,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Area &&
          other.id == this.id &&
          other.baseCategory == this.baseCategory &&
          other.displayName == this.displayName &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.purposeStatement == this.purposeStatement &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AreasCompanion extends UpdateCompanion<Area> {
  final Value<String> id;
  final Value<BaseCategory> baseCategory;
  final Value<String> displayName;
  final Value<String?> icon;
  final Value<String?> color;
  final Value<String?> purposeStatement;
  final Value<int> sortOrder;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AreasCompanion({
    this.id = const Value.absent(),
    this.baseCategory = const Value.absent(),
    this.displayName = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.purposeStatement = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AreasCompanion.insert({
    required String id,
    required BaseCategory baseCategory,
    required String displayName,
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.purposeStatement = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       baseCategory = Value(baseCategory),
       displayName = Value(displayName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Area> custom({
    Expression<String>? id,
    Expression<String>? baseCategory,
    Expression<String>? displayName,
    Expression<String>? icon,
    Expression<String>? color,
    Expression<String>? purposeStatement,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baseCategory != null) 'base_category': baseCategory,
      if (displayName != null) 'display_name': displayName,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (purposeStatement != null) 'purpose_statement': purposeStatement,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AreasCompanion copyWith({
    Value<String>? id,
    Value<BaseCategory>? baseCategory,
    Value<String>? displayName,
    Value<String?>? icon,
    Value<String?>? color,
    Value<String?>? purposeStatement,
    Value<int>? sortOrder,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AreasCompanion(
      id: id ?? this.id,
      baseCategory: baseCategory ?? this.baseCategory,
      displayName: displayName ?? this.displayName,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      purposeStatement: purposeStatement ?? this.purposeStatement,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (baseCategory.present) {
      map['base_category'] = Variable<String>(
        $AreasTable.$converterbaseCategory.toSql(baseCategory.value),
      );
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (purposeStatement.present) {
      map['purpose_statement'] = Variable<String>(purposeStatement.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AreasCompanion(')
          ..write('id: $id, ')
          ..write('baseCategory: $baseCategory, ')
          ..write('displayName: $displayName, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('purposeStatement: $purposeStatement, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MeasurableResultsTable extends MeasurableResults
    with TableInfo<$MeasurableResultsTable, MeasurableResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeasurableResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _areaIdMeta = const VerificationMeta('areaId');
  @override
  late final GeneratedColumn<String> areaId = GeneratedColumn<String>(
    'area_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES areas (id)',
    ),
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
  @override
  late final GeneratedColumnWithTypeConverter<MetricType, String> metricType =
      GeneratedColumn<String>(
        'metric_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MetricType>($MeasurableResultsTable.$convertermetricType);
  static const VerificationMeta _targetValueMeta = const VerificationMeta(
    'targetValue',
  );
  @override
  late final GeneratedColumn<double> targetValue = GeneratedColumn<double>(
    'target_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Comparator, String> comparator =
      GeneratedColumn<String>(
        'comparator',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Comparator>($MeasurableResultsTable.$convertercomparator);
  @override
  late final GeneratedColumnWithTypeConverter<Cadence, String> cadence =
      GeneratedColumn<String>(
        'cadence',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Cadence>($MeasurableResultsTable.$convertercadence);
  static const VerificationMeta _daysPerCadenceMeta = const VerificationMeta(
    'daysPerCadence',
  );
  @override
  late final GeneratedColumn<int> daysPerCadence = GeneratedColumn<int>(
    'days_per_cadence',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Verification, String>
  verification = GeneratedColumn<String>(
    'verification',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<Verification>($MeasurableResultsTable.$converterverification);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalEndDateMeta = const VerificationMeta(
    'originalEndDate',
  );
  @override
  late final GeneratedColumn<DateTime> originalEndDate =
      GeneratedColumn<DateTime>(
        'original_end_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deadlineMovesMeta = const VerificationMeta(
    'deadlineMoves',
  );
  @override
  late final GeneratedColumn<int> deadlineMoves = GeneratedColumn<int>(
    'deadline_moves',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    areaId,
    title,
    metricType,
    targetValue,
    comparator,
    cadence,
    daysPerCadence,
    verification,
    unit,
    startDate,
    endDate,
    originalEndDate,
    deadlineMoves,
    active,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'measurable_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeasurableResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('area_id')) {
      context.handle(
        _areaIdMeta,
        areaId.isAcceptableOrUnknown(data['area_id']!, _areaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_areaIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_value')) {
      context.handle(
        _targetValueMeta,
        targetValue.isAcceptableOrUnknown(
          data['target_value']!,
          _targetValueMeta,
        ),
      );
    }
    if (data.containsKey('days_per_cadence')) {
      context.handle(
        _daysPerCadenceMeta,
        daysPerCadence.isAcceptableOrUnknown(
          data['days_per_cadence']!,
          _daysPerCadenceMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('original_end_date')) {
      context.handle(
        _originalEndDateMeta,
        originalEndDate.isAcceptableOrUnknown(
          data['original_end_date']!,
          _originalEndDateMeta,
        ),
      );
    }
    if (data.containsKey('deadline_moves')) {
      context.handle(
        _deadlineMovesMeta,
        deadlineMoves.isAcceptableOrUnknown(
          data['deadline_moves']!,
          _deadlineMovesMeta,
        ),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeasurableResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeasurableResult(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      areaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      metricType: $MeasurableResultsTable.$convertermetricType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}metric_type'],
        )!,
      ),
      targetValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_value'],
      ),
      comparator: $MeasurableResultsTable.$convertercomparator.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}comparator'],
        )!,
      ),
      cadence: $MeasurableResultsTable.$convertercadence.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cadence'],
        )!,
      ),
      daysPerCadence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days_per_cadence'],
      ),
      verification: $MeasurableResultsTable.$converterverification.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}verification'],
        )!,
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      originalEndDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}original_end_date'],
      ),
      deadlineMoves: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deadline_moves'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MeasurableResultsTable createAlias(String alias) {
    return $MeasurableResultsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MetricType, String, String> $convertermetricType =
      const EnumNameConverter<MetricType>(MetricType.values);
  static JsonTypeConverter2<Comparator, String, String> $convertercomparator =
      const EnumNameConverter<Comparator>(Comparator.values);
  static JsonTypeConverter2<Cadence, String, String> $convertercadence =
      const EnumNameConverter<Cadence>(Cadence.values);
  static JsonTypeConverter2<Verification, String, String>
  $converterverification = const EnumNameConverter<Verification>(
    Verification.values,
  );
}

class MeasurableResult extends DataClass
    implements Insertable<MeasurableResult> {
  final String id;
  final String areaId;
  final String title;
  final MetricType metricType;
  final double? targetValue;
  final Comparator comparator;
  final Cadence cadence;
  final int? daysPerCadence;
  final Verification verification;
  final String? unit;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? originalEndDate;
  final int deadlineMoves;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MeasurableResult({
    required this.id,
    required this.areaId,
    required this.title,
    required this.metricType,
    this.targetValue,
    required this.comparator,
    required this.cadence,
    this.daysPerCadence,
    required this.verification,
    this.unit,
    required this.startDate,
    this.endDate,
    this.originalEndDate,
    required this.deadlineMoves,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['area_id'] = Variable<String>(areaId);
    map['title'] = Variable<String>(title);
    {
      map['metric_type'] = Variable<String>(
        $MeasurableResultsTable.$convertermetricType.toSql(metricType),
      );
    }
    if (!nullToAbsent || targetValue != null) {
      map['target_value'] = Variable<double>(targetValue);
    }
    {
      map['comparator'] = Variable<String>(
        $MeasurableResultsTable.$convertercomparator.toSql(comparator),
      );
    }
    {
      map['cadence'] = Variable<String>(
        $MeasurableResultsTable.$convertercadence.toSql(cadence),
      );
    }
    if (!nullToAbsent || daysPerCadence != null) {
      map['days_per_cadence'] = Variable<int>(daysPerCadence);
    }
    {
      map['verification'] = Variable<String>(
        $MeasurableResultsTable.$converterverification.toSql(verification),
      );
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || originalEndDate != null) {
      map['original_end_date'] = Variable<DateTime>(originalEndDate);
    }
    map['deadline_moves'] = Variable<int>(deadlineMoves);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MeasurableResultsCompanion toCompanion(bool nullToAbsent) {
    return MeasurableResultsCompanion(
      id: Value(id),
      areaId: Value(areaId),
      title: Value(title),
      metricType: Value(metricType),
      targetValue: targetValue == null && nullToAbsent
          ? const Value.absent()
          : Value(targetValue),
      comparator: Value(comparator),
      cadence: Value(cadence),
      daysPerCadence: daysPerCadence == null && nullToAbsent
          ? const Value.absent()
          : Value(daysPerCadence),
      verification: Value(verification),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      originalEndDate: originalEndDate == null && nullToAbsent
          ? const Value.absent()
          : Value(originalEndDate),
      deadlineMoves: Value(deadlineMoves),
      active: Value(active),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MeasurableResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeasurableResult(
      id: serializer.fromJson<String>(json['id']),
      areaId: serializer.fromJson<String>(json['areaId']),
      title: serializer.fromJson<String>(json['title']),
      metricType: $MeasurableResultsTable.$convertermetricType.fromJson(
        serializer.fromJson<String>(json['metricType']),
      ),
      targetValue: serializer.fromJson<double?>(json['targetValue']),
      comparator: $MeasurableResultsTable.$convertercomparator.fromJson(
        serializer.fromJson<String>(json['comparator']),
      ),
      cadence: $MeasurableResultsTable.$convertercadence.fromJson(
        serializer.fromJson<String>(json['cadence']),
      ),
      daysPerCadence: serializer.fromJson<int?>(json['daysPerCadence']),
      verification: $MeasurableResultsTable.$converterverification.fromJson(
        serializer.fromJson<String>(json['verification']),
      ),
      unit: serializer.fromJson<String?>(json['unit']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      originalEndDate: serializer.fromJson<DateTime?>(json['originalEndDate']),
      deadlineMoves: serializer.fromJson<int>(json['deadlineMoves']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'areaId': serializer.toJson<String>(areaId),
      'title': serializer.toJson<String>(title),
      'metricType': serializer.toJson<String>(
        $MeasurableResultsTable.$convertermetricType.toJson(metricType),
      ),
      'targetValue': serializer.toJson<double?>(targetValue),
      'comparator': serializer.toJson<String>(
        $MeasurableResultsTable.$convertercomparator.toJson(comparator),
      ),
      'cadence': serializer.toJson<String>(
        $MeasurableResultsTable.$convertercadence.toJson(cadence),
      ),
      'daysPerCadence': serializer.toJson<int?>(daysPerCadence),
      'verification': serializer.toJson<String>(
        $MeasurableResultsTable.$converterverification.toJson(verification),
      ),
      'unit': serializer.toJson<String?>(unit),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'originalEndDate': serializer.toJson<DateTime?>(originalEndDate),
      'deadlineMoves': serializer.toJson<int>(deadlineMoves),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MeasurableResult copyWith({
    String? id,
    String? areaId,
    String? title,
    MetricType? metricType,
    Value<double?> targetValue = const Value.absent(),
    Comparator? comparator,
    Cadence? cadence,
    Value<int?> daysPerCadence = const Value.absent(),
    Verification? verification,
    Value<String?> unit = const Value.absent(),
    DateTime? startDate,
    Value<DateTime?> endDate = const Value.absent(),
    Value<DateTime?> originalEndDate = const Value.absent(),
    int? deadlineMoves,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MeasurableResult(
    id: id ?? this.id,
    areaId: areaId ?? this.areaId,
    title: title ?? this.title,
    metricType: metricType ?? this.metricType,
    targetValue: targetValue.present ? targetValue.value : this.targetValue,
    comparator: comparator ?? this.comparator,
    cadence: cadence ?? this.cadence,
    daysPerCadence: daysPerCadence.present
        ? daysPerCadence.value
        : this.daysPerCadence,
    verification: verification ?? this.verification,
    unit: unit.present ? unit.value : this.unit,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    originalEndDate: originalEndDate.present
        ? originalEndDate.value
        : this.originalEndDate,
    deadlineMoves: deadlineMoves ?? this.deadlineMoves,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MeasurableResult copyWithCompanion(MeasurableResultsCompanion data) {
    return MeasurableResult(
      id: data.id.present ? data.id.value : this.id,
      areaId: data.areaId.present ? data.areaId.value : this.areaId,
      title: data.title.present ? data.title.value : this.title,
      metricType: data.metricType.present
          ? data.metricType.value
          : this.metricType,
      targetValue: data.targetValue.present
          ? data.targetValue.value
          : this.targetValue,
      comparator: data.comparator.present
          ? data.comparator.value
          : this.comparator,
      cadence: data.cadence.present ? data.cadence.value : this.cadence,
      daysPerCadence: data.daysPerCadence.present
          ? data.daysPerCadence.value
          : this.daysPerCadence,
      verification: data.verification.present
          ? data.verification.value
          : this.verification,
      unit: data.unit.present ? data.unit.value : this.unit,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      originalEndDate: data.originalEndDate.present
          ? data.originalEndDate.value
          : this.originalEndDate,
      deadlineMoves: data.deadlineMoves.present
          ? data.deadlineMoves.value
          : this.deadlineMoves,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeasurableResult(')
          ..write('id: $id, ')
          ..write('areaId: $areaId, ')
          ..write('title: $title, ')
          ..write('metricType: $metricType, ')
          ..write('targetValue: $targetValue, ')
          ..write('comparator: $comparator, ')
          ..write('cadence: $cadence, ')
          ..write('daysPerCadence: $daysPerCadence, ')
          ..write('verification: $verification, ')
          ..write('unit: $unit, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('originalEndDate: $originalEndDate, ')
          ..write('deadlineMoves: $deadlineMoves, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    areaId,
    title,
    metricType,
    targetValue,
    comparator,
    cadence,
    daysPerCadence,
    verification,
    unit,
    startDate,
    endDate,
    originalEndDate,
    deadlineMoves,
    active,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeasurableResult &&
          other.id == this.id &&
          other.areaId == this.areaId &&
          other.title == this.title &&
          other.metricType == this.metricType &&
          other.targetValue == this.targetValue &&
          other.comparator == this.comparator &&
          other.cadence == this.cadence &&
          other.daysPerCadence == this.daysPerCadence &&
          other.verification == this.verification &&
          other.unit == this.unit &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.originalEndDate == this.originalEndDate &&
          other.deadlineMoves == this.deadlineMoves &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MeasurableResultsCompanion extends UpdateCompanion<MeasurableResult> {
  final Value<String> id;
  final Value<String> areaId;
  final Value<String> title;
  final Value<MetricType> metricType;
  final Value<double?> targetValue;
  final Value<Comparator> comparator;
  final Value<Cadence> cadence;
  final Value<int?> daysPerCadence;
  final Value<Verification> verification;
  final Value<String?> unit;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<DateTime?> originalEndDate;
  final Value<int> deadlineMoves;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MeasurableResultsCompanion({
    this.id = const Value.absent(),
    this.areaId = const Value.absent(),
    this.title = const Value.absent(),
    this.metricType = const Value.absent(),
    this.targetValue = const Value.absent(),
    this.comparator = const Value.absent(),
    this.cadence = const Value.absent(),
    this.daysPerCadence = const Value.absent(),
    this.verification = const Value.absent(),
    this.unit = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.originalEndDate = const Value.absent(),
    this.deadlineMoves = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeasurableResultsCompanion.insert({
    required String id,
    required String areaId,
    required String title,
    required MetricType metricType,
    this.targetValue = const Value.absent(),
    required Comparator comparator,
    required Cadence cadence,
    this.daysPerCadence = const Value.absent(),
    required Verification verification,
    this.unit = const Value.absent(),
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.originalEndDate = const Value.absent(),
    this.deadlineMoves = const Value.absent(),
    this.active = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       areaId = Value(areaId),
       title = Value(title),
       metricType = Value(metricType),
       comparator = Value(comparator),
       cadence = Value(cadence),
       verification = Value(verification),
       startDate = Value(startDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MeasurableResult> custom({
    Expression<String>? id,
    Expression<String>? areaId,
    Expression<String>? title,
    Expression<String>? metricType,
    Expression<double>? targetValue,
    Expression<String>? comparator,
    Expression<String>? cadence,
    Expression<int>? daysPerCadence,
    Expression<String>? verification,
    Expression<String>? unit,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<DateTime>? originalEndDate,
    Expression<int>? deadlineMoves,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (areaId != null) 'area_id': areaId,
      if (title != null) 'title': title,
      if (metricType != null) 'metric_type': metricType,
      if (targetValue != null) 'target_value': targetValue,
      if (comparator != null) 'comparator': comparator,
      if (cadence != null) 'cadence': cadence,
      if (daysPerCadence != null) 'days_per_cadence': daysPerCadence,
      if (verification != null) 'verification': verification,
      if (unit != null) 'unit': unit,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (originalEndDate != null) 'original_end_date': originalEndDate,
      if (deadlineMoves != null) 'deadline_moves': deadlineMoves,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeasurableResultsCompanion copyWith({
    Value<String>? id,
    Value<String>? areaId,
    Value<String>? title,
    Value<MetricType>? metricType,
    Value<double?>? targetValue,
    Value<Comparator>? comparator,
    Value<Cadence>? cadence,
    Value<int?>? daysPerCadence,
    Value<Verification>? verification,
    Value<String?>? unit,
    Value<DateTime>? startDate,
    Value<DateTime?>? endDate,
    Value<DateTime?>? originalEndDate,
    Value<int>? deadlineMoves,
    Value<bool>? active,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MeasurableResultsCompanion(
      id: id ?? this.id,
      areaId: areaId ?? this.areaId,
      title: title ?? this.title,
      metricType: metricType ?? this.metricType,
      targetValue: targetValue ?? this.targetValue,
      comparator: comparator ?? this.comparator,
      cadence: cadence ?? this.cadence,
      daysPerCadence: daysPerCadence ?? this.daysPerCadence,
      verification: verification ?? this.verification,
      unit: unit ?? this.unit,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      originalEndDate: originalEndDate ?? this.originalEndDate,
      deadlineMoves: deadlineMoves ?? this.deadlineMoves,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (areaId.present) {
      map['area_id'] = Variable<String>(areaId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (metricType.present) {
      map['metric_type'] = Variable<String>(
        $MeasurableResultsTable.$convertermetricType.toSql(metricType.value),
      );
    }
    if (targetValue.present) {
      map['target_value'] = Variable<double>(targetValue.value);
    }
    if (comparator.present) {
      map['comparator'] = Variable<String>(
        $MeasurableResultsTable.$convertercomparator.toSql(comparator.value),
      );
    }
    if (cadence.present) {
      map['cadence'] = Variable<String>(
        $MeasurableResultsTable.$convertercadence.toSql(cadence.value),
      );
    }
    if (daysPerCadence.present) {
      map['days_per_cadence'] = Variable<int>(daysPerCadence.value);
    }
    if (verification.present) {
      map['verification'] = Variable<String>(
        $MeasurableResultsTable.$converterverification.toSql(
          verification.value,
        ),
      );
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (originalEndDate.present) {
      map['original_end_date'] = Variable<DateTime>(originalEndDate.value);
    }
    if (deadlineMoves.present) {
      map['deadline_moves'] = Variable<int>(deadlineMoves.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeasurableResultsCompanion(')
          ..write('id: $id, ')
          ..write('areaId: $areaId, ')
          ..write('title: $title, ')
          ..write('metricType: $metricType, ')
          ..write('targetValue: $targetValue, ')
          ..write('comparator: $comparator, ')
          ..write('cadence: $cadence, ')
          ..write('daysPerCadence: $daysPerCadence, ')
          ..write('verification: $verification, ')
          ..write('unit: $unit, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('originalEndDate: $originalEndDate, ')
          ..write('deadlineMoves: $deadlineMoves, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MeasurableLogsTable extends MeasurableLogs
    with TableInfo<$MeasurableLogsTable, MeasurableLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeasurableLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultIdMeta = const VerificationMeta(
    'resultId',
  );
  @override
  late final GeneratedColumn<String> resultId = GeneratedColumn<String>(
    'result_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES measurable_results (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
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
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    resultId,
    date,
    value,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'measurable_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeasurableLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('result_id')) {
      context.handle(
        _resultIdMeta,
        resultId.isAcceptableOrUnknown(data['result_id']!, _resultIdMeta),
      );
    } else if (isInserting) {
      context.missing(_resultIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeasurableLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeasurableLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      resultId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MeasurableLogsTable createAlias(String alias) {
    return $MeasurableLogsTable(attachedDatabase, alias);
  }
}

class MeasurableLog extends DataClass implements Insertable<MeasurableLog> {
  final String id;
  final String resultId;
  final String date;
  final double value;
  final String? note;
  final DateTime createdAt;
  const MeasurableLog({
    required this.id,
    required this.resultId,
    required this.date,
    required this.value,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['result_id'] = Variable<String>(resultId);
    map['date'] = Variable<String>(date);
    map['value'] = Variable<double>(value);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MeasurableLogsCompanion toCompanion(bool nullToAbsent) {
    return MeasurableLogsCompanion(
      id: Value(id),
      resultId: Value(resultId),
      date: Value(date),
      value: Value(value),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory MeasurableLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeasurableLog(
      id: serializer.fromJson<String>(json['id']),
      resultId: serializer.fromJson<String>(json['resultId']),
      date: serializer.fromJson<String>(json['date']),
      value: serializer.fromJson<double>(json['value']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'resultId': serializer.toJson<String>(resultId),
      'date': serializer.toJson<String>(date),
      'value': serializer.toJson<double>(value),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MeasurableLog copyWith({
    String? id,
    String? resultId,
    String? date,
    double? value,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => MeasurableLog(
    id: id ?? this.id,
    resultId: resultId ?? this.resultId,
    date: date ?? this.date,
    value: value ?? this.value,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  MeasurableLog copyWithCompanion(MeasurableLogsCompanion data) {
    return MeasurableLog(
      id: data.id.present ? data.id.value : this.id,
      resultId: data.resultId.present ? data.resultId.value : this.resultId,
      date: data.date.present ? data.date.value : this.date,
      value: data.value.present ? data.value.value : this.value,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeasurableLog(')
          ..write('id: $id, ')
          ..write('resultId: $resultId, ')
          ..write('date: $date, ')
          ..write('value: $value, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, resultId, date, value, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeasurableLog &&
          other.id == this.id &&
          other.resultId == this.resultId &&
          other.date == this.date &&
          other.value == this.value &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class MeasurableLogsCompanion extends UpdateCompanion<MeasurableLog> {
  final Value<String> id;
  final Value<String> resultId;
  final Value<String> date;
  final Value<double> value;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MeasurableLogsCompanion({
    this.id = const Value.absent(),
    this.resultId = const Value.absent(),
    this.date = const Value.absent(),
    this.value = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeasurableLogsCompanion.insert({
    required String id,
    required String resultId,
    required String date,
    required double value,
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       resultId = Value(resultId),
       date = Value(date),
       value = Value(value),
       createdAt = Value(createdAt);
  static Insertable<MeasurableLog> custom({
    Expression<String>? id,
    Expression<String>? resultId,
    Expression<String>? date,
    Expression<double>? value,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (resultId != null) 'result_id': resultId,
      if (date != null) 'date': date,
      if (value != null) 'value': value,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeasurableLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? resultId,
    Value<String>? date,
    Value<double>? value,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MeasurableLogsCompanion(
      id: id ?? this.id,
      resultId: resultId ?? this.resultId,
      date: date ?? this.date,
      value: value ?? this.value,
      note: note ?? this.note,
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
    if (resultId.present) {
      map['result_id'] = Variable<String>(resultId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
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
    return (StringBuffer('MeasurableLogsCompanion(')
          ..write('id: $id, ')
          ..write('resultId: $resultId, ')
          ..write('date: $date, ')
          ..write('value: $value, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaIdMeta = const VerificationMeta('areaId');
  @override
  late final GeneratedColumn<String> areaId = GeneratedColumn<String>(
    'area_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES areas (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(TaskStatus.created.name),
      ).withConverter<TaskStatus>($TasksTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<TaskKind?, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<TaskKind?>($TasksTable.$converterkindn);
  static const VerificationMeta _attachmentImagePathMeta =
      const VerificationMeta('attachmentImagePath');
  @override
  late final GeneratedColumn<String> attachmentImagePath =
      GeneratedColumn<String>(
        'attachment_image_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _documentLinkMeta = const VerificationMeta(
    'documentLink',
  );
  @override
  late final GeneratedColumn<String> documentLink = GeneratedColumn<String>(
    'document_link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledStartMeta = const VerificationMeta(
    'scheduledStart',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledStart =
      GeneratedColumn<DateTime>(
        'scheduled_start',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _durationMinMeta = const VerificationMeta(
    'durationMin',
  );
  @override
  late final GeneratedColumn<int> durationMin = GeneratedColumn<int>(
    'duration_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
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
  static const VerificationMeta _timeToCompleteMinMeta = const VerificationMeta(
    'timeToCompleteMin',
  );
  @override
  late final GeneratedColumn<int> timeToCompleteMin = GeneratedColumn<int>(
    'time_to_complete_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rruleMeta = const VerificationMeta('rrule');
  @override
  late final GeneratedColumn<String> rrule = GeneratedColumn<String>(
    'rrule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentRecurringIdMeta = const VerificationMeta(
    'parentRecurringId',
  );
  @override
  late final GeneratedColumn<String> parentRecurringId =
      GeneratedColumn<String>(
        'parent_recurring_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _occurrenceSlotMeta = const VerificationMeta(
    'occurrenceSlot',
  );
  @override
  late final GeneratedColumn<DateTime> occurrenceSlot =
      GeneratedColumn<DateTime>(
        'occurrence_slot',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _parentEventIdMeta = const VerificationMeta(
    'parentEventId',
  );
  @override
  late final GeneratedColumn<String> parentEventId = GeneratedColumn<String>(
    'parent_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewNotesMeta = const VerificationMeta(
    'reviewNotes',
  );
  @override
  late final GeneratedColumn<String> reviewNotes = GeneratedColumn<String>(
    'review_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _meetingLinkMeta = const VerificationMeta(
    'meetingLink',
  );
  @override
  late final GeneratedColumn<String> meetingLink = GeneratedColumn<String>(
    'meeting_link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MeetingProvider?, String>
  meetingProvider = GeneratedColumn<String>(
    'meeting_provider',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<MeetingProvider?>($TasksTable.$convertermeetingProvidern);
  static const VerificationMeta _locationNameMeta = const VerificationMeta(
    'locationName',
  );
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
    'location_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _geofenceEnabledMeta = const VerificationMeta(
    'geofenceEnabled',
  );
  @override
  late final GeneratedColumn<bool> geofenceEnabled = GeneratedColumn<bool>(
    'geofence_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("geofence_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<int>?, String>
  reminderOffsets = GeneratedColumn<String>(
    'reminder_offsets',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<List<int>?>($TasksTable.$converterreminderOffsetsn);
  static const VerificationMeta _gcalEventIdMeta = const VerificationMeta(
    'gcalEventId',
  );
  @override
  late final GeneratedColumn<String> gcalEventId = GeneratedColumn<String>(
    'gcal_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gcalCalendarIdMeta = const VerificationMeta(
    'gcalCalendarId',
  );
  @override
  late final GeneratedColumn<String> gcalCalendarId = GeneratedColumn<String>(
    'gcal_calendar_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gcalEtagMeta = const VerificationMeta(
    'gcalEtag',
  );
  @override
  late final GeneratedColumn<String> gcalEtag = GeneratedColumn<String>(
    'gcal_etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(TaskSource.manual.name),
      ).withConverter<TaskSource>($TasksTable.$convertersource);
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    notes,
    areaId,
    status,
    kind,
    attachmentImagePath,
    documentLink,
    scheduledStart,
    durationMin,
    dueDate,
    completedAt,
    timeToCompleteMin,
    rrule,
    parentRecurringId,
    occurrenceSlot,
    parentEventId,
    reviewNotes,
    meetingLink,
    meetingProvider,
    locationName,
    lat,
    lng,
    geofenceEnabled,
    reminderOffsets,
    gcalEventId,
    gcalCalendarId,
    gcalEtag,
    lastSyncedAt,
    source,
    priority,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('area_id')) {
      context.handle(
        _areaIdMeta,
        areaId.isAcceptableOrUnknown(data['area_id']!, _areaIdMeta),
      );
    }
    if (data.containsKey('attachment_image_path')) {
      context.handle(
        _attachmentImagePathMeta,
        attachmentImagePath.isAcceptableOrUnknown(
          data['attachment_image_path']!,
          _attachmentImagePathMeta,
        ),
      );
    }
    if (data.containsKey('document_link')) {
      context.handle(
        _documentLinkMeta,
        documentLink.isAcceptableOrUnknown(
          data['document_link']!,
          _documentLinkMeta,
        ),
      );
    }
    if (data.containsKey('scheduled_start')) {
      context.handle(
        _scheduledStartMeta,
        scheduledStart.isAcceptableOrUnknown(
          data['scheduled_start']!,
          _scheduledStartMeta,
        ),
      );
    }
    if (data.containsKey('duration_min')) {
      context.handle(
        _durationMinMeta,
        durationMin.isAcceptableOrUnknown(
          data['duration_min']!,
          _durationMinMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
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
    if (data.containsKey('time_to_complete_min')) {
      context.handle(
        _timeToCompleteMinMeta,
        timeToCompleteMin.isAcceptableOrUnknown(
          data['time_to_complete_min']!,
          _timeToCompleteMinMeta,
        ),
      );
    }
    if (data.containsKey('rrule')) {
      context.handle(
        _rruleMeta,
        rrule.isAcceptableOrUnknown(data['rrule']!, _rruleMeta),
      );
    }
    if (data.containsKey('parent_recurring_id')) {
      context.handle(
        _parentRecurringIdMeta,
        parentRecurringId.isAcceptableOrUnknown(
          data['parent_recurring_id']!,
          _parentRecurringIdMeta,
        ),
      );
    }
    if (data.containsKey('occurrence_slot')) {
      context.handle(
        _occurrenceSlotMeta,
        occurrenceSlot.isAcceptableOrUnknown(
          data['occurrence_slot']!,
          _occurrenceSlotMeta,
        ),
      );
    }
    if (data.containsKey('parent_event_id')) {
      context.handle(
        _parentEventIdMeta,
        parentEventId.isAcceptableOrUnknown(
          data['parent_event_id']!,
          _parentEventIdMeta,
        ),
      );
    }
    if (data.containsKey('review_notes')) {
      context.handle(
        _reviewNotesMeta,
        reviewNotes.isAcceptableOrUnknown(
          data['review_notes']!,
          _reviewNotesMeta,
        ),
      );
    }
    if (data.containsKey('meeting_link')) {
      context.handle(
        _meetingLinkMeta,
        meetingLink.isAcceptableOrUnknown(
          data['meeting_link']!,
          _meetingLinkMeta,
        ),
      );
    }
    if (data.containsKey('location_name')) {
      context.handle(
        _locationNameMeta,
        locationName.isAcceptableOrUnknown(
          data['location_name']!,
          _locationNameMeta,
        ),
      );
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    }
    if (data.containsKey('geofence_enabled')) {
      context.handle(
        _geofenceEnabledMeta,
        geofenceEnabled.isAcceptableOrUnknown(
          data['geofence_enabled']!,
          _geofenceEnabledMeta,
        ),
      );
    }
    if (data.containsKey('gcal_event_id')) {
      context.handle(
        _gcalEventIdMeta,
        gcalEventId.isAcceptableOrUnknown(
          data['gcal_event_id']!,
          _gcalEventIdMeta,
        ),
      );
    }
    if (data.containsKey('gcal_calendar_id')) {
      context.handle(
        _gcalCalendarIdMeta,
        gcalCalendarId.isAcceptableOrUnknown(
          data['gcal_calendar_id']!,
          _gcalCalendarIdMeta,
        ),
      );
    }
    if (data.containsKey('gcal_etag')) {
      context.handle(
        _gcalEtagMeta,
        gcalEtag.isAcceptableOrUnknown(data['gcal_etag']!, _gcalEtagMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      areaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_id'],
      ),
      status: $TasksTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      kind: $TasksTable.$converterkindn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        ),
      ),
      attachmentImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_image_path'],
      ),
      documentLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_link'],
      ),
      scheduledStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_start'],
      ),
      durationMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_min'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      timeToCompleteMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_to_complete_min'],
      ),
      rrule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rrule'],
      ),
      parentRecurringId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_recurring_id'],
      ),
      occurrenceSlot: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurrence_slot'],
      ),
      parentEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_event_id'],
      ),
      reviewNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_notes'],
      ),
      meetingLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meeting_link'],
      ),
      meetingProvider: $TasksTable.$convertermeetingProvidern.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}meeting_provider'],
        ),
      ),
      locationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_name'],
      ),
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      ),
      geofenceEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}geofence_enabled'],
      )!,
      reminderOffsets: $TasksTable.$converterreminderOffsetsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}reminder_offsets'],
        ),
      ),
      gcalEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gcal_event_id'],
      ),
      gcalCalendarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gcal_calendar_id'],
      ),
      gcalEtag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gcal_etag'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      source: $TasksTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskStatus, String, String> $converterstatus =
      const EnumNameConverter<TaskStatus>(TaskStatus.values);
  static JsonTypeConverter2<TaskKind, String, String> $converterkind =
      const EnumNameConverter<TaskKind>(TaskKind.values);
  static JsonTypeConverter2<TaskKind?, String?, String?> $converterkindn =
      JsonTypeConverter2.asNullable($converterkind);
  static JsonTypeConverter2<MeetingProvider, String, String>
  $convertermeetingProvider = const EnumNameConverter<MeetingProvider>(
    MeetingProvider.values,
  );
  static JsonTypeConverter2<MeetingProvider?, String?, String?>
  $convertermeetingProvidern = JsonTypeConverter2.asNullable(
    $convertermeetingProvider,
  );
  static TypeConverter<List<int>, String> $converterreminderOffsets =
      const IntListConverter();
  static TypeConverter<List<int>?, String?> $converterreminderOffsetsn =
      NullAwareTypeConverter.wrap($converterreminderOffsets);
  static JsonTypeConverter2<TaskSource, String, String> $convertersource =
      const EnumNameConverter<TaskSource>(TaskSource.values);
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String title;
  final String? notes;
  final String? areaId;
  final TaskStatus status;
  final TaskKind? kind;
  final String? attachmentImagePath;
  final String? documentLink;
  final DateTime? scheduledStart;
  final int? durationMin;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final int? timeToCompleteMin;
  final String? rrule;
  final String? parentRecurringId;

  /// The slot in the rule this occurrence was generated for — its *identity*,
  /// fixed for life. [scheduledStart] is where the occurrence currently sits and
  /// the user may move it; this records where the rule put it.
  ///
  /// Without this the engine matched occurrences by `scheduledStart`, so moving
  /// one date left its original slot looking empty and the next expansion
  /// helpfully re-created it — a ghost at the old time (§4).
  final DateTime? occurrenceSlot;
  final String? parentEventId;
  final String? reviewNotes;
  final String? meetingLink;
  final MeetingProvider? meetingProvider;
  final String? locationName;
  final double? lat;
  final double? lng;
  final bool geofenceEnabled;
  final List<int>? reminderOffsets;
  final String? gcalEventId;
  final String? gcalCalendarId;
  final String? gcalEtag;
  final DateTime? lastSyncedAt;
  final TaskSource source;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Task({
    required this.id,
    required this.title,
    this.notes,
    this.areaId,
    required this.status,
    this.kind,
    this.attachmentImagePath,
    this.documentLink,
    this.scheduledStart,
    this.durationMin,
    this.dueDate,
    this.completedAt,
    this.timeToCompleteMin,
    this.rrule,
    this.parentRecurringId,
    this.occurrenceSlot,
    this.parentEventId,
    this.reviewNotes,
    this.meetingLink,
    this.meetingProvider,
    this.locationName,
    this.lat,
    this.lng,
    required this.geofenceEnabled,
    this.reminderOffsets,
    this.gcalEventId,
    this.gcalCalendarId,
    this.gcalEtag,
    this.lastSyncedAt,
    required this.source,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || areaId != null) {
      map['area_id'] = Variable<String>(areaId);
    }
    {
      map['status'] = Variable<String>(
        $TasksTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>($TasksTable.$converterkindn.toSql(kind));
    }
    if (!nullToAbsent || attachmentImagePath != null) {
      map['attachment_image_path'] = Variable<String>(attachmentImagePath);
    }
    if (!nullToAbsent || documentLink != null) {
      map['document_link'] = Variable<String>(documentLink);
    }
    if (!nullToAbsent || scheduledStart != null) {
      map['scheduled_start'] = Variable<DateTime>(scheduledStart);
    }
    if (!nullToAbsent || durationMin != null) {
      map['duration_min'] = Variable<int>(durationMin);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || timeToCompleteMin != null) {
      map['time_to_complete_min'] = Variable<int>(timeToCompleteMin);
    }
    if (!nullToAbsent || rrule != null) {
      map['rrule'] = Variable<String>(rrule);
    }
    if (!nullToAbsent || parentRecurringId != null) {
      map['parent_recurring_id'] = Variable<String>(parentRecurringId);
    }
    if (!nullToAbsent || occurrenceSlot != null) {
      map['occurrence_slot'] = Variable<DateTime>(occurrenceSlot);
    }
    if (!nullToAbsent || parentEventId != null) {
      map['parent_event_id'] = Variable<String>(parentEventId);
    }
    if (!nullToAbsent || reviewNotes != null) {
      map['review_notes'] = Variable<String>(reviewNotes);
    }
    if (!nullToAbsent || meetingLink != null) {
      map['meeting_link'] = Variable<String>(meetingLink);
    }
    if (!nullToAbsent || meetingProvider != null) {
      map['meeting_provider'] = Variable<String>(
        $TasksTable.$convertermeetingProvidern.toSql(meetingProvider),
      );
    }
    if (!nullToAbsent || locationName != null) {
      map['location_name'] = Variable<String>(locationName);
    }
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    map['geofence_enabled'] = Variable<bool>(geofenceEnabled);
    if (!nullToAbsent || reminderOffsets != null) {
      map['reminder_offsets'] = Variable<String>(
        $TasksTable.$converterreminderOffsetsn.toSql(reminderOffsets),
      );
    }
    if (!nullToAbsent || gcalEventId != null) {
      map['gcal_event_id'] = Variable<String>(gcalEventId);
    }
    if (!nullToAbsent || gcalCalendarId != null) {
      map['gcal_calendar_id'] = Variable<String>(gcalCalendarId);
    }
    if (!nullToAbsent || gcalEtag != null) {
      map['gcal_etag'] = Variable<String>(gcalEtag);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    {
      map['source'] = Variable<String>(
        $TasksTable.$convertersource.toSql(source),
      );
    }
    map['priority'] = Variable<int>(priority);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      areaId: areaId == null && nullToAbsent
          ? const Value.absent()
          : Value(areaId),
      status: Value(status),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
      attachmentImagePath: attachmentImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentImagePath),
      documentLink: documentLink == null && nullToAbsent
          ? const Value.absent()
          : Value(documentLink),
      scheduledStart: scheduledStart == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledStart),
      durationMin: durationMin == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMin),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      timeToCompleteMin: timeToCompleteMin == null && nullToAbsent
          ? const Value.absent()
          : Value(timeToCompleteMin),
      rrule: rrule == null && nullToAbsent
          ? const Value.absent()
          : Value(rrule),
      parentRecurringId: parentRecurringId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentRecurringId),
      occurrenceSlot: occurrenceSlot == null && nullToAbsent
          ? const Value.absent()
          : Value(occurrenceSlot),
      parentEventId: parentEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentEventId),
      reviewNotes: reviewNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewNotes),
      meetingLink: meetingLink == null && nullToAbsent
          ? const Value.absent()
          : Value(meetingLink),
      meetingProvider: meetingProvider == null && nullToAbsent
          ? const Value.absent()
          : Value(meetingProvider),
      locationName: locationName == null && nullToAbsent
          ? const Value.absent()
          : Value(locationName),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      geofenceEnabled: Value(geofenceEnabled),
      reminderOffsets: reminderOffsets == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderOffsets),
      gcalEventId: gcalEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(gcalEventId),
      gcalCalendarId: gcalCalendarId == null && nullToAbsent
          ? const Value.absent()
          : Value(gcalCalendarId),
      gcalEtag: gcalEtag == null && nullToAbsent
          ? const Value.absent()
          : Value(gcalEtag),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      source: Value(source),
      priority: Value(priority),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      areaId: serializer.fromJson<String?>(json['areaId']),
      status: $TasksTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      kind: $TasksTable.$converterkindn.fromJson(
        serializer.fromJson<String?>(json['kind']),
      ),
      attachmentImagePath: serializer.fromJson<String?>(
        json['attachmentImagePath'],
      ),
      documentLink: serializer.fromJson<String?>(json['documentLink']),
      scheduledStart: serializer.fromJson<DateTime?>(json['scheduledStart']),
      durationMin: serializer.fromJson<int?>(json['durationMin']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      timeToCompleteMin: serializer.fromJson<int?>(json['timeToCompleteMin']),
      rrule: serializer.fromJson<String?>(json['rrule']),
      parentRecurringId: serializer.fromJson<String?>(
        json['parentRecurringId'],
      ),
      occurrenceSlot: serializer.fromJson<DateTime?>(json['occurrenceSlot']),
      parentEventId: serializer.fromJson<String?>(json['parentEventId']),
      reviewNotes: serializer.fromJson<String?>(json['reviewNotes']),
      meetingLink: serializer.fromJson<String?>(json['meetingLink']),
      meetingProvider: $TasksTable.$convertermeetingProvidern.fromJson(
        serializer.fromJson<String?>(json['meetingProvider']),
      ),
      locationName: serializer.fromJson<String?>(json['locationName']),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      geofenceEnabled: serializer.fromJson<bool>(json['geofenceEnabled']),
      reminderOffsets: serializer.fromJson<List<int>?>(json['reminderOffsets']),
      gcalEventId: serializer.fromJson<String?>(json['gcalEventId']),
      gcalCalendarId: serializer.fromJson<String?>(json['gcalCalendarId']),
      gcalEtag: serializer.fromJson<String?>(json['gcalEtag']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      source: $TasksTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      priority: serializer.fromJson<int>(json['priority']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'areaId': serializer.toJson<String?>(areaId),
      'status': serializer.toJson<String>(
        $TasksTable.$converterstatus.toJson(status),
      ),
      'kind': serializer.toJson<String?>(
        $TasksTable.$converterkindn.toJson(kind),
      ),
      'attachmentImagePath': serializer.toJson<String?>(attachmentImagePath),
      'documentLink': serializer.toJson<String?>(documentLink),
      'scheduledStart': serializer.toJson<DateTime?>(scheduledStart),
      'durationMin': serializer.toJson<int?>(durationMin),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'timeToCompleteMin': serializer.toJson<int?>(timeToCompleteMin),
      'rrule': serializer.toJson<String?>(rrule),
      'parentRecurringId': serializer.toJson<String?>(parentRecurringId),
      'occurrenceSlot': serializer.toJson<DateTime?>(occurrenceSlot),
      'parentEventId': serializer.toJson<String?>(parentEventId),
      'reviewNotes': serializer.toJson<String?>(reviewNotes),
      'meetingLink': serializer.toJson<String?>(meetingLink),
      'meetingProvider': serializer.toJson<String?>(
        $TasksTable.$convertermeetingProvidern.toJson(meetingProvider),
      ),
      'locationName': serializer.toJson<String?>(locationName),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'geofenceEnabled': serializer.toJson<bool>(geofenceEnabled),
      'reminderOffsets': serializer.toJson<List<int>?>(reminderOffsets),
      'gcalEventId': serializer.toJson<String?>(gcalEventId),
      'gcalCalendarId': serializer.toJson<String?>(gcalCalendarId),
      'gcalEtag': serializer.toJson<String?>(gcalEtag),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'source': serializer.toJson<String>(
        $TasksTable.$convertersource.toJson(source),
      ),
      'priority': serializer.toJson<int>(priority),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    Value<String?> notes = const Value.absent(),
    Value<String?> areaId = const Value.absent(),
    TaskStatus? status,
    Value<TaskKind?> kind = const Value.absent(),
    Value<String?> attachmentImagePath = const Value.absent(),
    Value<String?> documentLink = const Value.absent(),
    Value<DateTime?> scheduledStart = const Value.absent(),
    Value<int?> durationMin = const Value.absent(),
    Value<DateTime?> dueDate = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    Value<int?> timeToCompleteMin = const Value.absent(),
    Value<String?> rrule = const Value.absent(),
    Value<String?> parentRecurringId = const Value.absent(),
    Value<DateTime?> occurrenceSlot = const Value.absent(),
    Value<String?> parentEventId = const Value.absent(),
    Value<String?> reviewNotes = const Value.absent(),
    Value<String?> meetingLink = const Value.absent(),
    Value<MeetingProvider?> meetingProvider = const Value.absent(),
    Value<String?> locationName = const Value.absent(),
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    bool? geofenceEnabled,
    Value<List<int>?> reminderOffsets = const Value.absent(),
    Value<String?> gcalEventId = const Value.absent(),
    Value<String?> gcalCalendarId = const Value.absent(),
    Value<String?> gcalEtag = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    TaskSource? source,
    int? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    notes: notes.present ? notes.value : this.notes,
    areaId: areaId.present ? areaId.value : this.areaId,
    status: status ?? this.status,
    kind: kind.present ? kind.value : this.kind,
    attachmentImagePath: attachmentImagePath.present
        ? attachmentImagePath.value
        : this.attachmentImagePath,
    documentLink: documentLink.present ? documentLink.value : this.documentLink,
    scheduledStart: scheduledStart.present
        ? scheduledStart.value
        : this.scheduledStart,
    durationMin: durationMin.present ? durationMin.value : this.durationMin,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    timeToCompleteMin: timeToCompleteMin.present
        ? timeToCompleteMin.value
        : this.timeToCompleteMin,
    rrule: rrule.present ? rrule.value : this.rrule,
    parentRecurringId: parentRecurringId.present
        ? parentRecurringId.value
        : this.parentRecurringId,
    occurrenceSlot: occurrenceSlot.present
        ? occurrenceSlot.value
        : this.occurrenceSlot,
    parentEventId: parentEventId.present
        ? parentEventId.value
        : this.parentEventId,
    reviewNotes: reviewNotes.present ? reviewNotes.value : this.reviewNotes,
    meetingLink: meetingLink.present ? meetingLink.value : this.meetingLink,
    meetingProvider: meetingProvider.present
        ? meetingProvider.value
        : this.meetingProvider,
    locationName: locationName.present ? locationName.value : this.locationName,
    lat: lat.present ? lat.value : this.lat,
    lng: lng.present ? lng.value : this.lng,
    geofenceEnabled: geofenceEnabled ?? this.geofenceEnabled,
    reminderOffsets: reminderOffsets.present
        ? reminderOffsets.value
        : this.reminderOffsets,
    gcalEventId: gcalEventId.present ? gcalEventId.value : this.gcalEventId,
    gcalCalendarId: gcalCalendarId.present
        ? gcalCalendarId.value
        : this.gcalCalendarId,
    gcalEtag: gcalEtag.present ? gcalEtag.value : this.gcalEtag,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    source: source ?? this.source,
    priority: priority ?? this.priority,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      areaId: data.areaId.present ? data.areaId.value : this.areaId,
      status: data.status.present ? data.status.value : this.status,
      kind: data.kind.present ? data.kind.value : this.kind,
      attachmentImagePath: data.attachmentImagePath.present
          ? data.attachmentImagePath.value
          : this.attachmentImagePath,
      documentLink: data.documentLink.present
          ? data.documentLink.value
          : this.documentLink,
      scheduledStart: data.scheduledStart.present
          ? data.scheduledStart.value
          : this.scheduledStart,
      durationMin: data.durationMin.present
          ? data.durationMin.value
          : this.durationMin,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      timeToCompleteMin: data.timeToCompleteMin.present
          ? data.timeToCompleteMin.value
          : this.timeToCompleteMin,
      rrule: data.rrule.present ? data.rrule.value : this.rrule,
      parentRecurringId: data.parentRecurringId.present
          ? data.parentRecurringId.value
          : this.parentRecurringId,
      occurrenceSlot: data.occurrenceSlot.present
          ? data.occurrenceSlot.value
          : this.occurrenceSlot,
      parentEventId: data.parentEventId.present
          ? data.parentEventId.value
          : this.parentEventId,
      reviewNotes: data.reviewNotes.present
          ? data.reviewNotes.value
          : this.reviewNotes,
      meetingLink: data.meetingLink.present
          ? data.meetingLink.value
          : this.meetingLink,
      meetingProvider: data.meetingProvider.present
          ? data.meetingProvider.value
          : this.meetingProvider,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      geofenceEnabled: data.geofenceEnabled.present
          ? data.geofenceEnabled.value
          : this.geofenceEnabled,
      reminderOffsets: data.reminderOffsets.present
          ? data.reminderOffsets.value
          : this.reminderOffsets,
      gcalEventId: data.gcalEventId.present
          ? data.gcalEventId.value
          : this.gcalEventId,
      gcalCalendarId: data.gcalCalendarId.present
          ? data.gcalCalendarId.value
          : this.gcalCalendarId,
      gcalEtag: data.gcalEtag.present ? data.gcalEtag.value : this.gcalEtag,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      source: data.source.present ? data.source.value : this.source,
      priority: data.priority.present ? data.priority.value : this.priority,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('areaId: $areaId, ')
          ..write('status: $status, ')
          ..write('kind: $kind, ')
          ..write('attachmentImagePath: $attachmentImagePath, ')
          ..write('documentLink: $documentLink, ')
          ..write('scheduledStart: $scheduledStart, ')
          ..write('durationMin: $durationMin, ')
          ..write('dueDate: $dueDate, ')
          ..write('completedAt: $completedAt, ')
          ..write('timeToCompleteMin: $timeToCompleteMin, ')
          ..write('rrule: $rrule, ')
          ..write('parentRecurringId: $parentRecurringId, ')
          ..write('occurrenceSlot: $occurrenceSlot, ')
          ..write('parentEventId: $parentEventId, ')
          ..write('reviewNotes: $reviewNotes, ')
          ..write('meetingLink: $meetingLink, ')
          ..write('meetingProvider: $meetingProvider, ')
          ..write('locationName: $locationName, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('geofenceEnabled: $geofenceEnabled, ')
          ..write('reminderOffsets: $reminderOffsets, ')
          ..write('gcalEventId: $gcalEventId, ')
          ..write('gcalCalendarId: $gcalCalendarId, ')
          ..write('gcalEtag: $gcalEtag, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('source: $source, ')
          ..write('priority: $priority, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    notes,
    areaId,
    status,
    kind,
    attachmentImagePath,
    documentLink,
    scheduledStart,
    durationMin,
    dueDate,
    completedAt,
    timeToCompleteMin,
    rrule,
    parentRecurringId,
    occurrenceSlot,
    parentEventId,
    reviewNotes,
    meetingLink,
    meetingProvider,
    locationName,
    lat,
    lng,
    geofenceEnabled,
    reminderOffsets,
    gcalEventId,
    gcalCalendarId,
    gcalEtag,
    lastSyncedAt,
    source,
    priority,
    createdAt,
    updatedAt,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.areaId == this.areaId &&
          other.status == this.status &&
          other.kind == this.kind &&
          other.attachmentImagePath == this.attachmentImagePath &&
          other.documentLink == this.documentLink &&
          other.scheduledStart == this.scheduledStart &&
          other.durationMin == this.durationMin &&
          other.dueDate == this.dueDate &&
          other.completedAt == this.completedAt &&
          other.timeToCompleteMin == this.timeToCompleteMin &&
          other.rrule == this.rrule &&
          other.parentRecurringId == this.parentRecurringId &&
          other.occurrenceSlot == this.occurrenceSlot &&
          other.parentEventId == this.parentEventId &&
          other.reviewNotes == this.reviewNotes &&
          other.meetingLink == this.meetingLink &&
          other.meetingProvider == this.meetingProvider &&
          other.locationName == this.locationName &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.geofenceEnabled == this.geofenceEnabled &&
          other.reminderOffsets == this.reminderOffsets &&
          other.gcalEventId == this.gcalEventId &&
          other.gcalCalendarId == this.gcalCalendarId &&
          other.gcalEtag == this.gcalEtag &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.source == this.source &&
          other.priority == this.priority &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> notes;
  final Value<String?> areaId;
  final Value<TaskStatus> status;
  final Value<TaskKind?> kind;
  final Value<String?> attachmentImagePath;
  final Value<String?> documentLink;
  final Value<DateTime?> scheduledStart;
  final Value<int?> durationMin;
  final Value<DateTime?> dueDate;
  final Value<DateTime?> completedAt;
  final Value<int?> timeToCompleteMin;
  final Value<String?> rrule;
  final Value<String?> parentRecurringId;
  final Value<DateTime?> occurrenceSlot;
  final Value<String?> parentEventId;
  final Value<String?> reviewNotes;
  final Value<String?> meetingLink;
  final Value<MeetingProvider?> meetingProvider;
  final Value<String?> locationName;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<bool> geofenceEnabled;
  final Value<List<int>?> reminderOffsets;
  final Value<String?> gcalEventId;
  final Value<String?> gcalCalendarId;
  final Value<String?> gcalEtag;
  final Value<DateTime?> lastSyncedAt;
  final Value<TaskSource> source;
  final Value<int> priority;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.areaId = const Value.absent(),
    this.status = const Value.absent(),
    this.kind = const Value.absent(),
    this.attachmentImagePath = const Value.absent(),
    this.documentLink = const Value.absent(),
    this.scheduledStart = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.timeToCompleteMin = const Value.absent(),
    this.rrule = const Value.absent(),
    this.parentRecurringId = const Value.absent(),
    this.occurrenceSlot = const Value.absent(),
    this.parentEventId = const Value.absent(),
    this.reviewNotes = const Value.absent(),
    this.meetingLink = const Value.absent(),
    this.meetingProvider = const Value.absent(),
    this.locationName = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.geofenceEnabled = const Value.absent(),
    this.reminderOffsets = const Value.absent(),
    this.gcalEventId = const Value.absent(),
    this.gcalCalendarId = const Value.absent(),
    this.gcalEtag = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.priority = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    this.notes = const Value.absent(),
    this.areaId = const Value.absent(),
    this.status = const Value.absent(),
    this.kind = const Value.absent(),
    this.attachmentImagePath = const Value.absent(),
    this.documentLink = const Value.absent(),
    this.scheduledStart = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.timeToCompleteMin = const Value.absent(),
    this.rrule = const Value.absent(),
    this.parentRecurringId = const Value.absent(),
    this.occurrenceSlot = const Value.absent(),
    this.parentEventId = const Value.absent(),
    this.reviewNotes = const Value.absent(),
    this.meetingLink = const Value.absent(),
    this.meetingProvider = const Value.absent(),
    this.locationName = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.geofenceEnabled = const Value.absent(),
    this.reminderOffsets = const Value.absent(),
    this.gcalEventId = const Value.absent(),
    this.gcalCalendarId = const Value.absent(),
    this.gcalEtag = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.priority = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<String>? areaId,
    Expression<String>? status,
    Expression<String>? kind,
    Expression<String>? attachmentImagePath,
    Expression<String>? documentLink,
    Expression<DateTime>? scheduledStart,
    Expression<int>? durationMin,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? completedAt,
    Expression<int>? timeToCompleteMin,
    Expression<String>? rrule,
    Expression<String>? parentRecurringId,
    Expression<DateTime>? occurrenceSlot,
    Expression<String>? parentEventId,
    Expression<String>? reviewNotes,
    Expression<String>? meetingLink,
    Expression<String>? meetingProvider,
    Expression<String>? locationName,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<bool>? geofenceEnabled,
    Expression<String>? reminderOffsets,
    Expression<String>? gcalEventId,
    Expression<String>? gcalCalendarId,
    Expression<String>? gcalEtag,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? source,
    Expression<int>? priority,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (areaId != null) 'area_id': areaId,
      if (status != null) 'status': status,
      if (kind != null) 'kind': kind,
      if (attachmentImagePath != null)
        'attachment_image_path': attachmentImagePath,
      if (documentLink != null) 'document_link': documentLink,
      if (scheduledStart != null) 'scheduled_start': scheduledStart,
      if (durationMin != null) 'duration_min': durationMin,
      if (dueDate != null) 'due_date': dueDate,
      if (completedAt != null) 'completed_at': completedAt,
      if (timeToCompleteMin != null) 'time_to_complete_min': timeToCompleteMin,
      if (rrule != null) 'rrule': rrule,
      if (parentRecurringId != null) 'parent_recurring_id': parentRecurringId,
      if (occurrenceSlot != null) 'occurrence_slot': occurrenceSlot,
      if (parentEventId != null) 'parent_event_id': parentEventId,
      if (reviewNotes != null) 'review_notes': reviewNotes,
      if (meetingLink != null) 'meeting_link': meetingLink,
      if (meetingProvider != null) 'meeting_provider': meetingProvider,
      if (locationName != null) 'location_name': locationName,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (geofenceEnabled != null) 'geofence_enabled': geofenceEnabled,
      if (reminderOffsets != null) 'reminder_offsets': reminderOffsets,
      if (gcalEventId != null) 'gcal_event_id': gcalEventId,
      if (gcalCalendarId != null) 'gcal_calendar_id': gcalCalendarId,
      if (gcalEtag != null) 'gcal_etag': gcalEtag,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (source != null) 'source': source,
      if (priority != null) 'priority': priority,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? notes,
    Value<String?>? areaId,
    Value<TaskStatus>? status,
    Value<TaskKind?>? kind,
    Value<String?>? attachmentImagePath,
    Value<String?>? documentLink,
    Value<DateTime?>? scheduledStart,
    Value<int?>? durationMin,
    Value<DateTime?>? dueDate,
    Value<DateTime?>? completedAt,
    Value<int?>? timeToCompleteMin,
    Value<String?>? rrule,
    Value<String?>? parentRecurringId,
    Value<DateTime?>? occurrenceSlot,
    Value<String?>? parentEventId,
    Value<String?>? reviewNotes,
    Value<String?>? meetingLink,
    Value<MeetingProvider?>? meetingProvider,
    Value<String?>? locationName,
    Value<double?>? lat,
    Value<double?>? lng,
    Value<bool>? geofenceEnabled,
    Value<List<int>?>? reminderOffsets,
    Value<String?>? gcalEventId,
    Value<String?>? gcalCalendarId,
    Value<String?>? gcalEtag,
    Value<DateTime?>? lastSyncedAt,
    Value<TaskSource>? source,
    Value<int>? priority,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      areaId: areaId ?? this.areaId,
      status: status ?? this.status,
      kind: kind ?? this.kind,
      attachmentImagePath: attachmentImagePath ?? this.attachmentImagePath,
      documentLink: documentLink ?? this.documentLink,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      durationMin: durationMin ?? this.durationMin,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      timeToCompleteMin: timeToCompleteMin ?? this.timeToCompleteMin,
      rrule: rrule ?? this.rrule,
      parentRecurringId: parentRecurringId ?? this.parentRecurringId,
      occurrenceSlot: occurrenceSlot ?? this.occurrenceSlot,
      parentEventId: parentEventId ?? this.parentEventId,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      meetingLink: meetingLink ?? this.meetingLink,
      meetingProvider: meetingProvider ?? this.meetingProvider,
      locationName: locationName ?? this.locationName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      geofenceEnabled: geofenceEnabled ?? this.geofenceEnabled,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      gcalEventId: gcalEventId ?? this.gcalEventId,
      gcalCalendarId: gcalCalendarId ?? this.gcalCalendarId,
      gcalEtag: gcalEtag ?? this.gcalEtag,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      source: source ?? this.source,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (areaId.present) {
      map['area_id'] = Variable<String>(areaId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $TasksTable.$converterstatus.toSql(status.value),
      );
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $TasksTable.$converterkindn.toSql(kind.value),
      );
    }
    if (attachmentImagePath.present) {
      map['attachment_image_path'] = Variable<String>(
        attachmentImagePath.value,
      );
    }
    if (documentLink.present) {
      map['document_link'] = Variable<String>(documentLink.value);
    }
    if (scheduledStart.present) {
      map['scheduled_start'] = Variable<DateTime>(scheduledStart.value);
    }
    if (durationMin.present) {
      map['duration_min'] = Variable<int>(durationMin.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (timeToCompleteMin.present) {
      map['time_to_complete_min'] = Variable<int>(timeToCompleteMin.value);
    }
    if (rrule.present) {
      map['rrule'] = Variable<String>(rrule.value);
    }
    if (parentRecurringId.present) {
      map['parent_recurring_id'] = Variable<String>(parentRecurringId.value);
    }
    if (occurrenceSlot.present) {
      map['occurrence_slot'] = Variable<DateTime>(occurrenceSlot.value);
    }
    if (parentEventId.present) {
      map['parent_event_id'] = Variable<String>(parentEventId.value);
    }
    if (reviewNotes.present) {
      map['review_notes'] = Variable<String>(reviewNotes.value);
    }
    if (meetingLink.present) {
      map['meeting_link'] = Variable<String>(meetingLink.value);
    }
    if (meetingProvider.present) {
      map['meeting_provider'] = Variable<String>(
        $TasksTable.$convertermeetingProvidern.toSql(meetingProvider.value),
      );
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (geofenceEnabled.present) {
      map['geofence_enabled'] = Variable<bool>(geofenceEnabled.value);
    }
    if (reminderOffsets.present) {
      map['reminder_offsets'] = Variable<String>(
        $TasksTable.$converterreminderOffsetsn.toSql(reminderOffsets.value),
      );
    }
    if (gcalEventId.present) {
      map['gcal_event_id'] = Variable<String>(gcalEventId.value);
    }
    if (gcalCalendarId.present) {
      map['gcal_calendar_id'] = Variable<String>(gcalCalendarId.value);
    }
    if (gcalEtag.present) {
      map['gcal_etag'] = Variable<String>(gcalEtag.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $TasksTable.$convertersource.toSql(source.value),
      );
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('areaId: $areaId, ')
          ..write('status: $status, ')
          ..write('kind: $kind, ')
          ..write('attachmentImagePath: $attachmentImagePath, ')
          ..write('documentLink: $documentLink, ')
          ..write('scheduledStart: $scheduledStart, ')
          ..write('durationMin: $durationMin, ')
          ..write('dueDate: $dueDate, ')
          ..write('completedAt: $completedAt, ')
          ..write('timeToCompleteMin: $timeToCompleteMin, ')
          ..write('rrule: $rrule, ')
          ..write('parentRecurringId: $parentRecurringId, ')
          ..write('occurrenceSlot: $occurrenceSlot, ')
          ..write('parentEventId: $parentEventId, ')
          ..write('reviewNotes: $reviewNotes, ')
          ..write('meetingLink: $meetingLink, ')
          ..write('meetingProvider: $meetingProvider, ')
          ..write('locationName: $locationName, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('geofenceEnabled: $geofenceEnabled, ')
          ..write('reminderOffsets: $reminderOffsets, ')
          ..write('gcalEventId: $gcalEventId, ')
          ..write('gcalCalendarId: $gcalCalendarId, ')
          ..write('gcalEtag: $gcalEtag, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('source: $source, ')
          ..write('priority: $priority, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskParticipantsTable extends TaskParticipants
    with TableInfo<$TaskParticipantsTable, TaskParticipant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskParticipantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id)',
    ),
  );
  static const VerificationMeta _contactLookupKeyMeta = const VerificationMeta(
    'contactLookupKey',
  );
  @override
  late final GeneratedColumn<String> contactLookupKey = GeneratedColumn<String>(
    'contact_lookup_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    contactLookupKey,
    displayName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_participants';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskParticipant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('contact_lookup_key')) {
      context.handle(
        _contactLookupKeyMeta,
        contactLookupKey.isAcceptableOrUnknown(
          data['contact_lookup_key']!,
          _contactLookupKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contactLookupKeyMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskParticipant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskParticipant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      contactLookupKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_lookup_key'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
    );
  }

  @override
  $TaskParticipantsTable createAlias(String alias) {
    return $TaskParticipantsTable(attachedDatabase, alias);
  }
}

class TaskParticipant extends DataClass implements Insertable<TaskParticipant> {
  final String id;
  final String taskId;
  final String contactLookupKey;
  final String displayName;
  const TaskParticipant({
    required this.id,
    required this.taskId,
    required this.contactLookupKey,
    required this.displayName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['contact_lookup_key'] = Variable<String>(contactLookupKey);
    map['display_name'] = Variable<String>(displayName);
    return map;
  }

  TaskParticipantsCompanion toCompanion(bool nullToAbsent) {
    return TaskParticipantsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      contactLookupKey: Value(contactLookupKey),
      displayName: Value(displayName),
    );
  }

  factory TaskParticipant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskParticipant(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      contactLookupKey: serializer.fromJson<String>(json['contactLookupKey']),
      displayName: serializer.fromJson<String>(json['displayName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'contactLookupKey': serializer.toJson<String>(contactLookupKey),
      'displayName': serializer.toJson<String>(displayName),
    };
  }

  TaskParticipant copyWith({
    String? id,
    String? taskId,
    String? contactLookupKey,
    String? displayName,
  }) => TaskParticipant(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    contactLookupKey: contactLookupKey ?? this.contactLookupKey,
    displayName: displayName ?? this.displayName,
  );
  TaskParticipant copyWithCompanion(TaskParticipantsCompanion data) {
    return TaskParticipant(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      contactLookupKey: data.contactLookupKey.present
          ? data.contactLookupKey.value
          : this.contactLookupKey,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskParticipant(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('contactLookupKey: $contactLookupKey, ')
          ..write('displayName: $displayName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, taskId, contactLookupKey, displayName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskParticipant &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.contactLookupKey == this.contactLookupKey &&
          other.displayName == this.displayName);
}

class TaskParticipantsCompanion extends UpdateCompanion<TaskParticipant> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> contactLookupKey;
  final Value<String> displayName;
  final Value<int> rowid;
  const TaskParticipantsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.contactLookupKey = const Value.absent(),
    this.displayName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskParticipantsCompanion.insert({
    required String id,
    required String taskId,
    required String contactLookupKey,
    required String displayName,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       contactLookupKey = Value(contactLookupKey),
       displayName = Value(displayName);
  static Insertable<TaskParticipant> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? contactLookupKey,
    Expression<String>? displayName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (contactLookupKey != null) 'contact_lookup_key': contactLookupKey,
      if (displayName != null) 'display_name': displayName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskParticipantsCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? contactLookupKey,
    Value<String>? displayName,
    Value<int>? rowid,
  }) {
    return TaskParticipantsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      contactLookupKey: contactLookupKey ?? this.contactLookupKey,
      displayName: displayName ?? this.displayName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (contactLookupKey.present) {
      map['contact_lookup_key'] = Variable<String>(contactLookupKey.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskParticipantsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('contactLookupKey: $contactLookupKey, ')
          ..write('displayName: $displayName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskTransitionsTable extends TaskTransitions
    with TableInfo<$TaskTransitionsTable, TaskTransition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskTransitionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskStatus?, String> fromStatus =
      GeneratedColumn<String>(
        'from_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<TaskStatus?>($TaskTransitionsTable.$converterfromStatusn);
  @override
  late final GeneratedColumnWithTypeConverter<TaskStatus, String> toStatus =
      GeneratedColumn<String>(
        'to_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TaskStatus>($TaskTransitionsTable.$convertertoStatus);
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    fromStatus,
    toStatus,
    at,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_transitions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskTransition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskTransition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTransition(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      fromStatus: $TaskTransitionsTable.$converterfromStatusn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}from_status'],
        ),
      ),
      toStatus: $TaskTransitionsTable.$convertertoStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}to_status'],
        )!,
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $TaskTransitionsTable createAlias(String alias) {
    return $TaskTransitionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskStatus, String, String> $converterfromStatus =
      const EnumNameConverter<TaskStatus>(TaskStatus.values);
  static JsonTypeConverter2<TaskStatus?, String?, String?>
  $converterfromStatusn = JsonTypeConverter2.asNullable($converterfromStatus);
  static JsonTypeConverter2<TaskStatus, String, String> $convertertoStatus =
      const EnumNameConverter<TaskStatus>(TaskStatus.values);
}

class TaskTransition extends DataClass implements Insertable<TaskTransition> {
  final String id;
  final String taskId;
  final TaskStatus? fromStatus;
  final TaskStatus toStatus;
  final DateTime at;
  final String? note;
  const TaskTransition({
    required this.id,
    required this.taskId,
    this.fromStatus,
    required this.toStatus,
    required this.at,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    if (!nullToAbsent || fromStatus != null) {
      map['from_status'] = Variable<String>(
        $TaskTransitionsTable.$converterfromStatusn.toSql(fromStatus),
      );
    }
    {
      map['to_status'] = Variable<String>(
        $TaskTransitionsTable.$convertertoStatus.toSql(toStatus),
      );
    }
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  TaskTransitionsCompanion toCompanion(bool nullToAbsent) {
    return TaskTransitionsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      fromStatus: fromStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(fromStatus),
      toStatus: Value(toStatus),
      at: Value(at),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory TaskTransition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTransition(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      fromStatus: $TaskTransitionsTable.$converterfromStatusn.fromJson(
        serializer.fromJson<String?>(json['fromStatus']),
      ),
      toStatus: $TaskTransitionsTable.$convertertoStatus.fromJson(
        serializer.fromJson<String>(json['toStatus']),
      ),
      at: serializer.fromJson<DateTime>(json['at']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'fromStatus': serializer.toJson<String?>(
        $TaskTransitionsTable.$converterfromStatusn.toJson(fromStatus),
      ),
      'toStatus': serializer.toJson<String>(
        $TaskTransitionsTable.$convertertoStatus.toJson(toStatus),
      ),
      'at': serializer.toJson<DateTime>(at),
      'note': serializer.toJson<String?>(note),
    };
  }

  TaskTransition copyWith({
    String? id,
    String? taskId,
    Value<TaskStatus?> fromStatus = const Value.absent(),
    TaskStatus? toStatus,
    DateTime? at,
    Value<String?> note = const Value.absent(),
  }) => TaskTransition(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    fromStatus: fromStatus.present ? fromStatus.value : this.fromStatus,
    toStatus: toStatus ?? this.toStatus,
    at: at ?? this.at,
    note: note.present ? note.value : this.note,
  );
  TaskTransition copyWithCompanion(TaskTransitionsCompanion data) {
    return TaskTransition(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      fromStatus: data.fromStatus.present
          ? data.fromStatus.value
          : this.fromStatus,
      toStatus: data.toStatus.present ? data.toStatus.value : this.toStatus,
      at: data.at.present ? data.at.value : this.at,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskTransition(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('fromStatus: $fromStatus, ')
          ..write('toStatus: $toStatus, ')
          ..write('at: $at, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, taskId, fromStatus, toStatus, at, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskTransition &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.fromStatus == this.fromStatus &&
          other.toStatus == this.toStatus &&
          other.at == this.at &&
          other.note == this.note);
}

class TaskTransitionsCompanion extends UpdateCompanion<TaskTransition> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<TaskStatus?> fromStatus;
  final Value<TaskStatus> toStatus;
  final Value<DateTime> at;
  final Value<String?> note;
  final Value<int> rowid;
  const TaskTransitionsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.fromStatus = const Value.absent(),
    this.toStatus = const Value.absent(),
    this.at = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskTransitionsCompanion.insert({
    required String id,
    required String taskId,
    this.fromStatus = const Value.absent(),
    required TaskStatus toStatus,
    required DateTime at,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       toStatus = Value(toStatus),
       at = Value(at);
  static Insertable<TaskTransition> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? fromStatus,
    Expression<String>? toStatus,
    Expression<DateTime>? at,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (fromStatus != null) 'from_status': fromStatus,
      if (toStatus != null) 'to_status': toStatus,
      if (at != null) 'at': at,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskTransitionsCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<TaskStatus?>? fromStatus,
    Value<TaskStatus>? toStatus,
    Value<DateTime>? at,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return TaskTransitionsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      fromStatus: fromStatus ?? this.fromStatus,
      toStatus: toStatus ?? this.toStatus,
      at: at ?? this.at,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (fromStatus.present) {
      map['from_status'] = Variable<String>(
        $TaskTransitionsTable.$converterfromStatusn.toSql(fromStatus.value),
      );
    }
    if (toStatus.present) {
      map['to_status'] = Variable<String>(
        $TaskTransitionsTable.$convertertoStatus.toSql(toStatus.value),
      );
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskTransitionsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('fromStatus: $fromStatus, ')
          ..write('toStatus: $toStatus, ')
          ..write('at: $at, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CapturesTable extends Captures with TableInfo<$CapturesTable, Capture> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CapturesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CaptureType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CaptureType>($CapturesTable.$convertertype);
  static const VerificationMeta _mediaPathMeta = const VerificationMeta(
    'mediaPath',
  );
  @override
  late final GeneratedColumn<String> mediaPath = GeneratedColumn<String>(
    'media_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textContentMeta = const VerificationMeta(
    'textContent',
  );
  @override
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
    'text_content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AttachedType, String>
  attachedType = GeneratedColumn<String>(
    'attached_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<AttachedType>($CapturesTable.$converterattachedType);
  static const VerificationMeta _attachedIdMeta = const VerificationMeta(
    'attachedId',
  );
  @override
  late final GeneratedColumn<String> attachedId = GeneratedColumn<String>(
    'attached_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _archiveUriMeta = const VerificationMeta(
    'archiveUri',
  );
  @override
  late final GeneratedColumn<String> archiveUri = GeneratedColumn<String>(
    'archive_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
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
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    mediaPath,
    textContent,
    caption,
    durationSec,
    sizeBytes,
    attachedType,
    attachedId,
    archived,
    archiveUri,
    thumbnailPath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'captures';
  @override
  VerificationContext validateIntegrity(
    Insertable<Capture> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('media_path')) {
      context.handle(
        _mediaPathMeta,
        mediaPath.isAcceptableOrUnknown(data['media_path']!, _mediaPathMeta),
      );
    }
    if (data.containsKey('text_content')) {
      context.handle(
        _textContentMeta,
        textContent.isAcceptableOrUnknown(
          data['text_content']!,
          _textContentMeta,
        ),
      );
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('attached_id')) {
      context.handle(
        _attachedIdMeta,
        attachedId.isAcceptableOrUnknown(data['attached_id']!, _attachedIdMeta),
      );
    } else if (isInserting) {
      context.missing(_attachedIdMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('archive_uri')) {
      context.handle(
        _archiveUriMeta,
        archiveUri.isAcceptableOrUnknown(data['archive_uri']!, _archiveUriMeta),
      );
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Capture map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Capture(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: $CapturesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      mediaPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_path'],
      ),
      textContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_content'],
      ),
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      ),
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      attachedType: $CapturesTable.$converterattachedType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}attached_type'],
        )!,
      ),
      attachedId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attached_id'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      archiveUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archive_uri'],
      ),
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CapturesTable createAlias(String alias) {
    return $CapturesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CaptureType, String, String> $convertertype =
      const EnumNameConverter<CaptureType>(CaptureType.values);
  static JsonTypeConverter2<AttachedType, String, String>
  $converterattachedType = const EnumNameConverter<AttachedType>(
    AttachedType.values,
  );
}

class Capture extends DataClass implements Insertable<Capture> {
  final String id;
  final CaptureType type;
  final String? mediaPath;
  final String? textContent;
  final String? caption;
  final int? durationSec;
  final int sizeBytes;
  final AttachedType attachedType;
  final String attachedId;
  final bool archived;
  final String? archiveUri;
  final String? thumbnailPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Capture({
    required this.id,
    required this.type,
    this.mediaPath,
    this.textContent,
    this.caption,
    this.durationSec,
    required this.sizeBytes,
    required this.attachedType,
    required this.attachedId,
    required this.archived,
    this.archiveUri,
    this.thumbnailPath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['type'] = Variable<String>($CapturesTable.$convertertype.toSql(type));
    }
    if (!nullToAbsent || mediaPath != null) {
      map['media_path'] = Variable<String>(mediaPath);
    }
    if (!nullToAbsent || textContent != null) {
      map['text_content'] = Variable<String>(textContent);
    }
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    if (!nullToAbsent || durationSec != null) {
      map['duration_sec'] = Variable<int>(durationSec);
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    {
      map['attached_type'] = Variable<String>(
        $CapturesTable.$converterattachedType.toSql(attachedType),
      );
    }
    map['attached_id'] = Variable<String>(attachedId);
    map['archived'] = Variable<bool>(archived);
    if (!nullToAbsent || archiveUri != null) {
      map['archive_uri'] = Variable<String>(archiveUri);
    }
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CapturesCompanion toCompanion(bool nullToAbsent) {
    return CapturesCompanion(
      id: Value(id),
      type: Value(type),
      mediaPath: mediaPath == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaPath),
      textContent: textContent == null && nullToAbsent
          ? const Value.absent()
          : Value(textContent),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      durationSec: durationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSec),
      sizeBytes: Value(sizeBytes),
      attachedType: Value(attachedType),
      attachedId: Value(attachedId),
      archived: Value(archived),
      archiveUri: archiveUri == null && nullToAbsent
          ? const Value.absent()
          : Value(archiveUri),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Capture.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Capture(
      id: serializer.fromJson<String>(json['id']),
      type: $CapturesTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      mediaPath: serializer.fromJson<String?>(json['mediaPath']),
      textContent: serializer.fromJson<String?>(json['textContent']),
      caption: serializer.fromJson<String?>(json['caption']),
      durationSec: serializer.fromJson<int?>(json['durationSec']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      attachedType: $CapturesTable.$converterattachedType.fromJson(
        serializer.fromJson<String>(json['attachedType']),
      ),
      attachedId: serializer.fromJson<String>(json['attachedId']),
      archived: serializer.fromJson<bool>(json['archived']),
      archiveUri: serializer.fromJson<String?>(json['archiveUri']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(
        $CapturesTable.$convertertype.toJson(type),
      ),
      'mediaPath': serializer.toJson<String?>(mediaPath),
      'textContent': serializer.toJson<String?>(textContent),
      'caption': serializer.toJson<String?>(caption),
      'durationSec': serializer.toJson<int?>(durationSec),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'attachedType': serializer.toJson<String>(
        $CapturesTable.$converterattachedType.toJson(attachedType),
      ),
      'attachedId': serializer.toJson<String>(attachedId),
      'archived': serializer.toJson<bool>(archived),
      'archiveUri': serializer.toJson<String?>(archiveUri),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Capture copyWith({
    String? id,
    CaptureType? type,
    Value<String?> mediaPath = const Value.absent(),
    Value<String?> textContent = const Value.absent(),
    Value<String?> caption = const Value.absent(),
    Value<int?> durationSec = const Value.absent(),
    int? sizeBytes,
    AttachedType? attachedType,
    String? attachedId,
    bool? archived,
    Value<String?> archiveUri = const Value.absent(),
    Value<String?> thumbnailPath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Capture(
    id: id ?? this.id,
    type: type ?? this.type,
    mediaPath: mediaPath.present ? mediaPath.value : this.mediaPath,
    textContent: textContent.present ? textContent.value : this.textContent,
    caption: caption.present ? caption.value : this.caption,
    durationSec: durationSec.present ? durationSec.value : this.durationSec,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    attachedType: attachedType ?? this.attachedType,
    attachedId: attachedId ?? this.attachedId,
    archived: archived ?? this.archived,
    archiveUri: archiveUri.present ? archiveUri.value : this.archiveUri,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Capture copyWithCompanion(CapturesCompanion data) {
    return Capture(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      mediaPath: data.mediaPath.present ? data.mediaPath.value : this.mediaPath,
      textContent: data.textContent.present
          ? data.textContent.value
          : this.textContent,
      caption: data.caption.present ? data.caption.value : this.caption,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      attachedType: data.attachedType.present
          ? data.attachedType.value
          : this.attachedType,
      attachedId: data.attachedId.present
          ? data.attachedId.value
          : this.attachedId,
      archived: data.archived.present ? data.archived.value : this.archived,
      archiveUri: data.archiveUri.present
          ? data.archiveUri.value
          : this.archiveUri,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Capture(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('textContent: $textContent, ')
          ..write('caption: $caption, ')
          ..write('durationSec: $durationSec, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('attachedType: $attachedType, ')
          ..write('attachedId: $attachedId, ')
          ..write('archived: $archived, ')
          ..write('archiveUri: $archiveUri, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    mediaPath,
    textContent,
    caption,
    durationSec,
    sizeBytes,
    attachedType,
    attachedId,
    archived,
    archiveUri,
    thumbnailPath,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Capture &&
          other.id == this.id &&
          other.type == this.type &&
          other.mediaPath == this.mediaPath &&
          other.textContent == this.textContent &&
          other.caption == this.caption &&
          other.durationSec == this.durationSec &&
          other.sizeBytes == this.sizeBytes &&
          other.attachedType == this.attachedType &&
          other.attachedId == this.attachedId &&
          other.archived == this.archived &&
          other.archiveUri == this.archiveUri &&
          other.thumbnailPath == this.thumbnailPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CapturesCompanion extends UpdateCompanion<Capture> {
  final Value<String> id;
  final Value<CaptureType> type;
  final Value<String?> mediaPath;
  final Value<String?> textContent;
  final Value<String?> caption;
  final Value<int?> durationSec;
  final Value<int> sizeBytes;
  final Value<AttachedType> attachedType;
  final Value<String> attachedId;
  final Value<bool> archived;
  final Value<String?> archiveUri;
  final Value<String?> thumbnailPath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CapturesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.mediaPath = const Value.absent(),
    this.textContent = const Value.absent(),
    this.caption = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.attachedType = const Value.absent(),
    this.attachedId = const Value.absent(),
    this.archived = const Value.absent(),
    this.archiveUri = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CapturesCompanion.insert({
    required String id,
    required CaptureType type,
    this.mediaPath = const Value.absent(),
    this.textContent = const Value.absent(),
    this.caption = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    required AttachedType attachedType,
    required String attachedId,
    this.archived = const Value.absent(),
    this.archiveUri = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       attachedType = Value(attachedType),
       attachedId = Value(attachedId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Capture> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? mediaPath,
    Expression<String>? textContent,
    Expression<String>? caption,
    Expression<int>? durationSec,
    Expression<int>? sizeBytes,
    Expression<String>? attachedType,
    Expression<String>? attachedId,
    Expression<bool>? archived,
    Expression<String>? archiveUri,
    Expression<String>? thumbnailPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (mediaPath != null) 'media_path': mediaPath,
      if (textContent != null) 'text_content': textContent,
      if (caption != null) 'caption': caption,
      if (durationSec != null) 'duration_sec': durationSec,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (attachedType != null) 'attached_type': attachedType,
      if (attachedId != null) 'attached_id': attachedId,
      if (archived != null) 'archived': archived,
      if (archiveUri != null) 'archive_uri': archiveUri,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CapturesCompanion copyWith({
    Value<String>? id,
    Value<CaptureType>? type,
    Value<String?>? mediaPath,
    Value<String?>? textContent,
    Value<String?>? caption,
    Value<int?>? durationSec,
    Value<int>? sizeBytes,
    Value<AttachedType>? attachedType,
    Value<String>? attachedId,
    Value<bool>? archived,
    Value<String?>? archiveUri,
    Value<String?>? thumbnailPath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CapturesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      mediaPath: mediaPath ?? this.mediaPath,
      textContent: textContent ?? this.textContent,
      caption: caption ?? this.caption,
      durationSec: durationSec ?? this.durationSec,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      attachedType: attachedType ?? this.attachedType,
      attachedId: attachedId ?? this.attachedId,
      archived: archived ?? this.archived,
      archiveUri: archiveUri ?? this.archiveUri,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $CapturesTable.$convertertype.toSql(type.value),
      );
    }
    if (mediaPath.present) {
      map['media_path'] = Variable<String>(mediaPath.value);
    }
    if (textContent.present) {
      map['text_content'] = Variable<String>(textContent.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (attachedType.present) {
      map['attached_type'] = Variable<String>(
        $CapturesTable.$converterattachedType.toSql(attachedType.value),
      );
    }
    if (attachedId.present) {
      map['attached_id'] = Variable<String>(attachedId.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (archiveUri.present) {
      map['archive_uri'] = Variable<String>(archiveUri.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CapturesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('textContent: $textContent, ')
          ..write('caption: $caption, ')
          ..write('durationSec: $durationSec, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('attachedType: $attachedType, ')
          ..write('attachedId: $attachedId, ')
          ..write('archived: $archived, ')
          ..write('archiveUri: $archiveUri, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CommittedListenersTable extends CommittedListeners
    with TableInfo<$CommittedListenersTable, CommittedListener> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommittedListenersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactLookupKeyMeta = const VerificationMeta(
    'contactLookupKey',
  );
  @override
  late final GeneratedColumn<String> contactLookupKey = GeneratedColumn<String>(
    'contact_lookup_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ListenerChannel, String> channel =
      GeneratedColumn<String>(
        'channel',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ListenerChannel>(
        $CommittedListenersTable.$converterchannel,
      );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ListenerScope, String> scope =
      GeneratedColumn<String>(
        'scope',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ListenerScope>($CommittedListenersTable.$converterscope);
  static const VerificationMeta _scopeIdMeta = const VerificationMeta(
    'scopeId',
  );
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
    'scope_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ListenerFrequency, String>
  frequency =
      GeneratedColumn<String>(
        'frequency',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ListenerFrequency>(
        $CommittedListenersTable.$converterfrequency,
      );
  static const VerificationMeta _includeCapturesMeta = const VerificationMeta(
    'includeCaptures',
  );
  @override
  late final GeneratedColumn<bool> includeCaptures = GeneratedColumn<bool>(
    'include_captures',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("include_captures" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _consentConfirmedAtMeta =
      const VerificationMeta('consentConfirmedAt');
  @override
  late final GeneratedColumn<DateTime> consentConfirmedAt =
      GeneratedColumn<DateTime>(
        'consent_confirmed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contactLookupKey,
    displayName,
    channel,
    email,
    scope,
    scopeId,
    frequency,
    includeCaptures,
    consentConfirmedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'committed_listeners';
  @override
  VerificationContext validateIntegrity(
    Insertable<CommittedListener> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('contact_lookup_key')) {
      context.handle(
        _contactLookupKeyMeta,
        contactLookupKey.isAcceptableOrUnknown(
          data['contact_lookup_key']!,
          _contactLookupKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contactLookupKeyMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('scope_id')) {
      context.handle(
        _scopeIdMeta,
        scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta),
      );
    }
    if (data.containsKey('include_captures')) {
      context.handle(
        _includeCapturesMeta,
        includeCaptures.isAcceptableOrUnknown(
          data['include_captures']!,
          _includeCapturesMeta,
        ),
      );
    }
    if (data.containsKey('consent_confirmed_at')) {
      context.handle(
        _consentConfirmedAtMeta,
        consentConfirmedAt.isAcceptableOrUnknown(
          data['consent_confirmed_at']!,
          _consentConfirmedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consentConfirmedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CommittedListener map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CommittedListener(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contactLookupKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_lookup_key'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      channel: $CommittedListenersTable.$converterchannel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}channel'],
        )!,
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      scope: $CommittedListenersTable.$converterscope.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}scope'],
        )!,
      ),
      scopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_id'],
      ),
      frequency: $CommittedListenersTable.$converterfrequency.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}frequency'],
        )!,
      ),
      includeCaptures: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}include_captures'],
      )!,
      consentConfirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}consent_confirmed_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CommittedListenersTable createAlias(String alias) {
    return $CommittedListenersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ListenerChannel, String, String> $converterchannel =
      const EnumNameConverter<ListenerChannel>(ListenerChannel.values);
  static JsonTypeConverter2<ListenerScope, String, String> $converterscope =
      const EnumNameConverter<ListenerScope>(ListenerScope.values);
  static JsonTypeConverter2<ListenerFrequency, String, String>
  $converterfrequency = const EnumNameConverter<ListenerFrequency>(
    ListenerFrequency.values,
  );
}

class CommittedListener extends DataClass
    implements Insertable<CommittedListener> {
  final String id;
  final String contactLookupKey;
  final String displayName;
  final ListenerChannel channel;
  final String? email;
  final ListenerScope scope;
  final String? scopeId;
  final ListenerFrequency frequency;
  final bool includeCaptures;
  final DateTime consentConfirmedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CommittedListener({
    required this.id,
    required this.contactLookupKey,
    required this.displayName,
    required this.channel,
    this.email,
    required this.scope,
    this.scopeId,
    required this.frequency,
    required this.includeCaptures,
    required this.consentConfirmedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['contact_lookup_key'] = Variable<String>(contactLookupKey);
    map['display_name'] = Variable<String>(displayName);
    {
      map['channel'] = Variable<String>(
        $CommittedListenersTable.$converterchannel.toSql(channel),
      );
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    {
      map['scope'] = Variable<String>(
        $CommittedListenersTable.$converterscope.toSql(scope),
      );
    }
    if (!nullToAbsent || scopeId != null) {
      map['scope_id'] = Variable<String>(scopeId);
    }
    {
      map['frequency'] = Variable<String>(
        $CommittedListenersTable.$converterfrequency.toSql(frequency),
      );
    }
    map['include_captures'] = Variable<bool>(includeCaptures);
    map['consent_confirmed_at'] = Variable<DateTime>(consentConfirmedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CommittedListenersCompanion toCompanion(bool nullToAbsent) {
    return CommittedListenersCompanion(
      id: Value(id),
      contactLookupKey: Value(contactLookupKey),
      displayName: Value(displayName),
      channel: Value(channel),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      scope: Value(scope),
      scopeId: scopeId == null && nullToAbsent
          ? const Value.absent()
          : Value(scopeId),
      frequency: Value(frequency),
      includeCaptures: Value(includeCaptures),
      consentConfirmedAt: Value(consentConfirmedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CommittedListener.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CommittedListener(
      id: serializer.fromJson<String>(json['id']),
      contactLookupKey: serializer.fromJson<String>(json['contactLookupKey']),
      displayName: serializer.fromJson<String>(json['displayName']),
      channel: $CommittedListenersTable.$converterchannel.fromJson(
        serializer.fromJson<String>(json['channel']),
      ),
      email: serializer.fromJson<String?>(json['email']),
      scope: $CommittedListenersTable.$converterscope.fromJson(
        serializer.fromJson<String>(json['scope']),
      ),
      scopeId: serializer.fromJson<String?>(json['scopeId']),
      frequency: $CommittedListenersTable.$converterfrequency.fromJson(
        serializer.fromJson<String>(json['frequency']),
      ),
      includeCaptures: serializer.fromJson<bool>(json['includeCaptures']),
      consentConfirmedAt: serializer.fromJson<DateTime>(
        json['consentConfirmedAt'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'contactLookupKey': serializer.toJson<String>(contactLookupKey),
      'displayName': serializer.toJson<String>(displayName),
      'channel': serializer.toJson<String>(
        $CommittedListenersTable.$converterchannel.toJson(channel),
      ),
      'email': serializer.toJson<String?>(email),
      'scope': serializer.toJson<String>(
        $CommittedListenersTable.$converterscope.toJson(scope),
      ),
      'scopeId': serializer.toJson<String?>(scopeId),
      'frequency': serializer.toJson<String>(
        $CommittedListenersTable.$converterfrequency.toJson(frequency),
      ),
      'includeCaptures': serializer.toJson<bool>(includeCaptures),
      'consentConfirmedAt': serializer.toJson<DateTime>(consentConfirmedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CommittedListener copyWith({
    String? id,
    String? contactLookupKey,
    String? displayName,
    ListenerChannel? channel,
    Value<String?> email = const Value.absent(),
    ListenerScope? scope,
    Value<String?> scopeId = const Value.absent(),
    ListenerFrequency? frequency,
    bool? includeCaptures,
    DateTime? consentConfirmedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CommittedListener(
    id: id ?? this.id,
    contactLookupKey: contactLookupKey ?? this.contactLookupKey,
    displayName: displayName ?? this.displayName,
    channel: channel ?? this.channel,
    email: email.present ? email.value : this.email,
    scope: scope ?? this.scope,
    scopeId: scopeId.present ? scopeId.value : this.scopeId,
    frequency: frequency ?? this.frequency,
    includeCaptures: includeCaptures ?? this.includeCaptures,
    consentConfirmedAt: consentConfirmedAt ?? this.consentConfirmedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CommittedListener copyWithCompanion(CommittedListenersCompanion data) {
    return CommittedListener(
      id: data.id.present ? data.id.value : this.id,
      contactLookupKey: data.contactLookupKey.present
          ? data.contactLookupKey.value
          : this.contactLookupKey,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      channel: data.channel.present ? data.channel.value : this.channel,
      email: data.email.present ? data.email.value : this.email,
      scope: data.scope.present ? data.scope.value : this.scope,
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      includeCaptures: data.includeCaptures.present
          ? data.includeCaptures.value
          : this.includeCaptures,
      consentConfirmedAt: data.consentConfirmedAt.present
          ? data.consentConfirmedAt.value
          : this.consentConfirmedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CommittedListener(')
          ..write('id: $id, ')
          ..write('contactLookupKey: $contactLookupKey, ')
          ..write('displayName: $displayName, ')
          ..write('channel: $channel, ')
          ..write('email: $email, ')
          ..write('scope: $scope, ')
          ..write('scopeId: $scopeId, ')
          ..write('frequency: $frequency, ')
          ..write('includeCaptures: $includeCaptures, ')
          ..write('consentConfirmedAt: $consentConfirmedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contactLookupKey,
    displayName,
    channel,
    email,
    scope,
    scopeId,
    frequency,
    includeCaptures,
    consentConfirmedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommittedListener &&
          other.id == this.id &&
          other.contactLookupKey == this.contactLookupKey &&
          other.displayName == this.displayName &&
          other.channel == this.channel &&
          other.email == this.email &&
          other.scope == this.scope &&
          other.scopeId == this.scopeId &&
          other.frequency == this.frequency &&
          other.includeCaptures == this.includeCaptures &&
          other.consentConfirmedAt == this.consentConfirmedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CommittedListenersCompanion extends UpdateCompanion<CommittedListener> {
  final Value<String> id;
  final Value<String> contactLookupKey;
  final Value<String> displayName;
  final Value<ListenerChannel> channel;
  final Value<String?> email;
  final Value<ListenerScope> scope;
  final Value<String?> scopeId;
  final Value<ListenerFrequency> frequency;
  final Value<bool> includeCaptures;
  final Value<DateTime> consentConfirmedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CommittedListenersCompanion({
    this.id = const Value.absent(),
    this.contactLookupKey = const Value.absent(),
    this.displayName = const Value.absent(),
    this.channel = const Value.absent(),
    this.email = const Value.absent(),
    this.scope = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.frequency = const Value.absent(),
    this.includeCaptures = const Value.absent(),
    this.consentConfirmedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CommittedListenersCompanion.insert({
    required String id,
    required String contactLookupKey,
    required String displayName,
    required ListenerChannel channel,
    this.email = const Value.absent(),
    required ListenerScope scope,
    this.scopeId = const Value.absent(),
    required ListenerFrequency frequency,
    this.includeCaptures = const Value.absent(),
    required DateTime consentConfirmedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       contactLookupKey = Value(contactLookupKey),
       displayName = Value(displayName),
       channel = Value(channel),
       scope = Value(scope),
       frequency = Value(frequency),
       consentConfirmedAt = Value(consentConfirmedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CommittedListener> custom({
    Expression<String>? id,
    Expression<String>? contactLookupKey,
    Expression<String>? displayName,
    Expression<String>? channel,
    Expression<String>? email,
    Expression<String>? scope,
    Expression<String>? scopeId,
    Expression<String>? frequency,
    Expression<bool>? includeCaptures,
    Expression<DateTime>? consentConfirmedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contactLookupKey != null) 'contact_lookup_key': contactLookupKey,
      if (displayName != null) 'display_name': displayName,
      if (channel != null) 'channel': channel,
      if (email != null) 'email': email,
      if (scope != null) 'scope': scope,
      if (scopeId != null) 'scope_id': scopeId,
      if (frequency != null) 'frequency': frequency,
      if (includeCaptures != null) 'include_captures': includeCaptures,
      if (consentConfirmedAt != null)
        'consent_confirmed_at': consentConfirmedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CommittedListenersCompanion copyWith({
    Value<String>? id,
    Value<String>? contactLookupKey,
    Value<String>? displayName,
    Value<ListenerChannel>? channel,
    Value<String?>? email,
    Value<ListenerScope>? scope,
    Value<String?>? scopeId,
    Value<ListenerFrequency>? frequency,
    Value<bool>? includeCaptures,
    Value<DateTime>? consentConfirmedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CommittedListenersCompanion(
      id: id ?? this.id,
      contactLookupKey: contactLookupKey ?? this.contactLookupKey,
      displayName: displayName ?? this.displayName,
      channel: channel ?? this.channel,
      email: email ?? this.email,
      scope: scope ?? this.scope,
      scopeId: scopeId ?? this.scopeId,
      frequency: frequency ?? this.frequency,
      includeCaptures: includeCaptures ?? this.includeCaptures,
      consentConfirmedAt: consentConfirmedAt ?? this.consentConfirmedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contactLookupKey.present) {
      map['contact_lookup_key'] = Variable<String>(contactLookupKey.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(
        $CommittedListenersTable.$converterchannel.toSql(channel.value),
      );
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(
        $CommittedListenersTable.$converterscope.toSql(scope.value),
      );
    }
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(
        $CommittedListenersTable.$converterfrequency.toSql(frequency.value),
      );
    }
    if (includeCaptures.present) {
      map['include_captures'] = Variable<bool>(includeCaptures.value);
    }
    if (consentConfirmedAt.present) {
      map['consent_confirmed_at'] = Variable<DateTime>(
        consentConfirmedAt.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommittedListenersCompanion(')
          ..write('id: $id, ')
          ..write('contactLookupKey: $contactLookupKey, ')
          ..write('displayName: $displayName, ')
          ..write('channel: $channel, ')
          ..write('email: $email, ')
          ..write('scope: $scope, ')
          ..write('scopeId: $scopeId, ')
          ..write('frequency: $frequency, ')
          ..write('includeCaptures: $includeCaptures, ')
          ..write('consentConfirmedAt: $consentConfirmedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListenerFeedbacksTable extends ListenerFeedbacks
    with TableInfo<$ListenerFeedbacksTable, ListenerFeedback> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListenerFeedbacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listenerIdMeta = const VerificationMeta(
    'listenerId',
  );
  @override
  late final GeneratedColumn<String> listenerId = GeneratedColumn<String>(
    'listener_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES committed_listeners (id)',
    ),
  );
  static const VerificationMeta _ratingPctMeta = const VerificationMeta(
    'ratingPct',
  );
  @override
  late final GeneratedColumn<int> ratingPct = GeneratedColumn<int>(
    'rating_pct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
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
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    listenerId,
    ratingPct,
    comment,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listener_feedbacks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListenerFeedback> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('listener_id')) {
      context.handle(
        _listenerIdMeta,
        listenerId.isAcceptableOrUnknown(data['listener_id']!, _listenerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listenerIdMeta);
    }
    if (data.containsKey('rating_pct')) {
      context.handle(
        _ratingPctMeta,
        ratingPct.isAcceptableOrUnknown(data['rating_pct']!, _ratingPctMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingPctMeta);
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListenerFeedback map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListenerFeedback(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      listenerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}listener_id'],
      )!,
      ratingPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating_pct'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ListenerFeedbacksTable createAlias(String alias) {
    return $ListenerFeedbacksTable(attachedDatabase, alias);
  }
}

class ListenerFeedback extends DataClass
    implements Insertable<ListenerFeedback> {
  final String id;
  final String listenerId;
  final int ratingPct;
  final String? comment;
  final DateTime createdAt;
  const ListenerFeedback({
    required this.id,
    required this.listenerId,
    required this.ratingPct,
    this.comment,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['listener_id'] = Variable<String>(listenerId);
    map['rating_pct'] = Variable<int>(ratingPct);
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ListenerFeedbacksCompanion toCompanion(bool nullToAbsent) {
    return ListenerFeedbacksCompanion(
      id: Value(id),
      listenerId: Value(listenerId),
      ratingPct: Value(ratingPct),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      createdAt: Value(createdAt),
    );
  }

  factory ListenerFeedback.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListenerFeedback(
      id: serializer.fromJson<String>(json['id']),
      listenerId: serializer.fromJson<String>(json['listenerId']),
      ratingPct: serializer.fromJson<int>(json['ratingPct']),
      comment: serializer.fromJson<String?>(json['comment']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'listenerId': serializer.toJson<String>(listenerId),
      'ratingPct': serializer.toJson<int>(ratingPct),
      'comment': serializer.toJson<String?>(comment),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ListenerFeedback copyWith({
    String? id,
    String? listenerId,
    int? ratingPct,
    Value<String?> comment = const Value.absent(),
    DateTime? createdAt,
  }) => ListenerFeedback(
    id: id ?? this.id,
    listenerId: listenerId ?? this.listenerId,
    ratingPct: ratingPct ?? this.ratingPct,
    comment: comment.present ? comment.value : this.comment,
    createdAt: createdAt ?? this.createdAt,
  );
  ListenerFeedback copyWithCompanion(ListenerFeedbacksCompanion data) {
    return ListenerFeedback(
      id: data.id.present ? data.id.value : this.id,
      listenerId: data.listenerId.present
          ? data.listenerId.value
          : this.listenerId,
      ratingPct: data.ratingPct.present ? data.ratingPct.value : this.ratingPct,
      comment: data.comment.present ? data.comment.value : this.comment,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListenerFeedback(')
          ..write('id: $id, ')
          ..write('listenerId: $listenerId, ')
          ..write('ratingPct: $ratingPct, ')
          ..write('comment: $comment, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, listenerId, ratingPct, comment, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListenerFeedback &&
          other.id == this.id &&
          other.listenerId == this.listenerId &&
          other.ratingPct == this.ratingPct &&
          other.comment == this.comment &&
          other.createdAt == this.createdAt);
}

class ListenerFeedbacksCompanion extends UpdateCompanion<ListenerFeedback> {
  final Value<String> id;
  final Value<String> listenerId;
  final Value<int> ratingPct;
  final Value<String?> comment;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ListenerFeedbacksCompanion({
    this.id = const Value.absent(),
    this.listenerId = const Value.absent(),
    this.ratingPct = const Value.absent(),
    this.comment = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListenerFeedbacksCompanion.insert({
    required String id,
    required String listenerId,
    required int ratingPct,
    this.comment = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       listenerId = Value(listenerId),
       ratingPct = Value(ratingPct),
       createdAt = Value(createdAt);
  static Insertable<ListenerFeedback> custom({
    Expression<String>? id,
    Expression<String>? listenerId,
    Expression<int>? ratingPct,
    Expression<String>? comment,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listenerId != null) 'listener_id': listenerId,
      if (ratingPct != null) 'rating_pct': ratingPct,
      if (comment != null) 'comment': comment,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListenerFeedbacksCompanion copyWith({
    Value<String>? id,
    Value<String>? listenerId,
    Value<int>? ratingPct,
    Value<String?>? comment,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ListenerFeedbacksCompanion(
      id: id ?? this.id,
      listenerId: listenerId ?? this.listenerId,
      ratingPct: ratingPct ?? this.ratingPct,
      comment: comment ?? this.comment,
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
    if (listenerId.present) {
      map['listener_id'] = Variable<String>(listenerId.value);
    }
    if (ratingPct.present) {
      map['rating_pct'] = Variable<int>(ratingPct.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
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
    return (StringBuffer('ListenerFeedbacksCompanion(')
          ..write('id: $id, ')
          ..write('listenerId: $listenerId, ')
          ..write('ratingPct: $ratingPct, ')
          ..write('comment: $comment, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SaaraGroupsTable extends SaaraGroups
    with TableInfo<$SaaraGroupsTable, SaaraGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaaraGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  memberLookupKeys = GeneratedColumn<String>(
    'member_lookup_keys',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<String>>($SaaraGroupsTable.$convertermemberLookupKeys);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    memberLookupKeys,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saara_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaaraGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaaraGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaaraGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      memberLookupKeys: $SaaraGroupsTable.$convertermemberLookupKeys.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}member_lookup_keys'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SaaraGroupsTable createAlias(String alias) {
    return $SaaraGroupsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertermemberLookupKeys =
      const StringListConverter();
}

class SaaraGroup extends DataClass implements Insertable<SaaraGroup> {
  final String id;
  final String name;
  final List<String> memberLookupKeys;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SaaraGroup({
    required this.id,
    required this.name,
    required this.memberLookupKeys,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['member_lookup_keys'] = Variable<String>(
        $SaaraGroupsTable.$convertermemberLookupKeys.toSql(memberLookupKeys),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SaaraGroupsCompanion toCompanion(bool nullToAbsent) {
    return SaaraGroupsCompanion(
      id: Value(id),
      name: Value(name),
      memberLookupKeys: Value(memberLookupKeys),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SaaraGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaaraGroup(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      memberLookupKeys: serializer.fromJson<List<String>>(
        json['memberLookupKeys'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'memberLookupKeys': serializer.toJson<List<String>>(memberLookupKeys),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SaaraGroup copyWith({
    String? id,
    String? name,
    List<String>? memberLookupKeys,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SaaraGroup(
    id: id ?? this.id,
    name: name ?? this.name,
    memberLookupKeys: memberLookupKeys ?? this.memberLookupKeys,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SaaraGroup copyWithCompanion(SaaraGroupsCompanion data) {
    return SaaraGroup(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      memberLookupKeys: data.memberLookupKeys.present
          ? data.memberLookupKeys.value
          : this.memberLookupKeys,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaaraGroup(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('memberLookupKeys: $memberLookupKeys, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, memberLookupKeys, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaaraGroup &&
          other.id == this.id &&
          other.name == this.name &&
          other.memberLookupKeys == this.memberLookupKeys &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SaaraGroupsCompanion extends UpdateCompanion<SaaraGroup> {
  final Value<String> id;
  final Value<String> name;
  final Value<List<String>> memberLookupKeys;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SaaraGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.memberLookupKeys = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SaaraGroupsCompanion.insert({
    required String id,
    required String name,
    required List<String> memberLookupKeys,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       memberLookupKeys = Value(memberLookupKeys),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SaaraGroup> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? memberLookupKeys,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (memberLookupKeys != null) 'member_lookup_keys': memberLookupKeys,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SaaraGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<List<String>>? memberLookupKeys,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SaaraGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      memberLookupKeys: memberLookupKeys ?? this.memberLookupKeys,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (memberLookupKeys.present) {
      map['member_lookup_keys'] = Variable<String>(
        $SaaraGroupsTable.$convertermemberLookupKeys.toSql(
          memberLookupKeys.value,
        ),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaaraGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('memberLookupKeys: $memberLookupKeys, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DayLogsTable extends DayLogs with TableInfo<$DayLogsTable, DayLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _committedAtMeta = const VerificationMeta(
    'committedAt',
  );
  @override
  late final GeneratedColumn<DateTime> committedAt = GeneratedColumn<DateTime>(
    'committed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reflectionCaptureIdMeta =
      const VerificationMeta('reflectionCaptureId');
  @override
  late final GeneratedColumn<String> reflectionCaptureId =
      GeneratedColumn<String>(
        'reflection_capture_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    openedAt,
    committedAt,
    closedAt,
    reflectionCaptureId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    }
    if (data.containsKey('committed_at')) {
      context.handle(
        _committedAtMeta,
        committedAt.isAcceptableOrUnknown(
          data['committed_at']!,
          _committedAtMeta,
        ),
      );
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('reflection_capture_id')) {
      context.handle(
        _reflectionCaptureIdMeta,
        reflectionCaptureId.isAcceptableOrUnknown(
          data['reflection_capture_id']!,
          _reflectionCaptureIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DayLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayLog(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      ),
      committedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}committed_at'],
      ),
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
      reflectionCaptureId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reflection_capture_id'],
      ),
    );
  }

  @override
  $DayLogsTable createAlias(String alias) {
    return $DayLogsTable(attachedDatabase, alias);
  }
}

class DayLog extends DataClass implements Insertable<DayLog> {
  final String date;
  final DateTime? openedAt;
  final DateTime? committedAt;
  final DateTime? closedAt;
  final String? reflectionCaptureId;
  const DayLog({
    required this.date,
    this.openedAt,
    this.committedAt,
    this.closedAt,
    this.reflectionCaptureId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || openedAt != null) {
      map['opened_at'] = Variable<DateTime>(openedAt);
    }
    if (!nullToAbsent || committedAt != null) {
      map['committed_at'] = Variable<DateTime>(committedAt);
    }
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    if (!nullToAbsent || reflectionCaptureId != null) {
      map['reflection_capture_id'] = Variable<String>(reflectionCaptureId);
    }
    return map;
  }

  DayLogsCompanion toCompanion(bool nullToAbsent) {
    return DayLogsCompanion(
      date: Value(date),
      openedAt: openedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAt),
      committedAt: committedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(committedAt),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      reflectionCaptureId: reflectionCaptureId == null && nullToAbsent
          ? const Value.absent()
          : Value(reflectionCaptureId),
    );
  }

  factory DayLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayLog(
      date: serializer.fromJson<String>(json['date']),
      openedAt: serializer.fromJson<DateTime?>(json['openedAt']),
      committedAt: serializer.fromJson<DateTime?>(json['committedAt']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      reflectionCaptureId: serializer.fromJson<String?>(
        json['reflectionCaptureId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'openedAt': serializer.toJson<DateTime?>(openedAt),
      'committedAt': serializer.toJson<DateTime?>(committedAt),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'reflectionCaptureId': serializer.toJson<String?>(reflectionCaptureId),
    };
  }

  DayLog copyWith({
    String? date,
    Value<DateTime?> openedAt = const Value.absent(),
    Value<DateTime?> committedAt = const Value.absent(),
    Value<DateTime?> closedAt = const Value.absent(),
    Value<String?> reflectionCaptureId = const Value.absent(),
  }) => DayLog(
    date: date ?? this.date,
    openedAt: openedAt.present ? openedAt.value : this.openedAt,
    committedAt: committedAt.present ? committedAt.value : this.committedAt,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    reflectionCaptureId: reflectionCaptureId.present
        ? reflectionCaptureId.value
        : this.reflectionCaptureId,
  );
  DayLog copyWithCompanion(DayLogsCompanion data) {
    return DayLog(
      date: data.date.present ? data.date.value : this.date,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      committedAt: data.committedAt.present
          ? data.committedAt.value
          : this.committedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      reflectionCaptureId: data.reflectionCaptureId.present
          ? data.reflectionCaptureId.value
          : this.reflectionCaptureId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayLog(')
          ..write('date: $date, ')
          ..write('openedAt: $openedAt, ')
          ..write('committedAt: $committedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('reflectionCaptureId: $reflectionCaptureId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(date, openedAt, committedAt, closedAt, reflectionCaptureId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayLog &&
          other.date == this.date &&
          other.openedAt == this.openedAt &&
          other.committedAt == this.committedAt &&
          other.closedAt == this.closedAt &&
          other.reflectionCaptureId == this.reflectionCaptureId);
}

class DayLogsCompanion extends UpdateCompanion<DayLog> {
  final Value<String> date;
  final Value<DateTime?> openedAt;
  final Value<DateTime?> committedAt;
  final Value<DateTime?> closedAt;
  final Value<String?> reflectionCaptureId;
  final Value<int> rowid;
  const DayLogsCompanion({
    this.date = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.committedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.reflectionCaptureId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayLogsCompanion.insert({
    required String date,
    this.openedAt = const Value.absent(),
    this.committedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.reflectionCaptureId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date);
  static Insertable<DayLog> custom({
    Expression<String>? date,
    Expression<DateTime>? openedAt,
    Expression<DateTime>? committedAt,
    Expression<DateTime>? closedAt,
    Expression<String>? reflectionCaptureId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (openedAt != null) 'opened_at': openedAt,
      if (committedAt != null) 'committed_at': committedAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (reflectionCaptureId != null)
        'reflection_capture_id': reflectionCaptureId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayLogsCompanion copyWith({
    Value<String>? date,
    Value<DateTime?>? openedAt,
    Value<DateTime?>? committedAt,
    Value<DateTime?>? closedAt,
    Value<String?>? reflectionCaptureId,
    Value<int>? rowid,
  }) {
    return DayLogsCompanion(
      date: date ?? this.date,
      openedAt: openedAt ?? this.openedAt,
      committedAt: committedAt ?? this.committedAt,
      closedAt: closedAt ?? this.closedAt,
      reflectionCaptureId: reflectionCaptureId ?? this.reflectionCaptureId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (committedAt.present) {
      map['committed_at'] = Variable<DateTime>(committedAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (reflectionCaptureId.present) {
      map['reflection_capture_id'] = Variable<String>(
        reflectionCaptureId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayLogsCompanion(')
          ..write('date: $date, ')
          ..write('openedAt: $openedAt, ')
          ..write('committedAt: $committedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('reflectionCaptureId: $reflectionCaptureId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HealthSnapshotsTable extends HealthSnapshots
    with TableInfo<$HealthSnapshotsTable, HealthSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metricMeta = const VerificationMeta('metric');
  @override
  late final GeneratedColumn<String> metric = GeneratedColumn<String>(
    'metric',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [date, metric, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<HealthSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('metric')) {
      context.handle(
        _metricMeta,
        metric.isAcceptableOrUnknown(data['metric']!, _metricMeta),
      );
    } else if (isInserting) {
      context.missing(_metricMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date, metric};
  @override
  HealthSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthSnapshot(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      metric: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metric'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $HealthSnapshotsTable createAlias(String alias) {
    return $HealthSnapshotsTable(attachedDatabase, alias);
  }
}

class HealthSnapshot extends DataClass implements Insertable<HealthSnapshot> {
  final String date;
  final String metric;
  final double value;
  const HealthSnapshot({
    required this.date,
    required this.metric,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['metric'] = Variable<String>(metric);
    map['value'] = Variable<double>(value);
    return map;
  }

  HealthSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return HealthSnapshotsCompanion(
      date: Value(date),
      metric: Value(metric),
      value: Value(value),
    );
  }

  factory HealthSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthSnapshot(
      date: serializer.fromJson<String>(json['date']),
      metric: serializer.fromJson<String>(json['metric']),
      value: serializer.fromJson<double>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'metric': serializer.toJson<String>(metric),
      'value': serializer.toJson<double>(value),
    };
  }

  HealthSnapshot copyWith({String? date, String? metric, double? value}) =>
      HealthSnapshot(
        date: date ?? this.date,
        metric: metric ?? this.metric,
        value: value ?? this.value,
      );
  HealthSnapshot copyWithCompanion(HealthSnapshotsCompanion data) {
    return HealthSnapshot(
      date: data.date.present ? data.date.value : this.date,
      metric: data.metric.present ? data.metric.value : this.metric,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthSnapshot(')
          ..write('date: $date, ')
          ..write('metric: $metric, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, metric, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthSnapshot &&
          other.date == this.date &&
          other.metric == this.metric &&
          other.value == this.value);
}

class HealthSnapshotsCompanion extends UpdateCompanion<HealthSnapshot> {
  final Value<String> date;
  final Value<String> metric;
  final Value<double> value;
  final Value<int> rowid;
  const HealthSnapshotsCompanion({
    this.date = const Value.absent(),
    this.metric = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HealthSnapshotsCompanion.insert({
    required String date,
    required String metric,
    required double value,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       metric = Value(metric),
       value = Value(value);
  static Insertable<HealthSnapshot> custom({
    Expression<String>? date,
    Expression<String>? metric,
    Expression<double>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (metric != null) 'metric': metric,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HealthSnapshotsCompanion copyWith({
    Value<String>? date,
    Value<String>? metric,
    Value<double>? value,
    Value<int>? rowid,
  }) {
    return HealthSnapshotsCompanion(
      date: date ?? this.date,
      metric: metric ?? this.metric,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (metric.present) {
      map['metric'] = Variable<String>(metric.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthSnapshotsCompanion(')
          ..write('date: $date, ')
          ..write('metric: $metric, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String? value;
  const Setting({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  Setting copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
  }) => Setting(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ApiCredentialsTable extends ApiCredentials
    with TableInfo<$ApiCredentialsTable, ApiCredential> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApiCredentialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyAliasMeta = const VerificationMeta(
    'keyAlias',
  );
  @override
  late final GeneratedColumn<String> keyAlias = GeneratedColumn<String>(
    'key_alias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [provider, keyAlias];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'api_credentials';
  @override
  VerificationContext validateIntegrity(
    Insertable<ApiCredential> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('key_alias')) {
      context.handle(
        _keyAliasMeta,
        keyAlias.isAcceptableOrUnknown(data['key_alias']!, _keyAliasMeta),
      );
    } else if (isInserting) {
      context.missing(_keyAliasMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {provider};
  @override
  ApiCredential map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApiCredential(
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      keyAlias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_alias'],
      )!,
    );
  }

  @override
  $ApiCredentialsTable createAlias(String alias) {
    return $ApiCredentialsTable(attachedDatabase, alias);
  }
}

class ApiCredential extends DataClass implements Insertable<ApiCredential> {
  final String provider;
  final String keyAlias;
  const ApiCredential({required this.provider, required this.keyAlias});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider'] = Variable<String>(provider);
    map['key_alias'] = Variable<String>(keyAlias);
    return map;
  }

  ApiCredentialsCompanion toCompanion(bool nullToAbsent) {
    return ApiCredentialsCompanion(
      provider: Value(provider),
      keyAlias: Value(keyAlias),
    );
  }

  factory ApiCredential.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApiCredential(
      provider: serializer.fromJson<String>(json['provider']),
      keyAlias: serializer.fromJson<String>(json['keyAlias']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'provider': serializer.toJson<String>(provider),
      'keyAlias': serializer.toJson<String>(keyAlias),
    };
  }

  ApiCredential copyWith({String? provider, String? keyAlias}) => ApiCredential(
    provider: provider ?? this.provider,
    keyAlias: keyAlias ?? this.keyAlias,
  );
  ApiCredential copyWithCompanion(ApiCredentialsCompanion data) {
    return ApiCredential(
      provider: data.provider.present ? data.provider.value : this.provider,
      keyAlias: data.keyAlias.present ? data.keyAlias.value : this.keyAlias,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApiCredential(')
          ..write('provider: $provider, ')
          ..write('keyAlias: $keyAlias')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(provider, keyAlias);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiCredential &&
          other.provider == this.provider &&
          other.keyAlias == this.keyAlias);
}

class ApiCredentialsCompanion extends UpdateCompanion<ApiCredential> {
  final Value<String> provider;
  final Value<String> keyAlias;
  final Value<int> rowid;
  const ApiCredentialsCompanion({
    this.provider = const Value.absent(),
    this.keyAlias = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApiCredentialsCompanion.insert({
    required String provider,
    required String keyAlias,
    this.rowid = const Value.absent(),
  }) : provider = Value(provider),
       keyAlias = Value(keyAlias);
  static Insertable<ApiCredential> custom({
    Expression<String>? provider,
    Expression<String>? keyAlias,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (provider != null) 'provider': provider,
      if (keyAlias != null) 'key_alias': keyAlias,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApiCredentialsCompanion copyWith({
    Value<String>? provider,
    Value<String>? keyAlias,
    Value<int>? rowid,
  }) {
    return ApiCredentialsCompanion(
      provider: provider ?? this.provider,
      keyAlias: keyAlias ?? this.keyAlias,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (keyAlias.present) {
      map['key_alias'] = Variable<String>(keyAlias.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApiCredentialsCompanion(')
          ..write('provider: $provider, ')
          ..write('keyAlias: $keyAlias, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AreasTable areas = $AreasTable(this);
  late final $MeasurableResultsTable measurableResults =
      $MeasurableResultsTable(this);
  late final $MeasurableLogsTable measurableLogs = $MeasurableLogsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $TaskParticipantsTable taskParticipants = $TaskParticipantsTable(
    this,
  );
  late final $TaskTransitionsTable taskTransitions = $TaskTransitionsTable(
    this,
  );
  late final $CapturesTable captures = $CapturesTable(this);
  late final $CommittedListenersTable committedListeners =
      $CommittedListenersTable(this);
  late final $ListenerFeedbacksTable listenerFeedbacks =
      $ListenerFeedbacksTable(this);
  late final $SaaraGroupsTable saaraGroups = $SaaraGroupsTable(this);
  late final $DayLogsTable dayLogs = $DayLogsTable(this);
  late final $HealthSnapshotsTable healthSnapshots = $HealthSnapshotsTable(
    this,
  );
  late final $SettingsTable settings = $SettingsTable(this);
  late final $ApiCredentialsTable apiCredentials = $ApiCredentialsTable(this);
  late final TaskDao taskDao = TaskDao(this as AppDatabase);
  late final AreaDao areaDao = AreaDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    areas,
    measurableResults,
    measurableLogs,
    tasks,
    taskParticipants,
    taskTransitions,
    captures,
    committedListeners,
    listenerFeedbacks,
    saaraGroups,
    dayLogs,
    healthSnapshots,
    settings,
    apiCredentials,
  ];
}

typedef $$AreasTableCreateCompanionBuilder =
    AreasCompanion Function({
      required String id,
      required BaseCategory baseCategory,
      required String displayName,
      Value<String?> icon,
      Value<String?> color,
      Value<String?> purposeStatement,
      Value<int> sortOrder,
      Value<bool> archived,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AreasTableUpdateCompanionBuilder =
    AreasCompanion Function({
      Value<String> id,
      Value<BaseCategory> baseCategory,
      Value<String> displayName,
      Value<String?> icon,
      Value<String?> color,
      Value<String?> purposeStatement,
      Value<int> sortOrder,
      Value<bool> archived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$AreasTableReferences
    extends BaseReferences<_$AppDatabase, $AreasTable, Area> {
  $$AreasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MeasurableResultsTable, List<MeasurableResult>>
  _measurableResultsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.measurableResults,
        aliasName: $_aliasNameGenerator(
          db.areas.id,
          db.measurableResults.areaId,
        ),
      );

  $$MeasurableResultsTableProcessedTableManager get measurableResultsRefs {
    final manager = $$MeasurableResultsTableTableManager(
      $_db,
      $_db.measurableResults,
    ).filter((f) => f.areaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _measurableResultsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: $_aliasNameGenerator(db.areas.id, db.tasks.areaId),
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.areaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AreasTableFilterComposer extends Composer<_$AppDatabase, $AreasTable> {
  $$AreasTableFilterComposer({
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

  ColumnWithTypeConverterFilters<BaseCategory, BaseCategory, String>
  get baseCategory => $composableBuilder(
    column: $table.baseCategory,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purposeStatement => $composableBuilder(
    column: $table.purposeStatement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> measurableResultsRefs(
    Expression<bool> Function($$MeasurableResultsTableFilterComposer f) f,
  ) {
    final $$MeasurableResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.measurableResults,
      getReferencedColumn: (t) => t.areaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurableResultsTableFilterComposer(
            $db: $db,
            $table: $db.measurableResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.areaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AreasTableOrderingComposer
    extends Composer<_$AppDatabase, $AreasTable> {
  $$AreasTableOrderingComposer({
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

  ColumnOrderings<String> get baseCategory => $composableBuilder(
    column: $table.baseCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purposeStatement => $composableBuilder(
    column: $table.purposeStatement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AreasTableAnnotationComposer
    extends Composer<_$AppDatabase, $AreasTable> {
  $$AreasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BaseCategory, String> get baseCategory =>
      $composableBuilder(
        column: $table.baseCategory,
        builder: (column) => column,
      );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get purposeStatement => $composableBuilder(
    column: $table.purposeStatement,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> measurableResultsRefs<T extends Object>(
    Expression<T> Function($$MeasurableResultsTableAnnotationComposer a) f,
  ) {
    final $$MeasurableResultsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.measurableResults,
          getReferencedColumn: (t) => t.areaId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MeasurableResultsTableAnnotationComposer(
                $db: $db,
                $table: $db.measurableResults,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.areaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AreasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AreasTable,
          Area,
          $$AreasTableFilterComposer,
          $$AreasTableOrderingComposer,
          $$AreasTableAnnotationComposer,
          $$AreasTableCreateCompanionBuilder,
          $$AreasTableUpdateCompanionBuilder,
          (Area, $$AreasTableReferences),
          Area,
          PrefetchHooks Function({bool measurableResultsRefs, bool tasksRefs})
        > {
  $$AreasTableTableManager(_$AppDatabase db, $AreasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AreasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AreasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AreasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<BaseCategory> baseCategory = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> purposeStatement = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AreasCompanion(
                id: id,
                baseCategory: baseCategory,
                displayName: displayName,
                icon: icon,
                color: color,
                purposeStatement: purposeStatement,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required BaseCategory baseCategory,
                required String displayName,
                Value<String?> icon = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> purposeStatement = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AreasCompanion.insert(
                id: id,
                baseCategory: baseCategory,
                displayName: displayName,
                icon: icon,
                color: color,
                purposeStatement: purposeStatement,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$AreasTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({measurableResultsRefs = false, tasksRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (measurableResultsRefs) db.measurableResults,
                    if (tasksRefs) db.tasks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (measurableResultsRefs)
                        await $_getPrefetchedData<
                          Area,
                          $AreasTable,
                          MeasurableResult
                        >(
                          currentTable: table,
                          referencedTable: $$AreasTableReferences
                              ._measurableResultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AreasTableReferences(
                                db,
                                table,
                                p0,
                              ).measurableResultsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.areaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tasksRefs)
                        await $_getPrefetchedData<Area, $AreasTable, Task>(
                          currentTable: table,
                          referencedTable: $$AreasTableReferences
                              ._tasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AreasTableReferences(db, table, p0).tasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.areaId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AreasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AreasTable,
      Area,
      $$AreasTableFilterComposer,
      $$AreasTableOrderingComposer,
      $$AreasTableAnnotationComposer,
      $$AreasTableCreateCompanionBuilder,
      $$AreasTableUpdateCompanionBuilder,
      (Area, $$AreasTableReferences),
      Area,
      PrefetchHooks Function({bool measurableResultsRefs, bool tasksRefs})
    >;
typedef $$MeasurableResultsTableCreateCompanionBuilder =
    MeasurableResultsCompanion Function({
      required String id,
      required String areaId,
      required String title,
      required MetricType metricType,
      Value<double?> targetValue,
      required Comparator comparator,
      required Cadence cadence,
      Value<int?> daysPerCadence,
      required Verification verification,
      Value<String?> unit,
      required DateTime startDate,
      Value<DateTime?> endDate,
      Value<DateTime?> originalEndDate,
      Value<int> deadlineMoves,
      Value<bool> active,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MeasurableResultsTableUpdateCompanionBuilder =
    MeasurableResultsCompanion Function({
      Value<String> id,
      Value<String> areaId,
      Value<String> title,
      Value<MetricType> metricType,
      Value<double?> targetValue,
      Value<Comparator> comparator,
      Value<Cadence> cadence,
      Value<int?> daysPerCadence,
      Value<Verification> verification,
      Value<String?> unit,
      Value<DateTime> startDate,
      Value<DateTime?> endDate,
      Value<DateTime?> originalEndDate,
      Value<int> deadlineMoves,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$MeasurableResultsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MeasurableResultsTable,
          MeasurableResult
        > {
  $$MeasurableResultsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AreasTable _areaIdTable(_$AppDatabase db) => db.areas.createAlias(
    $_aliasNameGenerator(db.measurableResults.areaId, db.areas.id),
  );

  $$AreasTableProcessedTableManager get areaId {
    final $_column = $_itemColumn<String>('area_id')!;

    final manager = $$AreasTableTableManager(
      $_db,
      $_db.areas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_areaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MeasurableLogsTable, List<MeasurableLog>>
  _measurableLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.measurableLogs,
    aliasName: $_aliasNameGenerator(
      db.measurableResults.id,
      db.measurableLogs.resultId,
    ),
  );

  $$MeasurableLogsTableProcessedTableManager get measurableLogsRefs {
    final manager = $$MeasurableLogsTableTableManager(
      $_db,
      $_db.measurableLogs,
    ).filter((f) => f.resultId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_measurableLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MeasurableResultsTableFilterComposer
    extends Composer<_$AppDatabase, $MeasurableResultsTable> {
  $$MeasurableResultsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MetricType, MetricType, String>
  get metricType => $composableBuilder(
    column: $table.metricType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Comparator, Comparator, String>
  get comparator => $composableBuilder(
    column: $table.comparator,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Cadence, Cadence, String> get cadence =>
      $composableBuilder(
        column: $table.cadence,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get daysPerCadence => $composableBuilder(
    column: $table.daysPerCadence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Verification, Verification, String>
  get verification => $composableBuilder(
    column: $table.verification,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get originalEndDate => $composableBuilder(
    column: $table.originalEndDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deadlineMoves => $composableBuilder(
    column: $table.deadlineMoves,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AreasTableFilterComposer get areaId {
    final $$AreasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.areaId,
      referencedTable: $db.areas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AreasTableFilterComposer(
            $db: $db,
            $table: $db.areas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> measurableLogsRefs(
    Expression<bool> Function($$MeasurableLogsTableFilterComposer f) f,
  ) {
    final $$MeasurableLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.measurableLogs,
      getReferencedColumn: (t) => t.resultId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurableLogsTableFilterComposer(
            $db: $db,
            $table: $db.measurableLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MeasurableResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeasurableResultsTable> {
  $$MeasurableResultsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metricType => $composableBuilder(
    column: $table.metricType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comparator => $composableBuilder(
    column: $table.comparator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cadence => $composableBuilder(
    column: $table.cadence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get daysPerCadence => $composableBuilder(
    column: $table.daysPerCadence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verification => $composableBuilder(
    column: $table.verification,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get originalEndDate => $composableBuilder(
    column: $table.originalEndDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deadlineMoves => $composableBuilder(
    column: $table.deadlineMoves,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AreasTableOrderingComposer get areaId {
    final $$AreasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.areaId,
      referencedTable: $db.areas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AreasTableOrderingComposer(
            $db: $db,
            $table: $db.areas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MeasurableResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeasurableResultsTable> {
  $$MeasurableResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MetricType, String> get metricType =>
      $composableBuilder(
        column: $table.metricType,
        builder: (column) => column,
      );

  GeneratedColumn<double> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Comparator, String> get comparator =>
      $composableBuilder(
        column: $table.comparator,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Cadence, String> get cadence =>
      $composableBuilder(column: $table.cadence, builder: (column) => column);

  GeneratedColumn<int> get daysPerCadence => $composableBuilder(
    column: $table.daysPerCadence,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Verification, String> get verification =>
      $composableBuilder(
        column: $table.verification,
        builder: (column) => column,
      );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<DateTime> get originalEndDate => $composableBuilder(
    column: $table.originalEndDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deadlineMoves => $composableBuilder(
    column: $table.deadlineMoves,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AreasTableAnnotationComposer get areaId {
    final $$AreasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.areaId,
      referencedTable: $db.areas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AreasTableAnnotationComposer(
            $db: $db,
            $table: $db.areas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> measurableLogsRefs<T extends Object>(
    Expression<T> Function($$MeasurableLogsTableAnnotationComposer a) f,
  ) {
    final $$MeasurableLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.measurableLogs,
      getReferencedColumn: (t) => t.resultId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurableLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.measurableLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MeasurableResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MeasurableResultsTable,
          MeasurableResult,
          $$MeasurableResultsTableFilterComposer,
          $$MeasurableResultsTableOrderingComposer,
          $$MeasurableResultsTableAnnotationComposer,
          $$MeasurableResultsTableCreateCompanionBuilder,
          $$MeasurableResultsTableUpdateCompanionBuilder,
          (MeasurableResult, $$MeasurableResultsTableReferences),
          MeasurableResult,
          PrefetchHooks Function({bool areaId, bool measurableLogsRefs})
        > {
  $$MeasurableResultsTableTableManager(
    _$AppDatabase db,
    $MeasurableResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeasurableResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeasurableResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeasurableResultsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> areaId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<MetricType> metricType = const Value.absent(),
                Value<double?> targetValue = const Value.absent(),
                Value<Comparator> comparator = const Value.absent(),
                Value<Cadence> cadence = const Value.absent(),
                Value<int?> daysPerCadence = const Value.absent(),
                Value<Verification> verification = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<DateTime?> originalEndDate = const Value.absent(),
                Value<int> deadlineMoves = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeasurableResultsCompanion(
                id: id,
                areaId: areaId,
                title: title,
                metricType: metricType,
                targetValue: targetValue,
                comparator: comparator,
                cadence: cadence,
                daysPerCadence: daysPerCadence,
                verification: verification,
                unit: unit,
                startDate: startDate,
                endDate: endDate,
                originalEndDate: originalEndDate,
                deadlineMoves: deadlineMoves,
                active: active,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String areaId,
                required String title,
                required MetricType metricType,
                Value<double?> targetValue = const Value.absent(),
                required Comparator comparator,
                required Cadence cadence,
                Value<int?> daysPerCadence = const Value.absent(),
                required Verification verification,
                Value<String?> unit = const Value.absent(),
                required DateTime startDate,
                Value<DateTime?> endDate = const Value.absent(),
                Value<DateTime?> originalEndDate = const Value.absent(),
                Value<int> deadlineMoves = const Value.absent(),
                Value<bool> active = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MeasurableResultsCompanion.insert(
                id: id,
                areaId: areaId,
                title: title,
                metricType: metricType,
                targetValue: targetValue,
                comparator: comparator,
                cadence: cadence,
                daysPerCadence: daysPerCadence,
                verification: verification,
                unit: unit,
                startDate: startDate,
                endDate: endDate,
                originalEndDate: originalEndDate,
                deadlineMoves: deadlineMoves,
                active: active,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MeasurableResultsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({areaId = false, measurableLogsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (measurableLogsRefs) db.measurableLogs,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (areaId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.areaId,
                                    referencedTable:
                                        $$MeasurableResultsTableReferences
                                            ._areaIdTable(db),
                                    referencedColumn:
                                        $$MeasurableResultsTableReferences
                                            ._areaIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (measurableLogsRefs)
                        await $_getPrefetchedData<
                          MeasurableResult,
                          $MeasurableResultsTable,
                          MeasurableLog
                        >(
                          currentTable: table,
                          referencedTable: $$MeasurableResultsTableReferences
                              ._measurableLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MeasurableResultsTableReferences(
                                db,
                                table,
                                p0,
                              ).measurableLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.resultId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MeasurableResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MeasurableResultsTable,
      MeasurableResult,
      $$MeasurableResultsTableFilterComposer,
      $$MeasurableResultsTableOrderingComposer,
      $$MeasurableResultsTableAnnotationComposer,
      $$MeasurableResultsTableCreateCompanionBuilder,
      $$MeasurableResultsTableUpdateCompanionBuilder,
      (MeasurableResult, $$MeasurableResultsTableReferences),
      MeasurableResult,
      PrefetchHooks Function({bool areaId, bool measurableLogsRefs})
    >;
typedef $$MeasurableLogsTableCreateCompanionBuilder =
    MeasurableLogsCompanion Function({
      required String id,
      required String resultId,
      required String date,
      required double value,
      Value<String?> note,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$MeasurableLogsTableUpdateCompanionBuilder =
    MeasurableLogsCompanion Function({
      Value<String> id,
      Value<String> resultId,
      Value<String> date,
      Value<double> value,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$MeasurableLogsTableReferences
    extends BaseReferences<_$AppDatabase, $MeasurableLogsTable, MeasurableLog> {
  $$MeasurableLogsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MeasurableResultsTable _resultIdTable(_$AppDatabase db) =>
      db.measurableResults.createAlias(
        $_aliasNameGenerator(
          db.measurableLogs.resultId,
          db.measurableResults.id,
        ),
      );

  $$MeasurableResultsTableProcessedTableManager get resultId {
    final $_column = $_itemColumn<String>('result_id')!;

    final manager = $$MeasurableResultsTableTableManager(
      $_db,
      $_db.measurableResults,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_resultIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MeasurableLogsTableFilterComposer
    extends Composer<_$AppDatabase, $MeasurableLogsTable> {
  $$MeasurableLogsTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MeasurableResultsTableFilterComposer get resultId {
    final $$MeasurableResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resultId,
      referencedTable: $db.measurableResults,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurableResultsTableFilterComposer(
            $db: $db,
            $table: $db.measurableResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MeasurableLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeasurableLogsTable> {
  $$MeasurableLogsTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MeasurableResultsTableOrderingComposer get resultId {
    final $$MeasurableResultsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resultId,
      referencedTable: $db.measurableResults,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeasurableResultsTableOrderingComposer(
            $db: $db,
            $table: $db.measurableResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MeasurableLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeasurableLogsTable> {
  $$MeasurableLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$MeasurableResultsTableAnnotationComposer get resultId {
    final $$MeasurableResultsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.resultId,
          referencedTable: $db.measurableResults,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MeasurableResultsTableAnnotationComposer(
                $db: $db,
                $table: $db.measurableResults,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$MeasurableLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MeasurableLogsTable,
          MeasurableLog,
          $$MeasurableLogsTableFilterComposer,
          $$MeasurableLogsTableOrderingComposer,
          $$MeasurableLogsTableAnnotationComposer,
          $$MeasurableLogsTableCreateCompanionBuilder,
          $$MeasurableLogsTableUpdateCompanionBuilder,
          (MeasurableLog, $$MeasurableLogsTableReferences),
          MeasurableLog,
          PrefetchHooks Function({bool resultId})
        > {
  $$MeasurableLogsTableTableManager(
    _$AppDatabase db,
    $MeasurableLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeasurableLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeasurableLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeasurableLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> resultId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeasurableLogsCompanion(
                id: id,
                resultId: resultId,
                date: date,
                value: value,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String resultId,
                required String date,
                required double value,
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MeasurableLogsCompanion.insert(
                id: id,
                resultId: resultId,
                date: date,
                value: value,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MeasurableLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({resultId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (resultId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.resultId,
                                referencedTable: $$MeasurableLogsTableReferences
                                    ._resultIdTable(db),
                                referencedColumn:
                                    $$MeasurableLogsTableReferences
                                        ._resultIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MeasurableLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MeasurableLogsTable,
      MeasurableLog,
      $$MeasurableLogsTableFilterComposer,
      $$MeasurableLogsTableOrderingComposer,
      $$MeasurableLogsTableAnnotationComposer,
      $$MeasurableLogsTableCreateCompanionBuilder,
      $$MeasurableLogsTableUpdateCompanionBuilder,
      (MeasurableLog, $$MeasurableLogsTableReferences),
      MeasurableLog,
      PrefetchHooks Function({bool resultId})
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      required String title,
      Value<String?> notes,
      Value<String?> areaId,
      Value<TaskStatus> status,
      Value<TaskKind?> kind,
      Value<String?> attachmentImagePath,
      Value<String?> documentLink,
      Value<DateTime?> scheduledStart,
      Value<int?> durationMin,
      Value<DateTime?> dueDate,
      Value<DateTime?> completedAt,
      Value<int?> timeToCompleteMin,
      Value<String?> rrule,
      Value<String?> parentRecurringId,
      Value<DateTime?> occurrenceSlot,
      Value<String?> parentEventId,
      Value<String?> reviewNotes,
      Value<String?> meetingLink,
      Value<MeetingProvider?> meetingProvider,
      Value<String?> locationName,
      Value<double?> lat,
      Value<double?> lng,
      Value<bool> geofenceEnabled,
      Value<List<int>?> reminderOffsets,
      Value<String?> gcalEventId,
      Value<String?> gcalCalendarId,
      Value<String?> gcalEtag,
      Value<DateTime?> lastSyncedAt,
      Value<TaskSource> source,
      Value<int> priority,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> notes,
      Value<String?> areaId,
      Value<TaskStatus> status,
      Value<TaskKind?> kind,
      Value<String?> attachmentImagePath,
      Value<String?> documentLink,
      Value<DateTime?> scheduledStart,
      Value<int?> durationMin,
      Value<DateTime?> dueDate,
      Value<DateTime?> completedAt,
      Value<int?> timeToCompleteMin,
      Value<String?> rrule,
      Value<String?> parentRecurringId,
      Value<DateTime?> occurrenceSlot,
      Value<String?> parentEventId,
      Value<String?> reviewNotes,
      Value<String?> meetingLink,
      Value<MeetingProvider?> meetingProvider,
      Value<String?> locationName,
      Value<double?> lat,
      Value<double?> lng,
      Value<bool> geofenceEnabled,
      Value<List<int>?> reminderOffsets,
      Value<String?> gcalEventId,
      Value<String?> gcalCalendarId,
      Value<String?> gcalEtag,
      Value<DateTime?> lastSyncedAt,
      Value<TaskSource> source,
      Value<int> priority,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AreasTable _areaIdTable(_$AppDatabase db) =>
      db.areas.createAlias($_aliasNameGenerator(db.tasks.areaId, db.areas.id));

  $$AreasTableProcessedTableManager? get areaId {
    final $_column = $_itemColumn<String>('area_id');
    if ($_column == null) return null;
    final manager = $$AreasTableTableManager(
      $_db,
      $_db.areas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_areaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TaskParticipantsTable, List<TaskParticipant>>
  _taskParticipantsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskParticipants,
    aliasName: $_aliasNameGenerator(db.tasks.id, db.taskParticipants.taskId),
  );

  $$TaskParticipantsTableProcessedTableManager get taskParticipantsRefs {
    final manager = $$TaskParticipantsTableTableManager(
      $_db,
      $_db.taskParticipants,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _taskParticipantsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskTransitionsTable, List<TaskTransition>>
  _taskTransitionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskTransitions,
    aliasName: $_aliasNameGenerator(db.tasks.id, db.taskTransitions.taskId),
  );

  $$TaskTransitionsTableProcessedTableManager get taskTransitionsRefs {
    final manager = $$TaskTransitionsTableTableManager(
      $_db,
      $_db.taskTransitions,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _taskTransitionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskStatus, TaskStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<TaskKind?, TaskKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get attachmentImagePath => $composableBuilder(
    column: $table.attachmentImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentLink => $composableBuilder(
    column: $table.documentLink,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledStart => $composableBuilder(
    column: $table.scheduledStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeToCompleteMin => $composableBuilder(
    column: $table.timeToCompleteMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentRecurringId => $composableBuilder(
    column: $table.parentRecurringId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurrenceSlot => $composableBuilder(
    column: $table.occurrenceSlot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentEventId => $composableBuilder(
    column: $table.parentEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewNotes => $composableBuilder(
    column: $table.reviewNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meetingLink => $composableBuilder(
    column: $table.meetingLink,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MeetingProvider?, MeetingProvider, String>
  get meetingProvider => $composableBuilder(
    column: $table.meetingProvider,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get geofenceEnabled => $composableBuilder(
    column: $table.geofenceEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<int>?, List<int>, String>
  get reminderOffsets => $composableBuilder(
    column: $table.reminderOffsets,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get gcalEventId => $composableBuilder(
    column: $table.gcalEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gcalCalendarId => $composableBuilder(
    column: $table.gcalCalendarId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gcalEtag => $composableBuilder(
    column: $table.gcalEtag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskSource, TaskSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AreasTableFilterComposer get areaId {
    final $$AreasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.areaId,
      referencedTable: $db.areas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AreasTableFilterComposer(
            $db: $db,
            $table: $db.areas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> taskParticipantsRefs(
    Expression<bool> Function($$TaskParticipantsTableFilterComposer f) f,
  ) {
    final $$TaskParticipantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskParticipants,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskParticipantsTableFilterComposer(
            $db: $db,
            $table: $db.taskParticipants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskTransitionsRefs(
    Expression<bool> Function($$TaskTransitionsTableFilterComposer f) f,
  ) {
    final $$TaskTransitionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTransitions,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTransitionsTableFilterComposer(
            $db: $db,
            $table: $db.taskTransitions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentImagePath => $composableBuilder(
    column: $table.attachmentImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentLink => $composableBuilder(
    column: $table.documentLink,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledStart => $composableBuilder(
    column: $table.scheduledStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeToCompleteMin => $composableBuilder(
    column: $table.timeToCompleteMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentRecurringId => $composableBuilder(
    column: $table.parentRecurringId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurrenceSlot => $composableBuilder(
    column: $table.occurrenceSlot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentEventId => $composableBuilder(
    column: $table.parentEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewNotes => $composableBuilder(
    column: $table.reviewNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meetingLink => $composableBuilder(
    column: $table.meetingLink,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meetingProvider => $composableBuilder(
    column: $table.meetingProvider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get geofenceEnabled => $composableBuilder(
    column: $table.geofenceEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderOffsets => $composableBuilder(
    column: $table.reminderOffsets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gcalEventId => $composableBuilder(
    column: $table.gcalEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gcalCalendarId => $composableBuilder(
    column: $table.gcalCalendarId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gcalEtag => $composableBuilder(
    column: $table.gcalEtag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AreasTableOrderingComposer get areaId {
    final $$AreasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.areaId,
      referencedTable: $db.areas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AreasTableOrderingComposer(
            $db: $db,
            $table: $db.areas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskKind?, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get attachmentImagePath => $composableBuilder(
    column: $table.attachmentImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documentLink => $composableBuilder(
    column: $table.documentLink,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledStart => $composableBuilder(
    column: $table.scheduledStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeToCompleteMin => $composableBuilder(
    column: $table.timeToCompleteMin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rrule =>
      $composableBuilder(column: $table.rrule, builder: (column) => column);

  GeneratedColumn<String> get parentRecurringId => $composableBuilder(
    column: $table.parentRecurringId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurrenceSlot => $composableBuilder(
    column: $table.occurrenceSlot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentEventId => $composableBuilder(
    column: $table.parentEventId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewNotes => $composableBuilder(
    column: $table.reviewNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get meetingLink => $composableBuilder(
    column: $table.meetingLink,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MeetingProvider?, String>
  get meetingProvider => $composableBuilder(
    column: $table.meetingProvider,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<bool> get geofenceEnabled => $composableBuilder(
    column: $table.geofenceEnabled,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<int>?, String> get reminderOffsets =>
      $composableBuilder(
        column: $table.reminderOffsets,
        builder: (column) => column,
      );

  GeneratedColumn<String> get gcalEventId => $composableBuilder(
    column: $table.gcalEventId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gcalCalendarId => $composableBuilder(
    column: $table.gcalCalendarId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gcalEtag =>
      $composableBuilder(column: $table.gcalEtag, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TaskSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$AreasTableAnnotationComposer get areaId {
    final $$AreasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.areaId,
      referencedTable: $db.areas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AreasTableAnnotationComposer(
            $db: $db,
            $table: $db.areas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> taskParticipantsRefs<T extends Object>(
    Expression<T> Function($$TaskParticipantsTableAnnotationComposer a) f,
  ) {
    final $$TaskParticipantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskParticipants,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskParticipantsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskParticipants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskTransitionsRefs<T extends Object>(
    Expression<T> Function($$TaskTransitionsTableAnnotationComposer a) f,
  ) {
    final $$TaskTransitionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTransitions,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTransitionsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskTransitions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, $$TasksTableReferences),
          Task,
          PrefetchHooks Function({
            bool areaId,
            bool taskParticipantsRefs,
            bool taskTransitionsRefs,
          })
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> areaId = const Value.absent(),
                Value<TaskStatus> status = const Value.absent(),
                Value<TaskKind?> kind = const Value.absent(),
                Value<String?> attachmentImagePath = const Value.absent(),
                Value<String?> documentLink = const Value.absent(),
                Value<DateTime?> scheduledStart = const Value.absent(),
                Value<int?> durationMin = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int?> timeToCompleteMin = const Value.absent(),
                Value<String?> rrule = const Value.absent(),
                Value<String?> parentRecurringId = const Value.absent(),
                Value<DateTime?> occurrenceSlot = const Value.absent(),
                Value<String?> parentEventId = const Value.absent(),
                Value<String?> reviewNotes = const Value.absent(),
                Value<String?> meetingLink = const Value.absent(),
                Value<MeetingProvider?> meetingProvider = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<bool> geofenceEnabled = const Value.absent(),
                Value<List<int>?> reminderOffsets = const Value.absent(),
                Value<String?> gcalEventId = const Value.absent(),
                Value<String?> gcalCalendarId = const Value.absent(),
                Value<String?> gcalEtag = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<TaskSource> source = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                notes: notes,
                areaId: areaId,
                status: status,
                kind: kind,
                attachmentImagePath: attachmentImagePath,
                documentLink: documentLink,
                scheduledStart: scheduledStart,
                durationMin: durationMin,
                dueDate: dueDate,
                completedAt: completedAt,
                timeToCompleteMin: timeToCompleteMin,
                rrule: rrule,
                parentRecurringId: parentRecurringId,
                occurrenceSlot: occurrenceSlot,
                parentEventId: parentEventId,
                reviewNotes: reviewNotes,
                meetingLink: meetingLink,
                meetingProvider: meetingProvider,
                locationName: locationName,
                lat: lat,
                lng: lng,
                geofenceEnabled: geofenceEnabled,
                reminderOffsets: reminderOffsets,
                gcalEventId: gcalEventId,
                gcalCalendarId: gcalCalendarId,
                gcalEtag: gcalEtag,
                lastSyncedAt: lastSyncedAt,
                source: source,
                priority: priority,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> notes = const Value.absent(),
                Value<String?> areaId = const Value.absent(),
                Value<TaskStatus> status = const Value.absent(),
                Value<TaskKind?> kind = const Value.absent(),
                Value<String?> attachmentImagePath = const Value.absent(),
                Value<String?> documentLink = const Value.absent(),
                Value<DateTime?> scheduledStart = const Value.absent(),
                Value<int?> durationMin = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int?> timeToCompleteMin = const Value.absent(),
                Value<String?> rrule = const Value.absent(),
                Value<String?> parentRecurringId = const Value.absent(),
                Value<DateTime?> occurrenceSlot = const Value.absent(),
                Value<String?> parentEventId = const Value.absent(),
                Value<String?> reviewNotes = const Value.absent(),
                Value<String?> meetingLink = const Value.absent(),
                Value<MeetingProvider?> meetingProvider = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<bool> geofenceEnabled = const Value.absent(),
                Value<List<int>?> reminderOffsets = const Value.absent(),
                Value<String?> gcalEventId = const Value.absent(),
                Value<String?> gcalCalendarId = const Value.absent(),
                Value<String?> gcalEtag = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<TaskSource> source = const Value.absent(),
                Value<int> priority = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                notes: notes,
                areaId: areaId,
                status: status,
                kind: kind,
                attachmentImagePath: attachmentImagePath,
                documentLink: documentLink,
                scheduledStart: scheduledStart,
                durationMin: durationMin,
                dueDate: dueDate,
                completedAt: completedAt,
                timeToCompleteMin: timeToCompleteMin,
                rrule: rrule,
                parentRecurringId: parentRecurringId,
                occurrenceSlot: occurrenceSlot,
                parentEventId: parentEventId,
                reviewNotes: reviewNotes,
                meetingLink: meetingLink,
                meetingProvider: meetingProvider,
                locationName: locationName,
                lat: lat,
                lng: lng,
                geofenceEnabled: geofenceEnabled,
                reminderOffsets: reminderOffsets,
                gcalEventId: gcalEventId,
                gcalCalendarId: gcalCalendarId,
                gcalEtag: gcalEtag,
                lastSyncedAt: lastSyncedAt,
                source: source,
                priority: priority,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TasksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                areaId = false,
                taskParticipantsRefs = false,
                taskTransitionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (taskParticipantsRefs) db.taskParticipants,
                    if (taskTransitionsRefs) db.taskTransitions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (areaId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.areaId,
                                    referencedTable: $$TasksTableReferences
                                        ._areaIdTable(db),
                                    referencedColumn: $$TasksTableReferences
                                        ._areaIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (taskParticipantsRefs)
                        await $_getPrefetchedData<
                          Task,
                          $TasksTable,
                          TaskParticipant
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._taskParticipantsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).taskParticipantsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskTransitionsRefs)
                        await $_getPrefetchedData<
                          Task,
                          $TasksTable,
                          TaskTransition
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._taskTransitionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).taskTransitionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, $$TasksTableReferences),
      Task,
      PrefetchHooks Function({
        bool areaId,
        bool taskParticipantsRefs,
        bool taskTransitionsRefs,
      })
    >;
typedef $$TaskParticipantsTableCreateCompanionBuilder =
    TaskParticipantsCompanion Function({
      required String id,
      required String taskId,
      required String contactLookupKey,
      required String displayName,
      Value<int> rowid,
    });
typedef $$TaskParticipantsTableUpdateCompanionBuilder =
    TaskParticipantsCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<String> contactLookupKey,
      Value<String> displayName,
      Value<int> rowid,
    });

final class $$TaskParticipantsTableReferences
    extends
        BaseReferences<_$AppDatabase, $TaskParticipantsTable, TaskParticipant> {
  $$TaskParticipantsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias(
    $_aliasNameGenerator(db.taskParticipants.taskId, db.tasks.id),
  );

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskParticipantsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskParticipantsTable> {
  $$TaskParticipantsTableFilterComposer({
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

  ColumnFilters<String> get contactLookupKey => $composableBuilder(
    column: $table.contactLookupKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskParticipantsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskParticipantsTable> {
  $$TaskParticipantsTableOrderingComposer({
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

  ColumnOrderings<String> get contactLookupKey => $composableBuilder(
    column: $table.contactLookupKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskParticipantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskParticipantsTable> {
  $$TaskParticipantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contactLookupKey => $composableBuilder(
    column: $table.contactLookupKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskParticipantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskParticipantsTable,
          TaskParticipant,
          $$TaskParticipantsTableFilterComposer,
          $$TaskParticipantsTableOrderingComposer,
          $$TaskParticipantsTableAnnotationComposer,
          $$TaskParticipantsTableCreateCompanionBuilder,
          $$TaskParticipantsTableUpdateCompanionBuilder,
          (TaskParticipant, $$TaskParticipantsTableReferences),
          TaskParticipant,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskParticipantsTableTableManager(
    _$AppDatabase db,
    $TaskParticipantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskParticipantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskParticipantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskParticipantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> contactLookupKey = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskParticipantsCompanion(
                id: id,
                taskId: taskId,
                contactLookupKey: contactLookupKey,
                displayName: displayName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required String contactLookupKey,
                required String displayName,
                Value<int> rowid = const Value.absent(),
              }) => TaskParticipantsCompanion.insert(
                id: id,
                taskId: taskId,
                contactLookupKey: contactLookupKey,
                displayName: displayName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskParticipantsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable:
                                    $$TaskParticipantsTableReferences
                                        ._taskIdTable(db),
                                referencedColumn:
                                    $$TaskParticipantsTableReferences
                                        ._taskIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskParticipantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskParticipantsTable,
      TaskParticipant,
      $$TaskParticipantsTableFilterComposer,
      $$TaskParticipantsTableOrderingComposer,
      $$TaskParticipantsTableAnnotationComposer,
      $$TaskParticipantsTableCreateCompanionBuilder,
      $$TaskParticipantsTableUpdateCompanionBuilder,
      (TaskParticipant, $$TaskParticipantsTableReferences),
      TaskParticipant,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$TaskTransitionsTableCreateCompanionBuilder =
    TaskTransitionsCompanion Function({
      required String id,
      required String taskId,
      Value<TaskStatus?> fromStatus,
      required TaskStatus toStatus,
      required DateTime at,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$TaskTransitionsTableUpdateCompanionBuilder =
    TaskTransitionsCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<TaskStatus?> fromStatus,
      Value<TaskStatus> toStatus,
      Value<DateTime> at,
      Value<String?> note,
      Value<int> rowid,
    });

final class $$TaskTransitionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $TaskTransitionsTable, TaskTransition> {
  $$TaskTransitionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias(
    $_aliasNameGenerator(db.taskTransitions.taskId, db.tasks.id),
  );

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskTransitionsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskTransitionsTable> {
  $$TaskTransitionsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<TaskStatus?, TaskStatus, String>
  get fromStatus => $composableBuilder(
    column: $table.fromStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskStatus, TaskStatus, String> get toStatus =>
      $composableBuilder(
        column: $table.toStatus,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskTransitionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskTransitionsTable> {
  $$TaskTransitionsTableOrderingComposer({
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

  ColumnOrderings<String> get fromStatus => $composableBuilder(
    column: $table.fromStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toStatus => $composableBuilder(
    column: $table.toStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskTransitionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskTransitionsTable> {
  $$TaskTransitionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskStatus?, String> get fromStatus =>
      $composableBuilder(
        column: $table.fromStatus,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<TaskStatus, String> get toStatus =>
      $composableBuilder(column: $table.toStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskTransitionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskTransitionsTable,
          TaskTransition,
          $$TaskTransitionsTableFilterComposer,
          $$TaskTransitionsTableOrderingComposer,
          $$TaskTransitionsTableAnnotationComposer,
          $$TaskTransitionsTableCreateCompanionBuilder,
          $$TaskTransitionsTableUpdateCompanionBuilder,
          (TaskTransition, $$TaskTransitionsTableReferences),
          TaskTransition,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskTransitionsTableTableManager(
    _$AppDatabase db,
    $TaskTransitionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskTransitionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskTransitionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskTransitionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<TaskStatus?> fromStatus = const Value.absent(),
                Value<TaskStatus> toStatus = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskTransitionsCompanion(
                id: id,
                taskId: taskId,
                fromStatus: fromStatus,
                toStatus: toStatus,
                at: at,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                Value<TaskStatus?> fromStatus = const Value.absent(),
                required TaskStatus toStatus,
                required DateTime at,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskTransitionsCompanion.insert(
                id: id,
                taskId: taskId,
                fromStatus: fromStatus,
                toStatus: toStatus,
                at: at,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskTransitionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable:
                                    $$TaskTransitionsTableReferences
                                        ._taskIdTable(db),
                                referencedColumn:
                                    $$TaskTransitionsTableReferences
                                        ._taskIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskTransitionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskTransitionsTable,
      TaskTransition,
      $$TaskTransitionsTableFilterComposer,
      $$TaskTransitionsTableOrderingComposer,
      $$TaskTransitionsTableAnnotationComposer,
      $$TaskTransitionsTableCreateCompanionBuilder,
      $$TaskTransitionsTableUpdateCompanionBuilder,
      (TaskTransition, $$TaskTransitionsTableReferences),
      TaskTransition,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$CapturesTableCreateCompanionBuilder =
    CapturesCompanion Function({
      required String id,
      required CaptureType type,
      Value<String?> mediaPath,
      Value<String?> textContent,
      Value<String?> caption,
      Value<int?> durationSec,
      Value<int> sizeBytes,
      required AttachedType attachedType,
      required String attachedId,
      Value<bool> archived,
      Value<String?> archiveUri,
      Value<String?> thumbnailPath,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CapturesTableUpdateCompanionBuilder =
    CapturesCompanion Function({
      Value<String> id,
      Value<CaptureType> type,
      Value<String?> mediaPath,
      Value<String?> textContent,
      Value<String?> caption,
      Value<int?> durationSec,
      Value<int> sizeBytes,
      Value<AttachedType> attachedType,
      Value<String> attachedId,
      Value<bool> archived,
      Value<String?> archiveUri,
      Value<String?> thumbnailPath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CapturesTableFilterComposer
    extends Composer<_$AppDatabase, $CapturesTable> {
  $$CapturesTableFilterComposer({
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

  ColumnWithTypeConverterFilters<CaptureType, CaptureType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get mediaPath => $composableBuilder(
    column: $table.mediaPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AttachedType, AttachedType, String>
  get attachedType => $composableBuilder(
    column: $table.attachedType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get attachedId => $composableBuilder(
    column: $table.attachedId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get archiveUri => $composableBuilder(
    column: $table.archiveUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CapturesTableOrderingComposer
    extends Composer<_$AppDatabase, $CapturesTable> {
  $$CapturesTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaPath => $composableBuilder(
    column: $table.mediaPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachedType => $composableBuilder(
    column: $table.attachedType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachedId => $composableBuilder(
    column: $table.attachedId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get archiveUri => $composableBuilder(
    column: $table.archiveUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CapturesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CapturesTable> {
  $$CapturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CaptureType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get mediaPath =>
      $composableBuilder(column: $table.mediaPath, builder: (column) => column);

  GeneratedColumn<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AttachedType, String> get attachedType =>
      $composableBuilder(
        column: $table.attachedType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get attachedId => $composableBuilder(
    column: $table.attachedId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get archiveUri => $composableBuilder(
    column: $table.archiveUri,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CapturesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CapturesTable,
          Capture,
          $$CapturesTableFilterComposer,
          $$CapturesTableOrderingComposer,
          $$CapturesTableAnnotationComposer,
          $$CapturesTableCreateCompanionBuilder,
          $$CapturesTableUpdateCompanionBuilder,
          (Capture, BaseReferences<_$AppDatabase, $CapturesTable, Capture>),
          Capture,
          PrefetchHooks Function()
        > {
  $$CapturesTableTableManager(_$AppDatabase db, $CapturesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CapturesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CapturesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CapturesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<CaptureType> type = const Value.absent(),
                Value<String?> mediaPath = const Value.absent(),
                Value<String?> textContent = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<AttachedType> attachedType = const Value.absent(),
                Value<String> attachedId = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String?> archiveUri = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CapturesCompanion(
                id: id,
                type: type,
                mediaPath: mediaPath,
                textContent: textContent,
                caption: caption,
                durationSec: durationSec,
                sizeBytes: sizeBytes,
                attachedType: attachedType,
                attachedId: attachedId,
                archived: archived,
                archiveUri: archiveUri,
                thumbnailPath: thumbnailPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required CaptureType type,
                Value<String?> mediaPath = const Value.absent(),
                Value<String?> textContent = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                required AttachedType attachedType,
                required String attachedId,
                Value<bool> archived = const Value.absent(),
                Value<String?> archiveUri = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CapturesCompanion.insert(
                id: id,
                type: type,
                mediaPath: mediaPath,
                textContent: textContent,
                caption: caption,
                durationSec: durationSec,
                sizeBytes: sizeBytes,
                attachedType: attachedType,
                attachedId: attachedId,
                archived: archived,
                archiveUri: archiveUri,
                thumbnailPath: thumbnailPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CapturesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CapturesTable,
      Capture,
      $$CapturesTableFilterComposer,
      $$CapturesTableOrderingComposer,
      $$CapturesTableAnnotationComposer,
      $$CapturesTableCreateCompanionBuilder,
      $$CapturesTableUpdateCompanionBuilder,
      (Capture, BaseReferences<_$AppDatabase, $CapturesTable, Capture>),
      Capture,
      PrefetchHooks Function()
    >;
typedef $$CommittedListenersTableCreateCompanionBuilder =
    CommittedListenersCompanion Function({
      required String id,
      required String contactLookupKey,
      required String displayName,
      required ListenerChannel channel,
      Value<String?> email,
      required ListenerScope scope,
      Value<String?> scopeId,
      required ListenerFrequency frequency,
      Value<bool> includeCaptures,
      required DateTime consentConfirmedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CommittedListenersTableUpdateCompanionBuilder =
    CommittedListenersCompanion Function({
      Value<String> id,
      Value<String> contactLookupKey,
      Value<String> displayName,
      Value<ListenerChannel> channel,
      Value<String?> email,
      Value<ListenerScope> scope,
      Value<String?> scopeId,
      Value<ListenerFrequency> frequency,
      Value<bool> includeCaptures,
      Value<DateTime> consentConfirmedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CommittedListenersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CommittedListenersTable,
          CommittedListener
        > {
  $$CommittedListenersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ListenerFeedbacksTable, List<ListenerFeedback>>
  _listenerFeedbacksRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.listenerFeedbacks,
        aliasName: $_aliasNameGenerator(
          db.committedListeners.id,
          db.listenerFeedbacks.listenerId,
        ),
      );

  $$ListenerFeedbacksTableProcessedTableManager get listenerFeedbacksRefs {
    final manager = $$ListenerFeedbacksTableTableManager(
      $_db,
      $_db.listenerFeedbacks,
    ).filter((f) => f.listenerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _listenerFeedbacksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CommittedListenersTableFilterComposer
    extends Composer<_$AppDatabase, $CommittedListenersTable> {
  $$CommittedListenersTableFilterComposer({
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

  ColumnFilters<String> get contactLookupKey => $composableBuilder(
    column: $table.contactLookupKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ListenerChannel, ListenerChannel, String>
  get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ListenerScope, ListenerScope, String>
  get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ListenerFrequency, ListenerFrequency, String>
  get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get includeCaptures => $composableBuilder(
    column: $table.includeCaptures,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get consentConfirmedAt => $composableBuilder(
    column: $table.consentConfirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> listenerFeedbacksRefs(
    Expression<bool> Function($$ListenerFeedbacksTableFilterComposer f) f,
  ) {
    final $$ListenerFeedbacksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listenerFeedbacks,
      getReferencedColumn: (t) => t.listenerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListenerFeedbacksTableFilterComposer(
            $db: $db,
            $table: $db.listenerFeedbacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CommittedListenersTableOrderingComposer
    extends Composer<_$AppDatabase, $CommittedListenersTable> {
  $$CommittedListenersTableOrderingComposer({
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

  ColumnOrderings<String> get contactLookupKey => $composableBuilder(
    column: $table.contactLookupKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get includeCaptures => $composableBuilder(
    column: $table.includeCaptures,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get consentConfirmedAt => $composableBuilder(
    column: $table.consentConfirmedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CommittedListenersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CommittedListenersTable> {
  $$CommittedListenersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contactLookupKey => $composableBuilder(
    column: $table.contactLookupKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ListenerChannel, String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ListenerScope, String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ListenerFrequency, String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<bool> get includeCaptures => $composableBuilder(
    column: $table.includeCaptures,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get consentConfirmedAt => $composableBuilder(
    column: $table.consentConfirmedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> listenerFeedbacksRefs<T extends Object>(
    Expression<T> Function($$ListenerFeedbacksTableAnnotationComposer a) f,
  ) {
    final $$ListenerFeedbacksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.listenerFeedbacks,
          getReferencedColumn: (t) => t.listenerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ListenerFeedbacksTableAnnotationComposer(
                $db: $db,
                $table: $db.listenerFeedbacks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CommittedListenersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CommittedListenersTable,
          CommittedListener,
          $$CommittedListenersTableFilterComposer,
          $$CommittedListenersTableOrderingComposer,
          $$CommittedListenersTableAnnotationComposer,
          $$CommittedListenersTableCreateCompanionBuilder,
          $$CommittedListenersTableUpdateCompanionBuilder,
          (CommittedListener, $$CommittedListenersTableReferences),
          CommittedListener,
          PrefetchHooks Function({bool listenerFeedbacksRefs})
        > {
  $$CommittedListenersTableTableManager(
    _$AppDatabase db,
    $CommittedListenersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CommittedListenersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CommittedListenersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CommittedListenersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> contactLookupKey = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<ListenerChannel> channel = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<ListenerScope> scope = const Value.absent(),
                Value<String?> scopeId = const Value.absent(),
                Value<ListenerFrequency> frequency = const Value.absent(),
                Value<bool> includeCaptures = const Value.absent(),
                Value<DateTime> consentConfirmedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommittedListenersCompanion(
                id: id,
                contactLookupKey: contactLookupKey,
                displayName: displayName,
                channel: channel,
                email: email,
                scope: scope,
                scopeId: scopeId,
                frequency: frequency,
                includeCaptures: includeCaptures,
                consentConfirmedAt: consentConfirmedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String contactLookupKey,
                required String displayName,
                required ListenerChannel channel,
                Value<String?> email = const Value.absent(),
                required ListenerScope scope,
                Value<String?> scopeId = const Value.absent(),
                required ListenerFrequency frequency,
                Value<bool> includeCaptures = const Value.absent(),
                required DateTime consentConfirmedAt,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CommittedListenersCompanion.insert(
                id: id,
                contactLookupKey: contactLookupKey,
                displayName: displayName,
                channel: channel,
                email: email,
                scope: scope,
                scopeId: scopeId,
                frequency: frequency,
                includeCaptures: includeCaptures,
                consentConfirmedAt: consentConfirmedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CommittedListenersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({listenerFeedbacksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (listenerFeedbacksRefs) db.listenerFeedbacks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (listenerFeedbacksRefs)
                    await $_getPrefetchedData<
                      CommittedListener,
                      $CommittedListenersTable,
                      ListenerFeedback
                    >(
                      currentTable: table,
                      referencedTable: $$CommittedListenersTableReferences
                          ._listenerFeedbacksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CommittedListenersTableReferences(
                            db,
                            table,
                            p0,
                          ).listenerFeedbacksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.listenerId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CommittedListenersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CommittedListenersTable,
      CommittedListener,
      $$CommittedListenersTableFilterComposer,
      $$CommittedListenersTableOrderingComposer,
      $$CommittedListenersTableAnnotationComposer,
      $$CommittedListenersTableCreateCompanionBuilder,
      $$CommittedListenersTableUpdateCompanionBuilder,
      (CommittedListener, $$CommittedListenersTableReferences),
      CommittedListener,
      PrefetchHooks Function({bool listenerFeedbacksRefs})
    >;
typedef $$ListenerFeedbacksTableCreateCompanionBuilder =
    ListenerFeedbacksCompanion Function({
      required String id,
      required String listenerId,
      required int ratingPct,
      Value<String?> comment,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ListenerFeedbacksTableUpdateCompanionBuilder =
    ListenerFeedbacksCompanion Function({
      Value<String> id,
      Value<String> listenerId,
      Value<int> ratingPct,
      Value<String?> comment,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ListenerFeedbacksTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ListenerFeedbacksTable,
          ListenerFeedback
        > {
  $$ListenerFeedbacksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CommittedListenersTable _listenerIdTable(_$AppDatabase db) =>
      db.committedListeners.createAlias(
        $_aliasNameGenerator(
          db.listenerFeedbacks.listenerId,
          db.committedListeners.id,
        ),
      );

  $$CommittedListenersTableProcessedTableManager get listenerId {
    final $_column = $_itemColumn<String>('listener_id')!;

    final manager = $$CommittedListenersTableTableManager(
      $_db,
      $_db.committedListeners,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listenerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ListenerFeedbacksTableFilterComposer
    extends Composer<_$AppDatabase, $ListenerFeedbacksTable> {
  $$ListenerFeedbacksTableFilterComposer({
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

  ColumnFilters<int> get ratingPct => $composableBuilder(
    column: $table.ratingPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CommittedListenersTableFilterComposer get listenerId {
    final $$CommittedListenersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listenerId,
      referencedTable: $db.committedListeners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommittedListenersTableFilterComposer(
            $db: $db,
            $table: $db.committedListeners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListenerFeedbacksTableOrderingComposer
    extends Composer<_$AppDatabase, $ListenerFeedbacksTable> {
  $$ListenerFeedbacksTableOrderingComposer({
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

  ColumnOrderings<int> get ratingPct => $composableBuilder(
    column: $table.ratingPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CommittedListenersTableOrderingComposer get listenerId {
    final $$CommittedListenersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listenerId,
      referencedTable: $db.committedListeners,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CommittedListenersTableOrderingComposer(
            $db: $db,
            $table: $db.committedListeners,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListenerFeedbacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListenerFeedbacksTable> {
  $$ListenerFeedbacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ratingPct =>
      $composableBuilder(column: $table.ratingPct, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CommittedListenersTableAnnotationComposer get listenerId {
    final $$CommittedListenersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.listenerId,
          referencedTable: $db.committedListeners,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CommittedListenersTableAnnotationComposer(
                $db: $db,
                $table: $db.committedListeners,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ListenerFeedbacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ListenerFeedbacksTable,
          ListenerFeedback,
          $$ListenerFeedbacksTableFilterComposer,
          $$ListenerFeedbacksTableOrderingComposer,
          $$ListenerFeedbacksTableAnnotationComposer,
          $$ListenerFeedbacksTableCreateCompanionBuilder,
          $$ListenerFeedbacksTableUpdateCompanionBuilder,
          (ListenerFeedback, $$ListenerFeedbacksTableReferences),
          ListenerFeedback,
          PrefetchHooks Function({bool listenerId})
        > {
  $$ListenerFeedbacksTableTableManager(
    _$AppDatabase db,
    $ListenerFeedbacksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListenerFeedbacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListenerFeedbacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListenerFeedbacksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> listenerId = const Value.absent(),
                Value<int> ratingPct = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListenerFeedbacksCompanion(
                id: id,
                listenerId: listenerId,
                ratingPct: ratingPct,
                comment: comment,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String listenerId,
                required int ratingPct,
                Value<String?> comment = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ListenerFeedbacksCompanion.insert(
                id: id,
                listenerId: listenerId,
                ratingPct: ratingPct,
                comment: comment,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ListenerFeedbacksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({listenerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (listenerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.listenerId,
                                referencedTable:
                                    $$ListenerFeedbacksTableReferences
                                        ._listenerIdTable(db),
                                referencedColumn:
                                    $$ListenerFeedbacksTableReferences
                                        ._listenerIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ListenerFeedbacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ListenerFeedbacksTable,
      ListenerFeedback,
      $$ListenerFeedbacksTableFilterComposer,
      $$ListenerFeedbacksTableOrderingComposer,
      $$ListenerFeedbacksTableAnnotationComposer,
      $$ListenerFeedbacksTableCreateCompanionBuilder,
      $$ListenerFeedbacksTableUpdateCompanionBuilder,
      (ListenerFeedback, $$ListenerFeedbacksTableReferences),
      ListenerFeedback,
      PrefetchHooks Function({bool listenerId})
    >;
typedef $$SaaraGroupsTableCreateCompanionBuilder =
    SaaraGroupsCompanion Function({
      required String id,
      required String name,
      required List<String> memberLookupKeys,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SaaraGroupsTableUpdateCompanionBuilder =
    SaaraGroupsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<List<String>> memberLookupKeys,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SaaraGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $SaaraGroupsTable> {
  $$SaaraGroupsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get memberLookupKeys => $composableBuilder(
    column: $table.memberLookupKeys,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SaaraGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $SaaraGroupsTable> {
  $$SaaraGroupsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberLookupKeys => $composableBuilder(
    column: $table.memberLookupKeys,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SaaraGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SaaraGroupsTable> {
  $$SaaraGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get memberLookupKeys =>
      $composableBuilder(
        column: $table.memberLookupKeys,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SaaraGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SaaraGroupsTable,
          SaaraGroup,
          $$SaaraGroupsTableFilterComposer,
          $$SaaraGroupsTableOrderingComposer,
          $$SaaraGroupsTableAnnotationComposer,
          $$SaaraGroupsTableCreateCompanionBuilder,
          $$SaaraGroupsTableUpdateCompanionBuilder,
          (
            SaaraGroup,
            BaseReferences<_$AppDatabase, $SaaraGroupsTable, SaaraGroup>,
          ),
          SaaraGroup,
          PrefetchHooks Function()
        > {
  $$SaaraGroupsTableTableManager(_$AppDatabase db, $SaaraGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SaaraGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SaaraGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SaaraGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<List<String>> memberLookupKeys = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SaaraGroupsCompanion(
                id: id,
                name: name,
                memberLookupKeys: memberLookupKeys,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required List<String> memberLookupKeys,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SaaraGroupsCompanion.insert(
                id: id,
                name: name,
                memberLookupKeys: memberLookupKeys,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SaaraGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SaaraGroupsTable,
      SaaraGroup,
      $$SaaraGroupsTableFilterComposer,
      $$SaaraGroupsTableOrderingComposer,
      $$SaaraGroupsTableAnnotationComposer,
      $$SaaraGroupsTableCreateCompanionBuilder,
      $$SaaraGroupsTableUpdateCompanionBuilder,
      (
        SaaraGroup,
        BaseReferences<_$AppDatabase, $SaaraGroupsTable, SaaraGroup>,
      ),
      SaaraGroup,
      PrefetchHooks Function()
    >;
typedef $$DayLogsTableCreateCompanionBuilder =
    DayLogsCompanion Function({
      required String date,
      Value<DateTime?> openedAt,
      Value<DateTime?> committedAt,
      Value<DateTime?> closedAt,
      Value<String?> reflectionCaptureId,
      Value<int> rowid,
    });
typedef $$DayLogsTableUpdateCompanionBuilder =
    DayLogsCompanion Function({
      Value<String> date,
      Value<DateTime?> openedAt,
      Value<DateTime?> committedAt,
      Value<DateTime?> closedAt,
      Value<String?> reflectionCaptureId,
      Value<int> rowid,
    });

class $$DayLogsTableFilterComposer
    extends Composer<_$AppDatabase, $DayLogsTable> {
  $$DayLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reflectionCaptureId => $composableBuilder(
    column: $table.reflectionCaptureId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $DayLogsTable> {
  $$DayLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reflectionCaptureId => $composableBuilder(
    column: $table.reflectionCaptureId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayLogsTable> {
  $$DayLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<String> get reflectionCaptureId => $composableBuilder(
    column: $table.reflectionCaptureId,
    builder: (column) => column,
  );
}

class $$DayLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayLogsTable,
          DayLog,
          $$DayLogsTableFilterComposer,
          $$DayLogsTableOrderingComposer,
          $$DayLogsTableAnnotationComposer,
          $$DayLogsTableCreateCompanionBuilder,
          $$DayLogsTableUpdateCompanionBuilder,
          (DayLog, BaseReferences<_$AppDatabase, $DayLogsTable, DayLog>),
          DayLog,
          PrefetchHooks Function()
        > {
  $$DayLogsTableTableManager(_$AppDatabase db, $DayLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<DateTime?> openedAt = const Value.absent(),
                Value<DateTime?> committedAt = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<String?> reflectionCaptureId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayLogsCompanion(
                date: date,
                openedAt: openedAt,
                committedAt: committedAt,
                closedAt: closedAt,
                reflectionCaptureId: reflectionCaptureId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                Value<DateTime?> openedAt = const Value.absent(),
                Value<DateTime?> committedAt = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<String?> reflectionCaptureId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayLogsCompanion.insert(
                date: date,
                openedAt: openedAt,
                committedAt: committedAt,
                closedAt: closedAt,
                reflectionCaptureId: reflectionCaptureId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayLogsTable,
      DayLog,
      $$DayLogsTableFilterComposer,
      $$DayLogsTableOrderingComposer,
      $$DayLogsTableAnnotationComposer,
      $$DayLogsTableCreateCompanionBuilder,
      $$DayLogsTableUpdateCompanionBuilder,
      (DayLog, BaseReferences<_$AppDatabase, $DayLogsTable, DayLog>),
      DayLog,
      PrefetchHooks Function()
    >;
typedef $$HealthSnapshotsTableCreateCompanionBuilder =
    HealthSnapshotsCompanion Function({
      required String date,
      required String metric,
      required double value,
      Value<int> rowid,
    });
typedef $$HealthSnapshotsTableUpdateCompanionBuilder =
    HealthSnapshotsCompanion Function({
      Value<String> date,
      Value<String> metric,
      Value<double> value,
      Value<int> rowid,
    });

class $$HealthSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $HealthSnapshotsTable> {
  $$HealthSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HealthSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $HealthSnapshotsTable> {
  $$HealthSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HealthSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HealthSnapshotsTable> {
  $$HealthSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get metric =>
      $composableBuilder(column: $table.metric, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$HealthSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HealthSnapshotsTable,
          HealthSnapshot,
          $$HealthSnapshotsTableFilterComposer,
          $$HealthSnapshotsTableOrderingComposer,
          $$HealthSnapshotsTableAnnotationComposer,
          $$HealthSnapshotsTableCreateCompanionBuilder,
          $$HealthSnapshotsTableUpdateCompanionBuilder,
          (
            HealthSnapshot,
            BaseReferences<
              _$AppDatabase,
              $HealthSnapshotsTable,
              HealthSnapshot
            >,
          ),
          HealthSnapshot,
          PrefetchHooks Function()
        > {
  $$HealthSnapshotsTableTableManager(
    _$AppDatabase db,
    $HealthSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<String> metric = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthSnapshotsCompanion(
                date: date,
                metric: metric,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required String metric,
                required double value,
                Value<int> rowid = const Value.absent(),
              }) => HealthSnapshotsCompanion.insert(
                date: date,
                metric: metric,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HealthSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HealthSnapshotsTable,
      HealthSnapshot,
      $$HealthSnapshotsTableFilterComposer,
      $$HealthSnapshotsTableOrderingComposer,
      $$HealthSnapshotsTableAnnotationComposer,
      $$HealthSnapshotsTableCreateCompanionBuilder,
      $$HealthSnapshotsTableUpdateCompanionBuilder,
      (
        HealthSnapshot,
        BaseReferences<_$AppDatabase, $HealthSnapshotsTable, HealthSnapshot>,
      ),
      HealthSnapshot,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      Value<String?> value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String?> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$ApiCredentialsTableCreateCompanionBuilder =
    ApiCredentialsCompanion Function({
      required String provider,
      required String keyAlias,
      Value<int> rowid,
    });
typedef $$ApiCredentialsTableUpdateCompanionBuilder =
    ApiCredentialsCompanion Function({
      Value<String> provider,
      Value<String> keyAlias,
      Value<int> rowid,
    });

class $$ApiCredentialsTableFilterComposer
    extends Composer<_$AppDatabase, $ApiCredentialsTable> {
  $$ApiCredentialsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyAlias => $composableBuilder(
    column: $table.keyAlias,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ApiCredentialsTableOrderingComposer
    extends Composer<_$AppDatabase, $ApiCredentialsTable> {
  $$ApiCredentialsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyAlias => $composableBuilder(
    column: $table.keyAlias,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ApiCredentialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApiCredentialsTable> {
  $$ApiCredentialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get keyAlias =>
      $composableBuilder(column: $table.keyAlias, builder: (column) => column);
}

class $$ApiCredentialsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ApiCredentialsTable,
          ApiCredential,
          $$ApiCredentialsTableFilterComposer,
          $$ApiCredentialsTableOrderingComposer,
          $$ApiCredentialsTableAnnotationComposer,
          $$ApiCredentialsTableCreateCompanionBuilder,
          $$ApiCredentialsTableUpdateCompanionBuilder,
          (
            ApiCredential,
            BaseReferences<_$AppDatabase, $ApiCredentialsTable, ApiCredential>,
          ),
          ApiCredential,
          PrefetchHooks Function()
        > {
  $$ApiCredentialsTableTableManager(
    _$AppDatabase db,
    $ApiCredentialsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApiCredentialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApiCredentialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApiCredentialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> provider = const Value.absent(),
                Value<String> keyAlias = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiCredentialsCompanion(
                provider: provider,
                keyAlias: keyAlias,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String provider,
                required String keyAlias,
                Value<int> rowid = const Value.absent(),
              }) => ApiCredentialsCompanion.insert(
                provider: provider,
                keyAlias: keyAlias,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ApiCredentialsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ApiCredentialsTable,
      ApiCredential,
      $$ApiCredentialsTableFilterComposer,
      $$ApiCredentialsTableOrderingComposer,
      $$ApiCredentialsTableAnnotationComposer,
      $$ApiCredentialsTableCreateCompanionBuilder,
      $$ApiCredentialsTableUpdateCompanionBuilder,
      (
        ApiCredential,
        BaseReferences<_$AppDatabase, $ApiCredentialsTable, ApiCredential>,
      ),
      ApiCredential,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AreasTableTableManager get areas =>
      $$AreasTableTableManager(_db, _db.areas);
  $$MeasurableResultsTableTableManager get measurableResults =>
      $$MeasurableResultsTableTableManager(_db, _db.measurableResults);
  $$MeasurableLogsTableTableManager get measurableLogs =>
      $$MeasurableLogsTableTableManager(_db, _db.measurableLogs);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$TaskParticipantsTableTableManager get taskParticipants =>
      $$TaskParticipantsTableTableManager(_db, _db.taskParticipants);
  $$TaskTransitionsTableTableManager get taskTransitions =>
      $$TaskTransitionsTableTableManager(_db, _db.taskTransitions);
  $$CapturesTableTableManager get captures =>
      $$CapturesTableTableManager(_db, _db.captures);
  $$CommittedListenersTableTableManager get committedListeners =>
      $$CommittedListenersTableTableManager(_db, _db.committedListeners);
  $$ListenerFeedbacksTableTableManager get listenerFeedbacks =>
      $$ListenerFeedbacksTableTableManager(_db, _db.listenerFeedbacks);
  $$SaaraGroupsTableTableManager get saaraGroups =>
      $$SaaraGroupsTableTableManager(_db, _db.saaraGroups);
  $$DayLogsTableTableManager get dayLogs =>
      $$DayLogsTableTableManager(_db, _db.dayLogs);
  $$HealthSnapshotsTableTableManager get healthSnapshots =>
      $$HealthSnapshotsTableTableManager(_db, _db.healthSnapshots);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$ApiCredentialsTableTableManager get apiCredentials =>
      $$ApiCredentialsTableTableManager(_db, _db.apiCredentials);
}
