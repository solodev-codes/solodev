// Generates the runtime logo variants from the master artwork.
//
// The master (`assets/branding/Solodev_logo_master.png`) is a full-bleed,
// opaque square. That is exactly right for launcher icons, but wrong for the
// dark app UI: a light square inside a rounded tile leaves visible gaps and
// hard corners. So this script edge-flood-fills the uniform light background
// to transparent, producing a mark that can be drawn edge-to-edge on any
// surface.
//
//   dart run tool/build_logo_assets.dart
//
// Interior light pixels are preserved, because the fill only starts from the
// image border and only spreads through pixels close to the border colour.
import 'dart:collection';
import 'dart:io';

import 'package:image/image.dart' as img;

/// Uniform background tolerance, per channel, around the border colour.
const _tolerance = 42;

void main() {
  const masterPath = 'assets/branding/Solodev_logo_master.png';
  const markPath = 'assets/images/solodev_mark.png';
  const platePath = 'assets/branding/solodev_icon_plate.png';
  const outputSize = 512;
  const plateSize = 1024;
  // Launcher icons and the web favicon need an opaque, light plate: the mark
  // itself is a mid-dark slate (#384d66) that would disappear on a dark plate.
  const plateColour = <int>[0xea, 0xea, 0xec];

  final master = File(masterPath);
  if (!master.existsSync()) {
    stderr.writeln('Master artwork not found: $masterPath');
    exit(1);
  }

  final image = img.decodePng(master.readAsBytesSync())!;
  final width = image.width;
  final height = image.height;

  // A source that is already transparent needs no flood fill, so the artwork is
  // never touched.
  if (_hasTransparentBorder(image)) {
    stdout.writeln('Source is already transparent: flood fill skipped.');
  } else {
    // The border colour is the average of the four corners.
    final corners = [
      _rgba(image, 0, 0),
      _rgba(image, width - 1, 0),
      _rgba(image, 0, height - 1),
      _rgba(image, width - 1, height - 1),
    ];
    var sr = 0, sg = 0, sb = 0, sa = 0;
    for (final c in corners) {
      sr += (c >> 24) & 0xff;
      sg += (c >> 16) & 0xff;
      sb += (c >> 8) & 0xff;
      sa += c & 0xff;
    }
    final seed = ((sr ~/ 4) << 24) | ((sg ~/ 4) << 16) | ((sb ~/ 4) << 8) | (sa ~/ 4);
    final cleared = _floodBackground(image, seed);
    stdout.writeln('Background pixels cleared: $cleared of ${width * height}');
  }

  final trimmed = _contentBox(image);
  final mark = _fit(image, trimmed, outputSize);
  File(markPath).writeAsBytesSync(img.encodePng(mark));
  stdout.writeln('Wrote $markPath (${mark.width}x${mark.height})');
  stdout.writeln('Content box: ${trimmed.width}x${trimmed.height} '
      'at (${trimmed.x}, ${trimmed.y})');

  final plate = _fit(image, trimmed, plateSize);
  // Fill first, then composite the mark over it. `BlendMode.direct` would
  // overwrite the fill with the mark's own transparent pixels.
  img.fill(
    plate,
    color: img.ColorRgba8(plateColour[0], plateColour[1], plateColour[2], 255),
  );
  img.compositeImage(plate, mark);
  File(platePath).writeAsBytesSync(img.encodePng(plate));
  stdout.writeln('Wrote $platePath (${plate.width}x${plate.height})');
}

/// Whether the outermost pixels are already transparent.
bool _hasTransparentBorder(img.Image image) {
  final w = image.width;
  final h = image.height;
  var transparent = 0;
  var sampled = 0;
  for (var x = 0; x < w; x += 4) {
    sampled += 2;
    if (image.getPixel(x, 0).a.toInt() < 8) transparent++;
    if (image.getPixel(x, h - 1).a.toInt() < 8) transparent++;
  }
  return sampled > 0 && transparent / sampled > 0.5;
}

/// Scales a cropped region to fit a square canvas, centred, with a hair of
/// even padding so the mark never touches the edge.
img.Image _fit(img.Image source, _Box box, int size) {
  const padding = 0.02;
  final cropped = img.copyCrop(
    source,
    x: box.x,
    y: box.y,
    width: box.width,
    height: box.height,
  );
  final available = (size * (1 - padding * 2)).round();
  final scale = available / (box.width > box.height ? box.width : box.height);
  final scaledWidth = (box.width * scale).round();
  final scaledHeight = (box.height * scale).round();
  final resized = img.copyResize(
    cropped,
    width: scaledWidth,
    height: scaledHeight,
    interpolation: img.Interpolation.cubic,
  );

  final canvas = img.Image(width: size, height: size, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));
  img.compositeImage(
    canvas,
    resized,
    dstX: (size - scaledWidth) ~/ 2,
    dstY: (size - scaledHeight) ~/ 2,
  );
  return canvas;
}

/// Packs a pixel's RGBA into one int for cheap comparisons.
int _rgba(img.Image image, int x, int y) {
  final p = image.getPixel(x, y);
  return ((p.r.toInt() & 0xff) << 24) |
      ((p.g.toInt() & 0xff) << 16) |
      ((p.b.toInt() & 0xff) << 8) |
      (p.a.toInt() & 0xff);
}

bool _isBackground(int rgba, int seed) {
  if ((rgba & 0xff) == 0) return true; // already transparent
  final dr = (((rgba >> 24) & 0xff) - ((seed >> 24) & 0xff)).abs();
  final dg = (((rgba >> 16) & 0xff) - ((seed >> 16) & 0xff)).abs();
  final db = (((rgba >> 8) & 0xff) - ((seed >> 8) & 0xff)).abs();
  return dr <= _tolerance && dg <= _tolerance && db <= _tolerance;
}

/// Clears the border-connected background and returns how many pixels changed.
int _floodBackground(img.Image image, int seed) {
  final width = image.width;
  final height = image.height;
  final visited = List<bool>.filled(width * height, false);
  final queue = Queue<int>();

  void enqueue(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    final index = y * width + x;
    if (visited[index]) return;
    visited[index] = true;
    queue.add(index);
  }

  for (var x = 0; x < width; x++) {
    enqueue(x, 0);
    enqueue(x, height - 1);
  }
  for (var y = 0; y < height; y++) {
    enqueue(0, y);
    enqueue(width - 1, y);
  }

  var cleared = 0;
  while (queue.isNotEmpty) {
    final index = queue.removeFirst();
    final x = index % width;
    final y = index ~/ width;
    if (!_isBackground(_rgba(image, x, y), seed)) continue;
    if ((_rgba(image, x, y) & 0xff) != 0) {
      image.setPixelRgba(x, y, 0, 0, 0, 0);
      cleared++;
    }
    enqueue(x + 1, y);
    enqueue(x - 1, y);
    enqueue(x, y + 1);
    enqueue(x, y - 1);
  }
  return cleared;
}

/// Bounding box of the pixels that are still visible after the flood fill.
_Box _contentBox(img.Image image) {
  final width = image.width;
  final height = image.height;
  var minX = width;
  var minY = height;
  var maxX = -1;
  var maxY = -1;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (image.getPixel(x, y).a.toInt() > 8) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (maxX < 0) {
    throw StateError('The flood fill removed the entire image.');
  }
  return _Box(minX, minY, maxX - minX + 1, maxY - minY + 1);
}

/// Minimal rectangle holder, avoiding a dependency on an internal type.
class _Box {
  const _Box(this.x, this.y, this.width, this.height);

  final int x;
  final int y;
  final int width;
  final int height;
}
