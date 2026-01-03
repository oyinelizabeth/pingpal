import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:typed_data';

class MarkerHelper {
  static Future<BitmapDescriptor> getMarkerWithImage(String? imageUrl, {int size = 120, Color borderColor = Colors.blue}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double radius = size / 2;

    // Draw the circle border
    final Paint borderPaint = Paint()..color = borderColor;
    canvas.drawCircle(Offset(radius, radius), radius, borderPaint);

    // Inner circle for the image
    final double innerRadius = radius * 0.9;
    final Paint innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(radius, radius), innerRadius, innerPaint);

    // Clip the canvas to a circle for the image
    final Path path = Path()..addOval(Rect.fromCircle(center: Offset(radius, radius), radius: innerRadius));
    canvas.clipPath(path);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final Completer<ui.Image> completer = Completer();
        final NetworkImage networkImage = NetworkImage(imageUrl);
        final ImageStream stream = networkImage.resolve(ImageConfiguration.empty);
        
        ImageStreamListener? listener;
        listener = ImageStreamListener((ImageInfo info, bool _) {
          completer.complete(info.image);
          stream.removeListener(listener!);
        }, onError: (dynamic exception, StackTrace? stackTrace) {
          completer.completeError(exception);
          stream.removeListener(listener!);
        });

        final ui.Image image = await completer.future;

        // Draw the image
        paintImage(
          canvas: canvas,
          rect: Rect.fromCircle(center: Offset(radius, radius), radius: innerRadius),
          image: image,
          fit: BoxFit.cover,
        );
      } catch (e) {
        // Fallback if image fails to load
        _drawPlaceholder(canvas, radius, innerRadius);
      }
    } else {
      _drawPlaceholder(canvas, radius, innerRadius);
    }

    final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(size, size);
    final ByteData? byteData = await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  static void _drawPlaceholder(Canvas canvas, double radius, double innerRadius) {
    final Paint placeholderPaint = Paint()..color = Colors.grey[400]!;
    canvas.drawCircle(Offset(radius, radius), innerRadius, placeholderPaint);
    
    // Draw a person icon using a path or icon data
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
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );
  }
}
