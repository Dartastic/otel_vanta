// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_vanta/otel_vanta.dart';

/// Traces Vanta calls with OpenTelemetry.
///
/// `otel_vanta` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Vanta call in
/// [tracedVanta]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'vanta-example');

  // Wraps a Vanta API call in a CLIENT span.
  final vantaId = await tracedVanta<String>(
    operation: 'tests.run',
    invoke: () async {
      // Make the Vanta call here, then report what it returned.
      const id = 'vanta_8f3a2c';
      return const VantaCallResult(
          value: id,
          result: VantaResult(
              organizationId: 'organization_8f3a2c',
              framework: 'soc2',
              controlId: 'vanta-control-1234',
              testId: 'test_8f3a2c',
              resourceKind: 'User',
              resourceId: 'resource_8f3a2c',
              testStatus: 'OK',
              severity: 'LOW',
              failingCount: 3,
              passingCount: 3,
              deactivatedCount: 3,
              dueDateSec: 1,
              evidenceId: 'evidence_8f3a2c',
              integrationSlug: 'aws',
              statusCode: 200));
    },
  );
  OTelLog.info('tracedVanta tests.run returned $vantaId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutVantaInstrumentationAsync.
  await runWithoutVantaInstrumentationAsync(
    () => tracedVanta<String>(
      operation: 'tests.run',
      invoke: () async {
        const id = 'vanta_8f3a2c';
        return const VantaCallResult(
            value: id,
            result: VantaResult(
                organizationId: 'organization_8f3a2c',
                framework: 'soc2',
                controlId: 'vanta-control-1234',
                testId: 'test_8f3a2c',
                resourceKind: 'User',
                resourceId: 'resource_8f3a2c',
                testStatus: 'OK',
                severity: 'LOW',
                failingCount: 3,
                passingCount: 3,
                deactivatedCount: 3,
                dueDateSec: 1,
                evidenceId: 'evidence_8f3a2c',
                integrationSlug: 'aws',
                statusCode: 200));
      },
    ),
  );

  await OTel.shutdown();
}
