import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/navigation/nav_extensions.dart';
import '../../core/theme/app_colors.dart';
import 'review_detected_medicines_screen.dart';

class PrescriptionScannerScreen extends StatelessWidget {
  const PrescriptionScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061016),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Prescription Scanner'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8EFE2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.aqua, width: 2),
                        ),
                        child: const _PrescriptionPaper(),
                      ),
                    ),
                    const Positioned(left: 0, top: 42, child: _ScannerCorner()),
                    const Positioned(
                      right: 0,
                      top: 42,
                      child: _ScannerCorner(flipX: true),
                    ),
                    const Positioned(
                      left: 0,
                      bottom: 42,
                      child: _ScannerCorner(flipY: true),
                    ),
                    const Positioned(
                      right: 0,
                      bottom: 42,
                      child: _ScannerCorner(flipX: true, flipY: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Align prescription in frame',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.photo_library_outlined),
                  ),
                  GestureDetector(
                    onTap: () => context.pushScreen(const _OcrProgressScreen()),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.center_focus_strong),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OcrProgressScreen extends StatefulWidget {
  const _OcrProgressScreen();

  @override
  State<_OcrProgressScreen> createState() => _OcrProgressScreenState();
}

class _OcrProgressScreenState extends State<_OcrProgressScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) context.replaceWith(const ReviewDetectedMedicinesScreen());
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF061016),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.aqua),
                SizedBox(height: 20),
                Text(
                  'Reading prescription...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'OCR progress preview. Future backend will run camera image extraction here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrescriptionPaper extends StatelessWidget {
  const _PrescriptionPaper();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rx', style: TextStyle(fontSize: 34, fontFamily: 'serif')),
        SizedBox(height: 22),
        Text(
          '1. Amoxicillin 500mg',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
        Divider(color: Color(0xFFD8C9B6)),
        Text(
          '2. Ibuprofen 400mg',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
        Divider(color: Color(0xFFD8C9B6)),
        Text(
          '3. Paracetamol 500mg',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
        Divider(color: Color(0xFFD8C9B6)),
        Text(
          '4. Omeprazole 20mg',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
        SizedBox(height: 42),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Dr. Smith',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}

class _ScannerCorner extends StatelessWidget {
  const _ScannerCorner({this.flipX = false, this.flipY = false});

  final bool flipX;
  final bool flipY;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(flipX ? math.pi : 0)
        ..rotateX(flipY ? math.pi : 0),
      child: CustomPaint(
        size: const Size(40, 40),
        painter: _ScannerCornerPainter(),
      ),
    );
  }
}

class _ScannerCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.aqua
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
