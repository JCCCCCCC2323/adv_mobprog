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
  late final Future<Cart?> _cartFuture;

  @override
  void initState() {
    super.initState();
    _cartFuture = CartService().getCartByUserId();
  }

  @override
  Widget build(BuildContext context) {
    // Enhancement 3: Cart screen renders only one user's cart from /carts/user/{userId}.
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
          if (cart == null || cart.products.isEmpty) {
            return Center(
              child: CustomText(text: 'No cart found.', fontSize: 14.sp),
            );
          }

          return ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              Card(
                margin: EdgeInsets.only(bottom: 12.h),
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
                            '${cart.totalProducts} products | Total: \$${cart.discountedTotal.toStringAsFixed(2)}',
                        fontSize: 13.sp,
                      ),
                    ],
                  ),
                ),
              ),
              ...cart.products.map((product) {
                return Card(
                  margin: EdgeInsets.only(bottom: 10.h),
                  child: ListTile(
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
                      text:
                          'Qty: ${product.quantity} | \$${product.price.toStringAsFixed(2)}',
                      fontSize: 12.sp,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Enhancement 1: Cart items are clickable and open detail_screen.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(product: product),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
