// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_vanta/otel_vanta.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_vanta-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('tests.run records framework + resource + counts', () async {
    await tracedVanta<String>(
      operation: 'tests.run',
      invoke: () async => const VantaCallResult(
        value: 'ok',
        result: VantaResult(
          organizationId: 'org_1',
          framework: 'soc2',
          controlId: 'vanta-control-1234',
          testId: 'test_5678',
          resourceKind: 'S3Bucket',
          testStatus: 'OK',
          severity: 'MEDIUM',
          failingCount: 0,
          passingCount: 42,
          deactivatedCount: 3,
          integrationSlug: 'aws',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('vanta tests.run')!);
    expect(a['vanta.framework'], 'soc2');
    expect(a['vanta.control.id'], 'vanta-control-1234');
    expect(a['vanta.resource.kind'], 'S3Bucket');
    expect(a['vanta.test.status'], 'OK');
    expect(a['vanta.passing.count'], 42);
    expect(a['vanta.integration.slug'], 'aws');
  });

  test('NEEDS_ATTENTION sets span error', () async {
    await tracedVanta<String>(
      operation: 'tests.get',
      invoke: () async => const VantaCallResult(
        value: 'ok',
        result: VantaResult(
          framework: 'soc2',
          controlId: 'vanta-control-mfa',
          testStatus: 'NEEDS_ATTENTION',
          severity: 'HIGH',
          failingCount: 3,
          dueDateSec: 1735776000,
        ),
      ),
    );
    expect(
      spans.findSpanByName('vanta tests.get')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutVantaInstrumentationAsync(() async {
      await tracedVanta<String>(
        operation: 'controls.list',
        invoke: () async => const VantaCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('vanta '), isEmpty);
  });
}
