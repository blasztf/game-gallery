import 'package:flutter/material.dart';

mixin AlertMessage {
  Future showAlertMessage(BuildContext context, String message) async {
    ThemeData theme = Theme.of(context);
    return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: theme.primaryColor,
              titleTextStyle: theme.primaryTextTheme.titleMedium,
              contentTextStyle: theme.primaryTextTheme.bodyMedium,
              content: Text(message),
            ));
  }
}
