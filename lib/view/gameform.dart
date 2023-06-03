import 'package:flutter/material.dart';
import 'package:mangw/model/formdata.dart';

class GameForm extends StatelessWidget {
  const GameForm({
    super.key,
    this.onSubmit,
    this.onCancel,
    this.children,
    this.submitLabel = const Text("Submit"),
  });

  final bool Function(FormData)? onSubmit;
  final void Function()? onCancel;
  final List<Widget> Function(FormData)? children;
  final Text submitLabel;

  @override
  Widget build(BuildContext context) {
    const double padding = 8.0;
    FormData formData = FormData();
    GlobalKey<FormState> formKey = GlobalKey<FormState>();
    return Theme(
      data: Theme.of(context),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...children?.call(formData).map(
                        (field) => Padding(
                          padding: const EdgeInsets.all(padding),
                          child: field,
                        ),
                      ) ??
                  [],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(padding),
                      child: ElevatedButton(
                        onPressed: onCancel,
                        child: const Text("Cancel"),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(padding),
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            if (onSubmit?.call(formData) ?? false) {
                              formData = FormData();
                            }
                          }
                        },
                        child: submitLabel,
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
