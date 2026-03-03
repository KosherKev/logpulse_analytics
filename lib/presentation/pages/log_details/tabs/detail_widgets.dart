import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Shared section container with left-accent border — used across all tabs
class DetailSection extends StatelessWidget {
  const DetailSection({
    super.key,
    required this.title,
    required this.children,
    required this.c,
    this.accentBorder,
  });

  final String title;
  final List<Widget> children;
  final AppColorTokens c;
  final Color? accentBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: accentBorder ?? c.accent, width: 3),
          top: BorderSide(color: c.border),
          right: BorderSide(color: c.border),
          bottom: BorderSide(color: c.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.label.copyWith(color: c.textTertiary)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

/// Key-value row — 90px label column in monoSm textTertiary, value in monoSm textPrimary
class DetailKVRow extends StatelessWidget {
  const DetailKVRow({
    super.key,
    required this.label,
    required this.value,
    required this.c,
    this.valueColor,
  });

  final String label;
  final String value;
  final AppColorTokens c;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: AppTextStyles.monoSm.copyWith(color: c.textTertiary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              style: AppTextStyles.monoSm
                  .copyWith(color: valueColor ?? c.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Expandable headers / query-params section
class DetailHeadersSection extends StatefulWidget {
  const DetailHeadersSection({
    super.key,
    required this.title,
    required this.content,
    required this.c,
  });

  final String title;
  final Map<String, dynamic>? content;
  final AppColorTokens c;

  @override
  State<DetailHeadersSection> createState() => _DetailHeadersSectionState();
}

class _DetailHeadersSectionState extends State<DetailHeadersSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final isEmpty = widget.content == null || widget.content!.isEmpty;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: isEmpty ? null : () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Text(widget.title,
                      style:
                          AppTextStyles.label.copyWith(color: c.textTertiary)),
                  const Spacer(),
                  if (!isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${widget.content!.length}',
                        style: AppTextStyles.monoSm.copyWith(
                            color: c.textTertiary, fontSize: 10),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: c.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && !isEmpty) ...[
            Divider(height: 1, color: c.borderSoft),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: widget.content!.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(entry.key,
                              style: AppTextStyles.monoSm
                                  .copyWith(color: c.textTertiary)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableText(
                            entry.value.toString(),
                            style: AppTextStyles.monoSm
                                .copyWith(color: c.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                'No ${widget.title.toLowerCase()}',
                style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dark terminal body block (JSON / raw text)
class DetailBodySection extends StatelessWidget {
  const DetailBodySection({
    super.key,
    required this.title,
    required this.body,
    required this.prettyPrint,
    required this.onTogglePretty,
    required this.c,
  });

  final String title;
  final dynamic body;
  final bool prettyPrint;
  final VoidCallback onTogglePretty;
  final AppColorTokens c;

  @override
  Widget build(BuildContext context) {
    String bodyText;
    try {
      bodyText =
          prettyPrint ? FormatUtils.prettyPrintJson(body) : json.encode(body);
    } catch (_) {
      bodyText = body.toString();
    }

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Text(title,
                    style:
                        AppTextStyles.label.copyWith(color: c.textTertiary)),
                const Spacer(),
                DetailActionChip(
                  label: prettyPrint ? 'RAW' : 'PRETTY',
                  c: c,
                  onTap: onTogglePretty,
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: bodyText));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text('Copied', style: AppTextStyles.monoSm),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.copy_rounded,
                        size: 16, color: c.textTertiary),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.borderSoft),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(11),
                bottomRight: Radius.circular(11),
              ),
            ),
            child: SelectableText(
              bodyText,
              style: AppTextStyles.monoSm.copyWith(
                color: AppColors.darkTextPrimary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple empty placeholder block
class DetailEmptyBlock extends StatelessWidget {
  const DetailEmptyBlock({super.key, required this.label, required this.c});
  final String label;
  final AppColorTokens c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Text(label,
          style: AppTextStyles.monoSm.copyWith(color: c.textTertiary)),
    );
  }
}

/// Small pill action chip (RAW / PRETTY toggle etc.)
class DetailActionChip extends StatelessWidget {
  const DetailActionChip(
      {super.key, required this.label, required this.c, required this.onTap});
  final String label;
  final AppColorTokens c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.border),
        ),
        child: Text(label,
            style: AppTextStyles.label.copyWith(color: c.textTertiary)),
      ),
    );
  }
}
