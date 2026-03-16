import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:prm393_finance_project/src/core/models/category_model.dart';

class AddCategoryModal extends StatefulWidget {
  const AddCategoryModal({super.key, this.existing});

  final CategoryModel? existing;

  @override
  State<AddCategoryModal> createState() => _AddCategoryModalState();
}

class _AddCategoryModalState extends State<AddCategoryModal> {
  late final TextEditingController _nameController;

  // We store the FontAwesome "name" as a string in CategoryModel.iconName.
  late String? _selectedIconName;
  late Color _selectedColor;

  static const _iconOptions = <(String, IconData)>[
    ('utensils', FontAwesomeIcons.utensils),
    ('cartShopping', FontAwesomeIcons.cartShopping),
    ('moneyBillWave', FontAwesomeIcons.moneyBillWave),
    ('sackDollar', FontAwesomeIcons.sackDollar),
    ('piggyBank', FontAwesomeIcons.piggyBank),
    ('wallet', FontAwesomeIcons.wallet),
    ('film', FontAwesomeIcons.film),
    ('gamepad', FontAwesomeIcons.gamepad),
    ('heartbeat', FontAwesomeIcons.heartPulse),
    ('hospital', FontAwesomeIcons.hospital),
    ('stethoscope', FontAwesomeIcons.stethoscope),
    ('graduationCap', FontAwesomeIcons.graduationCap),
    ('bus', FontAwesomeIcons.bus),
    ('car', FontAwesomeIcons.car),
    ('motorcycle', FontAwesomeIcons.motorcycle),
    ('house', FontAwesomeIcons.house),
    ('lightbulb', FontAwesomeIcons.lightbulb),
    ('gift', FontAwesomeIcons.gift),
    ('plane', FontAwesomeIcons.plane),
    ('coffee', FontAwesomeIcons.mugSaucer),
  ];

  static const _colorOptions = <Color>[
    Color(0xFF006D5B),
    Color(0xFF2E7D32),
    Color(0xFF0288D1),
    Color(0xFF7B1FA2),
    Color(0xFFF57C00),
    Color(0xFFD32F2F),
    Color(0xFF5D4037),
    Color(0xFF455A64),
    Color(0xFF009688),
    Color(0xFF9C27B0),
    Color(0xFFFFC107),
    Color(0xFF8BC34A),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _selectedIconName = widget.existing?.iconName;
    _selectedColor = _parseColor(widget.existing?.colorHex) ?? _colorOptions.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final h = hex.startsWith('#') ? hex : '#$hex';
    if (h.length != 7) return null;
    final r = int.tryParse(h.substring(1, 3), radix: 16);
    final g = int.tryParse(h.substring(3, 5), radix: 16);
    final b = int.tryParse(h.substring(5, 7), radix: 16);
    if (r == null || g == null || b == null) return null;
    return Color.fromARGB(255, r, g, b);
  }

  String _colorToHex(Color color) {
    return '#${color.red.toRadixString(16).padLeft(2, '0')}${color.green.toRadixString(16).padLeft(2, '0')}${color.blue.toRadixString(16).padLeft(2, '0')}';
  }

  IconData _iconFromName(String? name) {
    if (name == null || name.isEmpty) {
      return FontAwesomeIcons.shapes;
    }
    final match = _iconOptions.firstWhere(
      (e) => e.$1 == name,
      orElse: () => ('shapes', FontAwesomeIcons.shapes),
    );
    return match.$2;
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  existing != null ? 'Sửa danh mục' : 'Thêm danh mục',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _selectedColor.withOpacity(0.15),
                  child: Icon(
                    _iconFromName(_selectedIconName),
                    color: _selectedColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên danh mục *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chọn biểu tượng',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _iconOptions.length,
                itemBuilder: (context, index) {
                  final (name, icon) = _iconOptions[index];
                  final isSelected = _selectedIconName == name;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        _selectedIconName = name;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor.withOpacity(0.12)
                            : Colors.grey.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? _selectedColor : Colors.transparent,
                          width: 1.6,
                        ),
                      ),
                      child: Center(
                        child: FaIcon(
                          icon,
                          color: isSelected ? _selectedColor : Colors.grey[700],
                          size: 22,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chọn màu sắc',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _colorOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final color = _colorOptions[index];
                  final isSelected = _selectedColor.value == color.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.black12,
                          width: 2,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: color.withOpacity(0.6),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _onSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: _selectedColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(existing != null ? 'Lưu' : 'Thêm'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _onSubmit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên danh mục')),
      );
      return;
    }

    final existing = widget.existing;
    final category = CategoryModel(
      id: existing?.id ?? 0,
      name: name,
      iconName: _selectedIconName,
      colorHex: _colorToHex(_selectedColor),
      sortOrder: existing?.sortOrder,
    );
    Navigator.of(context).pop(category);
  }
}

