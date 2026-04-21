import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_theme.dart';
import '../models/app_models.dart';
import 'app_frame.dart';

Future<void> showReceiptPreviewSheet({
  required BuildContext context,
  required String receipt,
  ReceiptPaperSize paperSize = ReceiptPaperSize.mm58,
  String title = 'Receipt Preview',
  Future<void> Function()? onPrint,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppInfoChip(
                      label: paperSize == ReceiptPaperSize.mm58 ? '58mm' : '80mm',
                      icon: Icons.receipt_long_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: ReceiptPaper(
                      receipt: receipt,
                      paperSize: paperSize,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                    if (onPrint != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await onPrint();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text('Print'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class ReceiptPaper extends StatelessWidget {
  const ReceiptPaper({
    super.key,
    required this.receipt,
    this.paperSize = ReceiptPaperSize.mm58,
  });

  final String receipt;
  final ReceiptPaperSize paperSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _previewWidth(paperSize)),
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                color: AppPalette.paper,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppPalette.line),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A101828),
                    blurRadius: 20,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppPalette.line,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        paperSize == ReceiptPaperSize.mm58 ? '58mm' : '80mm',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppPalette.slate,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SelectableText(
                    receipt,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: paperSize == ReceiptPaperSize.mm58 ? 12.4 : 12.8,
                      height: 1.55,
                      color: AppPalette.ink,
                    ),
                  ),
                ],
              ),
            ),
            for (final side in const [Alignment.centerLeft, Alignment.centerRight])
              Align(
                alignment: side,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppPalette.mist,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _previewWidth(ReceiptPaperSize size) {
    switch (size) {
      case ReceiptPaperSize.mm58:
        return 300;
      case ReceiptPaperSize.mm80:
        return 392;
    }
  }
}
