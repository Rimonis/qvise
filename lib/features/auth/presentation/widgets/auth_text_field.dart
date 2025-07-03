import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final bool showClearButton;
  final bool showObscureToggle;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final Function(String)? onChanged;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.showClearButton = false,
    this.showObscureToggle = false,
    this.inputFormatters,
    this.maxLength,
    this.onChanged,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscured = true;
  late final TextEditingController _internalController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
    _internalController = widget.controller;
    _hasText = _internalController.text.isNotEmpty;
    
    // Listen to controller changes
    _internalController.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    _internalController.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    final hasText = _internalController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  // Input sanitization helper
  List<TextInputFormatter> _getInputFormatters() {
    final formatters = <TextInputFormatter>[];
    
    // Add custom formatters if provided
    if (widget.inputFormatters != null) {
      formatters.addAll(widget.inputFormatters!);
    }
    
    // Add sanitization based on keyboard type
    switch (widget.keyboardType) {
      case TextInputType.emailAddress:
        // For email: remove dangerous characters but allow valid email chars
        formatters.add(
          FilteringTextInputFormatter.deny(
            RegExp(r'[<>\";&\\]'), // Deny HTML/SQL injection chars
          ),
        );
        // Convert to lowercase
        formatters.add(LowerCaseTextFormatter());
        // Limit length
        formatters.add(LengthLimitingTextInputFormatter(100));
        break;
        
      case TextInputType.name:
        // For names: allow letters, spaces, hyphens, apostrophes
        formatters.add(
          FilteringTextInputFormatter.allow(
            RegExp(r"[a-zA-Z\s\-']"), // Only allow valid name characters
          ),
        );
        // Limit length
        formatters.add(LengthLimitingTextInputFormatter(50));
        break;
        
      case TextInputType.text:
        // For general text: basic sanitization
        formatters.add(
          FilteringTextInputFormatter.deny(
            RegExp(r'[<>]'), // Deny basic HTML tags
          ),
        );
        break;
        
      case TextInputType.phone:
        // For phone numbers: only digits, spaces, plus, dash, parentheses
        formatters.add(
          FilteringTextInputFormatter.allow(
            RegExp(r'[\d\s\+\-\(\)]'),
          ),
        );
        formatters.add(LengthLimitingTextInputFormatter(20));
        break;
        
      case TextInputType.number:
        // For numbers: only digits and decimal point
        formatters.add(
          FilteringTextInputFormatter.allow(
            RegExp(r'[\d\.]'),
          ),
        );
        break;
        
      default:
        // Default: basic sanitization
        formatters.add(
          FilteringTextInputFormatter.deny(
            RegExp(r'[<>]'),
          ),
        );
        break;
    }
    
    // Add max length formatter if specified and not already added
    if (widget.maxLength != null && 
        !formatters.any((f) => f is LengthLimitingTextInputFormatter)) {
      formatters.add(LengthLimitingTextInputFormatter(widget.maxLength));
    }
    
    return formatters;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      inputFormatters: _getInputFormatters(),
      onChanged: widget.onChanged,
      style: context.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: context.textTheme.bodyLarge?.copyWith(
          color: context.textTertiaryColor,
        ),
        prefixIcon: widget.prefixIcon != null 
          ? Icon(
              widget.prefixIcon,
              color: context.iconColor,
            ) 
          : null,
        suffixIcon: _buildSuffixIcons(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: BorderSide(color: context.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: BorderSide(color: context.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: BorderSide(color: context.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: AppSpacing.paddingAllMd,
        counterText: '', // Hide counter for maxLength
        filled: true,
        fillColor: context.surfaceColor,
      ),
    );
  }

  Widget? _buildSuffixIcons() {
    final List<Widget> icons = [];

    if (widget.showClearButton && _hasText) {
      icons.add(
        IconButton(
          icon: Icon(
            Icons.clear, 
            size: AppSpacing.iconSm,
            color: context.iconColor,
          ),
          onPressed: () {
            widget.controller.clear();
            // Notify parent of change
            widget.onChanged?.call('');
          },
          tooltip: 'Clear',
        ),
      );
    }

    if (widget.showObscureToggle) {
      icons.add(
        IconButton(
          icon: Icon(
            _obscured ? Icons.visibility : Icons.visibility_off,
            size: AppSpacing.iconSm,
            color: context.iconColor,
          ),
          onPressed: () {
            setState(() {
              _obscured = !_obscured;
            });
          },
          tooltip: _obscured ? 'Show password' : 'Hide password',
        ),
      );
    }

    if (icons.isEmpty) return null;
    
    return icons.length == 1 
        ? icons.first 
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: icons,
          );
  }
}

// Custom text formatter for lowercase
class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}

// Custom formatter to prevent consecutive spaces
class NoConsecutiveSpacesFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\s+'), ' ');
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: text.length.clamp(0, text.length),
      ),
    );
  }
}

// Custom formatter to capitalize first letter of each word (for names)
class NameCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final words = newValue.text.split(' ');
    final formatted = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    
    return TextEditingValue(
      text: formatted,
      selection: newValue.selection,
    );
  }
}

// Email validator helper
class EmailValidator {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  static bool isValid(String email) {
    return _emailRegex.hasMatch(email);
  }
  
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 5) {
      return 'Email is too short';
    }
    
    if (trimmed.length > 100) {
      return 'Email is too long';
    }
    
    if (!isValid(trimmed)) {
      return 'Please enter a valid email address';
    }
    
    // Check for common typos
    final domain = trimmed.split('@').last.toLowerCase();
    final commonDomains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com'];
    final typoDomains = ['gmial.com', 'gmai.com', 'yahooo.com', 'hotmial.com'];
    
    if (typoDomains.contains(domain)) {
      return 'Please check your email address for typos';
    }
    
    return null;
  }
}