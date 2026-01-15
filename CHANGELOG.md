# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-01-14

### Added

- **Virtual Folder Management**

  - Create, edit, and delete virtual folders
  - Connect to any WebDAV server (Nextcloud, ownCloud, etc.)
  - Secure credential storage using Android EncryptedSharedPreferences
  - Use existing folders as templates for new connections
  - Custom icon colors for folder identification

- **File Browser**

  - Navigate WebDAV directories
  - Grid and list view modes
  - Breadcrumb navigation for quick directory jumping
  - Pull-to-refresh for directory reload
  - File type icons based on MIME type
  - Offline availability indicators

- **Image Viewer**

  - Fullscreen image display
  - Pinch-to-zoom and pan gestures
  - Swipe navigation between images
  - Auto-hiding overlay controls
  - Image caching for performance

- **Video Player**

  - Stream videos directly from WebDAV server
  - Playback controls (play/pause, seek, volume)
  - Progress bar with buffering indicator
  - Fullscreen playback
  - Support for offline video playback

- **VR/360 Video Support**

  - Automatic detection of 360/VR content from filename
  - Equirectangular video projection
  - Viewer mode selector (Normal, Cinema, Panorama, VR 3D)
  - Device motion controls for 360 viewing

- **Offline Mode**

  - Download files for offline viewing
  - Progress indicator during downloads
  - Cancel ongoing downloads
  - Manage offline files (view, delete)
  - Total storage usage display
  - Clear all offline files option

- **Quest 3 Optimization**
  - Dark theme optimized for VR readability
  - Large touch targets for VR interaction
  - UI scaled for 2064x2208 per-eye resolution
  - 90Hz display support

### Technical

- Flutter 3.10.7+ with Dart 3
- Drift database for local storage
- Riverpod for state management
- 68 unit and widget tests
- AGPL-3.0 license

[0.1.0]: https://github.com/user/quest3_webdav_client/releases/tag/v0.1.0
