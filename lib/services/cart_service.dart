import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart.dart';
import '../models/product.dart';
import 'user_service.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();

  factory CartService() => _instance;

  CartService._internal();

  Cart? _cart;
  int _userId = 0;

  Cart? get currentCart => _cart;

  Future<Cart?> getCartByUserId() async {
    // Enhancement 3: Use the saved logged-in user ID for the cart endpoint.
    //Ocray do this completed//
    final userData = await UserService().getUserData();
    final savedUserId = userData['id'] as int? ?? 0;

    if (savedUserId <= 0) {
      throw Exception('No logged-in user found');
    }

    if (_userId != savedUserId) {
      _userId = savedUserId;
      _cart = null;
    }

    if (_cart != null) return _cart;

    final response = await http.get(Uri.parse('$host/carts/user/$_userId'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load user cart');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List cartsJson = data['carts'] ?? [];
    _cart = cartsJson.isEmpty
        ? _emptyCart()
        : Cart.fromJson(cartsJson.first as Map<String, dynamic>);

    notifyListeners();
    return _cart;
  }

  Future<Cart> addToCart(Product product, {int quantity = 1}) async {
    await getCartByUserId();

    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': _userId,
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

  void increaseQuantity(int productId) => _changeQuantity(productId, 1);

  void decreaseQuantity(int productId) => _changeQuantity(productId, -1);

  void removeProduct(int productId) {
    final products = List<CartProduct>.from(_cart?.products ?? [])
      ..removeWhere((item) => item.id == productId);
    _rebuildCart(products);
  }

  void resetCart() {
    _userId = 0;
    _cart = null;
    notifyListeners();
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
      userId: _userId,
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
      userId: _userId,
      totalProducts: 0,
      totalQuantity: 0,
    );
  }
}
