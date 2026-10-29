import "package:flutter/material.dart";

class ErpApp extends StatelessWidget {
  const ErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Enterprise ERP",
      theme: ThemeData(useMaterial3: true),
      home: const Scaffold(
        body: Center(child: Text("Enterprise ERP skeleton")),
      ),
    );
  }
}
