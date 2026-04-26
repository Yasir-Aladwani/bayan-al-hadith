import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_font.dart';
import '../models/answer_response.dart';

class HadithSourceCard extends StatefulWidget {
  final HadithSource source;

  const HadithSourceCard({super.key, required this.source});

  @override
  State<HadithSourceCard> createState() => _HadithSourceCardState();
}

class _HadithSourceCardState extends State<HadithSourceCard> {
  bool _expanded = false;

  Color _gradeColor(String grade) {
    if (grade.contains('صحيح')) return const Color(0xFF4CAF50);
    if (grade.contains('حسن')) return const Color(0xFFD4AF37);
    if (grade.contains('ثابت')) return const Color(0xFF81C784);
    return const Color(0xFF6B8A6B);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          // ── Header (always visible) ──────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Grade badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _gradeColor(widget.source.grade).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _gradeColor(widget.source.grade).withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      widget.source.grade,
                      style: appFont(
                        color: _gradeColor(widget.source.grade),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.source.source,
                      style: appFont(
                        color: const Color(0xFF8AB89A),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF4A6A4A),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded Content ─────────────────────────
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFF1A3A2A), height: 1),
                  const SizedBox(height: 10),

                  // Hadith text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162B1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.source.text,
                      style: GoogleFonts.amiri(
                        color: const Color(0xFFF5EDD6),
                        fontSize: 15,
                        height: 1.8,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Meta rows
                  _MetaRow(label: 'الراوي', value: widget.source.narrator),
                  const SizedBox(height: 4),
                  _MetaRow(label: 'المصدر', value: widget.source.source),
                  const SizedBox(height: 4),
                  _MetaRow(label: 'الدرجة', value: widget.source.grade),

                  const SizedBox(height: 10),

                  // Copy button
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: widget.source.text),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تم نسخ الحديث',
                            style: appFont(),
                            textDirection: TextDirection.rtl,
                          ),
                          backgroundColor: const Color(0xFF1A4A2A),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: Color(0xFF4A6A4A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'نسخ الحديث',
                          style: appFont(
                            color: const Color(0xFF4A6A4A),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: appFont(
            color: const Color(0xFF6B8A6B),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: appFont(
              color: const Color(0xFFB8A07A),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
