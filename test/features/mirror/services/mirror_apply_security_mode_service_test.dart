import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/services/mirror_apply_security_mode_service.dart';

void main() {
	group('MirrorApplySecurityModeService', () {
		final service = MirrorApplySecurityModeService();

		ApplySecurityModeFactors factors({
			int totalPatchBytes = 1024,
			bool auditLoggingEnabled = false,
			bool isCloudMode = false,
			bool requireSignedApply = false,
			int userTrustScore = 100,
		}) {
			return ApplySecurityModeFactors(
				totalPatchBytes: totalPatchBytes,
				auditLoggingEnabled: auditLoggingEnabled,
				isCloudMode: isCloudMode,
				requireSignedApply: requireSignedApply,
				userTrustScore: userTrustScore,
			);
		}

		test('explicit policy forces signed flow', () {
			final decision = service.determineApplySecurityMode(
				factors(requireSignedApply: true),
			);

			expect(decision.mode, MirrorApplySecurityMode.signed);
			expect(decision.isSecurityBindingDecision, isTrue);
		});

		test('cloud mode with large patches forces signed flow', () {
			final decision = service.determineApplySecurityMode(
				factors(isCloudMode: true, totalPatchBytes: 60 * 1024),
			);

			expect(decision.mode, MirrorApplySecurityMode.signed);
			expect(decision.isSecurityBindingDecision, isTrue);
			expect(decision.rationale, contains('Cloud mode + large patches'));
		});

		test('cloud mode with small patches can still use direct flow', () {
			final decision = service.determineApplySecurityMode(
				factors(isCloudMode: true, totalPatchBytes: 10 * 1024),
			);

			expect(decision.mode, MirrorApplySecurityMode.direct);
			expect(decision.isSecurityBindingDecision, isFalse);
		});

		test('low trust score forces signed flow', () {
			final decision = service.determineApplySecurityMode(
				factors(userTrustScore: 35),
			);

			expect(decision.mode, MirrorApplySecurityMode.signed);
			expect(decision.isSecurityBindingDecision, isTrue);
			expect(decision.rationale, contains('trust score'));
		});

		test('audit logging with medium patches prefers signed flow', () {
			final decision = service.determineApplySecurityMode(
				factors(
					auditLoggingEnabled: true,
					totalPatchBytes: 60 * 1024,
					userTrustScore: 90,
				),
			);

			expect(decision.mode, MirrorApplySecurityMode.signed);
			expect(decision.isSecurityBindingDecision, isFalse);
		});

		test('small patches use direct flow', () {
			final decision = service.determineApplySecurityMode(
				factors(totalPatchBytes: 8 * 1024),
			);

			expect(decision.mode, MirrorApplySecurityMode.direct);
			expect(decision.isSecurityBindingDecision, isFalse);
		});

		test('exact 100KB threshold still uses direct flow', () {
			final decision = service.determineApplySecurityMode(
				factors(totalPatchBytes: 100 * 1024),
			);

			expect(decision.mode, MirrorApplySecurityMode.direct);
		});

		test('patches above 100KB default to signed flow', () {
			final decision = service.determineApplySecurityMode(
				factors(totalPatchBytes: 100 * 1024 + 1),
			);

			expect(decision.mode, MirrorApplySecurityMode.signed);
			expect(decision.isSecurityBindingDecision, isFalse);
		});

		test('trust score boundary at 70 allows direct flow', () {
			final decision = service.determineApplySecurityMode(
				factors(userTrustScore: 70, totalPatchBytes: 4 * 1024),
			);

			expect(decision.mode, MirrorApplySecurityMode.direct);
		});

		test('build factors clamps negative trust scores', () {
			final built = buildApplySecurityModeFactors(
				totalPatchBytes: 1024,
				auditLoggingEnabled: false,
				mode: 'private',
				requireSignedApply: false,
				userTrustScore: -5,
			);

			expect(built.userTrustScore, 0);
			final decision = service.determineApplySecurityMode(built);
			expect(decision.mode, MirrorApplySecurityMode.signed);
		});

		test('build factors clamps oversized trust scores', () {
			final built = buildApplySecurityModeFactors(
				totalPatchBytes: 1024,
				auditLoggingEnabled: false,
				mode: 'private',
				requireSignedApply: false,
				userTrustScore: 500,
			);

			expect(built.userTrustScore, 100);
			final decision = service.determineApplySecurityMode(built);
			expect(decision.mode, MirrorApplySecurityMode.direct);
		});

		test('build factors marks cloud mode correctly', () {
			final built = buildApplySecurityModeFactors(
				totalPatchBytes: 60 * 1024,
				auditLoggingEnabled: false,
				mode: 'cloud',
				requireSignedApply: false,
				userTrustScore: 95,
			);

			expect(built.isCloudMode, isTrue);
			final decision = service.determineApplySecurityMode(built);
			expect(decision.mode, MirrorApplySecurityMode.signed);
		});

		test('logging security mode decision does not throw', () {
			final decision = service.determineApplySecurityMode(
				factors(totalPatchBytes: 10 * 1024),
			);

			expect(
				() => service.logSecurityModeDecision(
					'project::task',
					decision,
					factors(totalPatchBytes: 10 * 1024),
				),
				returnsNormally,
			);
		});
	});
}


