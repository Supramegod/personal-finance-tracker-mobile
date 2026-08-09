/// Bottom sheet setor / tarik tabungan.
///
/// Setoran menurunkan saldo kas dan penarikan mengembalikannya, tapi keduanya
/// tercatat sebagai TRANSFER — tidak muncul di laporan pemasukan/pengeluaran.
library; // Savings deposit/withdraw sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/idr_input_formatter.dart';
import '../../domain/entities/savings_goal.dart';
import '../providers/savings_provider.dart';

class SavingsEntrySheet extends ConsumerStatefulWidget {
  const SavingsEntrySheet({
    super.key,
    required this.goal,
    required this.isWithdraw,
  });

  final SavingsGoal goal;
  final bool isWithdraw;

  @override
  ConsumerState<SavingsEntrySheet> createState() => _SavingsEntrySheetState();
}

class _SavingsEntrySheetState extends ConsumerState<SavingsEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nominal wajib diisi';
    final amount = parseIdrInput(value);
    if (amount <= 0) return 'Nominal harus lebih besar dari 0';
    if (widget.isWithdraw && amount > widget.goal.savedAmount) {
      // Pesan menyebutkan batasnya, bukan sekadar "tidak valid".
      return 'Melebihi saldo tabungan (${formatIdr(widget.goal.savedAmount)})';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // Tombol sudah dinonaktifkan saat submit, tapi guard ini menutup celah
    // tap ganda yang cepat — ini uang, setoran dobel tidak boleh terjadi.
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    final amount = parseIdrInput(_amountController.text);
    final notifier = ref.read(savingsProvider.notifier);
    final date =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-'
        '${_date.day.toString().padLeft(2, '0')}';
    final note = _noteController.text.trim();

    try {
      if (widget.isWithdraw) {
        await notifier.withdraw(
          id: widget.goal.id,
          amount: amount,
          date: date,
          note: note,
        );
      } else {
        await notifier.deposit(
          id: widget.goal.id,
          amount: amount,
          date: date,
          note: note,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.isWithdraw
        ? 'Tarik dari ${widget.goal.name}'
        : 'Setor ke ${widget.goal.name}';

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHeader(title: title),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isWithdraw ? 'Saldo tabungan' : 'Terkumpul',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      formatIdr(widget.goal.savedAmount),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: const [IdrInputFormatter()],
                validator: _validateAmount,
              ),
              const SizedBox(height: AppSpacing.md),
              _DateField(
                date: _date,
                onPicked: (picked) => setState(() => _date = picked),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: widget.isWithdraw
                      ? 'mis. servis motor'
                      : 'mis. sisa gajian',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.isWithdraw
                    ? 'Penarikan mengembalikan uang ke saldo kas dan tercatat '
                          'sebagai transfer, bukan pemasukan.'
                    : 'Setoran mengurangi saldo kas dan tercatat sebagai '
                          'transfer, bukan pengeluaran — laporan tidak terpengaruh.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.isWithdraw ? 'TARIK' : 'SETOR'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

/// Judul sheet + tombol tutup eksplisit.
///
/// Tombolnya bukan hiasan: menutup sheet hanya dengan swipe adalah gerakan
/// yang tidak punya alternatif satu-pointer, dan `namesRoute` memberi rute ini
/// nama yang bisa diumumkan pembaca layar.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Semantics(
                namesRoute: true,
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              tooltip: 'Tutup',
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onPicked});

  final DateTime date;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          locale: const Locale('id', 'ID'),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tanggal',
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(formatDate(date)),
      ),
    );
  }
}
