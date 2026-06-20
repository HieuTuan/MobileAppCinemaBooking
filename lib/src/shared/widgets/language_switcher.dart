import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';

/// A segmented control that lets the user switch between Vietnamese and English.
///
/// Rebuilds when [LocaleService] notifies so the UI updates immediately.
///
/// **Requirements: 39.1, 39.2, 39.7**
class LanguageSwitcher extends StatefulWidget {
  const LanguageSwitcher({super.key});

  @override
  State<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<LanguageSwitcher> {
  @override
  void initState() {
    super.initState();
    LocaleService.instance.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LocaleService.instance.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = LocaleService.instance.locale.languageCode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LangButton(
          label: 'VI',
          selected: current == 'vi',
          onTap: () => LocaleService.instance.setLocale(const Locale('vi')),
        ),
        const SizedBox(width: 6),
        _LangButton(
          label: 'EN',
          selected: current == 'en',
          onTap: () => LocaleService.instance.setLocale(const Locale('en')),
        ),
      ],
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Colors.black : Colors.grey.shade400,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
