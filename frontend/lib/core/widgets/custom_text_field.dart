import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final String? Function(String?)? validator;
  final String? errorText;
  final String? helperText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry? contentPadding;
  final bool filled;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final TextStyle? style;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final bool showCounter;
  final AutovalidateMode autovalidateMode;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
    this.validator,
    this.errorText,
    this.helperText,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.textInputAction,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.contentPadding,
    this.filled = true,
    this.fillColor,
    this.borderRadius,
    this.style,
    this.labelStyle,
    this.hintStyle,
    this.showCounter = false,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      controller: controller,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      textInputAction: textInputAction,
      focusNode: focusNode,
      autovalidateMode: autovalidateMode,
      style: style ?? Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        helperText: helperText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: filled,
        fillColor: fillColor ?? Theme.of(context).colorScheme.surface,
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        labelStyle: labelStyle,
        hintStyle: hintStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        counterText: showCounter ? null : '',
      ),
    );
  }
}

class CustomPasswordTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final String? errorText;
  final String? helperText;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;
  final bool filled;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final TextStyle? style;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;

  const CustomPasswordTextField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.errorText,
    this.helperText,
    this.textInputAction,
    this.focusNode,
    this.contentPadding,
    this.filled = true,
    this.fillColor,
    this.borderRadius,
    this.style,
    this.labelStyle,
    this.hintStyle,
  });

  @override
  State<CustomPasswordTextField> createState() => _CustomPasswordTextFieldState();
}

class _CustomPasswordTextFieldState extends State<CustomPasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: widget.label,
      hint: widget.hint,
      initialValue: widget.initialValue,
      controller: widget.controller,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      obscureText: _obscureText,
      validator: widget.validator,
      errorText: widget.errorText,
      helperText: widget.helperText,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      contentPadding: widget.contentPadding,
      filled: widget.filled,
      fillColor: widget.fillColor,
      borderRadius: widget.borderRadius,
      style: widget.style,
      labelStyle: widget.labelStyle,
      hintStyle: widget.hintStyle,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}

class CustomSearchTextField extends StatefulWidget {
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final bool filled;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final TextStyle? style;
  final TextStyle? hintStyle;

  const CustomSearchTextField({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.enabled = true,
    this.contentPadding,
    this.filled = true,
    this.fillColor,
    this.borderRadius,
    this.style,
    this.hintStyle,
  });

  @override
  State<CustomSearchTextField> createState() => _CustomSearchTextFieldState();
}

class _CustomSearchTextFieldState extends State<CustomSearchTextField> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    final controller = widget.controller;
    if (controller != null) {
      _hasText = controller.text.isNotEmpty;
      controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller?.text.isNotEmpty ?? false;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      hint: widget.hint ?? 'Search...',
      controller: widget.controller,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      contentPadding: widget.contentPadding,
      filled: widget.filled,
      fillColor: widget.fillColor,
      borderRadius: widget.borderRadius,
      style: widget.style,
      hintStyle: widget.hintStyle,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: _hasText
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                widget.controller?.clear();
                widget.onClear?.call();
              },
            )
          : null,
    );
  }
}
