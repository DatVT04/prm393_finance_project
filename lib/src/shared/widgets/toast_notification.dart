import 'dart:async';

import 'package:flutter/material.dart';

enum ToastStatus { info, success, warning, error }

class ToastNotification {
  ToastNotification._();

  static void show(
    BuildContext context,
    String message, {
    ToastStatus status = ToastStatus.info,
  }) {
    final hostState = ToastHost.of(context);
    hostState?.show(message.trim(), status);
  }
}

class ToastHost extends StatefulWidget {
  const ToastHost({required this.child, super.key});

  final Widget child;

  static _ToastHostState? of(BuildContext context) {
    return context.findAncestorStateOfType<_ToastHostState>();
  }

  @override
  State<ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<ToastHost> {
  final List<_ToastEntry> _entries = [];
  final Duration _displayDuration = const Duration(seconds: 3);

  void show(String message, ToastStatus status) {
    if (message.isEmpty) return;
    final entry = _ToastEntry(
      id: UniqueKey().toString(),
      message: message,
      status: status,
    );
    setState(() {
      _entries.insert(0, entry);
    });

    unawaited(Future.delayed(_displayDuration, () => _remove(entry.id)));
  }

  void _remove(String id) {
    if (!mounted) return;
    setState(() {
      _entries.removeWhere((entry) => entry.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            minimum: const EdgeInsets.only(top: 16, right: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                _entries.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _ToastCard(entry: _entries[index]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToastEntry {
  const _ToastEntry({
    required this.id,
    required this.message,
    required this.status,
  });

  final String id;
  final String message;
  final ToastStatus status;
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({required this.entry});

  final _ToastEntry entry;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = _ToastStyle.fromStatus(widget.entry.status);
    return AnimatedSlide(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : const Offset(0.4, 0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 280),
        opacity: _visible ? 1 : 0,
        child: GestureDetector(
          onTap: () => ToastHost.of(context)?._remove(widget.entry.id),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              gradient: style.gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: style.shadowColor,
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(style.icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                child: Text(
                  widget.entry.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastStyle {
  const _ToastStyle({
    required this.gradient,
    required this.icon,
    required this.shadowColor,
  });

  final Gradient gradient;
  final IconData icon;
  final Color shadowColor;

  static _ToastStyle fromStatus(ToastStatus status) {
    switch (status) {
      case ToastStatus.success:
        return _ToastStyle(
          gradient: const LinearGradient(colors: [Color(0xFF0FB9B1), Color(0xFF34C18C)]),
          icon: Icons.check_circle,
          shadowColor: const Color(0xFF22C5AD).withOpacity(0.45),
        );
      case ToastStatus.warning:
        return _ToastStyle(
          gradient: const LinearGradient(colors: [Color(0xFFF6B347), Color(0xFFF06932)]),
          icon: Icons.warning,
          shadowColor: const Color(0xFFF58C3A).withOpacity(0.45),
        );
      case ToastStatus.error:
        return _ToastStyle(
          gradient: const LinearGradient(colors: [Color(0xFFEF476F), Color(0xFFB4162A)]),
          icon: Icons.error_outline,
          shadowColor: const Color(0xFFB4162A).withOpacity(0.45),
        );
      case ToastStatus.info:
      default:
        return _ToastStyle(
          gradient: const LinearGradient(colors: [Color(0xFF5A7BFF), Color(0xFF3DD3C7)]),
          icon: Icons.info_outline,
          shadowColor: const Color(0xFF3DD3C7).withOpacity(0.45),
        );
    }
  }
}
