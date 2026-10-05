import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AlignedLogoView extends StatelessWidget {
  final double height;
  final double? width;
  final BoxFit fit;

  const AlignedLogoView({
    super.key,
    this.height = 32,
    this.width,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/aligned_logo.svg',
      height: height,
      width: width,
      fit: fit,
      placeholderBuilder: (context) => Image.asset(
        'assets/images/aligned_logo.png',
        height: height,
        width: width,
        fit: fit,
      ),
    );
  }
}

class AlignedIconView extends StatelessWidget {
  final double size;

  const AlignedIconView({
    super.key,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/aligned_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
