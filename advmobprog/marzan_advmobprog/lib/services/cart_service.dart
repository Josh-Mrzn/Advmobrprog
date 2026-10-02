import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart.dart';

class CartService {
  // Products added with addToCart. DummyJSON does not save /carts/add,
  // so they are kept here and merged into the CartScreen.
  static final ValueNotifier<List<CartProduct>> addedProducts =
      ValueNotifier([]);

  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(Uri.parse('$host/carts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }

  // ======================= ENHANCEMENT 3 =======================
  // Cart by user id: GET /carts/user/{userId}. The endpoint returns a
  // list of carts, so only the first one is used to render a single
  // user cart. Returns null when that user has no cart.
  // =============================================================
  Future<Cart?> getCartByUserId(int userId) async {
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      if (cartsJson.isEmpty) return null;
      return Cart.fromJson(cartsJson.first);
    } else {
      throw Exception('Failed to load user cart');
    }
  }

  // ENHANCEMENT 3: get a single cart by its own id, GET /carts/{id}.
  Future<Cart> getCartById(int id) async {
    final response = await http.get(Uri.parse('$host/carts/$id'));

    if (response.statusCode == 200) {
      return Cart.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load cart $id');
    }
  }

  // ======================= ENHANCEMENT 3 =======================
  // Add to cart: POST /carts/add with the user id and the product
  // values. DummyJSON only simulates this (the new cart is returned
  // but not saved on the server).
  // =============================================================
  Future<Cart> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {'id': productId, 'quantity': quantity},
        ],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final cart = Cart.fromJson(jsonDecode(response.body));
      addedProducts.value = [...addedProducts.value, ...cart.products];
      return cart;
    } else {
      throw Exception('Failed to add to cart');
    }
  }
}
