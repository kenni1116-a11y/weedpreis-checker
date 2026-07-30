import type {
  AdapterBatch,
  AdapterRecord,
  AssertionTrace,
  JsonValue,
  NormalizedAssertion,
  SourceEvidence,
  ValidatedAdapterBatch,
} from "./types.ts";

type UnknownRecord = Record<string, unknown>;

const timestampPattern =
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,9})?(?:Z|[+-]\d{2}:\d{2})$/;
const sha256Pattern = /^[0-9a-f]{64}$/;
const sourceIdPattern = /^[a-z0-9][a-z0-9._-]{2,79}$/;
const productForms = ["flower", "extract", "oil", "other"] as const;

function invalid(path: string, reason: string): never {
  throw new Error(`Invalid adapter batch at ${path}: ${reason}`);
}

function recordAt(value: unknown, path: string): UnknownRecord {
  if (
    typeof value !== "object" ||
    value === null ||
    Array.isArray(value) ||
    (
      Object.getPrototypeOf(value) !== Object.prototype &&
      Object.getPrototypeOf(value) !== null
    )
  ) {
    invalid(path, "expected an object");
  }
  return value as UnknownRecord;
}

function exactKeys(
  record: UnknownRecord,
  allowed: readonly string[],
  path: string,
): void {
  const allowedKeys = new Set(allowed);
  const unknownKey = Object.keys(record).find((key) => !allowedKeys.has(key));
  if (unknownKey) invalid(path, `unknown field ${unknownKey}`);

  const missingKey = allowed.find((key) => !(key in record));
  if (missingKey) invalid(path, `missing field ${missingKey}`);
}

function text(
  value: unknown,
  path: string,
  maximumLength: number,
): string {
  if (
    typeof value !== "string" ||
    value.length === 0 ||
    value.length > maximumLength ||
    value.trim() !== value
  ) {
    invalid(path, `expected 1-${maximumLength} trimmed characters`);
  }
  return value;
}

function nullableText(
  value: unknown,
  path: string,
  maximumLength: number,
): string | null {
  return value === null ? null : text(value, path, maximumLength);
}

function timestamp(value: unknown, path: string): string {
  if (
    typeof value !== "string" ||
    !timestampPattern.test(value) ||
    !Number.isFinite(Date.parse(value))
  ) {
    invalid(path, "expected an ISO timestamp");
  }
  return value;
}

function nullableTimestamp(value: unknown, path: string): string | null {
  return value === null ? null : timestamp(value, path);
}

function oneOf<const Values extends readonly string[]>(
  value: unknown,
  values: Values,
  path: string,
): Values[number] {
  if (typeof value !== "string" || !values.includes(value)) {
    invalid(path, `expected one of ${values.join(", ")}`);
  }
  return value as Values[number];
}

function isJsonValue(value: unknown): value is JsonValue {
  if (
    value === null ||
    typeof value === "string" ||
    typeof value === "boolean"
  ) {
    return true;
  }
  if (typeof value === "number") return Number.isFinite(value);
  if (Array.isArray(value)) return value.every(isJsonValue);
  if (typeof value !== "object") return false;
  if (
    Object.getPrototypeOf(value) !== Object.prototype &&
    Object.getPrototypeOf(value) !== null
  ) {
    return false;
  }
  return Object.values(value).every(isJsonValue);
}

function safeRetrievalReference(value: unknown, path: string): string {
  const reference = text(value, path, 2048);
  let url: URL;
  try {
    url = new URL(reference);
  } catch {
    invalid(path, "expected an absolute HTTP(S) URL");
  }
  if (url.protocol !== "https:" && url.protocol !== "http:") {
    invalid(path, "expected an absolute HTTP(S) URL");
  }
  return reference;
}

function evidence(value: unknown, path: string): SourceEvidence {
  const input = recordAt(value, path);
  const kind = input.kind;

  if (kind === "raw") {
    exactKeys(input, ["kind", "mediaType", "payload"], path);
    const mediaType = oneOf(
      input.mediaType,
      ["application/json", "application/xml", "text/csv"] as const,
      `${path}.mediaType`,
    );
    if (!isJsonValue(input.payload)) {
      invalid(`${path}.payload`, "expected a finite JSON value");
    }
    return { kind, mediaType, payload: input.payload };
  }

  if (kind === "checksum") {
    exactKeys(
      input,
      ["kind", "algorithm", "digest", "retrievalReference"],
      path,
    );
    if (input.algorithm !== "sha256") {
      invalid(`${path}.algorithm`, "expected sha256");
    }
    if (typeof input.digest !== "string" || !sha256Pattern.test(input.digest)) {
      invalid(`${path}.digest`, "expected a lowercase SHA-256 digest");
    }
    return {
      kind,
      algorithm: input.algorithm,
      digest: input.digest,
      retrievalReference: safeRetrievalReference(
        input.retrievalReference,
        `${path}.retrievalReference`,
      ),
    };
  }

  invalid(`${path}.kind`, "expected raw or checksum");
}

function externalKey(value: unknown, path: string): string {
  return text(value, path, 240);
}

function language(value: unknown, path: string): string | null {
  const result = nullableText(value, path, 35);
  if (
    result !== null &&
    !/^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$/.test(result)
  ) {
    invalid(path, "expected a BCP 47-style language tag");
  }
  return result;
}

function finiteNumber(value: unknown, path: string): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    invalid(path, "expected a finite number");
  }
  return value;
}

function nullableFiniteNumber(value: unknown, path: string): number | null {
  return value === null ? null : finiteNumber(value, path);
}

function nullableYear(value: unknown, path: string): number | null {
  if (value === null) return null;
  const year = finiteNumber(value, path);
  if (!Number.isInteger(year)) invalid(path, "expected an integer year");
  if (year < -10000 || year > 2100) {
    invalid(path, "expected a year between -10000 and 2100");
  }
  return year;
}

function assertionTrace(value: unknown, path: string): AssertionTrace {
  const input = recordAt(value, path);
  exactKeys(input, ["sourceLocator", "extractionMethod"], path);
  return {
    sourceLocator: text(input.sourceLocator, `${path}.sourceLocator`, 1000),
    extractionMethod: oneOf(
      input.extractionMethod,
      ["structured", "manual", "ai_assisted"] as const,
      `${path}.extractionMethod`,
    ),
  };
}

function assertion(
  value: unknown,
  path: string,
): NormalizedAssertion {
  const input = recordAt(value, path);
  const kind = input.kind;

  if (kind === "entity_kind") {
    exactKeys(
      input,
      ["kind", "trace", "subjectExternalKey", "entityKind"],
      path,
    );
    return {
      kind,
      trace: assertionTrace(input.trace, `${path}.trace`),
      subjectExternalKey: externalKey(
        input.subjectExternalKey,
        `${path}.subjectExternalKey`,
      ),
      entityKind: oneOf(
        input.entityKind,
        ["origin_population", "cultivar", "genetic_sample", "product"] as const,
        `${path}.entityKind`,
      ),
    };
  }

  if (kind === "name") {
    exactKeys(input, [
      "kind",
      "trace",
      "subjectExternalKey",
      "name",
      "language",
    ], path);
    return {
      kind,
      trace: assertionTrace(input.trace, `${path}.trace`),
      subjectExternalKey: externalKey(
        input.subjectExternalKey,
        `${path}.subjectExternalKey`,
      ),
      name: text(input.name, `${path}.name`, 240),
      language: language(input.language, `${path}.language`),
    };
  }

  if (kind === "alias") {
    exactKeys(
      input,
      [
        "kind",
        "trace",
        "subjectExternalKey",
        "name",
        "language",
        "aliasType",
        "market",
      ],
      path,
    );
    return {
      kind,
      trace: assertionTrace(input.trace, `${path}.trace`),
      subjectExternalKey: externalKey(
        input.subjectExternalKey,
        `${path}.subjectExternalKey`,
      ),
      name: text(input.name, `${path}.name`, 240),
      language: language(input.language, `${path}.language`),
      aliasType: oneOf(
        input.aliasType,
        ["spelling", "breeder", "market", "historical", "other"] as const,
        `${path}.aliasType`,
      ),
      market: nullableText(input.market, `${path}.market`, 240),
    };
  }

  if (kind === "traditional_classification") {
    exactKeys(
      input,
      ["kind", "trace", "subjectExternalKey", "classification"],
      path,
    );
    return {
      kind,
      trace: assertionTrace(input.trace, `${path}.trace`),
      subjectExternalKey: externalKey(
        input.subjectExternalKey,
        `${path}.subjectExternalKey`,
      ),
      classification: oneOf(
        input.classification,
        ["sativa", "indica", "hybrid"] as const,
        `${path}.classification`,
      ),
    };
  }

  if (kind === "origin_region") {
    exactKeys(input, [
      "kind",
      "trace",
      "subjectExternalKey",
      "regionName",
      "regionCode",
    ], path);
    return {
      kind,
      trace: assertionTrace(input.trace, `${path}.trace`),
      subjectExternalKey: externalKey(
        input.subjectExternalKey,
        `${path}.subjectExternalKey`,
      ),
      regionName: text(input.regionName, `${path}.regionName`, 240),
      regionCode: nullableText(input.regionCode, `${path}.regionCode`, 35),
    };
  }

  if (kind === "era") {
    exactKeys(input, [
      "kind",
      "trace",
      "subjectExternalKey",
      "startYear",
      "endYear",
      "label",
    ], path);
    const startYear = nullableYear(input.startYear, `${path}.startYear`);
    const endYear = nullableYear(input.endYear, `${path}.endYear`);
    if (startYear !== null && endYear !== null && endYear < startYear) {
      invalid(`${path}.endYear`, "must not be before startYear");
    }
    return {
      kind,
      trace: assertionTrace(input.trace, `${path}.trace`),
      subjectExternalKey: externalKey(
        input.subjectExternalKey,
        `${path}.subjectExternalKey`,
      ),
      startYear,
      endYear,
      label: nullableText(input.label, `${path}.label`, 240),
    };
  }

  if (kind === "sample_reference") {
    exactKeys(
      input,
      [
        "kind",
        "trace",
        "subjectExternalKey",
        "sampleIdentifier",
        "datasetName",
        "datasetVersion",
        "submitter",
        "laboratory",
        "sampledAt",
      ],
      path,
    );
    return {
      kind,
      trace: assertionTrace(input.trace, `${path}.trace`),
      subjectExternalKey: externalKey(
        input.subjectExternalKey,
        `${path}.subjectExternalKey`,
      ),
      sampleIdentifier: text(
        input.sampleIdentifier,
        `${path}.sampleIdentifier`,
        240,
      ),
      datasetName: text(input.datasetName, `${path}.datasetName`, 240),
      datasetVersion: nullableText(
        input.datasetVersion,
        `${path}.datasetVersion`,
        160,
      ),
      submitter: nullableText(input.submitter, `${path}.submitter`, 240),
      laboratory: nullableText(input.laboratory, `${path}.laboratory`, 240),
      sampledAt: nullableTimestamp(input.sampledAt, `${path}.sampledAt`),
    };
  }

  if (kind === "lineage") {
    exactKeys(
      input,
      [
        "kind",
        "trace",
        "subjectExternalKey",
        "relatedExternalKey",
        "relationship",
        "position",
      ],
      path,
    );
    if (
      input.position !== null && input.position !== 1 && input.position !== 2
    ) {
      invalid(`${path}.position`, "expected 1, 2, or null");
    }
    const relatedExternalKey = input.relatedExternalKey === null
      ? null
      : externalKey(input.relatedExternalKey, `${path}.relatedExternalKey`);
    const relationship = oneOf(
      input.relationship,
      [
        "reported_parent",
        "cross",
        "backcross",
        "selection_from",
        "historical_origin",
        "population_membership",
        "unknown_parent",
      ] as const,
      `${path}.relationship`,
    );
    if (relationship === "unknown_parent" && relatedExternalKey !== null) {
      invalid(`${path}.relatedExternalKey`, "must be null for unknown_parent");
    }
    if (relationship !== "unknown_parent" && relatedExternalKey === null) {
      invalid(
        `${path}.relatedExternalKey`,
        "is required for this relationship",
      );
    }
    return {
      kind,
      trace: assertionTrace(input.trace, `${path}.trace`),
      subjectExternalKey: externalKey(
        input.subjectExternalKey,
        `${path}.subjectExternalKey`,
      ),
      relatedExternalKey,
      relationship,
      position: input.position,
    };
  }

  if (kind === "genetic_relation") {
    exactKeys(
      input,
      [
        "kind",
        "trace",
        "subjectExternalKey",
        "relatedExternalKey",
        "relationship",
        "method",
        "datasetName",
        "datasetVersion",
        "metricName",
        "value",
        "unit",
      ],
      path,
    );
    const subjectExternalKey = externalKey(
      input.subjectExternalKey,
      `${path}.subjectExternalKey`,
    );
    const relatedExternalKey = externalKey(
      input.relatedExternalKey,
      `${path}.relatedExternalKey`,
    );
    if (relatedExternalKey === subjectExternalKey) {
      invalid(
        `${path}.relatedExternalKey`,
        "must differ from subjectExternalKey",
      );
    }
    const relationship = oneOf(
      input.relationship,
      ["genetic_similarity", "sample_match"] as const,
      `${path}.relationship`,
    );
    const value = nullableFiniteNumber(input.value, `${path}.value`);
    const unit = nullableText(input.unit, `${path}.unit`, 100);
    const hasPair = (value === null && unit === null) ||
      (typeof value === "number" && unit !== null);
    if (!hasPair) {
      invalid(path, "value and unit must both be present or both be null");
    }
    if (
      relationship === "sample_match" && (value !== null || unit !== null)
    ) {
      invalid(path, "sample_match does not carry a numeric score");
    }
    return {
      kind,
      trace: assertionTrace(input.trace, `${path}.trace`),
      subjectExternalKey,
      relatedExternalKey,
      relationship,
      method: text(input.method, `${path}.method`, 240),
      datasetName: text(input.datasetName, `${path}.datasetName`, 240),
      datasetVersion: nullableText(
        input.datasetVersion,
        `${path}.datasetVersion`,
        160,
      ),
      metricName: text(input.metricName, `${path}.metricName`, 240),
      value,
      unit,
    };
  }

  if (kind === "product_cultivar") {
    exactKeys(
      input,
      [
        "kind",
        "trace",
        "subjectExternalKey",
        "cultivarExternalKey",
        "productForm",
      ],
      path,
    );
    return {
      kind,
      trace: assertionTrace(input.trace, `${path}.trace`),
      subjectExternalKey: externalKey(
        input.subjectExternalKey,
        `${path}.subjectExternalKey`,
      ),
      cultivarExternalKey: externalKey(
        input.cultivarExternalKey,
        `${path}.cultivarExternalKey`,
      ),
      productForm: oneOf(
        input.productForm,
        productForms,
        `${path}.productForm`,
      ),
    };
  }

  if (kind === "product_market") {
    exactKeys(input, [
      "kind",
      "trace",
      "subjectExternalKey",
      "countryCode",
      "medical",
    ], path);
    if (input.medical !== true) invalid(`${path}.medical`, "expected true");
    const countryCode = text(input.countryCode, `${path}.countryCode`, 2);
    if (!/^[A-Z]{2}$/.test(countryCode)) {
      invalid(`${path}.countryCode`, "expected two uppercase ASCII letters");
    }
    return {
      kind,
      trace: assertionTrace(input.trace, `${path}.trace`),
      subjectExternalKey: externalKey(
        input.subjectExternalKey,
        `${path}.subjectExternalKey`,
      ),
      countryCode,
      medical: true,
    };
  }

  if (kind === "measurement") {
    exactKeys(
      input,
      [
        "kind",
        "trace",
        "subjectExternalKey",
        "analyte",
        "value",
        "unit",
        "productForm",
        "batchIdentifier",
        "measuredAt",
      ],
      path,
    );
    if (input.unit !== "percent") {
      invalid(`${path}.unit`, "expected percent");
    }
    return {
      kind,
      trace: assertionTrace(input.trace, `${path}.trace`),
      subjectExternalKey: externalKey(
        input.subjectExternalKey,
        `${path}.subjectExternalKey`,
      ),
      analyte: oneOf(
        input.analyte,
        ["thc", "cbd"] as const,
        `${path}.analyte`,
      ),
      value: finiteNumber(input.value, `${path}.value`),
      unit: input.unit,
      productForm: oneOf(
        input.productForm,
        productForms,
        `${path}.productForm`,
      ),
      batchIdentifier: nullableText(
        input.batchIdentifier,
        `${path}.batchIdentifier`,
        240,
      ),
      measuredAt: nullableTimestamp(
        input.measuredAt,
        `${path}.measuredAt`,
      ),
    };
  }

  invalid(`${path}.kind`, "unknown assertion kind");
}

function adapterRecord(value: unknown, path: string): AdapterRecord {
  const input = recordAt(value, path);
  exactKeys(
    input,
    [
      "externalRecordKey",
      "upstreamState",
      "retrievedAt",
      "sourceVersion",
      "evidence",
      "validFrom",
      "validTo",
      "assertions",
    ],
    path,
  );
  if (!Array.isArray(input.assertions)) {
    invalid(`${path}.assertions`, "expected an array");
  }
  const upstreamState = oneOf(
    input.upstreamState,
    ["present", "deleted"] as const,
    `${path}.upstreamState`,
  );
  if (upstreamState === "present" && input.assertions.length === 0) {
    invalid(`${path}.assertions`, "expected at least one assertion");
  }
  if (upstreamState === "deleted" && input.assertions.length !== 0) {
    invalid(`${path}.assertions`, "deleted records cannot make assertions");
  }

  const validFrom = nullableTimestamp(input.validFrom, `${path}.validFrom`);
  const validTo = nullableTimestamp(input.validTo, `${path}.validTo`);
  if (
    validFrom !== null &&
    validTo !== null &&
    Date.parse(validTo) < Date.parse(validFrom)
  ) {
    invalid(`${path}.validTo`, "must not be before validFrom");
  }

  return {
    externalRecordKey: externalKey(
      input.externalRecordKey,
      `${path}.externalRecordKey`,
    ),
    upstreamState,
    retrievedAt: timestamp(input.retrievedAt, `${path}.retrievedAt`),
    sourceVersion: nullableText(
      input.sourceVersion,
      `${path}.sourceVersion`,
      160,
    ),
    evidence: evidence(input.evidence, `${path}.evidence`),
    validFrom,
    validTo,
    assertions: input.assertions.map((item, index) =>
      assertion(item, `${path}.assertions[${index}]`)
    ),
  };
}

function adapterError(value: unknown, path: string) {
  const input = recordAt(value, path);
  exactKeys(input, ["externalRecordKey", "code", "message"], path);
  return {
    externalRecordKey: nullableText(
      input.externalRecordKey,
      `${path}.externalRecordKey`,
      240,
    ),
    code: oneOf(
      input.code,
      ["timeout", "schema_changed", "rate_limited", "invalid_record"] as const,
      `${path}.code`,
    ),
    message: text(input.message, `${path}.message`, 1000),
  };
}

export function validateAdapterBatch(input: unknown): ValidatedAdapterBatch {
  const value = recordAt(input, "batch");
  exactKeys(
    value,
    [
      "contractVersion",
      "sourceId",
      "startedAt",
      "completedAt",
      "cursor",
      "records",
      "errors",
    ],
    "batch",
  );
  if (
    typeof value.contractVersion !== "number" || value.contractVersion !== 2
  ) {
    invalid("batch.contractVersion", "expected contract version 2");
  }
  if (
    typeof value.sourceId !== "string" ||
    !sourceIdPattern.test(value.sourceId)
  ) {
    invalid("batch.sourceId", "expected a stable lowercase source ID");
  }
  if (!Array.isArray(value.records)) {
    invalid("batch.records", "expected an array");
  }
  if (!Array.isArray(value.errors)) {
    invalid("batch.errors", "expected an array");
  }

  const startedAt = timestamp(value.startedAt, "batch.startedAt");
  const completedAt = timestamp(value.completedAt, "batch.completedAt");
  if (Date.parse(completedAt) < Date.parse(startedAt)) {
    invalid("batch.completedAt", "must not be before startedAt");
  }

  const records = value.records.map((item, index) =>
    adapterRecord(item, `records[${index}]`)
  );
  const seenKeys = new Set<string>();
  for (const record of records) {
    if (seenKeys.has(record.externalRecordKey)) {
      invalid(
        "batch.records.externalRecordKey",
        `duplicate ${record.externalRecordKey}`,
      );
    }
    seenKeys.add(record.externalRecordKey);
  }

  const reviewReasonsByRecord: Record<string, string[]> = {};
  for (const record of records) {
    if (record.upstreamState === "deleted") {
      reviewReasonsByRecord[record.externalRecordKey] = [
        "upstream_record_deleted",
      ];
      continue;
    }
    const hasUnrealisticFlowerValue = record.assertions.some((item) =>
      item.kind === "measurement" &&
      item.productForm === "flower" &&
      item.value > 70
    );
    if (hasUnrealisticFlowerValue) {
      reviewReasonsByRecord[record.externalRecordKey] = [
        "flower_value_above_70",
      ];
    }
  }

  const batch: AdapterBatch = {
    contractVersion: 2,
    sourceId: value.sourceId,
    startedAt,
    completedAt,
    cursor: nullableText(value.cursor, "batch.cursor", 2000),
    records,
    errors: value.errors.map((item, index) =>
      adapterError(item, `errors[${index}]`)
    ),
  };

  return { batch, reviewReasonsByRecord };
}
