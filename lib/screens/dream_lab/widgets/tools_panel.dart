import 'package:flutter/material.dart';

class ToolsPanel extends StatelessWidget {
  const ToolsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      padding: const EdgeInsets.all(10),
      color: const Color(0xffE7F7F5),
      child: Row(
        children: [
          _toolButton(
            Icons.science,
            "Tools",
          ),
          const SizedBox(width: 10),
          _toolButton(
            Icons.refresh,
            "Reset",
          ),
        ],
      ),
    );
  }

  Widget _toolButton(
      IconData icon,
      String title,
      ) {
    return Expanded(
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xff315E6B),
            ),
            const SizedBox(width: 7),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}