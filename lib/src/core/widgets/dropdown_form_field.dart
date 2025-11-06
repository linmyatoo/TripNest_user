import 'package:flutter/material.dart';

class WhiteDropdownFormField<T> extends StatelessWidget {
  final T? value;
  final Widget? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration? decoration;

  const WhiteDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    this.hint,
    this.onChanged,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.white),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        hint: hint,
        dropdownColor: Colors.white,
        decoration: decoration ?? const InputDecoration(),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
