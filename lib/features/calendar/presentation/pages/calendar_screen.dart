import 'package:flutter/material.dart'; // Calendar presentation page.

import '../../../../core/constants/app_spacing.dart';
import '../widgets/calendar_view_widget.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kalender Transaksi')),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        Text(
          'Aktivitas harian',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Pilih tanggal bertanda untuk melihat rincian transaksi.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        const CalendarViewWidget(),
      ],
    ),
  );
}
