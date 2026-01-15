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

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Application entry point.
///
/// Initializes Flutter bindings, sets up error handling,
/// and runs the application.
void main() {
  // Run in a guarded zone to catch all errors
  runZonedGuarded(
    () async {
      // Ensure Flutter bindings are initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Set up error handling for Flutter framework errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        if (kDebugMode) {
          // In debug mode, also print to console
          debugPrint('Flutter Error: ${details.exception}');
          debugPrint('Stack trace:\n${details.stack}');
        }
      };

      // Set up error handling for platform errors
      PlatformDispatcher.instance.onError = (error, stack) {
        if (kDebugMode) {
          debugPrint('Platform Error: $error');
          debugPrint('Stack trace:\n$stack');
        }
        return true;
      };

      // Run the application
      runApp(
        const ProviderScope(
          child: AppErrorBoundary(
            child: Quest3WebDavApp(),
          ),
        ),
      );
    },
    (error, stack) {
      // Handle uncaught errors from the zone
      if (kDebugMode) {
        debugPrint('Uncaught Error: $error');
        debugPrint('Stack trace:\n$stack');
      }
    },
  );
}
