// web_view_registry_web.dart
import 'dart:html';
import 'dart:js' as js;

void registerReCAPTCHAContainer() {
  try {
    final platformViewRegistry = js.context['flutter']?['platformViewRegistry'];

    if (platformViewRegistry != null) {
      platformViewRegistry.callMethod('registerViewFactory', [
        'recaptcha-container',
        js.allowInterop((int viewId) {
          final element = DivElement()..id = 'recaptcha-container';
          return element;
        }),
      ]);
    } else {
      print("⚠️ platformViewRegistry not found in JS context");
    }
  } catch (e) {
    print("⚠️ Error registering recaptcha container: $e");
  }
}
