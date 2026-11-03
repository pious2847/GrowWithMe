import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Nana Plus entitlement.
///
/// Billing is intentionally behind this controller. Today it activates a
/// clearly-labelled 7-day preview on the device; when a payment provider
/// (Paystack / RevenueCat / store billing) is connected, only this file needs
/// to change — every screen already asks the same questions.

enum PlusPlan { monthly, yearly }

extension PlusPlanInfo on PlusPlan {
  String get storageKey => name;

  String get title => switch (this) {
    PlusPlan.monthly => 'Monthly',
    PlusPlan.yearly => 'Yearly',
  };

  String get price => switch (this) {
    PlusPlan.monthly => 'GH₵19',
    PlusPlan.yearly => 'GH₵149',
  };

  String get cadence => switch (this) {
    PlusPlan.monthly => 'per month',
    PlusPlan.yearly => 'per year',
  };

  String get monthlyEquivalent => switch (this) {
    PlusPlan.monthly => 'GH₵19 / month',
    PlusPlan.yearly => 'GH₵12.42 / month',
  };

  String? get badge => switch (this) {
    PlusPlan.monthly => null,
    PlusPlan.yearly => 'SAVE 35%',
  };

  static PlusPlan fromStorage(String? value) {
    for (final plan in PlusPlan.values) {
      if (plan.storageKey == value) return plan;
    }
    return PlusPlan.monthly;
  }
}

@immutable
class PlusState {
  const PlusState({
    required this.active,
    required this.plan,
    this.startedAt,
    this.renewsAt,
    this.trial = false,
    this.preview = false,
  });

  const PlusState.free()
    : active = false,
      plan = PlusPlan.monthly,
      startedAt = null,
      renewsAt = null,
      trial = false,
      preview = false;

  final bool active;
  final PlusPlan plan;
  final DateTime? startedAt;
  final DateTime? renewsAt;
  final bool trial;
  final bool preview;

  bool get isActive =>
      active && (renewsAt == null || renewsAt!.isAfter(DateTime.now()));

  int get daysLeft {
    final end = renewsAt;
    if (end == null) return 0;
    final days = end.difference(DateTime.now()).inHours / 24;
    return days <= 0 ? 0 : days.ceil();
  }

  String get statusLine {
    if (!isActive) return 'Free plan';
    if (trial) return 'Nana Plus trial · ${daysLeft}d left';
    return 'Nana Plus · ${plan.title}';
  }

  String get renewalLine {
    if (!isActive) return 'This week\'s report is always free.';
    final end = renewsAt;
    if (end == null) return 'Active on this phone';
    final d = end;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final date = '${d.day} ${months[d.month - 1]} ${d.year}';
    if (trial) {
      return preview
          ? 'Preview ends $date. No payment will be taken.'
          : 'Trial ends $date.';
    }
    return 'Renews $date';
  }
}

class PlusController extends AsyncNotifier<PlusState> {
  static const _activeKey = 'plusActive';
  static const _planKey = 'plusPlan';
  static const _startedKey = 'plusStartedAt';
  static const _renewsKey = 'plusRenewsAt';
  static const _trialKey = 'plusTrial';
  static const _previewKey = 'plusPreview';

  @override
  Future<PlusState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final state = _read(prefs);
    if (state.active && !state.isActive) {
      await prefs.setBool(_activeKey, false);
      return const PlusState.free();
    }
    return state;
  }

  PlusState _read(SharedPreferences prefs) {
    final active = prefs.getBool(_activeKey) ?? false;
    final startedMs = prefs.getInt(_startedKey);
    final renewsMs = prefs.getInt(_renewsKey);
    return PlusState(
      active: active,
      plan: PlusPlanInfo.fromStorage(prefs.getString(_planKey)),
      startedAt: startedMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(startedMs),
      renewsAt: renewsMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(renewsMs),
      trial: prefs.getBool(_trialKey) ?? false,
      preview: prefs.getBool(_previewKey) ?? false,
    );
  }

  Future<void> _write(PlusState value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activeKey, value.active);
    await prefs.setString(_planKey, value.plan.storageKey);
    await prefs.setBool(_trialKey, value.trial);
    await prefs.setBool(_previewKey, value.preview);
    if (value.startedAt == null) {
      await prefs.remove(_startedKey);
    } else {
      await prefs.setInt(_startedKey, value.startedAt!.millisecondsSinceEpoch);
    }
    if (value.renewsAt == null) {
      await prefs.remove(_renewsKey);
    } else {
      await prefs.setInt(_renewsKey, value.renewsAt!.millisecondsSinceEpoch);
    }
    state = AsyncData(value);
  }

  /// Activates the 7-day preview. No money moves; the UI says so plainly.
  Future<void> startPreview(PlusPlan plan) async {
    final now = DateTime.now();
    await _write(
      PlusState(
        active: true,
        plan: plan,
        startedAt: now,
        renewsAt: now.add(const Duration(days: 7)),
        trial: true,
        preview: true,
      ),
    );
  }

  Future<void> switchPlan(PlusPlan plan) async {
    final current = state.value ?? const PlusState.free();
    if (!current.isActive) return;
    await _write(
      PlusState(
        active: true,
        plan: plan,
        startedAt: current.startedAt,
        renewsAt: current.renewsAt,
        trial: current.trial,
        preview: current.preview,
      ),
    );
  }

  Future<void> cancel() async {
    await _write(const PlusState.free());
  }

  /// Returns true when a valid local entitlement was restored.
  Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final restored = _read(prefs);
    if (!restored.isActive) {
      state = const AsyncData(PlusState.free());
      return false;
    }
    state = AsyncData(restored);
    return true;
  }
}

final plusProvider = AsyncNotifierProvider<PlusController, PlusState>(
  PlusController.new,
);

/// Convenience for feature gates. Defaults to free while loading.
final isPlusProvider = Provider<bool>((ref) {
  return ref.watch(plusProvider).value?.isActive ?? false;
});
