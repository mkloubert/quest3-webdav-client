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
import 'package:quest3_webdav_client/models/virtual_folder.dart';
import 'package:quest3_webdav_client/widgets/folder_card.dart';

void main() {
  final testFolder = VirtualFolder(
    id: 'test-id',
    name: 'Test Folder',
    serverUrl: 'https://cloud.example.com',
    basePath: '/remote.php/dav/files/user',
    credentialId: 'cred-id',
    iconColor: Colors.blue.toARGB32(),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  Widget buildTestWidget({
    required VirtualFolder folder,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: FolderCard(
          folder: folder,
          onTap: onTap,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );
  }

  group('FolderCard', () {
    testWidgets('displays folder name', (tester) async {
      await tester.pumpWidget(buildTestWidget(folder: testFolder));

      expect(find.text('Test Folder'), findsOneWidget);
    });

    testWidgets('displays server URL', (tester) async {
      await tester.pumpWidget(buildTestWidget(folder: testFolder));

      expect(find.text('cloud.example.com'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(buildTestWidget(
        folder: testFolder,
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(FolderCard));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('shows folder icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(folder: testFolder));

      expect(find.byIcon(Icons.folder_rounded), findsOneWidget);
    });

    testWidgets('displays icon with custom color', (tester) async {
      await tester.pumpWidget(buildTestWidget(folder: testFolder));

      final iconFinder = find.byIcon(Icons.folder_rounded);
      final icon = tester.widget<Icon>(iconFinder);

      expect(icon.color, Color(testFolder.iconColor!));
    });

    testWidgets('uses default color when iconColor is null', (tester) async {
      final folderNoColor = VirtualFolder(
        id: 'test-id',
        name: 'Test Folder',
        serverUrl: 'https://cloud.example.com',
        basePath: '/remote.php/dav/files/user',
        credentialId: 'cred-id',
        iconColor: null,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(buildTestWidget(folder: folderNoColor));

      final iconFinder = find.byIcon(Icons.folder_rounded);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('shows chevron icon for navigation', (tester) async {
      await tester.pumpWidget(buildTestWidget(folder: testFolder));

      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });
  });

  group('DismissibleFolderCard', () {
    Widget buildDismissibleTestWidget({
      required VirtualFolder folder,
      VoidCallback? onTap,
      VoidCallback? onEdit,
      VoidCallback? onDelete,
    }) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: ListView(
            children: [
              DismissibleFolderCard(
                folder: folder,
                onTap: onTap,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('displays folder name', (tester) async {
      await tester.pumpWidget(buildDismissibleTestWidget(folder: testFolder));

      expect(find.text('Test Folder'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(buildDismissibleTestWidget(
        folder: testFolder,
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(FolderCard));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('shows bottom sheet on long press', (tester) async {
      await tester.pumpWidget(buildDismissibleTestWidget(
        folder: testFolder,
        onEdit: () {},
      ));

      await tester.longPress(find.byType(FolderCard));
      await tester.pumpAndSettle();

      // Verify bottom sheet appears with folder name and actions
      expect(find.text('Test Folder'), findsWidgets);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
