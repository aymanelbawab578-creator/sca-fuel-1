import 'package:flutter/material.dart';

import '../widgets/sca_layout.dart';

class ModelsScreen extends StatelessWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScaAppBar(title: 'إدارة الموديلات'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('هذه صفحة إدارة الموديلات', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}
