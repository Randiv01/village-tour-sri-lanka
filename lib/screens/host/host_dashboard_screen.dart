import 'package:flutter/material.dart';

class HostDashboardScreen extends StatelessWidget {
  const HostDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host Dashboard')),
      body: const Center(child: Text('Host features coming soon!')),
    );
  }
}
