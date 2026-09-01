import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';
import 'detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  late Future<Cart?> _cartFuture;

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_refreshCart);
    _cartFuture = _cartService.getCartByUserId();
  }

  // Enhancement 3: Refresh whenever an item or quantity changes.
  void _refreshCart() {
    if (!mounted) return;
    setState(() {
      _cartFuture = Future.value(_cartService.currentCart);
    });
  }

  @override
  void dispose() {
    _cartService.removeListener(_refreshCart);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Enhancement 3: Render one user's interactive cart.
    return SafeArea(
      child: FutureBuilder<Cart?>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: CustomText(
                text: 'Error: ${snapshot.error}',
                fontSize: 14.sp,
              ),
            );
          }

          final cart = snapshot.data;
          if (cart == null) {
            return Center(
              child: CustomText(text: 'No cart found.', fontSize: 14.sp),
            );
          }

          return ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              _CartSummary(cart: cart),
              SizedBox(height: 12.h),
              if (cart.products.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 80.h),
                  child: Column(
                    children: [
                      Icon(Icons.remove_shopping_cart_outlined, size: 56.sp),
                      SizedBox(height: 12.h),
                      CustomText(
                        text: 'Your cart is empty.',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      SizedBox(height: 6.h),
                      CustomText(
                        text: 'Go to Shop and add a product.',
                        fontSize: 13.sp,
                      ),
                    ],
                  ),
                )
              else
                ...cart.products.map(
                  (product) => _CartProductCard(
                    product: product,
                    onIncrease: () => _cartService.increaseQuantity(product.id),
                    onDecrease: () => _cartService.decreaseQuantity(product.id),
                    onDelete: () => _cartService.removeProduct(product.id),
                    onOpen: () {
                      // Enhancement 1: Cart items remain clickable and reuse detail_screen.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(product: product),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: 'User ${cart.userId} Cart #${cart.id}',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 6.h),
            CustomText(
              text:
                  '${cart.totalProducts} products | ${cart.totalQuantity} items',
              fontSize: 13.sp,
            ),
            SizedBox(height: 8.h),
            CustomText(
              text: 'Total: \$${cart.total.toStringAsFixed(2)}',
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartProductCard extends StatelessWidget {
  const _CartProductCard({
    required this.product,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
    required this.onOpen,
  });

  final CartProduct product;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Column(
        children: [
          ListTile(
            onTap: onOpen,
            leading: Image.network(
              product.thumbnail,
              width: 48.w,
              height: 48.w,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.shopping_cart),
            ),
            title: CustomText(
              text: product.title,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: CustomText(
              text: '\$${product.price.toStringAsFixed(2)} each',
              fontSize: 12.sp,
            ),
            trailing: IconButton(
              tooltip: 'Remove product',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            child: Row(
              children: [
                CustomText(
                  text: 'Subtotal: \$${product.total.toStringAsFixed(2)}',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Decrease quantity',
                  onPressed: onDecrease,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                CustomText(
                  text: '${product.quantity}',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
                IconButton(
                  tooltip: 'Increase quantity',
                  onPressed: onIncrease,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
