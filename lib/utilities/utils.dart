import 'package:amana_pos/utilities/responsive_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Utils {
  static bool isValidEmail(String input) {
    const emailRegex = r"""^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+""";
    return RegExp(emailRegex).hasMatch(input);
  }

  static void hideKeyboard(BuildContext? c) {
    c != null
        ? FocusManager.instance.primaryFocus?.unfocus()
        : SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  static Future<void> hidePlatformKeyboard() async {
    await SystemChannels.textInput.invokeMethod('TextInput.hide');
    await SystemChannels.textInput.invokeMethod('TextInput.clearClient');
  }

  static double getSize(BuildContext context, double size) =>
      ResponsiveSize.getResponsiveSize(context, size);


}
