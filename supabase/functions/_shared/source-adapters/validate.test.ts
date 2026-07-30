import { assertEquals, assertThrows } from "@std/assert";
import invalidFlowerValue from "../../tests/fixtures/source-adapter-invalid-flower-value.json" with {
  type: "json",
};
import validFixture from "../../tests/fixtures/source-adapter-valid.json" with {
  type: "json",
};
import knowledgeGraphFixture from "../../tests/fixtures/source-adapter-knowledge-graph-valid.json" with {
  type: "json",
};
import { validateAdapterBatch } from "./validate.ts";

function cloned<T>(value: T): T {
  return structuredClone(value);
}

function version2Fixture(): Record<string, unknown> {
  const input = cloned(validFixture) as Record<string, unknown>;
  input.contractVersion = 2;
  const records = input.records as Array<Record<string, unknown>>;
  for (const [recordIndex, record] of records.entries()) {
    const assertions = record.assertions as Array<Record<string, unknown>>;
    for (const [assertionIndex, item] of assertions.entries()) {
      item.trace = {
        sourceLocator:
          `$.records[${recordIndex}].assertions[${assertionIndex}]`,
        extractionMethod: "structured",
      };
    }
  }
  return input;
}

function graphFixture(): Record<string, unknown> {
  return cloned(knowledgeGraphFixture) as Record<string, unknown>;
}

function graphAssertion(
  input: Record<string, unknown>,
  subjectExternalKey: string,
  kind: string,
  relationship?: string,
): Record<string, unknown> {
  const records = input.records as Array<Record<string, unknown>>;
  const assertions = records.flatMap((record) =>
    record.assertions as Array<Record<string, unknown>>
  );
  const result = assertions.find((assertion) =>
    assertion.subjectExternalKey === subjectExternalKey &&
    assertion.kind === kind &&
    (relationship === undefined || assertion.relationship === relationship)
  );
  if (!result) throw new Error(`missing ${kind} for ${subjectExternalKey}`);
  return result;
}

Deno.test("source adapter preserves synthetic knowledge graph assertions without inference", () => {
  const input = graphFixture();
  const result = validateAdapterBatch(input);

  assertEquals(result.batch as unknown, knowledgeGraphFixture);
  assertEquals(result.reviewReasonsByRecord, {});
  assertEquals(
    result.batch.records[2].assertions.filter((item) =>
      item.kind === "lineage"
    ),
    (knowledgeGraphFixture.records[2].assertions as Array<
      Record<string, unknown>
    >)
      .filter((item) => item.kind === "lineage"),
  );
  assertEquals(
    result.batch.records[3].assertions[3],
    knowledgeGraphFixture.records[3].assertions[3] as unknown,
  );
});

Deno.test("source adapter validates knowledge assertion cross-field constraints", () => {
  const mutations: Array<[
    string,
    (input: Record<string, unknown>) => void,
  ]> = [
    ["unknown_parent must not name a related record", (input) => {
      graphAssertion(input, "synthetic-child-001", "lineage", "unknown_parent")
        .relatedExternalKey = "synthetic-parent-001";
    }],
    ["reported_parent must name a related record", (input) => {
      graphAssertion(input, "synthetic-child-001", "lineage", "reported_parent")
        .relatedExternalKey = null;
    }],
    ["lineage position is limited to first or second", (input) => {
      graphAssertion(input, "synthetic-child-001", "lineage", "reported_parent")
        .position = 3;
    }],
    ["era cannot end before it starts", (input) => {
      graphAssertion(input, "synthetic-origin-001", "era").endYear = -1201;
    }],
    ["era years have bounded historical range", (input) => {
      graphAssertion(input, "synthetic-origin-001", "era").startYear = 2101;
    }],
    ["genetic relations cannot be self-referential", (input) => {
      const relation = graphAssertion(
        input,
        "synthetic-sample-001",
        "genetic_relation",
      );
      relation.relatedExternalKey = relation.subjectExternalKey;
    }],
    ["genetic relation scores must be finite", (input) => {
      graphAssertion(input, "synthetic-sample-001", "genetic_relation").value =
        Number.POSITIVE_INFINITY;
    }],
    ["sample matches do not carry a numeric value", (input) => {
      const relation = graphAssertion(
        input,
        "synthetic-sample-001",
        "genetic_relation",
      );
      relation.relationship = "sample_match";
      relation.unit = null;
    }],
    ["sample matches do not carry a unit", (input) => {
      const relation = graphAssertion(
        input,
        "synthetic-sample-001",
        "genetic_relation",
      );
      relation.relationship = "sample_match";
      relation.value = null;
    }],
    ["genetic similarity scores require a unit with a value", (input) => {
      graphAssertion(input, "synthetic-sample-001", "genetic_relation").unit =
        null;
    }],
    ["genetic similarity scores require a value with a unit", (input) => {
      graphAssertion(input, "synthetic-sample-001", "genetic_relation").value =
        null;
    }],
    ["product markets use two uppercase ASCII country letters", (input) => {
      graphAssertion(input, "synthetic-product-001", "product_market")
        .countryCode = "De";
    }],
    ["product markets are always medical", (input) => {
      graphAssertion(input, "synthetic-product-001", "product_market")
        .medical = false;
    }],
    ["empty genetic method is rejected", (input) => {
      graphAssertion(input, "synthetic-sample-001", "genetic_relation").method =
        "";
    }],
    ["empty genetic dataset is rejected", (input) => {
      graphAssertion(input, "synthetic-sample-001", "genetic_relation")
        .datasetName = "";
    }],
    ["empty genetic metric is rejected", (input) => {
      graphAssertion(input, "synthetic-sample-001", "genetic_relation")
        .metricName = "";
    }],
    ["empty sample identifier is rejected", (input) => {
      graphAssertion(input, "synthetic-sample-001", "sample_reference")
        .sampleIdentifier = "";
    }],
    ["empty region is rejected", (input) => {
      graphAssertion(input, "synthetic-origin-001", "origin_region")
        .regionName = "";
    }],
    ["empty alias type is rejected", (input) => {
      graphAssertion(input, "synthetic-parent-001", "alias").aliasType = "";
    }],
  ];

  for (const [name, mutate] of mutations) {
    const input = graphFixture();
    mutate(input);
    assertThrows(
      () => validateAdapterBatch(input),
      Error,
      undefined,
      `expected ${name} to be rejected`,
    );
  }
});

Deno.test("source adapter requires contract version 2", () => {
  const missingVersion = cloned(validFixture) as Record<string, unknown>;
  delete missingVersion.contractVersion;
  assertThrows(
    () => validateAdapterBatch(missingVersion),
    Error,
    "contractVersion",
  );

  const mutations: Array<[string, unknown]> = [
    ["a string", "2"],
    ["null", null],
    ["an older version", 1],
    ["a future version", 3],
  ];
  for (const [name, contractVersion] of mutations) {
    const input = cloned(validFixture) as Record<string, unknown>;
    input.contractVersion = contractVersion;
    assertThrows(
      () => validateAdapterBatch(input),
      Error,
      "contractVersion",
      `expected ${name} to be rejected`,
    );
  }
});

Deno.test("source adapter preserves the exact JSON-path trace locator", () => {
  const input = version2Fixture();
  const records = input.records as Array<Record<string, unknown>>;
  const assertions = records[0].assertions as Array<Record<string, unknown>>;
  const trace = assertions[0].trace as Record<string, unknown>;
  trace.sourceLocator = "$.records[0].name";

  const result = validateAdapterBatch(input);

  assertEquals(
    (result.batch.records[0].assertions[0] as unknown as Record<
      string,
      unknown
    >).trace,
    {
      sourceLocator: "$.records[0].name",
      extractionMethod: "structured",
    },
  );
});

Deno.test("source adapter requires a bounded, trimmed trace locator and closed extraction method", () => {
  const mutations: Array<[string, (trace: Record<string, unknown>) => void]> = [
    ["missing source locator", (trace) => delete trace.sourceLocator],
    ["empty source locator", (trace) => trace.sourceLocator = ""],
    [
      "untrimmed source locator",
      (trace) => trace.sourceLocator = " $.records[0].name",
    ],
    [
      "overlong source locator",
      (trace) => trace.sourceLocator = "a".repeat(1001),
    ],
    [
      "unknown extraction method",
      (trace) => trace.extractionMethod = "scraped",
    ],
  ];

  for (const [name, mutate] of mutations) {
    const input = version2Fixture();
    const records = input.records as Array<Record<string, unknown>>;
    const assertions = records[0].assertions as Array<Record<string, unknown>>;
    mutate(assertions[0].trace as Record<string, unknown>);
    assertThrows(
      () => validateAdapterBatch(input),
      Error,
      "trace",
      `expected ${name} to be rejected`,
    );
  }
});

Deno.test("source adapter accepts raw and checksum evidence without changing source precision", () => {
  const result = validateAdapterBatch(cloned(validFixture));

  assertEquals(result.batch as unknown, validFixture);
  assertEquals(
    result.batch.records[0].assertions[2],
    {
      kind: "measurement",
      trace: {
        sourceLocator: "$.records[0].measurements.thc",
        extractionMethod: "ai_assisted",
      },
      subjectExternalKey: "synthetic-cultivar-001",
      analyte: "thc",
      value: 21.375,
      unit: "percent",
      productForm: "flower",
      batchIdentifier: null,
      measuredAt: "2026-07-01T00:00:00.000Z",
    },
  );
  assertEquals(result.reviewReasonsByRecord, {});
});

Deno.test("source adapter retains an unrealistic flower value only for review", () => {
  const result = validateAdapterBatch(cloned(invalidFlowerValue));

  assertEquals(
    result.batch.records[0].assertions[0] as unknown,
    invalidFlowerValue.records[0].assertions[0],
  );
  assertEquals(result.reviewReasonsByRecord, {
    "synthetic-flower-above-limit": ["flower_value_above_70"],
  });
});

Deno.test("source adapter represents upstream deletion as review-only evidence", () => {
  const input = cloned(validFixture) as Record<string, unknown>;
  const records = input.records as Array<Record<string, unknown>>;
  records[0].upstreamState = "deleted";
  records[0].assertions = [];

  const result = validateAdapterBatch(input);

  assertEquals(result.batch.records[0].upstreamState, "deleted");
  assertEquals(result.batch.records[0].assertions, []);
  assertEquals(result.reviewReasonsByRecord, {
    "synthetic-cultivar-001": ["upstream_record_deleted"],
  });
});

Deno.test("source adapter accepts only the closed normalized assertion contract", () => {
  const input = cloned(validFixture) as Record<string, unknown>;
  const records = input.records as Array<Record<string, unknown>>;
  const assertions = records[0].assertions as Array<Record<string, unknown>>;
  assertions[0].sourceSpecificTitle = "must not cross the adapter boundary";

  assertThrows(
    () => validateAdapterBatch(input),
    Error,
    "records[0].assertions[0]",
  );
});

Deno.test("source adapter rejects malformed checksums, timestamps, positions, and measurements", () => {
  const mutations: Array<[string, (input: Record<string, unknown>) => void]> = [
    ["checksum", (input) => {
      const records = input.records as Array<Record<string, unknown>>;
      const evidence = records[1].evidence as Record<string, unknown>;
      evidence.digest = "ABC123";
    }],
    ["timestamp", (input) => {
      input.completedAt = "not-a-timestamp";
    }],
    ["position", (input) => {
      const records = input.records as Array<Record<string, unknown>>;
      records[0].assertions = [{
        kind: "lineage",
        trace: {
          sourceLocator: "$.records[0].lineage[0]",
          extractionMethod: "structured",
        },
        subjectExternalKey: "synthetic-cultivar-001",
        relatedExternalKey: "synthetic-parent-001",
        relationship: "reported_parent",
        position: 3,
      }];
    }],
    ["measurement", (input) => {
      const records = input.records as Array<Record<string, unknown>>;
      const assertions = records[0].assertions as Array<
        Record<string, unknown>
      >;
      assertions[2].value = Number.POSITIVE_INFINITY;
    }],
  ];

  for (const [name, mutate] of mutations) {
    const input = cloned(validFixture) as Record<string, unknown>;
    mutate(input);
    assertThrows(
      () => validateAdapterBatch(input),
      Error,
      undefined,
      `expected ${name} mutation to be rejected`,
    );
  }
});

Deno.test("source adapter rejects unknown batch and record fields", () => {
  const batch = cloned(validFixture) as Record<string, unknown>;
  batch.providerCursor = "source-specific";
  assertThrows(() => validateAdapterBatch(batch), Error, "batch");

  const record = cloned(validFixture) as Record<string, unknown>;
  const records = record.records as Array<Record<string, unknown>>;
  records[0].providerUpdatedAt = "2026-07-28";
  assertThrows(
    () => validateAdapterBatch(record),
    Error,
    "records[0]",
  );

  const trace = cloned(validFixture) as Record<string, unknown>;
  const traceRecords = trace.records as Array<Record<string, unknown>>;
  const assertions = traceRecords[0].assertions as Array<
    Record<string, unknown>
  >;
  const assertionTrace = assertions[0].trace as Record<string, unknown>;
  assertionTrace.sourceSpecificPath = "must-not-cross-boundary";
  assertThrows(
    () => validateAdapterBatch(trace),
    Error,
    "records[0].assertions[0].trace",
  );
});

Deno.test("source adapter rejects non-JSON raw payload objects", () => {
  const input = cloned(validFixture) as Record<string, unknown>;
  const records = input.records as Array<Record<string, unknown>>;
  const evidence = records[0].evidence as Record<string, unknown>;
  evidence.payload = new Date("2026-07-28T18:00:00.000Z");

  assertThrows(
    () => validateAdapterBatch(input),
    Error,
    "payload",
  );
});

Deno.test("source adapter rejects duplicate record keys and invalid validity windows", () => {
  const duplicate = cloned(validFixture) as Record<string, unknown>;
  const duplicateRecords = duplicate.records as Array<Record<string, unknown>>;
  duplicateRecords[1].externalRecordKey = duplicateRecords[0].externalRecordKey;
  assertThrows(
    () => validateAdapterBatch(duplicate),
    Error,
    "externalRecordKey",
  );

  const invalidWindow = cloned(validFixture) as Record<string, unknown>;
  const windowRecords = invalidWindow.records as Array<Record<string, unknown>>;
  windowRecords[0].validFrom = "2026-07-02T00:00:00.000Z";
  windowRecords[0].validTo = "2026-07-01T00:00:00.000Z";
  assertThrows(
    () => validateAdapterBatch(invalidWindow),
    Error,
    "validTo",
  );
});
