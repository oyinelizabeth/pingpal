import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Utility for generating custom Google Map markers with user avatars
class MarkerHelper {

  // Builds a circular map marker using a network image or a fallback icon
  static Future<BitmapDescriptor> getMarkerWithImage(
      String? imageUrl, {
        int size = 120,
        Color borderColor = Colors.blue,
      }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double radius = size / 2;

    // Draw outer coloured border
    final Paint borderPaint = Paint()..color = borderColor;
    canvas.drawCircle(Offset(radius, radius), radius, borderPaint);

    // Draw inner white background
    final double innerRadius = radius * 0.9;
    final Paint innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(radius, radius), innerRadius, innerPaint);

    // Clip drawing area to circular image bounds
    final Path path = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(radius, radius),
          radius: innerRadius,
        ),
      );
    canvas.clipPath(path);

    // Attempt to load and paint network image
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final Completer<ui.Image> completer = Completer();
        final NetworkImage networkImage = NetworkImage(imageUrl);
        final ImageStream stream =
        networkImage.resolve(ImageConfiguration.empty);

        ImageStreamListener? listener;
        listener = ImageStreamListener(
              (ImageInfo info, bool _) {
            completer.complete(info.image);
            stream.removeListener(listener!);
          },
          onError: (dynamic exception, StackTrace? stackTrace) {
            completer.completeError(exception);
            stream.removeListener(listener!);
          },
        );

        final ui.Image image = await completer.future;

        // Paint the avatar image inside the circle
        paintImage(
          canvas: canvas,
          rect: Rect.fromCircle(
            center: Offset(radius, radius),
            radius: innerRadius,
          ),
          image: image,
          fit: BoxFit.cover,
        );
      } catch (_) {
        // Fallback if image loading fails
        _drawPlaceholder(canvas, radius, innerRadius);
      }
    } else {
      // Fallback when no image URL is provided
      _drawPlaceholder(canvas, radius, innerRadius);
    }

    // Convert canvas drawing to bitmap bytes
    final ui.Image markerImage =
    await pictureRecorder.endRecording().toImage(size, size);
    final ByteData? byteData =
    await markerImage.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(
      byteData!.buffer.asUint8List(),
    );
  }

  // Draws a default placeholder avatar inside the marker
  static void _drawPlaceholder(
      Canvas canvas,
      double radius,
      double innerRadius,
      ) {
    final Paint placeholderPaint =
    Paint()..color = Colors.grey[400]!;
    canvas.drawCircle(
      Offset(radius, radius),
      innerRadius,
      placeholderPaint,
    );

    // Draw centered person icon
    const IconData personIcon = Icons.person;
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(personIcon.codePoint),
        style: TextStyle(
          fontSize: radius * 1.2,
          fontFamily: personIcon.fontFamily,
          package: personIcon.fontPackage,
          color: Colors.white,
        ),
      ),
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );
  }
}
