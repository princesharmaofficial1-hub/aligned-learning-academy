import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_palette.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppPalette.lightTextPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SvgPicture.asset(
          'assets/images/aligned_mark.svg',
          height: height,
          fit: fit,
          placeholderBuilder: (context) => Image.asset(
            'assets/images/aligned_icon.png',
            height: height,
            fit: fit,
          ),
        ),
        SizedBox(width: height * 0.25),
        SvgPicture.asset(
          'assets/images/aligned_text_full.svg',
          height: height * 0.72,
          fit: fit,
          colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
        ),
      ],
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
