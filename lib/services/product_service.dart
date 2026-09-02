import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product.dart';

class ProductService {
  static const List<int> sampleProductIds = [162, 113, 122, 138];

  Future<List<Product>> getAllProducts() async {
    // Enhancement 3: Render the exact four products from User 1's sample cart.
    final response = await http.get(Uri.parse('$host/products?limit=0'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List productsJson = data['products'] ?? [];
      final products = productsJson
          .map((json) => Product.fromJson(json))
          .where((product) => sampleProductIds.contains(product.id))
          .toList();

      products.sort(
        (first, second) => sampleProductIds
            .indexOf(first.id)
            .compareTo(sampleProductIds.indexOf(second.id)),
      );
      return products;
    } else {
      throw Exception('Failed to load products');
    }
  }
}
