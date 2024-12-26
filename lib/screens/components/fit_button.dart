import 'package:flutter/material.dart';

class FitButton extends StatelessWidget {
  final void Function() onPressed;
  final String text;

  const FitButton({Key? key, required this.onPressed, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Container(
            padding: const EdgeInsets.all(10),
            child: MaterialButton(
              onPressed: onPressed,
              child: Center(
                child: Text(text),
              ),
            ),
          ),
        );
      },
    );
  }
}
