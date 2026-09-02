import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart.dart';
import '../models/product.dart';

class CartService extends ChangeNotifier {
  static const int userId = 1;
  static final CartService _instance = CartService._internal();

  factory CartService() => _instance;

  CartService._internal();

  Cart? _cart;

  Cart? get currentCart => _cart;

  Future<Cart?> getCartByUserId() async {
    if (_cart != null) return _cart;

    // Enhancement 3: Load only one user's cart from DummyJSON.
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load user cart');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List cartsJson = data['carts'] ?? [];
    if (cartsJson.isEmpty) {
      _cart = _emptyCart();
    } else {
      _cart = Cart.fromJson(cartsJson.first);
    }

    notifyListeners();
    return _cart;
  }

  Future<Cart> addToCart(Product product, {int quantity = 1}) async {
    await getCartByUserId();

    // Enhancement 3: Send the selected product and user values to /carts/add.
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

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add product');
    }

    // DummyJSON simulates the request, so also update the shared local cart.
    _addProductLocally(product, quantity);
    return _cart!;
  }

  // Enhancement 3: Add, subtract, and delete items while updating the total.
  void increaseQuantity(int productId) => _changeQuantity(productId, 1);

  void decreaseQuantity(int productId) => _changeQuantity(productId, -1);

  void removeProduct(int productId) {
    final products = List<CartProduct>.from(_cart?.products ?? [])
      ..removeWhere((item) => item.id == productId);
    _rebuildCart(products);
  }

  void _changeQuantity(int productId, int change) {
    final products = List<CartProduct>.from(_cart?.products ?? []);
    final index = products.indexWhere((item) => item.id == productId);
    if (index < 0) return;

    final item = products[index];
    final quantity = item.quantity + change;
    if (quantity <= 0) {
      products.removeAt(index);
    } else {
      products[index] = _copyWithQuantity(item, quantity);
    }
    _rebuildCart(products);
  }

  void _addProductLocally(Product product, int quantity) {
    final products = List<CartProduct>.from(_cart?.products ?? []);
    final index = products.indexWhere((item) => item.id == product.id);

    if (index >= 0) {
      final item = products[index];
      products[index] = _copyWithQuantity(item, item.quantity + quantity);
    } else {
      final total = product.price * quantity;
      products.add(
        CartProduct(
          id: product.id,
          title: product.title,
          price: product.price,
          quantity: quantity,
          total: total,
          discountPercentage: product.discountPercentage,
          discountedTotal: total * (1 - product.discountPercentage / 100),
          thumbnail: product.thumbnail,
        ),
      );
    }
    _rebuildCart(products);
  }

  CartProduct _copyWithQuantity(CartProduct item, int quantity) {
    final total = item.price * quantity;
    return CartProduct(
      id: item.id,
      title: item.title,
      price: item.price,
      quantity: quantity,
      total: total,
      discountPercentage: item.discountPercentage,
      discountedTotal: total * (1 - item.discountPercentage / 100),
      thumbnail: item.thumbnail,
    );
  }

  void _rebuildCart(List<CartProduct> products) {
    _cart = Cart(
      id: _cart?.id ?? 0,
      products: products,
      total: products.fold(0.0, (sum, item) => sum + item.total),
      discountedTotal: products.fold(
        0.0,
        (sum, item) => sum + item.discountedTotal,
      ),
      userId: userId,
      totalProducts: products.length,
      totalQuantity: products.fold(0, (sum, item) => sum + item.quantity),
    );
    notifyListeners();
  }

  Cart _emptyCart() {
    return Cart(
      id: 0,
      products: const [],
      total: 0,
      discountedTotal: 0,
      userId: userId,
      totalProducts: 0,
      totalQuantity: 0,
    );
  }
}
