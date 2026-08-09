/// Bottom sheet buat / ubah pot tabungan.
///
/// Target nominal dan tenggat bersifat opsional — pot tanpa target (mis. dana
/// darurat) tetap sah, dan mengosongkannya mengirim null ke backend.
library; // Savings goal form sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/idr_input_formatter.dart';
import '../../domain/entities/savings_goal.dart';
import '../providers/savings_provider.dart';

class SavingsForm extends ConsumerStatefulWidget {
  const SavingsForm({super.key, this.goal});

  /// null = mode buat baru.
  final SavingsGoal? goal;

  @override
  ConsumerState<SavingsForm> createState() => _SavingsFormState();
}

class _SavingsFormState extends ConsumerState<SavingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  final _noteController = TextEditingController();
  DateTime? _targetDate;
  late String _status;
  bool _isSubmitting = false;

  bool get _isEdit => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _nameController = TextEditingController(text: goal?.name ?? '');
    _targetController = TextEditingController(
      // Dibulatkan lebih dulu: amount bertipe DECIMAL(15,2) di backend, dan
      // titik desimalnya akan terbaca sebagai pemisah ribuan kalau dibiarkan.
      text: goal?.targetAmount != null
          ? formatIdrInput(goal!.targetAmount!.round().toString())
          : '',
    );
    _noteController.text = goal?.note ?? '';
    _targetDate = goal?.targetDate;
    _status = goal?.status ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    final notifier = ref.read(savingsProvider.notifier);
    final targetText = _targetController.text.trim();
    final target = targetText.isEmpty ? null : parseIdrInput(targetText);
    final date = _targetDate == null
        ? ''
        : '${_targetDate!.year}-${_targetDate!.month.toString().padLeft(2, '0')}-'
              '${_targetDate!.day.toString().padLeft(2, '0')}';

    try {
      if (_isEdit) {
        await notifier.update(
          id: widget.goal!.id,
          name: _nameController.text.trim(),
          targetAmount: target,
          targetDate: date,
          note: _noteController.text.trim(),
          status: _status,
        );
      } else {
        await notifier.create(
          name: _nameController.text.trim(),
          targetAmount: target,
          targetDate: date,
          note: _noteController.text.trim(),
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
              _FormHeader(
                title: _isEdit ? 'Ubah Tabungan' : 'Tambah Tabungan',
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama tabungan',
                  hintText: 'Contoh: Dana Darurat',
                ),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama tabungan wajib diisi'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _targetController,
                decoration: const InputDecoration(
                  labelText: 'Target (opsional)',
                  prefixText: 'Rp ',
                  helperText: 'Kosongkan kalau ini celengan bebas',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: const [IdrInputFormatter()],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return parseIdrInput(v) <= 0
                      ? 'Target harus lebih besar dari 0, atau kosongkan'
                      : null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _targetDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    locale: const Locale('id', 'ID'),
                  );
                  if (picked != null) setState(() => _targetDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tercapai pada (opsional)',
                    prefixIcon: const Icon(Icons.event),
                    suffixIcon: _targetDate == null
                        ? null
                        : IconButton(
                            tooltip: 'Hapus tenggat',
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _targetDate = null),
                          ),
                  ),
                  child: Text(
                    _targetDate == null
                        ? 'Belum ditentukan'
                        : formatDate(_targetDate!),
                  ),
                ),
              ),
              if (_isEdit) ...[
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Aktif')),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Tercapai'),
                    ),
                    DropdownMenuItem(
                      value: 'archived',
                      child: Text('Diarsipkan'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'active'),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                ),
                maxLines: 2,
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
                      : const Text('SIMPAN'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Menabung memindahkan uang dari saldo kas ke pot ini. '
                'Kekayaan bersihmu tidak berkurang.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({required this.title});

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
