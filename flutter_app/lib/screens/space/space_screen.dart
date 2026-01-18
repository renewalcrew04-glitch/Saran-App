import 'package:flutter/material.dart';

class SpaceScreen extends StatelessWidget {
  const SpaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Space'),
      ),
      body: const Center(
        child: Text('Space Screen'),
      ),
    );
  }
}
