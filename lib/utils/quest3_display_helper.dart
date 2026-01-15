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

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Helper class for Quest 3 display optimization.
///
/// Provides utilities for calculating optimal panel sizes,
/// display settings, and VR-specific adjustments.
class Quest3DisplayHelper {
  Quest3DisplayHelper._();

  // Quest 3 Display Specifications
  /// Resolution per eye (width).
  static const int eyeResolutionWidth = 2064;

  /// Resolution per eye (height).
  static const int eyeResolutionHeight = 2208;

  /// Default refresh rate in Hz.
  static const int defaultRefreshRate = 90;

  /// Maximum refresh rate in Hz.
  static const int maxRefreshRate = 120;

  /// Horizontal field of view in degrees.
  static const double horizontalFov = 110.0;

  /// Vertical field of view in degrees.
  static const double verticalFov = 96.0;

  /// Recommended minimum touch target size in logical pixels.
  static const double minTouchTargetSize = 48.0;

  /// Recommended text size multiplier for VR readability.
  static const double vrTextScaleFactor = 1.2;

  // Panel Size Recommendations

  /// Default panel width for standard UI.
  static const double defaultPanelWidth = 1280.0;

  /// Default panel height for standard UI.
  static const double defaultPanelHeight = 720.0;

  /// Cinema mode panel width (larger for immersive viewing).
  static const double cinemaPanelWidth = 1920.0;

  /// Cinema mode panel height.
  static const double cinemaPanelHeight = 1080.0;

  /// Compact panel width for smaller UI elements.
  static const double compactPanelWidth = 800.0;

  /// Compact panel height.
  static const double compactPanelHeight = 600.0;

  /// Calculates optimal panel size based on content type.
  ///
  /// [contentType] - The type of content being displayed.
  /// [screenSize] - The available screen size.
  /// Returns the recommended panel size.
  static Size calculateOptimalPanelSize(
    ContentType contentType,
    Size screenSize,
  ) {
    switch (contentType) {
      case ContentType.fileBrowser:
        return _clampToScreen(
          const Size(defaultPanelWidth, defaultPanelHeight),
          screenSize,
        );

      case ContentType.imageViewer:
        // Use larger panel for image viewing
        return _clampToScreen(
          const Size(cinemaPanelWidth, cinemaPanelHeight),
          screenSize,
        );

      case ContentType.videoPlayer:
        // Use cinema size for video playback
        return _clampToScreen(
          const Size(cinemaPanelWidth, cinemaPanelHeight),
          screenSize,
        );

      case ContentType.vrVideo:
        // For VR video, use full available space
        return screenSize;

      case ContentType.settings:
        // Use compact panel for settings
        return _clampToScreen(
          const Size(compactPanelWidth, compactPanelHeight),
          screenSize,
        );

      case ContentType.dialog:
        // Dialogs should be smaller
        return _clampToScreen(
          const Size(480, 320),
          screenSize,
        );
    }
  }

  /// Clamps a size to fit within the screen bounds.
  static Size _clampToScreen(Size size, Size screenSize) {
    return Size(
      math.min(size.width, screenSize.width),
      math.min(size.height, screenSize.height),
    );
  }

  /// Calculates optimal video aspect ratio for Quest 3.
  ///
  /// [videoAspectRatio] - The native aspect ratio of the video.
  /// [screenSize] - The available screen size.
  /// Returns the optimal display size maintaining aspect ratio.
  static Size calculateVideoDisplaySize(
    double videoAspectRatio,
    Size screenSize,
  ) {
    final screenAspectRatio = screenSize.width / screenSize.height;

    if (videoAspectRatio > screenAspectRatio) {
      // Video is wider than screen - fit to width
      final width = screenSize.width;
      final height = width / videoAspectRatio;
      return Size(width, height);
    } else {
      // Video is taller than screen - fit to height
      final height = screenSize.height;
      final width = height * videoAspectRatio;
      return Size(width, height);
    }
  }

  /// Determines if a video resolution is suitable for VR playback.
  ///
  /// For 360° video, higher resolutions provide better quality.
  /// [width] - Video width in pixels.
  /// [height] - Video height in pixels.
  static VrVideoQuality getVrVideoQuality(int width, int height) {
    final totalPixels = width * height;

    if (totalPixels >= 7680 * 3840) {
      return VrVideoQuality.ultra8k;
    } else if (totalPixels >= 5760 * 2880) {
      return VrVideoQuality.high6k;
    } else if (totalPixels >= 3840 * 1920) {
      return VrVideoQuality.medium4k;
    } else if (totalPixels >= 1920 * 960) {
      return VrVideoQuality.low2k;
    } else {
      return VrVideoQuality.veryLow;
    }
  }

  /// Calculates recommended buffer size for video streaming.
  ///
  /// Higher quality videos need larger buffers.
  /// [quality] - The video quality level.
  /// Returns buffer size in bytes.
  static int getRecommendedBufferSize(VrVideoQuality quality) {
    switch (quality) {
      case VrVideoQuality.ultra8k:
        return 64 * 1024 * 1024; // 64 MB
      case VrVideoQuality.high6k:
        return 48 * 1024 * 1024; // 48 MB
      case VrVideoQuality.medium4k:
        return 32 * 1024 * 1024; // 32 MB
      case VrVideoQuality.low2k:
        return 16 * 1024 * 1024; // 16 MB
      case VrVideoQuality.veryLow:
        return 8 * 1024 * 1024; // 8 MB
    }
  }

  /// Determines optimal text size for VR readability.
  ///
  /// [baseSize] - The base text size.
  /// [distance] - Viewing distance in meters (default 1.5m).
  /// Returns adjusted text size.
  static double getOptimalTextSize(double baseSize, {double distance = 1.5}) {
    // Text should be larger at greater distances
    final scaleFactor = 1.0 + (distance - 1.0) * 0.2;
    return baseSize * vrTextScaleFactor * scaleFactor;
  }

  /// Checks if the current device is likely a Quest device.
  ///
  /// This is a heuristic based on screen characteristics.
  static bool isLikelyQuestDevice(Size screenSize, double devicePixelRatio) {
    // Quest 3 typically reports specific screen dimensions
    // This is a rough heuristic
    final totalWidth = screenSize.width * devicePixelRatio;
    final totalHeight = screenSize.height * devicePixelRatio;

    // Check if resolution is close to Quest 3 specs
    return (totalWidth >= 2000 && totalWidth <= 2200) ||
        (totalHeight >= 2000 && totalHeight <= 2400);
  }

  /// Returns optimal grid column count for file browser.
  ///
  /// [screenWidth] - Available screen width.
  /// [itemMinWidth] - Minimum width per item.
  static int getOptimalGridColumns(double screenWidth, {double itemMinWidth = 180}) {
    final columns = (screenWidth / itemMinWidth).floor();
    return columns.clamp(2, 6);
  }
}

/// Types of content for panel size calculation.
enum ContentType {
  /// File browser / folder view.
  fileBrowser,

  /// Image viewer.
  imageViewer,

  /// Standard video player.
  videoPlayer,

  /// 360° / VR video player.
  vrVideo,

  /// Settings screen.
  settings,

  /// Dialog or modal.
  dialog,
}

/// Quality levels for VR video.
enum VrVideoQuality {
  /// 8K+ resolution (7680x3840 or higher).
  ultra8k,

  /// 6K resolution (5760x2880).
  high6k,

  /// 4K resolution (3840x1920).
  medium4k,

  /// 2K resolution (1920x960).
  low2k,

  /// Below 2K resolution.
  veryLow,
}

/// Extension for VrVideoQuality descriptions.
extension VrVideoQualityExtension on VrVideoQuality {
  /// Returns a human-readable name for the quality level.
  String get displayName {
    switch (this) {
      case VrVideoQuality.ultra8k:
        return '8K Ultra';
      case VrVideoQuality.high6k:
        return '6K High';
      case VrVideoQuality.medium4k:
        return '4K Medium';
      case VrVideoQuality.low2k:
        return '2K Low';
      case VrVideoQuality.veryLow:
        return 'Low Quality';
    }
  }

  /// Returns a quality description.
  String get description {
    switch (this) {
      case VrVideoQuality.ultra8k:
        return 'Best quality for VR, requires fast connection';
      case VrVideoQuality.high6k:
        return 'Excellent quality for VR';
      case VrVideoQuality.medium4k:
        return 'Good quality for VR viewing';
      case VrVideoQuality.low2k:
        return 'Acceptable quality, may appear blurry';
      case VrVideoQuality.veryLow:
        return 'Not recommended for VR';
    }
  }
}
