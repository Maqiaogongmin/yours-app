import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yours/redesign/shareability/yours_share_models.dart';

part 'yours_share_poster_background.dart';
part 'yours_share_poster_content.dart';
part 'yours_share_poster_style.dart';

class YoursWorkoutSharePoster extends StatelessWidget {
  const YoursWorkoutSharePoster({
    super.key,
    required this.data,
    required this.options,
  });

  final YoursWorkoutShareData data;
  final YoursSharePosterOptions options;

  @override
  Widget build(BuildContext context) {
    final style = _PosterStyle.resolve(options);
    final palette = style.palette;
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: 1080,
            height: 1920,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (options.hasPhotoBackground)
                  _PhotoBackground(path: options.photoPath!, overlay: palette.photoOverlay)
                else
                  _PosterBackground(palette: palette),
                Padding(
                  padding: const EdgeInsets.fromLTRB(88, 128, 88, 110),
                  child: _PosterContent(data: data, options: options, style: style),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
