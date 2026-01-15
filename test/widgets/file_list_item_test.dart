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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quest3_webdav_client/constants/app_theme.dart';
import 'package:quest3_webdav_client/models/file_item.dart';
import 'package:quest3_webdav_client/widgets/file_list_item.dart';

void main() {
  Widget buildTestWidget({
    required FileItem file,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onDownload,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: ListView(
          children: [
            FileListItem(
              file: file,
              onTap: onTap,
              onLongPress: onLongPress,
              onDownload: onDownload,
            ),
          ],
        ),
      ),
    );
  }

  group('FileListItem', () {
    group('directory display', () {
      testWidgets('displays directory name', (tester) async {
        final folder = FileItem(
          name: 'Documents',
          path: '/Documents',
          isDirectory: true,
        );

        await tester.pumpWidget(buildTestWidget(file: folder));

        expect(find.text('Documents'), findsOneWidget);
      });

      testWidgets('shows folder icon for directories', (tester) async {
        final folder = FileItem(
          name: 'Documents',
          path: '/Documents',
          isDirectory: true,
        );

        await tester.pumpWidget(buildTestWidget(file: folder));

        expect(find.byIcon(Icons.folder_rounded), findsOneWidget);
      });

      testWidgets('shows chevron for directories', (tester) async {
        final folder = FileItem(
          name: 'Documents',
          path: '/Documents',
          isDirectory: true,
        );

        await tester.pumpWidget(buildTestWidget(file: folder));

        expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      });

      testWidgets('does not show subtitle for directories', (tester) async {
        final folder = FileItem(
          name: 'Documents',
          path: '/Documents',
          isDirectory: true,
        );

        await tester.pumpWidget(buildTestWidget(file: folder));

        // Should only find the title (Documents), not a subtitle
        final listTile = tester.widget<ListTile>(find.byType(ListTile));
        expect(listTile.subtitle, isNull);
      });
    });

    group('file display', () {
      testWidgets('displays file name', (tester) async {
        final file = FileItem(
          name: 'document.pdf',
          path: '/document.pdf',
          isDirectory: false,
        );

        await tester.pumpWidget(buildTestWidget(file: file));

        expect(find.text('document.pdf'), findsOneWidget);
      });

      testWidgets('shows image icon for images', (tester) async {
        final file = FileItem(
          name: 'photo.jpg',
          path: '/photo.jpg',
          isDirectory: false,
          mimeType: 'image/jpeg',
        );

        await tester.pumpWidget(buildTestWidget(file: file));

        expect(find.byIcon(Icons.image_rounded), findsOneWidget);
      });

      testWidgets('shows video icon for videos', (tester) async {
        final file = FileItem(
          name: 'video.mp4',
          path: '/video.mp4',
          isDirectory: false,
          mimeType: 'video/mp4',
        );

        await tester.pumpWidget(buildTestWidget(file: file));

        expect(find.byIcon(Icons.movie_rounded), findsOneWidget);
      });

      testWidgets('shows audio icon for audio files', (tester) async {
        final file = FileItem(
          name: 'music.mp3',
          path: '/music.mp3',
          isDirectory: false,
          mimeType: 'audio/mpeg',
        );

        await tester.pumpWidget(buildTestWidget(file: file));

        expect(find.byIcon(Icons.audiotrack_rounded), findsOneWidget);
      });

      testWidgets('shows PDF icon for PDF files', (tester) async {
        final file = FileItem(
          name: 'document.pdf',
          path: '/document.pdf',
          isDirectory: false,
          mimeType: 'application/pdf',
        );

        await tester.pumpWidget(buildTestWidget(file: file));

        expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
      });

      testWidgets('shows text icon for text files', (tester) async {
        final file = FileItem(
          name: 'readme.txt',
          path: '/readme.txt',
          isDirectory: false,
          mimeType: 'text/plain',
        );

        await tester.pumpWidget(buildTestWidget(file: file));

        expect(find.byIcon(Icons.description_rounded), findsOneWidget);
      });

      testWidgets('shows archive icon for zip files', (tester) async {
        final file = FileItem(
          name: 'archive.zip',
          path: '/archive.zip',
          isDirectory: false,
        );

        await tester.pumpWidget(buildTestWidget(file: file));

        expect(find.byIcon(Icons.archive_rounded), findsOneWidget);
      });

      testWidgets('displays file size in subtitle', (tester) async {
        final file = FileItem(
          name: 'document.pdf',
          path: '/document.pdf',
          isDirectory: false,
          size: 1024 * 1024 * 5, // 5 MB
        );

        await tester.pumpWidget(buildTestWidget(file: file));

        expect(find.textContaining('MB'), findsOneWidget);
      });
    });

    group('offline status', () {
      testWidgets('shows offline indicator when available', (tester) async {
        final file = FileItem(
          name: 'video.mp4',
          path: '/video.mp4',
          isDirectory: false,
          isOfflineAvailable: true,
        );

        await tester.pumpWidget(buildTestWidget(file: file));

        expect(find.byIcon(Icons.offline_pin_rounded), findsOneWidget);
      });

      testWidgets('does not show download button when offline available', (tester) async {
        final file = FileItem(
          name: 'video.mp4',
          path: '/video.mp4',
          isDirectory: false,
          mimeType: 'video/mp4',
          isOfflineAvailable: true,
        );

        await tester.pumpWidget(buildTestWidget(
          file: file,
          onDownload: () {},
        ));

        expect(find.byIcon(Icons.download_rounded), findsNothing);
      });

      testWidgets('shows download button for media files not offline', (tester) async {
        final file = FileItem(
          name: 'video.mp4',
          path: '/video.mp4',
          isDirectory: false,
          mimeType: 'video/mp4',
          isOfflineAvailable: false,
        );

        await tester.pumpWidget(buildTestWidget(
          file: file,
          onDownload: () {},
        ));

        expect(find.byIcon(Icons.download_rounded), findsOneWidget);
      });
    });

    group('interactions', () {
      testWidgets('calls onTap when tapped', (tester) async {
        var tapped = false;
        final file = FileItem(
          name: 'document.pdf',
          path: '/document.pdf',
          isDirectory: false,
        );

        await tester.pumpWidget(buildTestWidget(
          file: file,
          onTap: () => tapped = true,
        ));

        await tester.tap(find.byType(FileListItem));
        await tester.pump();

        expect(tapped, true);
      });

      testWidgets('calls onLongPress when long pressed', (tester) async {
        var longPressed = false;
        final file = FileItem(
          name: 'document.pdf',
          path: '/document.pdf',
          isDirectory: false,
        );

        await tester.pumpWidget(buildTestWidget(
          file: file,
          onLongPress: () => longPressed = true,
        ));

        await tester.longPress(find.byType(FileListItem));
        await tester.pump();

        expect(longPressed, true);
      });

      testWidgets('calls onDownload when download button pressed', (tester) async {
        var downloaded = false;
        final file = FileItem(
          name: 'video.mp4',
          path: '/video.mp4',
          isDirectory: false,
          mimeType: 'video/mp4',
          isOfflineAvailable: false,
        );

        await tester.pumpWidget(buildTestWidget(
          file: file,
          onDownload: () => downloaded = true,
        ));

        await tester.tap(find.byIcon(Icons.download_rounded));
        await tester.pump();

        expect(downloaded, true);
      });
    });
  });
}
