import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Wynik weryfikacji'),
        ),
        body: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Text(isVerified
                ? 'Weryfikacja pomyślna!'
                : 'Weryfikacja nie powiodła się!'),
          ],
        ));
  }
}
