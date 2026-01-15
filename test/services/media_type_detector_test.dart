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

import 'package:flutter_test/flutter_test.dart';

import 'package:quest3_webdav_client/models/file_item.dart';
import 'package:quest3_webdav_client/services/media_type_detector.dart';

void main() {
  group('MediaTypeDetector', () {
    group('detectMediaType', () {
      test('detects 360 video from file name', () {
        final file = FileItem(
          name: 'vacation_360.mp4',
          path: '/videos/vacation_360.mp4',
          isDirectory: false,
        );

        final result = MediaTypeDetector.detectMediaType(file);

        expect(result.is360Content, true);
        expect(result.projectionType, ProjectionType.equirectangular);
        expect(result.confidence, greaterThan(0.0));
      });

      test('detects VR content from file name', () {
        final file = FileItem(
          name: 'experience_vr.mp4',
          path: '/videos/experience_vr.mp4',
          isDirectory: false,
        );

        final result = MediaTypeDetector.detectMediaType(file);

        expect(result.isVrContent, true);
        expect(result.confidence, greaterThan(0.0));
      });

      test('detects 3D side-by-side content', () {
        final file = FileItem(
          name: 'movie_3d_sbs.mp4',
          path: '/videos/movie_3d_sbs.mp4',
          isDirectory: false,
        );

        final result = MediaTypeDetector.detectMediaType(file);

        expect(result.is3dContent, true);
        expect(result.stereoFormat, StereoscopicFormat.sideBySide);
      });

      test('detects 3D over-under content', () {
        final file = FileItem(
          name: 'movie_3d_ou.mp4',
          path: '/videos/movie_3d_ou.mp4',
          isDirectory: false,
        );

        final result = MediaTypeDetector.detectMediaType(file);

        expect(result.is3dContent, true);
        expect(result.stereoFormat, StereoscopicFormat.overUnder);
      });

      test('detects spherical content', () {
        final file = FileItem(
          name: 'panorama_equirectangular.mp4',
          path: '/videos/panorama_equirectangular.mp4',
          isDirectory: false,
        );

        final result = MediaTypeDetector.detectMediaType(file);

        expect(result.is360Content, true);
        expect(result.projectionType, ProjectionType.equirectangular);
      });

      test('returns flat projection for normal video', () {
        final file = FileItem(
          name: 'normal_video.mp4',
          path: '/videos/normal_video.mp4',
          isDirectory: false,
        );

        final result = MediaTypeDetector.detectMediaType(file);

        expect(result.is360Content, false);
        expect(result.isVrContent, false);
        expect(result.is3dContent, false);
        expect(result.projectionType, ProjectionType.flat);
        expect(result.stereoFormat, StereoscopicFormat.mono);
      });

      test('is case insensitive', () {
        final file = FileItem(
          name: 'VIDEO_360_VR.MP4',
          path: '/videos/VIDEO_360_VR.MP4',
          isDirectory: false,
        );

        final result = MediaTypeDetector.detectMediaType(file);

        expect(result.is360Content, true);
        expect(result.isVrContent, true);
      });
    });

    group('detectFromDimensions', () {
      test('detects equirectangular from 2:1 aspect ratio', () {
        final result = MediaTypeDetector.detectFromDimensions(3840, 1920);

        expect(result.is360Content, true);
        expect(result.projectionType, ProjectionType.equirectangular);
        expect(result.stereoFormat, StereoscopicFormat.mono);
      });

      test('detects stacked stereo from 1:1 high resolution', () {
        final result = MediaTypeDetector.detectFromDimensions(3840, 3840);

        expect(result.is360Content, true);
        expect(result.is3dContent, true);
        expect(result.stereoFormat, StereoscopicFormat.overUnder);
      });

      test('detects side-by-side stereo from 4:1 aspect ratio', () {
        final result = MediaTypeDetector.detectFromDimensions(7680, 1920);

        expect(result.is360Content, true);
        expect(result.is3dContent, true);
        expect(result.stereoFormat, StereoscopicFormat.sideBySide);
      });

      test('returns flat for normal aspect ratios', () {
        final result = MediaTypeDetector.detectFromDimensions(1920, 1080);

        expect(result.is360Content, false);
        expect(result.projectionType, ProjectionType.flat);
      });
    });

    group('detectCombined', () {
      test('prefers file name detection when confident', () {
        final file = FileItem(
          name: 'video_360_vr.mp4',
          path: '/videos/video_360_vr.mp4',
          isDirectory: false,
        );

        final result = MediaTypeDetector.detectCombined(file, 1920, 1080);

        expect(result.is360Content, true);
        expect(result.detectionSource, DetectionSource.fileName);
      });

      test('uses dimensions when file name not confident', () {
        final file = FileItem(
          name: 'video.mp4',
          path: '/videos/video.mp4',
          isDirectory: false,
        );

        final result = MediaTypeDetector.detectCombined(file, 3840, 1920);

        expect(result.is360Content, true);
        expect(result.detectionSource, DetectionSource.dimensions);
      });
    });

    group('getRecommendedViewerMode', () {
      test('recommends panorama for 360 content', () {
        const info = MediaTypeInfo(
          is360Content: true,
          isVrContent: false,
          is3dContent: false,
          projectionType: ProjectionType.equirectangular,
          stereoFormat: StereoscopicFormat.mono,
          confidence: 0.8,
          detectionSource: DetectionSource.fileName,
        );

        final mode = MediaTypeDetector.getRecommendedViewerMode(info);
        expect(mode, ViewerMode.panorama360);
      });

      test('recommends VR 3D for VR content', () {
        const info = MediaTypeInfo(
          is360Content: false,
          isVrContent: true,
          is3dContent: true,
          projectionType: ProjectionType.flat,
          stereoFormat: StereoscopicFormat.sideBySide,
          confidence: 0.8,
          detectionSource: DetectionSource.fileName,
        );

        final mode = MediaTypeDetector.getRecommendedViewerMode(info);
        expect(mode, ViewerMode.vr3d);
      });

      test('recommends normal for flat content', () {
        const info = MediaTypeInfo(
          is360Content: false,
          isVrContent: false,
          is3dContent: false,
          projectionType: ProjectionType.flat,
          stereoFormat: StereoscopicFormat.mono,
          confidence: 0.9,
          detectionSource: DetectionSource.dimensions,
        );

        final mode = MediaTypeDetector.getRecommendedViewerMode(info);
        expect(mode, ViewerMode.normal);
      });
    });
  });

  group('MediaTypeInfo', () {
    test('isImmersive returns true for 360 content', () {
      const info = MediaTypeInfo(
        is360Content: true,
        isVrContent: false,
        is3dContent: false,
        projectionType: ProjectionType.equirectangular,
        stereoFormat: StereoscopicFormat.mono,
        confidence: 0.8,
        detectionSource: DetectionSource.fileName,
      );

      expect(info.isImmersive, true);
    });

    test('isImmersive returns true for VR content', () {
      const info = MediaTypeInfo(
        is360Content: false,
        isVrContent: true,
        is3dContent: false,
        projectionType: ProjectionType.flat,
        stereoFormat: StereoscopicFormat.mono,
        confidence: 0.8,
        detectionSource: DetectionSource.fileName,
      );

      expect(info.isImmersive, true);
    });

    test('isImmersive returns false for flat content', () {
      const info = MediaTypeInfo(
        is360Content: false,
        isVrContent: false,
        is3dContent: false,
        projectionType: ProjectionType.flat,
        stereoFormat: StereoscopicFormat.mono,
        confidence: 0.9,
        detectionSource: DetectionSource.dimensions,
      );

      expect(info.isImmersive, false);
    });

    test('summary returns correct string', () {
      const info360 = MediaTypeInfo(
        is360Content: true,
        isVrContent: false,
        is3dContent: false,
        projectionType: ProjectionType.equirectangular,
        stereoFormat: StereoscopicFormat.mono,
        confidence: 0.8,
        detectionSource: DetectionSource.fileName,
      );

      const infoVr3d = MediaTypeInfo(
        is360Content: false,
        isVrContent: true,
        is3dContent: true,
        projectionType: ProjectionType.flat,
        stereoFormat: StereoscopicFormat.sideBySide,
        confidence: 0.8,
        detectionSource: DetectionSource.fileName,
      );

      const infoStandard = MediaTypeInfo(
        is360Content: false,
        isVrContent: false,
        is3dContent: false,
        projectionType: ProjectionType.flat,
        stereoFormat: StereoscopicFormat.mono,
        confidence: 0.9,
        detectionSource: DetectionSource.dimensions,
      );

      expect(info360.summary, contains('360'));
      expect(infoVr3d.summary, contains('3D'));
      expect(infoVr3d.summary, contains('VR'));
      expect(infoStandard.summary, 'Standard');
    });

    test('copyWith creates modified copy', () {
      const original = MediaTypeInfo(
        is360Content: false,
        isVrContent: false,
        is3dContent: false,
        projectionType: ProjectionType.flat,
        stereoFormat: StereoscopicFormat.mono,
        confidence: 0.5,
        detectionSource: DetectionSource.fileName,
      );

      final modified = original.copyWith(
        is360Content: true,
        confidence: 0.9,
      );

      expect(modified.is360Content, true);
      expect(modified.confidence, 0.9);
      expect(modified.isVrContent, false);
      expect(modified.projectionType, ProjectionType.flat);
    });
  });

  group('ViewerMode', () {
    test('displayName returns correct values', () {
      expect(ViewerMode.normal.displayName, 'Normal');
      expect(ViewerMode.cinema.displayName, 'Cinema');
      expect(ViewerMode.panorama360.displayName, '360° Panorama');
      expect(ViewerMode.vr3d.displayName, 'VR 3D');
    });

    test('description returns non-empty values', () {
      for (final mode in ViewerMode.values) {
        expect(mode.description, isNotEmpty);
      }
    });
  });
}
