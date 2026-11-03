import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grow_with_me/features/plus/plus_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts free', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = await container.read(plusProvider.future);

    expect(state.isActive, isFalse);
    expect(state.plan, PlusPlan.monthly);
    expect(state.statusLine, 'Free plan');
  });

  test('preview activates a clearly-labelled seven-day trial', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(plusProvider.future);

    await container.read(plusProvider.notifier).startPreview(PlusPlan.yearly);

    final state = container.read(plusProvider).value!;
    expect(state.isActive, isTrue);
    expect(state.trial, isTrue);
    expect(state.preview, isTrue);
    expect(state.plan, PlusPlan.yearly);
    expect(state.daysLeft, inInclusiveRange(6, 7));
    expect(state.statusLine, contains('trial'));
    expect(state.renewalLine, contains('No payment'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('plusActive'), isTrue);
    expect(prefs.getString('plusPlan'), 'yearly');
    expect(prefs.getBool('plusPreview'), isTrue);
  });

  test('switchPlan keeps the same trial window', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(plusProvider.future);
    await container.read(plusProvider.notifier).startPreview(PlusPlan.monthly);

    final before = container.read(plusProvider).value!;
    await container.read(plusProvider.notifier).switchPlan(PlusPlan.yearly);
    final after = container.read(plusProvider).value!;

    expect(after.plan, PlusPlan.yearly);
    expect(after.trial, isTrue);
    expect(after.renewsAt, before.renewsAt);
  });

  test('cancel clears the entitlement', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(plusProvider.future);
    await container.read(plusProvider.notifier).startPreview(PlusPlan.monthly);
    await container.read(plusProvider.notifier).cancel();

    final state = container.read(plusProvider).value!;
    expect(state.isActive, isFalse);
    expect(state.statusLine, 'Free plan');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('plusActive'), isFalse);
    expect(prefs.getBool('plusPreview'), isFalse);
  });

  test('expired entitlement is cleared when the controller loads', () async {
    final expired = DateTime.now()
        .subtract(const Duration(days: 1))
        .millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'plusActive': true,
      'plusPlan': 'monthly',
      'plusRenewsAt': expired,
      'plusTrial': true,
      'plusPreview': true,
      'plusStartedAt': expired - 604800000,
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = await container.read(plusProvider.future);

    expect(state.isActive, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('plusActive'), isFalse);
  });

  test('restore finds a live entitlement and rejects a missing one', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(plusProvider.future);

    expect(await container.read(plusProvider.notifier).restore(), isFalse);

    await container.read(plusProvider.notifier).startPreview(PlusPlan.monthly);
    expect(await container.read(plusProvider.notifier).restore(), isTrue);

    await container.read(plusProvider.notifier).cancel();
    expect(await container.read(plusProvider.notifier).restore(), isFalse);
  });

  test('storage round-trips into a fresh container', () async {
    final first = ProviderContainer();
    addTearDown(first.dispose);
    await first.read(plusProvider.future);
    await first.read(plusProvider.notifier).startPreview(PlusPlan.yearly);

    final second = ProviderContainer();
    addTearDown(second.dispose);
    final restored = await second.read(plusProvider.future);

    expect(restored.isActive, isTrue);
    expect(restored.plan, PlusPlan.yearly);
    expect(restored.trial, isTrue);
  });
}
