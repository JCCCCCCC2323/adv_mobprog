import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart.dart';
import '../models/product.dart';

class CartService {
  static const int userId = 5;

  Future<Cart?> getCartByUserId() async {
    // Enhancement 3: This uses the DummyJSON /carts/user/{userId} endpoint to render one user's cart.
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];

      if (cartsJson.isEmpty) {
        return null;
      }

      return Cart.fromJson(cartsJson.first);
    } else {
      throw Exception('Failed to load user cart');
    }
  }

  Future<Cart> addToCart(Product product, {int quantity = 1}) async {
    // Enhancement 3: This sends product values to the DummyJSON /carts/add endpoint.
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {'id': product.id, 'quantity': quantity},
        ],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Cart.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add product to cart');
    }
  }
}
