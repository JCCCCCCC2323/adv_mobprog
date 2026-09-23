# ocray_advmobprog

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Lab Activity 2: Discussion

In this activity, the app has three main parts: model, service, and screen. The model holds the product data, the service gets the data from the API, and the screen shows the products in the app.

The app also has a search bar, a details page when a product is clicked, and a settings page for dark and light mode. The design pattern used is helpful because each file has its own job, so the code is easier to understand and fix.

## Lab Activity 4: Discussion

The user model, user service, and screens work together to show information from the API. The user service logs in to the API and changes the JSON response into a User model, while the sign-in, splash, and profile screens use the saved user data to show the correct page and user information.

This activity uses an updated layered design pattern where the model holds the user data, the service handles the API and saved login, and the screens display the interface. The saved user ID is also used by the cart service to request `/carts/user/{userId}`, so the cart screen displays the cart that belongs to the logged-in user.

