import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// constants
import '../constants.dart';

// models
import '../models/product.dart';

// services
import '../services/cart_service.dart';
import '../services/product_service.dart';

// widgets
import '../widgets/custom_text.dart';

// ======================= ENHANCEMENT 2 =======================
// Details page shown when a product card is tapped on the
// ProductScreen. The tapped Product object is passed straight into
// this screen, so no extra API call is needed to render it.
// =============================================================
// ======================= LAB 3 - ENHANCEMENT 1 =======================
// Renamed to detail_screen.dart and shared by ProductScreen and
// CartScreen. ProductScreen passes the whole Product; CartScreen only
// has the product id, so the screen fetches the product by id.
// =====================================================================
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.productId, this.product});

  final int productId;
  final Product? product;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final Future<Product> _productFuture;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    // LAB 3 - ENHANCEMENT 1: only call the API when no Product was passed.
    _productFuture = widget.product != null
        ? Future.value(widget.product!)
        : ProductService().getProductById(widget.productId);
  }

  // LAB 3 - ENHANCEMENT 3: POST /carts/add with this product's values.
  Future<void> _addToCart() async {
    setState(() => _isAdding = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final cart = await CartService().addToCart(
        userId: cartUserId,
        productId: widget.productId,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Added to cart #${cart.id} • '
            'total \$${cart.total.toStringAsFixed(2)}',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, size: 24.sp),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Product>(
          future: _productFuture,
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

            return _buildDetails(snapshot.data!);
          },
        ),
      ),
      // LAB 3 - ENHANCEMENT 3: add to cart button.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
          child: SizedBox(
            height: 48.h,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: _isAdding ? null : _addToCart,
              icon: _isAdding
                  ? SizedBox(
                      width: 18.r,
                      height: 18.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.add_shopping_cart, size: 20.sp),
              label: CustomText(
                text: 'Add to Cart',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(Product product) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ENHANCEMENT 2: hero image of the selected product.
          Container(
            width: double.infinity,
            height: 260.h,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Image.network(
              product.thumbnail,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(Icons.image, size: 40.sp),
            ),
          ),
          SizedBox(height: 16.h),

          // ENHANCEMENT 2: category pill.
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: CustomText(
                text: product.category.toUpperCase(),
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // ENHANCEMENT 2: title, price and rating.
          CustomText(
            text: product.title,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              CustomText(
                text: '\$${product.price.toStringAsFixed(2)}',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(width: 12.w),
              Icon(Icons.star, size: 16.sp, color: Colors.amber),
              SizedBox(width: 4.w),
              CustomText(
                text: '${product.rating} (${product.reviews.length})',
                fontSize: 13.sp,
              ),
              const Spacer(),
              CustomText(
                text: product.availabilityStatus,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // ENHANCEMENT 2: full description.
          CustomText(
            text: product.description,
            fontSize: 13.sp,
            textAlign: TextAlign.justify,
          ),
          SizedBox(height: 24.h),

          // ENHANCEMENT 2: remaining fields returned by the API.
          CustomText(
            text: 'PRODUCT INFO',
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
          SizedBox(height: 8.h),
          _infoRow('Brand', product.brand),
          _infoRow('SKU', product.sku),
          _infoRow('Stock', '${product.stock}'),
          _infoRow('Discount', '${product.discountPercentage}%'),
          _infoRow('Weight', '${product.weight}'),
          _infoRow(
            'Dimensions',
            '${product.dimensions.width} x '
                '${product.dimensions.height} x '
                '${product.dimensions.depth}',
          ),
          _infoRow('Warranty', product.warrantyInformation),
          _infoRow('Shipping', product.shippingInformation),
          _infoRow('Return policy', product.returnPolicy),
          _infoRow('Min. order', '${product.minimumOrderQuantity}'),
          _infoRow('Tags', product.tags.join(', ')),

          // ENHANCEMENT 2: reviews section.
          if (product.reviews.isNotEmpty) ...[
            SizedBox(height: 24.h),
            CustomText(
              text: 'REVIEWS',
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
            SizedBox(height: 8.h),
            ...product.reviews.map(
              (review) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomText(
                          text: review.reviewerName,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(width: 8.w),
                        Icon(Icons.star, size: 13.sp, color: Colors.amber),
                        SizedBox(width: 2.w),
                        CustomText(text: '${review.rating}', fontSize: 12.sp),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    CustomText(text: review.comment, fontSize: 12.sp),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  // ENHANCEMENT 2: single label/value line used by the info section.
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: CustomText(
              text: label,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: CustomText(text: value, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}
