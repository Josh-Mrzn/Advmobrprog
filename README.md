# marzan_advmobprog

Advanced Mobile Programming — AY 2627. The Flutter project lives in `marzan_advmobprog/`.

## Lab Activity 2: discussion

### How the model, service and screen interact to render the API endpoint

The app fetches its data from the DummyJSON products endpoint, and the work is split across
four layers so that each file has a single job:

1. **Configuration — `assets/.env` + `lib/constants.dart`.**
   The base URL is kept out of the source code in `assets/.env` (`HOST=https://dummyjson.com`).
   `main()` calls `dotenv.load()` before `runApp()`, and `constants.dart` exposes it as
   `var host = dotenv.env['HOST']`. Changing the API host never requires touching a screen.

2. **Service — `lib/services/product_service.dart`.**
   `ProductService.getAllProducts()` performs the HTTP call to `$host/products`, checks the
   status code, decodes the JSON body, and reaches into the `products` array of the response.
   This is the only layer that knows about `http` and `dart:convert`. If the request fails it
   throws, so the caller can decide how to present the error.

3. **Model — `lib/models/product.dart`.**
   The raw `Map<String, dynamic>` from the service is converted into a `Product` object by the
   `Product.fromJson()` factory, with the nested objects handled by `ProductDimensions`,
   `ProductReview` and `ProductMeta`. Every field is null-safe (`json['title'] ?? ''`,
   `(json['price'] as num?)?.toDouble() ?? 0.0`), so a missing or malformed field cannot crash
   the UI. From this point on the rest of the app works with typed Dart objects, not JSON.

4. **Screen — `lib/screens/product_screen.dart`.**
   The screen holds a `Future<List<Product>>` created once in `initState()` (so the request is
   not repeated on every rebuild) and hands it to a `FutureBuilder`. The builder renders the
   three states of the call: a `CircularProgressIndicator` while waiting, an error message if
   the service threw, and a `GridView` of cards once the products arrive. The screen never
   parses JSON and never knows the URL — it only consumes `Product` objects.

So the flow in one line:

```
.env -> constants.dart -> ProductService (HTTP + decode) -> Product.fromJson (typed model)
     -> FutureBuilder in ProductScreen (loading / error / data) -> Cards -> ProductDetailsScreen
```

### The design pattern used in this activity

The project follows a **layered / separation-of-concerns architecture** with `provider` supplying
the state management, which is the structure the folder layout enforces:

- `models/` — plain data classes and the JSON mapping.
- `services/` — network access and the API contract.
- `providers/` — app-wide state exposed with `ChangeNotifier` (here, the theme).
- `screens/` — the pages the user navigates between.
- `widgets/` — small reusable UI pieces such as `CustomText`.
- `constants.dart` — environment-driven values shared by the whole app.

The state management uses the **ChangeNotifier / observer pattern**: `ThemeProvider` extends
`ChangeNotifier` and calls `notifyListeners()` inside `toggleTheme()`. `MaterialApp` is wrapped by
a `ChangeNotifierProvider` and watches that provider (`build.watch<ThemeProvider>()`), so a switch
flipped on the settings page rebuilds the whole app with the other theme — no callbacks are
threaded through the widget tree.

`ProductService` is also a small **repository**: the screens depend on the method
`getAllProducts()`, not on `http`. Swapping DummyJSON for another backend, or adding caching,
only changes that one file. `flutter_screenutil` keeps the layout proportional across screen
sizes (`.w`, `.h`, `.sp`, `.r`), and `CustomText` centralises typography so a font change is a
one-file edit.

### Enhancements

- **Enhancement 1 — Search bar.** The static `Search` container above the list was replaced by a
  real `TextField`. Typing updates `_searchQuery`, and `_filterProducts()` filters the fetched
  list by title, brand or category before the grid is built. A clear (`x`) button appears while a
  query is active. The filtering happens on the already-downloaded list, so no extra API calls are
  made while typing.
- **Enhancement 2 — Details page.** Each card is wrapped in an `InkWell`; tapping it pushes
  `ProductDetailsScreen` and passes the tapped `Product` object directly, so the details page needs
  no second network request. The page shows the image, category pill, title, price, rating,
  availability, description, the remaining API fields (brand, SKU, stock, discount, weight,
  dimensions, warranty, shipping, return policy, minimum order, tags) and the reviews list.
- **Enhancement 3 — Settings page.** The dark/light switch was moved out of the home screen into
  `SettingsScreen`, reached from the gear icon in the AppBar via the `/settings` route. The
  `SwitchListTile` reads `ThemeProvider.isDark` and calls `toggleTheme()`.

### Dark / light mode text handling

`ThemeProvider` builds both themes from a `ColorScheme.fromSeed()`, one per `Brightness`, so the
light theme pairs dark text with light surfaces and the dark theme does the opposite.

The important detail is in `CustomText`. A `TextStyle` that sets no colour leaves the text with
whatever colour the parent happens to supply, which is how text ends up unreadable after a theme
switch. `CustomText` therefore resolves the colour itself: it uses the explicit `color` argument if
one is given, otherwise the nearest `DefaultTextStyle` (AppBar, Card, Scaffold body), and finally
falls back to `Theme.of(context).colorScheme.onSurface`. Because every label in the app goes
through `CustomText`, flipping the switch turns all text light in dark mode and dark in light mode.
The search bar sets its border, hint and typed-text colours from the same `ColorScheme` for the
same reason.

## Lab Activity 3: discussion

> The Lab 3 project lives in `advmobprog/marzan_advmobprog/`.

### How the cart model, service and screen interact to render the API endpoint

The cart follows the same flow as the products from Lab 2, and both lists end in the same
`detail_screen.dart`:

1. **Model — `lib/models/cart.dart`.**
   `Cart.fromJson()` turns the response into a `Cart` (id, userId, totals, quantities), and each
   entry of its `products` array becomes a `CartProduct` (id, title, price, quantity, discount,
   thumbnail). `toJson()` does the reverse, so the same model can be sent back to the API.

2. **Service — `lib/services/cart_service.dart`.**
   `CartService` is the only place that calls the cart endpoints:
   - `getAllCarts()` → `GET $host/carts`
   - `getCartByUserId(userId)` → `GET $host/carts/user/{userId}`; the first cart in the result is
     returned so only **one user's cart** is rendered (user `1`, set in `constants.dart`).
   - `getCartById(id)` → `GET $host/carts/{id}`
   - `addToCart(userId, productId, quantity)` → `POST $host/carts/add`

3. **Screen — `lib/screens/cart_screen.dart`.**
   `CartScreen` creates the `Future<Cart?>` once in `initState()` and renders it with a
   `FutureBuilder` (loading, error, empty, data). Each `CartProduct` is a card with its thumbnail,
   price, discount, and `+` / `-` quantity buttons, and a summary shows subtotal, discount,
   delivery fee and total above a **Confirm Order** button.

4. **Same detail screen.**
   A `CartProduct` only carries a few product fields, so tapping a cart item opens
   `DetailScreen(productId: item.id)`. The detail screen then loads the full product with
   `ProductService.getProductById()` (`GET $host/products/{id}`). `ProductScreen` already has the
   full `Product`, so it passes it in as `DetailScreen(productId: product.id, product: product)`
   and no second request is made. One screen widget therefore serves both lists.

```
CartService (HTTP + decode) -> Cart.fromJson / CartProduct.fromJson -> FutureBuilder in CartScreen
     -> tap item -> DetailScreen(productId) -> ProductService.getProductById -> product details
```

### The updated design pattern

The layered structure from Lab 2 is kept and extended with one more feature on each layer:

- `models/` — `cart.dart` added beside `product.dart`.
- `services/` — `cart_service.dart` added beside `product_service.dart`.
- `screens/` — `cart_screen.dart` added; `product_details_screen.dart` was renamed to
  `detail_screen.dart` because it is now shared by two screens.
- `constants.dart` — still holds the `HOST` from `.env`, plus `cartUserId`.

Screens still never call `http` or parse JSON; they only use the services and the typed models.
`detail_screen.dart` is a reusable screen that accepts either a full `Product` or just an id.

### How to use getById at the Cart endpoint

DummyJSON exposes a single cart at `GET https://dummyjson.com/carts/{id}`, which returns one cart
object (not a list). In `CartService`:

```dart
Future<Cart> getCartById(int id) async {
  final response = await http.get(Uri.parse('$host/carts/$id'));
  if (response.statusCode == 200) {
    return Cart.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load cart $id');
  }
}
```

The difference from the user endpoint: `/carts/{id}` looks up the cart's own id and returns the
object directly, while `/carts/user/{userId}` looks up the owner and returns
`{ "carts": [ ... ] }`, so the list has to be unwrapped first.

### Enhancements

- **Enhancement 1 — Cart screen.** `CartScreen` renders the cart endpoint. Every item is clickable
  and opens the shared `detail_screen.dart`.
- **Enhancement 2 — Chat as a FloatingActionButton.** Chat was removed from the bottom navigation
  (now Shop, Cart and Profile) and moved to a `FloatingActionButton`. In `HomeScreen` the button
  is set to `null` when `_selectedIndex == 1`, so it is hidden on the cart screen.
- **Enhancement 3 — Cart by user id and add to cart.** The cart screen uses
  `GET /carts/user/1` to show one user's cart. The detail screen has an **Add to Cart** button
  that posts `{ userId, products: [{ id, quantity }] }` to `POST /carts/add` and shows the
  returned cart id and total. DummyJSON only simulates this request: the new cart is returned
  but not saved, so it does not appear in `GET /carts/user/1` afterwards.

## Lab Activity 4: discussion

### How the user model, services and screens interact to render the API endpoint on the profile_screen

Logging in and showing the profile goes through the same layers as the products and the cart, with
`shared_preferences` added as local storage between the API and the screens:

1. **Screen → Service (sign in).** `SignInScreen` validates the form and calls
   `UserService.loginUser(username, password)`. The service sends `POST $host/auth/login` with
   `{ username, password, expiresInMins: 60 }`. On a `200` it decodes the body (id, username,
   email, firstName, lastName, gender, image, accessToken, refreshToken); on any other status it
   throws, and the screen shows a `Login failed` snackbar.

2. **Service → Model → SharedPreferences.** `UserService.saveUserData()` turns the response map
   into a `User` with `User.fromJson()` and writes every field to `SharedPreferences`
   (`id`, `username`, `email`, ..., `accessToken`, `refreshToken`, `token`). The `User` model
   is the contract for which keys are saved, so the service never stores a field the model does
   not know about.

3. **Navigation.** After a successful login the screen calls
   `Navigator.pushReplacementNamed(context, '/home', arguments: response)`. `HomeScreen` reads
   those arguments with `ModalRoute.of(context)?.settings.arguments` and shows the user's first
   name in the app bar on the profile tab.

4. **Service → Model → Screen (profile).** `ProfileScreen` creates
   `UserService().getUser()` once in `initState()`. `getUser()` reads the saved values back with
   `getUserData()` and builds a `User` with `User.fromJson()`. A `FutureBuilder` renders the
   loading, error and data states: an avatar from `user.image`, `user.fullName`,
   `@user.username`, and an info card with email, gender and user id. The screen never calls the
   login endpoint itself; it only reads the typed `User`.

5. **Persistent authentication (splash).** `SplashScreen` is the initial route (`/`). After a
   short delay it calls `UserService.isLoggedIn()`, which checks for a saved `accessToken`. If one
   exists it sends the saved user data to `/home`; otherwise it goes to `/signin`. Closing and
   reopening the app therefore keeps the user logged in.

6. **Log out.** The Log Out button calls `UserService.logout()`, which clears
   `SharedPreferences`, empties the locally added cart items, and returns to `/signin` with
   `pushNamedAndRemoveUntil`, so the back button cannot return to `/home`.

```
SignInScreen -> UserService.loginUser (POST /auth/login) -> User.fromJson -> SharedPreferences
SplashScreen -> UserService.isLoggedIn -> /home or /signin
ProfileScreen -> UserService.getUser (SharedPreferences) -> User -> FutureBuilder -> profile UI
```

### The updated design pattern

The layered structure from the previous activities stays the same, with the user feature added in
each layer:

- `models/` — `cart.dart`, `product.dart`, and the new `user.dart`.
- `services/` — `cart_service.dart`, `product_service.dart`, and the new `user_service.dart`,
  which owns both the auth API call and the local storage (`SharedPreferences`).
- `screens/` — the new `splash_screen.dart`, `signin_screen.dart` and `profile_screen.dart`
  alongside the existing screens.
- `providers/`, `widgets/`, `constants.dart` — unchanged.

`shared_preferences` is added to `pubspec.yaml` as the persistence layer. Screens never touch
`SharedPreferences` directly; they only call `UserService`, which keeps storage keys and API
details in one place. Navigation now uses named routes (`/`, `/signin`, `/home`, `/settings`)
and the app starts on the splash screen instead of going straight to home.

### How the saved data is used to render the cart_screen by user id

The hard-coded `cartUserId` constant from Lab 3 was removed. `CartScreen` now reads the saved user
first and then requests that user's cart:

```dart
_cartFuture = UserService().getUser().then(
  (user) => CartService().getCartByUserId(user.id),
);
```

So logging in as `emilys` (id 1) shows `GET /carts/user/1`, and logging in as another user shows
that user's cart, or "Your cart is empty." if the user has none. The detail screen's
**Add to Cart** does the same: it reads `UserService().getUser()` and posts to `/carts/add` with
the saved `user.id`.

### Enhancements

- **Enhancement 1 — Splash screen.** Custom splash UI (NU logo, "NUBD Exchange", loader) that
  implements persistent authentication through `UserService.isLoggedIn()`.
- **Enhancement 2 — Sign in screen.** Custom sign in UI (logo, "Welcome", outlined username and
  password fields with show/hide, Log In button with a loading state) that uses
  `UserService.loginUser()` and `saveUserData()`.
- **Enhancement 3 — User model, profile screen and cart by user id.** `models/user.dart` maps the
  login response and the saved data. `ProfileScreen` renders the saved user (avatar, name,
  username, email, gender, user id) with a Log Out button, and `CartScreen` loads the cart of the
  saved user id.
