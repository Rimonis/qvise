import 'package:flutter/material.dart';
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class ContentFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool enabled;
  final List<String> suggestions;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final int maxLines;
  
  const ContentFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.enabled = true,
    this.suggestions = const [],
    this.onChanged,
    this.validator,
    this.maxLines = 1,
  });

  @override
  State<ContentFormField> createState() => _ContentFormFieldState();
}

class _ContentFormFieldState extends State<ContentFormField> {
  late FocusNode _focusNode;
  List<String> _filteredSuggestions = [];
  bool _showSuggestions = false;
  
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }
  
  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }
  
  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      setState(() {
        _showSuggestions = false;
      });
    }
  }
  
  void _onTextChanged() {
    final text = widget.controller.text.toLowerCase();
    if (text.isEmpty || widget.suggestions.isEmpty) {
      setState(() {
        _filteredSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    
    final filtered = widget.suggestions
        .where((s) => s.toLowerCase().contains(text))
        .toList();
    
    setState(() {
      _filteredSuggestions = filtered;
      _showSuggestions = filtered.isNotEmpty && _focusNode.hasFocus;
    });
    
    widget.onChanged?.call(widget.controller.text);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          validator: widget.validator,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              borderSide: BorderSide(
                color: context.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              borderSide: BorderSide(color: context.borderColor.withValues(alpha: 0.5)),
            ),
            filled: !widget.enabled,
            fillColor: widget.enabled ? null : context.surfaceVariantColor.withValues(alpha: 0.3),
          ),
          onTap: () {
            _onTextChanged();
          },
        ),
        if (_showSuggestions && _filteredSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xs),
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: context.borderColor),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _filteredSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _filteredSuggestions[index];
                final isSelected = suggestion == widget.controller.text;
                
                return ListTile(
                  dense: true,
                  title: Text(
                    suggestion,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check,
                          size: AppSpacing.iconSm,
                          color: context.primaryColor,
                        )
                      : null,
                  onTap: () {
                    widget.controller.text = suggestion;
                    widget.onChanged?.call(suggestion);
                    setState(() {
                      _showSuggestions = false;
                    });
                    _focusNode.unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}