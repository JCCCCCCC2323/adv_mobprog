import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../widgets/custom_text.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.product});

  final CartProduct product;

  @override
  Widget build(BuildContext context) {
    // Enhancement 1: Detail screen displays the clicked cart item using a screen widget.
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Cart Item Details',
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(
                product.thumbnail,
                height: 220.h,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.shopping_cart, size: 80.sp),
              ),
            ),
            SizedBox(height: 24.h),
            CustomText(
              text: product.title,
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 12.h),
            CustomText(
              text: 'Price: \$${product.price.toStringAsFixed(2)}',
              fontSize: 16.sp,
            ),
            SizedBox(height: 8.h),
            CustomText(text: 'Quantity: ${product.quantity}', fontSize: 16.sp),
            SizedBox(height: 8.h),
            CustomText(
              text: 'Total: \$${product.total.toStringAsFixed(2)}',
              fontSize: 16.sp,
            ),
            SizedBox(height: 8.h),
            CustomText(
              text:
                  'Discount: ${product.discountPercentage.toStringAsFixed(2)}%',
              fontSize: 16.sp,
            ),
            SizedBox(height: 8.h),
            CustomText(
              text:
                  'Discounted Total: \$${product.discountedTotal.toStringAsFixed(2)}',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ],
        ),
      ),
    );
  }
}
