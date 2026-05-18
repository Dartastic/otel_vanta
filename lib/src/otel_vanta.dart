// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_vanta_suppression.dart';

const _tracerName = 'dartastic_otel_libs_vanta';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class VantaResult {
  const VantaResult({
    this.organizationId,
    this.framework,
    this.controlId,
    this.testId,
    this.resourceKind,
    this.resourceId,
    this.testStatus,
    this.severity,
    this.failingCount,
    this.passingCount,
    this.deactivatedCount,
    this.dueDateSec,
    this.evidenceId,
    this.integrationSlug,
    this.statusCode,
  });

  /// Vanta tenant/organization.
  final String? organizationId;

  /// `soc2` / `iso27001` / `hipaa` / `pci_dss` / `gdpr` / `nist_csf`
  /// / `cmmc` / `fedramp` / `australia_essential_eight`.
  final String? framework;

  /// Vanta control identifier (e.g., `vanta-control-1234`).
  final String? controlId;

  /// Specific test under a control.
  final String? testId;

  /// `User` / `Group` / `Computer` / `Repository` / `S3Bucket` /
  /// `IamPolicy` / `Database` / `VendorAccount` — what was tested.
  final String? resourceKind;

  final String? resourceId;

  /// `OK` / `NEEDS_ATTENTION` / `DEACTIVATED` / `IN_PROGRESS`.
  final String? testStatus;

  /// `LOW` / `MEDIUM` / `HIGH` / `CRITICAL`.
  final String? severity;

  final int? failingCount;
  final int? passingCount;
  final int? deactivatedCount;

  /// Remediation deadline (unix seconds).
  final int? dueDateSec;

  final String? evidenceId;

  /// e.g., `aws` / `gcp` / `okta` / `github` / `jira` — Vanta's
  /// integration source.
  final String? integrationSlug;

  final int? statusCode;
}

class VantaCallResult<T> {
  const VantaCallResult({required this.value, this.result});
  final T value;
  final VantaResult? result;
}

/// Wraps a Vanta API call in a CLIENT span. [operation] is one of
/// `controls.list`, `controls.get`, `tests.list`, `tests.get`,
/// `tests.run`, `evidence.upload`, `resources.list`,
/// `integrations.connect`, `policies.list`, `personnel.list`,
/// `vendors.list`.
Future<T> tracedVanta<T>({
  required String operation,
  required Future<VantaCallResult<T>> Function() invoke,
}) async {
  if (vantaInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'vanta',
    'rpc.method': operation,
    'vanta.operation': operation,
  };

  final span = _tracer().startSpan(
    'vanta $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.organizationId != null) {
        extras.add(OTel.attributeString(
          'vanta.organization.id',
          r.result!.organizationId!,
        ));
      }
      if (r.result!.framework != null) {
        extras.add(OTel.attributeString(
          'vanta.framework',
          r.result!.framework!,
        ));
      }
      if (r.result!.controlId != null) {
        extras.add(OTel.attributeString(
          'vanta.control.id',
          r.result!.controlId!,
        ));
      }
      if (r.result!.testId != null) {
        extras.add(OTel.attributeString(
          'vanta.test.id',
          r.result!.testId!,
        ));
      }
      if (r.result!.resourceKind != null) {
        extras.add(OTel.attributeString(
          'vanta.resource.kind',
          r.result!.resourceKind!,
        ));
      }
      if (r.result!.resourceId != null) {
        extras.add(OTel.attributeString(
          'vanta.resource.id',
          r.result!.resourceId!,
        ));
      }
      if (r.result!.testStatus != null) {
        extras.add(OTel.attributeString(
          'vanta.test.status',
          r.result!.testStatus!,
        ));
        if (r.result!.testStatus == 'NEEDS_ATTENTION') {
          span.setStatus(
            SpanStatusCode.Error,
            'Vanta test NEEDS_ATTENTION',
          );
        }
      }
      if (r.result!.severity != null) {
        extras.add(OTel.attributeString(
          'vanta.severity',
          r.result!.severity!,
        ));
      }
      if (r.result!.failingCount != null) {
        extras.add(OTel.attributeInt(
          'vanta.failing.count',
          r.result!.failingCount!,
        ));
      }
      if (r.result!.passingCount != null) {
        extras.add(OTel.attributeInt(
          'vanta.passing.count',
          r.result!.passingCount!,
        ));
      }
      if (r.result!.deactivatedCount != null) {
        extras.add(OTel.attributeInt(
          'vanta.deactivated.count',
          r.result!.deactivatedCount!,
        ));
      }
      if (r.result!.dueDateSec != null) {
        extras.add(OTel.attributeInt(
          'vanta.due_date_sec',
          r.result!.dueDateSec!,
        ));
      }
      if (r.result!.evidenceId != null) {
        extras.add(OTel.attributeString(
          'vanta.evidence.id',
          r.result!.evidenceId!,
        ));
      }
      if (r.result!.integrationSlug != null) {
        extras.add(OTel.attributeString(
          'vanta.integration.slug',
          r.result!.integrationSlug!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Vanta HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
