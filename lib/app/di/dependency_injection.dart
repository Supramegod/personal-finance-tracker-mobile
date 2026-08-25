import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_di.dart';
import '../../features/calendar/calendar_di.dart';
import '../../features/dashboard/dashboard_di.dart';
import '../../features/groups/groups_di.dart';
import '../../features/installments/installments_di.dart';
import '../../features/more/more_di.dart';
import '../../features/reports/reports_di.dart';
import '../../features/savings/savings_di.dart';
import '../../features/settings/settings_di.dart';
import '../../features/transactions/transactions_di.dart';

/// Central composition root. Feature providers remain lazy by Riverpod design;
/// feature registrars expose the override seam used by tests and environments.
List<Override> buildDependencyOverrides() => [
  ...registerAuthDependencies(),
  ...registerCalendarDependencies(),
  ...registerDashboardDependencies(),
  ...registerGroupsDependencies(),
  ...registerInstallmentsDependencies(),
  ...registerMoreDependencies(),
  ...registerReportsDependencies(),
  ...registerSavingsDependencies(),
  ...registerSettingsDependencies(),
  ...registerTransactionsDependencies(),
];
