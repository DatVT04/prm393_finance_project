import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class IconUtils {
  static IconData getIconData(String? name, {String? fallbackName}) {
    if (name == null || name.isEmpty) {
      if (fallbackName != null) {
        return getIconByDisplayName(fallbackName);
      }
      return Icons.help_outline;
    }

    // Material Icons
    switch (name) {
      case 'account_balance_wallet': return Icons.account_balance_wallet;
      case 'account_balance': return Icons.account_balance;
      case 'credit_card': return Icons.credit_card;
      case 'savings': return Icons.savings;
      case 'payments': return Icons.payments;
      case 'wallet': return Icons.wallet;
      case 'money': return Icons.money;
      case 'attach_money': return Icons.attach_money;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'restaurant': return Icons.restaurant;
      case 'directions_car': return Icons.directions_car;
      case 'house': return Icons.house;
      case 'devices': return Icons.devices;
      case 'health_and_safety': return Icons.health_and_safety;
      case 'school': return Icons.school;
      case 'redeem': return Icons.redeem;
      case 'category': return Icons.category;
      case 'local_parking': return Icons.local_parking;
      case 'medical_services': return Icons.medical_services;
      case 'add_circle_outline': return Icons.add_circle_outline;
    }

    // FontAwesome Icons
    switch (name) {
      case 'utensils': return FontAwesomeIcons.utensils;
      case 'cartShopping': return FontAwesomeIcons.cartShopping;
      case 'moneyBillWave': return FontAwesomeIcons.moneyBillWave;
      case 'sackDollar': return FontAwesomeIcons.sackDollar;
      case 'piggyBank': return FontAwesomeIcons.piggyBank;
      case 'wallet_fa': return FontAwesomeIcons.wallet;
      case 'film': return FontAwesomeIcons.film;
      case 'gamepad': return FontAwesomeIcons.gamepad;
      case 'heartbeat':
      case 'heartPulse': return FontAwesomeIcons.heartPulse;
      case 'hospital': return FontAwesomeIcons.hospital;
      case 'stethoscope': return FontAwesomeIcons.stethoscope;
      case 'graduationCap': return FontAwesomeIcons.graduationCap;
      case 'bus': return FontAwesomeIcons.bus;
      case 'car': return FontAwesomeIcons.car;
      case 'motorcycle': return FontAwesomeIcons.motorcycle;
      case 'house_fa': return FontAwesomeIcons.house;
      case 'lightbulb': return FontAwesomeIcons.lightbulb;
      case 'gift': return FontAwesomeIcons.gift;
      case 'plane': return FontAwesomeIcons.plane;
      case 'coffee':
      case 'mugSaucer': return FontAwesomeIcons.mugSaucer;
      case 'shapes': return FontAwesomeIcons.shapes;
    }

    if (fallbackName != null) {
      return getIconByDisplayName(fallbackName);
    }
    return Icons.help_outline;
  }

  static IconData getIconByDisplayName(String name) {
    switch (name) {
      case 'Ăn uống': return Icons.restaurant;
      case 'Xăng xe': return Icons.directions_car;
      case 'Mua sắm': return Icons.shopping_cart;
      case 'Giải trí': return Icons.gamepad;
      case 'Y tế': return Icons.medical_services;
      case 'Giáo dục': return Icons.school;
      case 'Gửi xe': return Icons.local_parking;
      case 'Nạp tiền':
      case 'Thu nhập': return Icons.add_circle_outline;
      case 'Khác': return Icons.category;
      default: return Icons.category;
    }
  }

  static Widget buildIcon(String? iconName, {String? categoryName, Color? color, double size = 24}) {
    final iconData = getIconData(iconName, fallbackName: categoryName);
    if (iconData is IconData && (iconName != null && _isFontAwesome(iconName))) {
      return FaIcon(iconData, color: color, size: size);
    }
    // Check if iconData itself is from FontAwesome (even if iconName is from fallback)
    if (_isFontAwesomeIcon(iconData)) {
       return FaIcon(iconData, color: color, size: size);
    }
    return Icon(iconData, color: color, size: size);
  }

  static bool _isFontAwesome(String name) {
    const faNames = {
      'utensils', 'cartShopping', 'moneyBillWave', 'sackDollar', 'piggyBank', 
      'wallet_fa', 'film', 'gamepad', 'heartbeat', 'heartPulse', 'hospital', 
      'stethoscope', 'graduationCap', 'bus', 'car', 'motorcycle', 'house_fa', 
      'lightbulb', 'gift', 'plane', 'coffee', 'mugSaucer', 'shapes'
    };
    return faNames.contains(name);
  }

  static bool _isFontAwesomeIcon(IconData icon) {
    return icon.fontFamily == 'FontAwesomeBrands' || 
           icon.fontFamily == 'FontAwesomeRegular' || 
           icon.fontFamily == 'FontAwesomeSolid' ||
           icon.fontPackage == 'font_awesome_flutter';
  }

  static Color getColor(String? hex, {Color defaultColor = Colors.blue}) {
    if (hex == null || hex.isEmpty) return defaultColor;
    try {
      final h = hex.startsWith('#') ? hex : '#$hex';
      if (h.length == 7) {
        return Color(int.parse(h.replaceFirst('#', '0xFF')));
      } else if (h.length == 9) {
        return Color(int.parse(h.replaceFirst('#', '0x')));
      }
      return defaultColor;
    } catch (_) {
      return defaultColor;
    }
  }

  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}
