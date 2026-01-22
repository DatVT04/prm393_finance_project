import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class QuickActionButtons extends StatelessWidget {
  const QuickActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          context,
          icon: FontAwesomeIcons.plus,
          label: 'Nạp tiền',
          color: Colors.blue,
        ),
        _buildActionButton(
          context,
          icon: FontAwesomeIcons.paperPlane,
          label: 'Chuyển khoản',
          color: Colors.orange,
        ),
        _buildActionButton(
          context,
          icon: FontAwesomeIcons.fileInvoice,
          label: 'Thanh toán',
          color: Colors.purple,
        ),
        _buildActionButton(
          context,
          icon: FontAwesomeIcons.ellipsis,
          label: 'Xem thêm',
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
