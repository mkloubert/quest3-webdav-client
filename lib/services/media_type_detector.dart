// quest3_webdav_client - A WebDAV client optimized for Meta Quest 3.
// Copyright (C) 2026  Marcel Joachim Kloubert <marcel@kloubert.dev>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import '../models/file_item.dart';

/// Service for detecting media types, especially 360°/VR content.
///
/// Uses file name patterns, aspect ratios, and other heuristics
/// to determine if content is immersive/panoramic.
class MediaTypeDetector {
  MediaTypeDetector._();

  /// Patterns in file names that indicate 360° content.
  static const List<String> _patterns360 = [
    '360',
    '_360',
    '-360',
    '.360',
    '360°',
    '360deg',
  ];

  /// Patterns in file names that indicate VR content.
  static const List<String> _vrPatterns = [
    '_vr',
    '-vr',
    '.vr',
    '_vr_',
    'vr_',
    'vr-',
    'virtualreality',
    'virtual_reality',
  ];

  /// Patterns in file names that indicate spherical/panoramic content.
  static const List<String> _sphericalPatterns = [
    'spherical',
    'panorama',
    'panoramic',
    'pano_',
    '_pano',
    'equirect',
    'equirectangular',
    'mono360',
    'stereo360',
  ];

  /// Patterns in file names that indicate 3D/stereoscopic content.
  static const List<String> _patterns3d = [
    '_3d',
    '-3d',
    '.3d',
    '3d_',
    'sbs', // Side-by-side
    'ou', // Over-under
    'tb', // Top-bottom
    'lr', // Left-right
    'stereoscopic',
    'stereo_',
    '_stereo',
  ];

  /// Detects the media type of a file.
  ///
  /// [file] - The file to analyze.
  /// Returns detected media type information.
  static MediaTypeInfo detectMediaType(FileItem file) {
    final fileName = file.name.toLowerCase();
    final is360 = _matchesAnyPattern(fileName, _patterns360);
    final isVr = _matchesAnyPattern(fileName, _vrPatterns);
    final isSpherical = _matchesAnyPattern(fileName, _sphericalPatterns);
    final is3d = _matchesAnyPattern(fileName, _patterns3d);

    // Determine projection type
    ProjectionType projectionType = ProjectionType.flat;
    if (is360 || isSpherical) {
      projectionType = ProjectionType.equirectangular;
    }

    // Determine stereoscopic format
    StereoscopicFormat stereoFormat = StereoscopicFormat.mono;
    if (is3d || isVr) {
      if (fileName.contains('sbs') || fileName.contains('lr')) {
        stereoFormat = StereoscopicFormat.sideBySide;
      } else if (fileName.contains('ou') || fileName.contains('tb')) {
        stereoFormat = StereoscopicFormat.overUnder;
      } else if (is3d) {
        // Default to side-by-side for 3D content
        stereoFormat = StereoscopicFormat.sideBySide;
      }
    }

    // Calculate confidence level
    double confidence = 0.0;
    if (is360) confidence += 0.4;
    if (isVr) confidence += 0.3;
    if (isSpherical) confidence += 0.4;
    if (is3d) confidence += 0.2;
    confidence = confidence.clamp(0.0, 1.0);

    return MediaTypeInfo(
      is360Content: is360 || isSpherical,
      isVrContent: isVr || is3d,
      is3dContent: is3d,
      projectionType: projectionType,
      stereoFormat: stereoFormat,
      confidence: confidence,
      detectionSource: DetectionSource.fileName,
    );
  }

  /// Detects media type based on video dimensions.
  ///
  /// [width] - Video width in pixels.
  /// [height] - Video height in pixels.
  /// Returns detected media type information.
  static MediaTypeInfo detectFromDimensions(int width, int height) {
    final aspectRatio = width / height;

    // Common 360° video aspect ratios
    // Equirectangular: 2:1
    // Cubemap: varies
    final isEquirectangular = (aspectRatio - 2.0).abs() < 0.1;

    // Stereoscopic 360° often uses 1:1 for stacked or 4:1 for side-by-side
    final isStackedStereo = (aspectRatio - 1.0).abs() < 0.1 && height >= 3840;
    final isSideBySideStereo = (aspectRatio - 4.0).abs() < 0.2;

    if (isEquirectangular) {
      return MediaTypeInfo(
        is360Content: true,
        isVrContent: false,
        is3dContent: false,
        projectionType: ProjectionType.equirectangular,
        stereoFormat: StereoscopicFormat.mono,
        confidence: 0.7,
        detectionSource: DetectionSource.dimensions,
      );
    }

    if (isStackedStereo) {
      return MediaTypeInfo(
        is360Content: true,
        isVrContent: true,
        is3dContent: true,
        projectionType: ProjectionType.equirectangular,
        stereoFormat: StereoscopicFormat.overUnder,
        confidence: 0.6,
        detectionSource: DetectionSource.dimensions,
      );
    }

    if (isSideBySideStereo) {
      return MediaTypeInfo(
        is360Content: true,
        isVrContent: true,
        is3dContent: true,
        projectionType: ProjectionType.equirectangular,
        stereoFormat: StereoscopicFormat.sideBySide,
        confidence: 0.5,
        detectionSource: DetectionSource.dimensions,
      );
    }

    // Standard flat video
    return MediaTypeInfo(
      is360Content: false,
      isVrContent: false,
      is3dContent: false,
      projectionType: ProjectionType.flat,
      stereoFormat: StereoscopicFormat.mono,
      confidence: 0.9,
      detectionSource: DetectionSource.dimensions,
    );
  }

  /// Combines file name and dimension detection for best results.
  ///
  /// [file] - The file to analyze.
  /// [width] - Video width in pixels.
  /// [height] - Video height in pixels.
  static MediaTypeInfo detectCombined(FileItem file, int width, int height) {
    final fromFileName = detectMediaType(file);
    final fromDimensions = detectFromDimensions(width, height);

    // Use file name detection if confident, otherwise use dimensions
    if (fromFileName.confidence >= 0.5) {
      return fromFileName;
    }

    // If dimensions suggest 360° but file name doesn't, use lower confidence
    if (fromDimensions.is360Content && !fromFileName.is360Content) {
      return fromDimensions.copyWith(
        confidence: fromDimensions.confidence * 0.7,
      );
    }

    return fromDimensions;
  }

  /// Checks if a string matches any pattern in the list.
  static bool _matchesAnyPattern(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  /// Returns recommended viewer mode based on media type.
  static ViewerMode getRecommendedViewerMode(MediaTypeInfo mediaType) {
    if (mediaType.is360Content) {
      return ViewerMode.panorama360;
    }
    if (mediaType.isVrContent || mediaType.is3dContent) {
      return ViewerMode.vr3d;
    }
    return ViewerMode.normal;
  }
}

/// Information about detected media type.
class MediaTypeInfo {
  /// Whether the content is 360° panoramic.
  final bool is360Content;

  /// Whether the content is designed for VR viewing.
  final bool isVrContent;

  /// Whether the content is 3D/stereoscopic.
  final bool is3dContent;

  /// The projection type of the video.
  final ProjectionType projectionType;

  /// The stereoscopic format if applicable.
  final StereoscopicFormat stereoFormat;

  /// Confidence level of the detection (0.0 to 1.0).
  final double confidence;

  /// Source of the detection.
  final DetectionSource detectionSource;

  const MediaTypeInfo({
    required this.is360Content,
    required this.isVrContent,
    required this.is3dContent,
    required this.projectionType,
    required this.stereoFormat,
    required this.confidence,
    required this.detectionSource,
  });

  /// Creates a copy with modified fields.
  MediaTypeInfo copyWith({
    bool? is360Content,
    bool? isVrContent,
    bool? is3dContent,
    ProjectionType? projectionType,
    StereoscopicFormat? stereoFormat,
    double? confidence,
    DetectionSource? detectionSource,
  }) {
    return MediaTypeInfo(
      is360Content: is360Content ?? this.is360Content,
      isVrContent: isVrContent ?? this.isVrContent,
      is3dContent: is3dContent ?? this.is3dContent,
      projectionType: projectionType ?? this.projectionType,
      stereoFormat: stereoFormat ?? this.stereoFormat,
      confidence: confidence ?? this.confidence,
      detectionSource: detectionSource ?? this.detectionSource,
    );
  }

  /// Whether any immersive features were detected.
  bool get isImmersive => is360Content || isVrContent || is3dContent;

  /// Returns a summary string.
  String get summary {
    final parts = <String>[];
    if (is360Content) parts.add('360°');
    if (is3dContent) parts.add('3D');
    if (isVrContent) parts.add('VR');
    if (parts.isEmpty) return 'Standard';
    return parts.join(' ');
  }
}

/// Video projection types.
enum ProjectionType {
  /// Standard flat/rectilinear video.
  flat,

  /// 360° equirectangular projection.
  equirectangular,

  /// 360° cubemap projection.
  cubemap,

  /// 180° half-sphere projection.
  halfSphere,

  /// Fisheye projection.
  fisheye,
}

/// Stereoscopic video formats.
enum StereoscopicFormat {
  /// Monoscopic (2D).
  mono,

  /// Side-by-side 3D.
  sideBySide,

  /// Over-under (top-bottom) 3D.
  overUnder,
}

/// Source of media type detection.
enum DetectionSource {
  /// Detected from file name patterns.
  fileName,

  /// Detected from video dimensions.
  dimensions,

  /// Detected from video metadata.
  metadata,

  /// Manually selected by user.
  userSelected,
}

/// Viewer modes for video playback.
enum ViewerMode {
  /// Normal flat video playback.
  normal,

  /// Cinema mode - large virtual screen.
  cinema,

  /// 360° panorama mode.
  panorama360,

  /// 3D VR mode with stereoscopic display.
  vr3d,
}

/// Extension for ViewerMode.
extension ViewerModeExtension on ViewerMode {
  /// Returns a display name for the mode.
  String get displayName {
    switch (this) {
      case ViewerMode.normal:
        return 'Normal';
      case ViewerMode.cinema:
        return 'Cinema';
      case ViewerMode.panorama360:
        return '360° Panorama';
      case ViewerMode.vr3d:
        return 'VR 3D';
    }
  }

  /// Returns a description for the mode.
  String get description {
    switch (this) {
      case ViewerMode.normal:
        return 'Standard video playback';
      case ViewerMode.cinema:
        return 'Large virtual screen experience';
      case ViewerMode.panorama360:
        return 'Immersive 360° viewing';
      case ViewerMode.vr3d:
        return 'Stereoscopic 3D VR experience';
    }
  }

  /// Returns an icon name for the mode.
  String get iconName {
    switch (this) {
      case ViewerMode.normal:
        return 'tv';
      case ViewerMode.cinema:
        return 'theaters';
      case ViewerMode.panorama360:
        return '360';
      case ViewerMode.vr3d:
        return 'vrpano';
    }
  }
}
