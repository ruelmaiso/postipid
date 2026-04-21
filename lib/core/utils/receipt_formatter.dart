import '../models/app_models.dart';
import 'formatters.dart';

class ReceiptFormatter {
  static String format(
    AppSettingsModel settings,
    TransactionModel transaction,
    List<TransactionItemModel> items,
  ) {
    final width = paperWidthFor(settings.receiptPaperSize);
    final storeName =
        settings.storeName.trim().isEmpty ? 'TipidPOS' : settings.storeName.trim();
    final customer = (transaction.customerName ?? '').trim().isEmpty
        ? 'Walk-in'
        : transaction.customerName!.trim();
    final thin = '-' * width;
    final thick = '=' * width;
    final lines = <String>[];

    lines
      ..addAll(_centerBlock(storeName.toUpperCase(), width))
      ..addAll(_centerBlock(settings.storeAddress.trim(), width))
      ..addAll(_centerBlock(settings.contactNumber.trim(), width))
      ..addAll(_centerBlock(settings.receiptHeader.trim(), width))
      ..add(thin)
      ..add(_labelValue('Receipt #', transaction.transactionId.toString(), width))
      ..add(_labelValue('Date', toDateTimeLabel(transaction.createdAt), width))
      ..add(_labelValue('Customer', customer, width))
      ..add(_labelValue('Payment', transaction.paymentType, width))
      ..add(thin)
      ..add(_itemTableHeader(width))
      ..add(thin);

    if (items.isEmpty) {
      lines.addAll(_centerBlock('NO ITEMS', width));
    } else {
      for (final item in items) {
        lines.addAll(_itemLines(item, width));
      }
    }

    final totalQuantity = items.fold<int>(0, (sum, item) => sum + item.quantity);

    lines
      ..add(thin)
      ..add(_labelValue('Items', totalQuantity.toString(), width))
      ..add(_labelValue('Subtotal', _moneyCompact(transaction.totalAmount), width));

    if (transaction.paymentType.toLowerCase() == 'cash') {
      final cashReceived = transaction.cashReceived ?? transaction.totalAmount;
      lines
        ..add(_labelValue('Cash', _moneyCompact(cashReceived), width))
        ..add(_labelValue('Change', _moneyCompact(transaction.changeAmount), width));
    } else {
      lines.add(
        _labelValue(
          'Status',
          transaction.status.replaceAll('_', ' '),
          width,
        ),
      );
    }

    lines
      ..add(thick)
      ..add(_emphasizeTotal('TOTAL', _moneyCompact(transaction.totalAmount), width))
      ..add(thick)
      ..addAll(
        _centerBlock(
          settings.receiptFooter.trim().isEmpty
              ? 'THANK YOU. COME AGAIN!'
              : settings.receiptFooter.trim(),
          width,
        ),
      )
      ..addAll(_centerBlock(_paperSizeLabel(settings.receiptPaperSize), width))
      ..add('')
      ..add('');

    return lines.join('\n');
  }

  static int paperWidthFor(ReceiptPaperSize size) {
    switch (size) {
      case ReceiptPaperSize.mm58:
        return 32;
      case ReceiptPaperSize.mm80:
        return 42;
    }
  }

  static String _paperSizeLabel(ReceiptPaperSize size) {
    switch (size) {
      case ReceiptPaperSize.mm58:
        return 'THERMAL 58MM';
      case ReceiptPaperSize.mm80:
        return 'THERMAL 80MM';
    }
  }

  static String _itemTableHeader(int width) {
    const totalLabel = 'TOTAL';
    final itemWidth = width - totalLabel.length - 2;
    return 'ITEM'.padRight(itemWidth) + totalLabel.padLeft(totalLabel.length + 2);
  }

  static List<String> _itemLines(TransactionItemModel item, int width) {
    final name = item.itemName.trim().isEmpty ? 'Item #${item.itemId}' : item.itemName.trim();
    final total = _moneyCompact(item.subtotal);
    final priceLine = '${item.quantity} x ${_moneyCompact(item.price)}';
    final rows = <String>[];
    final wrappedName = _wrapText(name, width);

    if (wrappedName.isNotEmpty) {
      rows.addAll(wrappedName);
    }

    rows.add(_labelValue(priceLine, total, width));
    return rows;
  }

  static List<String> _centerBlock(String value, int width) {
    final clean = value.trim();
    if (clean.isEmpty) {
      return const [];
    }

    return _wrapText(clean, width).map((line) => _centerText(line, width)).toList(growable: false);
  }

  static List<String> _wrapText(String value, int width) {
    final clean = value.replaceAll('\n', ' ').trim();
    if (clean.isEmpty) {
      return const [];
    }

    final words = clean.split(RegExp(r'\s+'));
    final rows = <String>[];
    var buffer = '';

    for (final word in words) {
      if (word.length > width) {
        if (buffer.isNotEmpty) {
          rows.add(buffer);
          buffer = '';
        }
        rows.addAll(_chunkWord(word, width));
        continue;
      }

      final tentative = buffer.isEmpty ? word : '$buffer $word';
      if (tentative.length <= width) {
        buffer = tentative;
      } else {
        rows.add(buffer);
        buffer = word;
      }
    }

    if (buffer.isNotEmpty) {
      rows.add(buffer);
    }

    return rows;
  }

  static List<String> _chunkWord(String value, int width) {
    final rows = <String>[];
    for (var i = 0; i < value.length; i += width) {
      final end = (i + width) > value.length ? value.length : i + width;
      rows.add(value.substring(i, end));
    }
    return rows;
  }

  static String _centerText(String value, int width) {
    if (value.length >= width) {
      return value;
    }
    final left = ((width - value.length) / 2).floor();
    return '${' ' * left}$value';
  }

  static String _labelValue(String label, String value, int width) {
    final cleanLabel = label.trim();
    final cleanValue = value.trim();
    final maxLabel = width - cleanValue.length - 1;

    if (maxLabel > 4 && cleanLabel.length <= maxLabel) {
      return cleanLabel.padRight(width - cleanValue.length) + cleanValue;
    }

    return '$cleanLabel\n${cleanValue.padLeft(width)}';
  }

  static String _emphasizeTotal(String label, String value, int width) {
    final compact = '$label $value';
    if (compact.length >= width) {
      return compact;
    }
    final filler = '.' * (width - label.length - value.length);
    return '$label$filler$value';
  }

  static String _moneyCompact(num value) {
    final formatted = toPeso(value).replaceFirst('PHP ', '');
    return 'P$formatted';
  }
}
