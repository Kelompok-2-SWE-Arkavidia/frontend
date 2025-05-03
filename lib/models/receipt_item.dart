class ReceiptItem {
  final String name;
  final String category;
  final double price;
  final int quantity;
  final String unitMeasure;
  final String expiryDate;
  final bool isPackaged;
  final int estimatedAge;
  final double confidence;

  ReceiptItem({
    required this.name,
    required this.category,
    required this.price,
    required this.quantity,
    required this.unitMeasure,
    required this.expiryDate,
    required this.isPackaged,
    required this.estimatedAge,
    required this.confidence,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    try {
      // Fungsi helper untuk mendapatkan nilai dengan tipe yang benar atau nilai default jika error
      String getString(String key, String defaultValue) {
        return json.containsKey(key) && json[key] != null
            ? json[key].toString()
            : defaultValue;
      }

      double getDouble(String key, double defaultValue) {
        if (!json.containsKey(key) || json[key] == null) return defaultValue;
        try {
          if (json[key] is num) return (json[key] as num).toDouble();

          // Coba parse string dan hapus simbol mata uang jika ada
          String priceStr = json[key].toString().trim();

          // Hapus simbol mata uang ($, Rp, €, etc.)
          priceStr = priceStr.replaceAll(RegExp(r'[^\d.,]'), '');

          // Ganti koma dengan titik untuk parsing
          priceStr = priceStr.replaceAll(',', '.');

          // Jika masih ada multiple dots, ambil yang terakhir sebagai desimal
          if (priceStr.split('.').length > 2) {
            final parts = priceStr.split('.');
            final lastPart = parts.removeLast();
            priceStr = parts.join('') + '.' + lastPart;
          }

          return double.tryParse(priceStr) ?? defaultValue;
        } catch (_) {
          return defaultValue;
        }
      }

      int getInt(String key, int defaultValue) {
        if (!json.containsKey(key) || json[key] == null) return defaultValue;
        try {
          if (json[key] is int) return json[key];
          return int.tryParse(json[key].toString()) ?? defaultValue;
        } catch (_) {
          return defaultValue;
        }
      }

      bool getBool(String key, bool defaultValue) {
        if (!json.containsKey(key) || json[key] == null) return defaultValue;
        if (json[key] is bool) return json[key];
        String val = json[key].toString().toLowerCase();
        if (val == 'true' || val == '1' || val == 'yes') return true;
        if (val == 'false' || val == '0' || val == 'no') return false;
        return defaultValue;
      }

      // Deteksi mata uang dan konversi ke IDR jika perlu
      double processPrice(Map<String, dynamic> json) {
        double price = getDouble('price', 0.0);

        // Cek jika ada currency field dan harga perlu dikonversi ke IDR
        String currency = getString('currency', '').toUpperCase();
        if (currency == 'USD' ||
            currency == '\$' ||
            json.toString().contains('USD') ||
            json.toString().contains('\$')) {
          // Kurs konversi USD ke IDR (1 USD = sekitar 15,500 IDR)
          final double usdToIdrRate = 15500.0;
          price = price * usdToIdrRate;
          print(
            'Harga dikonversi dari USD ($price / $usdToIdrRate) ke IDR ($price)',
          );
        }

        // Mengalikan dengan 1000 untuk menangani kesalahan backend
        // Hanya lakukan jika harga sangat kecil (kemungkinan besar salah format)
        if (price > 0 && price < 1000) {
          double originalPrice = price;
          price = price * 1000;
          print(
            'Harga dikonversi dari $originalPrice menjadi $price (dikalikan 1000)',
          );
        }

        return price;
      }

      return ReceiptItem(
        name: getString('name', 'Unnamed Item'),
        category: getString('category', 'Uncategorized'),
        price: processPrice(json),
        quantity: getInt('quantity', 1),
        unitMeasure: getString('unit_measure', 'pcs'),
        expiryDate: getString('expiry_date', ''),
        isPackaged: getBool('is_packaged', true),
        estimatedAge: getInt('estimated_age', 0),
        confidence: getDouble('confidence', 1.0),
      );
    } catch (e) {
      // Log error dan return item default
      print('Error parsing ReceiptItem: $e');
      print('Problematic JSON: $json');

      // Return item default jika parsing gagal
      return ReceiptItem(
        name: 'Error Item',
        category: 'Error',
        price: 0.0,
        quantity: 1,
        unitMeasure: 'pcs',
        expiryDate: '',
        isPackaged: true,
        estimatedAge: 0,
        confidence: 0.0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'quantity': quantity,
      'unit_measure': unitMeasure,
      'expiry_date': expiryDate,
      'is_packaged': isPackaged,
      'estimated_age': estimatedAge,
      'confidence': confidence,
    };
  }
}
