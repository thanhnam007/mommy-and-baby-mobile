import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/baby_provider.dart';

class BabyPickerSheet extends StatelessWidget {
  const BabyPickerSheet({super.key});

  void _showAddBabyDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final nickCtrl = TextEditingController();
    String gender = 'boy';
    DateTime birthDate = DateTime.now().subtract(const Duration(days: 60));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thêm Hồ Sơ Bé Mới 👶', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Tên bé *', hintText: 'VD: Nguyễn Minh An'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nickCtrl,
                    decoration: const InputDecoration(labelText: 'Tên thân mật ở nhà', hintText: 'VD: Bắp, Sữa...'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('👦 Bé Trai')),
                          selected: gender == 'boy',
                          onSelected: (val) => setState(() => gender = 'boy'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('👧 Bé Gái')),
                          selected: gender == 'girl',
                          onSelected: (val) => setState(() => gender = 'girl'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.grey, width: 0.5)),
                    leading: const Icon(Icons.cake_outlined, color: AppTheme.brand500),
                    title: const Text('Ngày sinh của bé', style: TextStyle(fontSize: 13)),
                    subtitle: Text('${birthDate.day}/${birthDate.month}/${birthDate.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.calendar_month, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: birthDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => birthDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;

                        final babyProv = Provider.of<BabyProvider>(context, listen: false);
                        final dateStr = '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}';
                        final ok = await babyProv.createBaby({
                          'name': name,
                          'nickname': nickCtrl.text.trim().isNotEmpty ? nickCtrl.text.trim() : null,
                          'gender': gender,
                          'birth_date': dateStr,
                        });

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted && ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã thêm hồ sơ bé thành công! 🎉')),
                          );
                        }
                      },
                      child: const Text('Tạo hồ sơ bé'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final babyProvider = Provider.of<BabyProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray700 : AppTheme.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Chọn Bé Đang Theo Dõi 👶', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm bé', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  Navigator.pop(context);
                  _showAddBabyDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (babyProvider.babies.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Chưa có hồ sơ bé nào.')),
            )
          else
            ...babyProvider.babies.map((baby) {
              final isSelected = babyProvider.activeBaby?.id == baby.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppTheme.brand500.withValues(alpha: 0.2) : AppTheme.brand50)
                      : (isDark ? AppTheme.gray800 : AppTheme.gray50),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.brand500 : (isDark ? AppTheme.gray700 : AppTheme.gray200),
                  ),
                ),
                child: ListTile(
                  leading: Text(baby.genderEmoji, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    '${baby.name} ${baby.nickname != null ? "(${baby.nickname})" : ""}',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppTheme.brand500 : null,
                    ),
                  ),
                  subtitle: Text(baby.ageText, style: const TextStyle(fontSize: 11)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppTheme.brand500)
                      : null,
                  onTap: () {
                    babyProvider.selectBaby(baby);
                    Navigator.pop(context);
                  },
                ),
              );
            }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
