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

          return Column(
            children: [
              Expanded(
                child: cart.products.isEmpty
                    ? _buildEmptyCart()
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                        itemCount: cart.products.length,
                        itemBuilder: (context, index) {
                          final product = cart.products[index];
                          return _CartProductCard(
                            product: product,
                            onIncrease: () =>
                                _cartService.increaseQuantity(product.id),
                            onDecrease: () =>
                                _cartService.decreaseQuantity(product.id),
                            onDelete: () =>
                                _cartService.removeProduct(product.id),
                            onOpen: () {
                              // Enhancement 1: Reuse detail_screen when a cart card is clicked.
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetailScreen(product: product),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
              _CheckoutSummary(
                cart: cart,
                onConfirm: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order confirmed')),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.remove_shopping_cart_outlined, size: 56.sp),
          SizedBox(height: 12.h),
          CustomText(
            text: 'Your cart is empty.',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 6.h),
          CustomText(text: 'Go to Shop and add a product.', fontSize: 13.sp),
        ],
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
    final colorScheme = Theme.of(context).colorScheme;

    // Swipe a card to the left to remove it from the cart.
    return Dismissible(
      key: ValueKey(product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.only(right: 24.w),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(Icons.delete, color: colorScheme.onError),
      ),
      child: Card(
        elevation: 1,
        margin: EdgeInsets.only(bottom: 12.h),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Image.network(
                    product.thumbnail,
                    width: 72.w,
                    height: 72.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 72.w,
                      height: 72.w,
                      color: colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.shopping_bag_outlined),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: product.title,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5.h),
                      CustomText(
                        text: '\$${product.price.toStringAsFixed(2)}',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: 4.h),
                      CustomText(
                        text:
                            '${product.discountPercentage.toStringAsFixed(0)}% off • '
                            '\$${product.discountedTotal.toStringAsFixed(2)} total',
                        fontSize: 10.sp,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QuantityButton(
                      icon: Icons.add,
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      onPressed: onIncrease,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 3.h),
                      child: CustomText(
                        text: '${product.quantity}',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _QuantityButton(
                      icon: Icons.remove,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurface,
                      onPressed: onDecrease,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32.r,
      height: 32.r,
      child: IconButton(
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18.sp),
      ),
    );
  }
}

class _CheckoutSummary extends StatelessWidget {
  const _CheckoutSummary({required this.cart, required this.onConfirm});

  final Cart cart;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final savings = cart.total - cart.discountedTotal;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', amount: cart.total),
          SizedBox(height: 4.h),
          _SummaryRow(label: 'Discount', amount: -savings),
          Divider(height: 18.h),
          _SummaryRow(
            label: 'Total',
            amount: cart.discountedTotal,
            isBold: true,
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: cart.products.isEmpty ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: const Text(
                'Confirm Order',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.amount,
    this.isBold = false,
  });

  final String label;
  final double amount;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final amountText = amount < 0
        ? '-\$${amount.abs().toStringAsFixed(2)}'
        : '\$${amount.toStringAsFixed(2)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: label,
          fontSize: isBold ? 14.sp : 12.sp,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
        CustomText(
          text: amountText,
          fontSize: isBold ? 14.sp : 12.sp,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ],
    );
  }
}
