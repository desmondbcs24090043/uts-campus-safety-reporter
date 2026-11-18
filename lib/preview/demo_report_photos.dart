import 'package:flutter/material.dart';

import 'preview_theme.dart';

class DemoReportPhoto {
  const DemoReportPhoto(this.asset, this.label);

  final String asset;
  final String label;

  static const samples = [
    DemoReportPhoto('assets/demo/corridor-light.jpg', 'Corridor'),
    DemoReportPhoto('assets/demo/corridor-side.jpg', 'Walkway crop'),
    DemoReportPhoto('assets/demo/corridor-fixture.jpg', 'Ceiling lights crop'),
  ];

  Image image({BoxFit fit = BoxFit.cover}) =>
      Image.asset(asset, fit: fit, semanticLabel: 'Demo photo: $label');
}

class DemoPhotoStrip extends StatelessWidget {
  const DemoPhotoStrip({
    super.key,
    required this.photos,
    this.onOpen,
    this.onRemove,
  });

  final List<DemoReportPhoto> photos;
  final ValueChanged<DemoReportPhoto>? onOpen;
  final ValueChanged<DemoReportPhoto>? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 6,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final photo in photos)
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Material(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AdaptivePalette.border),
                ),
                borderOnForeground: true,
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    photo.image(),
                    if (onOpen != null)
                      Semantics(
                        button: true,
                        label: 'Enlarge demo photo: ${photo.label}',
                        child: InkWell(
                          key: ValueKey('open-${photo.asset}'),
                          onTap: () => onOpen!(photo),
                        ),
                      ),
                    if (onRemove != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          tooltip: 'Remove ${photo.label}',
                          onPressed: () => onRemove!(photo),
                          iconSize: 16,
                          icon: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AdaptivePalette.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Icon(
                                Icons.close,
                                color: AdaptivePalette.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        for (var i = photos.length; i < DemoReportPhoto.samples.length; i++)
          const Spacer(),
      ],
    );
  }
}
