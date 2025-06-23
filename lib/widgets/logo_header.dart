import 'package:flutter/material.dart';

class LogoHeader extends StatelessWidget {
  final double imageSize;
  final double overlap;
  final bool isWhite; // NEW: toggle for white logo version

  const LogoHeader({
    super.key,
    this.imageSize = 120,
    this.overlap = 35,
    this.isWhite = false, // default is not white
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: imageSize * 2 - overlap,
      height: imageSize,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Image.asset(
              'assets/images/GB_Crest.png',
              width: imageSize,
              height: imageSize,
            ),
          ),
          Positioned(
            left: imageSize - overlap,
            child: Image.asset(
              isWhite
                  ? 'assets/images/1stKLGB_Logo_White.png'
                  : 'assets/images/1stKLGB_Logo.png',
              width: imageSize,
              height: imageSize,
            ),
          ),
        ],
      ),
    );
  }
}