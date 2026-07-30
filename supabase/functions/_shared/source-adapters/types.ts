export type JsonValue =
  | null
  | boolean
  | number
  | string
  | JsonValue[]
  | { [key: string]: JsonValue };

export type SourceEvidence =
  | {
    kind: "raw";
    mediaType: "application/json" | "application/xml" | "text/csv";
    payload: JsonValue;
  }
  | {
    kind: "checksum";
    algorithm: "sha256";
    digest: string;
    retrievalReference: string;
  };

export type EntityKind =
  | "origin_population"
  | "cultivar"
  | "genetic_sample"
  | "product";

export type ExtractionMethod =
  | "structured"
  | "manual"
  | "ai_assisted";

export type AssertionTrace = {
  sourceLocator: string;
  extractionMethod: ExtractionMethod;
};

export type EvidenceStatus =
  | "confirmed"
  | "single_source"
  | "disputed"
  | "historical"
  | "unknown"
  | "retracted";

type TracedAssertion = {
  trace: AssertionTrace;
};

export type NormalizedAssertion =
  | (TracedAssertion & {
    kind: "entity_kind";
    subjectExternalKey: string;
    entityKind: EntityKind;
  })
  | (TracedAssertion & {
    kind: "name";
    subjectExternalKey: string;
    name: string;
    language: string | null;
  })
  | (TracedAssertion & {
    kind: "alias";
    subjectExternalKey: string;
    name: string;
    language: string | null;
    aliasType: "spelling" | "breeder" | "market" | "historical" | "other";
    market: string | null;
  })
  | (TracedAssertion & {
    kind: "traditional_classification";
    subjectExternalKey: string;
    classification: "sativa" | "indica" | "hybrid";
  })
  | (TracedAssertion & {
    kind: "origin_region";
    subjectExternalKey: string;
    regionName: string;
    regionCode: string | null;
  })
  | (TracedAssertion & {
    kind: "era";
    subjectExternalKey: string;
    startYear: number | null;
    endYear: number | null;
    label: string | null;
  })
  | (TracedAssertion & {
    kind: "sample_reference";
    subjectExternalKey: string;
    sampleIdentifier: string;
    datasetName: string;
    datasetVersion: string | null;
    submitter: string | null;
    laboratory: string | null;
    sampledAt: string | null;
  })
  | (TracedAssertion & {
    kind: "lineage";
    subjectExternalKey: string;
    relatedExternalKey: string | null;
    relationship:
      | "reported_parent"
      | "cross"
      | "backcross"
      | "selection_from"
      | "historical_origin"
      | "population_membership"
      | "unknown_parent";
    position: 1 | 2 | null;
  })
  | (TracedAssertion & {
    kind: "genetic_relation";
    subjectExternalKey: string;
    relatedExternalKey: string;
    relationship: "genetic_similarity" | "sample_match";
    method: string;
    datasetName: string;
    datasetVersion: string | null;
    metricName: string;
    value: number | null;
    unit: string | null;
  })
  | (TracedAssertion & {
    kind: "product_cultivar";
    subjectExternalKey: string;
    cultivarExternalKey: string;
    productForm: "flower" | "extract" | "oil" | "other";
  })
  | (TracedAssertion & {
    kind: "product_market";
    subjectExternalKey: string;
    countryCode: string;
    medical: true;
  })
  | (TracedAssertion & {
    kind: "measurement";
    subjectExternalKey: string;
    analyte: "thc" | "cbd";
    value: number;
    unit: "percent";
    productForm: "flower" | "extract" | "oil" | "other";
    batchIdentifier: string | null;
    measuredAt: string | null;
  });

export type AdapterRecord = {
  externalRecordKey: string;
  upstreamState: "present" | "deleted";
  retrievedAt: string;
  sourceVersion: string | null;
  evidence: SourceEvidence;
  validFrom: string | null;
  validTo: string | null;
  assertions: NormalizedAssertion[];
};

export type AdapterError = {
  externalRecordKey: string | null;
  code: "timeout" | "schema_changed" | "rate_limited" | "invalid_record";
  message: string;
};

export type AdapterBatch = {
  contractVersion: 2;
  sourceId: string;
  startedAt: string;
  completedAt: string;
  cursor: string | null;
  records: AdapterRecord[];
  errors: AdapterError[];
};

export type ValidatedAdapterBatch = {
  batch: AdapterBatch;
  reviewReasonsByRecord: Record<string, string[]>;
};
