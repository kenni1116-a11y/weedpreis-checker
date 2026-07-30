import { assertEquals, assertFalse, assertStringIncludes } from "@std/assert";
import validFixture from "../tests/fixtures/source-adapter-valid.json" with {
  type: "json",
};
import type { AdapterBatch } from "../_shared/source-adapters/types.ts";
import {
  createSourceImportHandler,
  secureTokenMatches,
  type SourceImportDependencies,
} from "./index.ts";

const triggerToken = "synthetic-trigger-token-at-least-32-characters";

type HarnessOptions = {
  authorized?: boolean;
  recordBatch?: SourceImportDependencies["recordBatch"];
};

function harness(options: HarnessOptions = {}) {
  const recorded: AdapterBatch[] = [];
  const logs: Array<{
    correlationId: string;
    sourceId: string | null;
    code: string;
  }> = [];
  const dependencies: SourceImportDependencies = {
    authorizeTriggerToken: () => Promise.resolve(options.authorized ?? true),
    recordBatch(batch) {
      recorded.push(batch);
      if (options.recordBatch) return options.recordBatch(batch);
      return Promise.resolve({
        run_id: "40000000-0000-4000-8000-000000000001",
        inserted_records: 2,
        inserted_assertions: 4,
        review_cases: 4,
      });
    },
    log(event) {
      logs.push(event);
    },
    correlationId: () => "synthetic-correlation-id",
  };
  return {
    handler: createSourceImportHandler(dependencies),
    logs,
    recorded,
  };
}

function request(
  body: unknown = validFixture,
  options: { method?: string; token?: string } = {},
): Request {
  return new Request("https://example.invalid/source-import", {
    method: options.method ?? "POST",
    headers: options.token === undefined
      ? undefined
      : { "X-Weedypedia-Import-Token": options.token },
    body: options.method === "GET" ? undefined : JSON.stringify(body),
  });
}

Deno.test("source import accepts only POST and never enables browser CORS", async () => {
  const { handler, recorded } = harness();
  const response = await handler(request(undefined, { method: "GET" }));

  assertEquals(response.status, 405);
  assertEquals(response.headers.get("allow"), "POST");
  assertEquals(response.headers.get("cache-control"), "no-store");
  assertEquals(response.headers.get("access-control-allow-origin"), null);
  assertEquals(recorded, []);
});

Deno.test("source import rejects an invalid trigger token before reading a batch", async () => {
  const { handler, recorded, logs } = harness({ authorized: false });
  const response = await handler(request({
    rawPayloadMarker: "must-never-be-read-or-logged",
  }));

  assertEquals(response.status, 401);
  assertEquals(await response.json(), {
    ok: false,
    code: "unauthorized",
  });
  assertEquals(recorded, []);
  assertEquals(logs, [{
    correlationId: "synthetic-correlation-id",
    sourceId: null,
    code: "unauthorized",
  }]);
});

Deno.test("source import validates a closed adapter batch before database access", async () => {
  const { handler, recorded } = harness();
  const invalid = structuredClone(validFixture) as Record<string, unknown>;
  invalid.sourceSpecificCursor = "must-not-cross-boundary";
  const response = await handler(request(invalid));
  const responseText = await response.text();

  assertEquals(response.status, 400);
  assertEquals(JSON.parse(responseText), {
    ok: false,
    code: "invalid_batch",
  });
  assertFalse(responseText.includes("sourceSpecificCursor"));
  assertEquals(recorded, []);
});

Deno.test("source import returns only safe counts from a valid idempotent batch", async () => {
  const { handler, recorded } = harness();
  const response = await handler(request());

  assertEquals(response.status, 200);
  assertEquals(await response.json(), {
    ok: true,
    runId: "40000000-0000-4000-8000-000000000001",
    insertedRecords: 2,
    insertedAssertions: 4,
    reviewCases: 4,
  });
  assertEquals(recorded.length, 1);
  assertEquals(recorded[0].contractVersion, 2);
  assertEquals(recorded[0].sourceId, "synthetic-contract-source");
  assertEquals(recorded[0].records[0].upstreamState, "present");
  assertEquals(response.headers.get("cache-control"), "no-store");
});

Deno.test("source import maps a blocked source without exposing database detail", async () => {
  const { handler, logs } = harness({
    recordBatch: () => {
      throw Object.assign(
        new Error(
          "raw database detail must not reach the response",
        ),
        { code: "42501" },
      );
    },
  });
  const response = await handler(request());
  const responseText = await response.text();

  assertEquals(response.status, 403);
  assertEquals(JSON.parse(responseText), {
    ok: false,
    code: "source_blocked",
  });
  assertFalse(responseText.includes("raw database detail"));
  assertEquals(logs[0].code, "source_blocked");
  assertEquals(logs[0].sourceId, "synthetic-contract-source");
});

Deno.test("source import maps database failure to an opaque retryable response", async () => {
  const { handler, logs } = harness({
    recordBatch: () => {
      throw new Error("postgres://secret-user:secret-password@internal");
    },
  });
  const response = await handler(request());
  const responseText = await response.text();

  assertEquals(response.status, 503);
  assertEquals(JSON.parse(responseText), {
    ok: false,
    code: "unavailable",
  });
  assertFalse(responseText.includes("secret-password"));
  assertEquals(logs, [{
    correlationId: "synthetic-correlation-id",
    sourceId: "synthetic-contract-source",
    code: "unavailable",
  }]);
});

Deno.test("source import token comparison accepts only the full configured secret", async () => {
  assertEquals(
    await secureTokenMatches(triggerToken, triggerToken),
    true,
  );
  assertEquals(
    await secureTokenMatches(`${triggerToken}-wrong`, triggerToken),
    false,
  );
  assertEquals(await secureTokenMatches("", triggerToken), false);
  assertEquals(await secureTokenMatches(triggerToken, "too-short"), false);
});

Deno.test("source import rejects an oversized request without parsing it", async () => {
  const { handler, recorded } = harness();
  const oversizedMarker = "raw-oversized-marker-".repeat(60_000);
  const response = await handler(request({ oversizedMarker }));
  const responseText = await response.text();

  assertEquals(response.status, 413);
  assertEquals(JSON.parse(responseText), {
    ok: false,
    code: "invalid_batch",
  });
  assertFalse(responseText.includes("raw-oversized-marker"));
  assertEquals(recorded, []);
  assertStringIncludes(
    response.headers.get("content-type") ?? "",
    "application/json",
  );
});
