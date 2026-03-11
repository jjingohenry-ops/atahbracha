import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;
  final Widget? icon;
  final ButtonStyle? style;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.textStyle,
    this.icon,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final effectiveForegroundColor = foregroundColor ?? Theme.of(context).colorScheme.onPrimary;
    
    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: (isLoading || isDisabled) ? null : onPressed,
        style: style ?? ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveForegroundColor,
          disabledBackgroundColor: effectiveBackgroundColor.withValues(alpha: 0.5),
          disabledForegroundColor: effectiveForegroundColor.withValues(alpha: 0.7),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveForegroundColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: textStyle ?? Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: effectiveForegroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class CustomOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Color? borderColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;
  final Widget? icon;

  const CustomOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.borderColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.textStyle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? Theme.of(context).colorScheme.primary;
    final effectiveForegroundColor = foregroundColor ?? Theme.of(context).colorScheme.primary;
    
    return Container(
      margin: margin,
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: (isLoading || isDisabled) ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: effectiveBorderColor),
          foregroundColor: effectiveForegroundColor,
          disabledBorderColor: effectiveBorderColor.withValues(alpha: 0.5),
          disabledForegroundColor: effectiveForegroundColor.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveForegroundColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: textStyle ?? Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: effectiveForegroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class CustomTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? textStyle;
  final Widget? icon;

  const CustomTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.foregroundColor,
    this.padding,
    this.margin,
    this.textStyle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveForegroundColor = foregroundColor ?? Theme.of(context).colorScheme.primary;
    
    return Container(
      margin: margin,
      child: TextButton(
        onPressed: (isLoading || isDisabled) ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: effectiveForegroundColor,
          disabledForegroundColor: effectiveForegroundColor.withValues(alpha: 0.7),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveForegroundColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: textStyle ?? Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: effectiveForegroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
