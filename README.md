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
