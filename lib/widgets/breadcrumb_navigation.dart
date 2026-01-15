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

import '../constants/app_theme.dart';

/// A horizontal scrollable breadcrumb navigation widget.
///
/// Shows the current path as clickable segments, allowing
/// users to navigate to any parent directory.
class BreadcrumbNavigation extends StatelessWidget {
  /// The path segments to display.
  final List<String> segments;

  /// Callback when a segment is tapped.
  /// The index corresponds to the segment position.
  final ValueChanged<int>? onSegmentTap;

  /// Whether to show a home icon for the root.
  final bool showHomeIcon;

  const BreadcrumbNavigation({
    super.key,
    required this.segments,
    this.onSegmentTap,
    this.showHomeIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppTheme.surfaceColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
        child: Row(
          children: _buildBreadcrumbs(),
        ),
      ),
    );
  }

  List<Widget> _buildBreadcrumbs() {
    final widgets = <Widget>[];

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isLast = i == segments.length - 1;

      // Add separator (except for first item)
      if (i > 0) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingXs),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.textSecondary,
            ),
          ),
        );
      }

      // Add breadcrumb item
      widgets.add(
        _BreadcrumbItem(
          segment: segment,
          isRoot: i == 0,
          isActive: isLast,
          showHomeIcon: showHomeIcon && i == 0,
          onTap: isLast ? null : () => onSegmentTap?.call(i),
        ),
      );
    }

    return widgets;
  }
}

class _BreadcrumbItem extends StatelessWidget {
  final String segment;
  final bool isRoot;
  final bool isActive;
  final bool showHomeIcon;
  final VoidCallback? onTap;

  const _BreadcrumbItem({
    required this.segment,
    required this.isRoot,
    required this.isActive,
    required this.showHomeIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = isRoot && showHomeIcon
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.home_rounded,
                size: 18,
                color: isActive ? AppTheme.textPrimary : AppTheme.primaryColor,
              ),
              const SizedBox(width: AppTheme.spacingXs),
              Text(
                'Root',
                style: _getTextStyle(),
              ),
            ],
          )
        : Text(
            segment,
            style: _getTextStyle(),
          );

    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: AppTheme.spacingSm,
        ),
        child: content,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: AppTheme.spacingSm,
        ),
        child: content,
      ),
    );
  }

  TextStyle _getTextStyle() {
    if (isActive) {
      return AppTheme.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
      );
    }
    return AppTheme.bodyMedium.copyWith(
      color: AppTheme.primaryColor,
    );
  }
}

/// A compact breadcrumb that shows only the current folder name
/// with a back button.
class CompactBreadcrumb extends StatelessWidget {
  /// The current folder name.
  final String currentFolder;

  /// Whether back navigation is available.
  final bool canGoBack;

  /// Callback when back is pressed.
  final VoidCallback? onBack;

  /// Full path for tooltip.
  final String? fullPath;

  const CompactBreadcrumb({
    super.key,
    required this.currentFolder,
    this.canGoBack = false,
    this.onBack,
    this.fullPath,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (canGoBack)
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Go back',
          ),
        Expanded(
          child: Tooltip(
            message: fullPath ?? currentFolder,
            child: Text(
              currentFolder,
              style: AppTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
