import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/cart.dart';

// services
import '../services/cart_service.dart';
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

// screens
import 'detail_screen.dart';

// ======================= LAB 3 - ENHANCEMENT 1 =======================
// Cart page that renders the cart API endpoint. Each item is clickable
// and opens the same detail_screen used by the ProductScreen.
// =====================================================================
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final Future<Cart?> _cartFuture;

  // Quantities changed with the +/- buttons, keyed by product id.
  final Map<int, int> _quantities = {};

  @override
  void initState() {
    super.initState();
    // LAB 4 - ENHANCEMENT 3: render the cart of the saved user id.
    _cartFuture = UserService().getUser().then(
      (user) => CartService().getCartByUserId(user.id),
    );
  }

  int _quantityOf(CartProduct item) => _quantities[item.id] ?? item.quantity;

  void _changeQuantity(CartProduct item, int delta) {
    final next = _quantityOf(item) + delta;
    if (next < 1) return;
    setState(() => _quantities[item.id] = next);
  }

  double _discountedTotalOf(CartProduct item) =>
      item.price * _quantityOf(item) * (1 - item.discountPercentage / 100);

  // Merges the products added from the DetailScreen into the fetched
  // cart. A product already in the cart gets its quantity raised.
  List<CartProduct> _withAddedProducts(List<CartProduct> products) {
    final merged = <int, CartProduct>{};
    for (final item in [...products, ...CartService.addedProducts.value]) {
      final existing = merged[item.id];
      merged[item.id] = existing == null
          ? item
          : CartProduct(
              id: existing.id,
              title: existing.title,
              price: existing.price,
              quantity: existing.quantity + item.quantity,
              total: existing.total + item.total,
              discountPercentage: existing.discountPercentage,
              discountedTotal: existing.discountedTotal + item.discountedTotal,
              thumbnail: existing.thumbnail,
            );
    }
    return merged.values.toList();
  }

  void _openDetails(CartProduct item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailScreen(productId: item.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds when a product is added while this screen is alive.
    return ValueListenableBuilder<List<CartProduct>>(
      valueListenable: CartService.addedProducts,
      builder: (context, _, _) => _buildCart(),
    );
  }

  Widget _buildCart() {
    return FutureBuilder<Cart?>(
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

        final products = _withAddedProducts(snapshot.data?.products ?? []);
        if (products.isEmpty) {
          return Center(
            child: CustomText(text: 'Your cart is empty.', fontSize: 14.sp),
          );
        }

        final subtotal = products.fold<double>(
          0,
          (sum, item) => sum + item.price * _quantityOf(item),
        );
        final total = products.fold<double>(
          0,
          (sum, item) => sum + _discountedTotalOf(item),
        );

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(16.r),
                itemCount: products.length,
                separatorBuilder: (_, _) => SizedBox(height: 12.h),
                itemBuilder: (context, index) =>
                    _buildCartItem(products[index]),
              ),
            ),
            _buildSummary(subtotal, total),
          ],
        );
      },
    );
  }

  Widget _buildCartItem(CartProduct item) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      // LAB 3 - ENHANCEMENT 1: tapping an item opens the detail_screen.
      child: InkWell(
        onTap: () => _openDetails(item),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              Image.network(
                item.thumbnail,
                width: 72.w,
                height: 72.w,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(Icons.image, size: 40.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: item.title,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text: '\$${item.price.toStringAsFixed(2)}',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade700,
                    ),
                    SizedBox(height: 2.h),
                    CustomText(
                      text:
                          '${item.discountPercentage.round()}% off • '
                          '\$${(item.price * _quantityOf(item)).toStringAsFixed(2)} total',
                      fontSize: 10.sp,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _quantityButton(
                    Icons.add,
                    Colors.amber,
                    () => _changeQuantity(item, 1),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: CustomText(
                      text: '${_quantityOf(item)}',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _quantityButton(
                    Icons.remove,
                    Colors.grey.shade300,
                    () => _changeQuantity(item, -1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quantityButton(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(6.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(6.r),
        onTap: onTap,
        child: SizedBox(
          width: 28.r,
          height: 28.r,
          child: Icon(icon, size: 16.sp, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildSummary(double subtotal, double total) {
    const deliveryFee = 0.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: Column(
        children: [
          _summaryRow('Subtotal:', subtotal),
          _summaryRow('Discount:', total - subtotal),
          _summaryRow('Delivery Fee:', deliveryFee),
          const Divider(),
          _summaryRow('Total:', total + deliveryFee, bold: true),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order confirmed!')),
                );
              },
              child: CustomText(
                text: 'Confirm Order',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            text: label,
            fontSize: 13.sp,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          ),
          CustomText(
            text: '\$${value.toStringAsFixed(2)}',
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.amber.shade700,
          ),
        ],
      ),
    );
  }
}
