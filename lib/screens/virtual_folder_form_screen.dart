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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_theme.dart';
import '../models/virtual_folder.dart';
import '../providers/providers.dart';
import '../widgets/connection_status_indicator.dart';

/// Screen for creating or editing a virtual folder.
///
/// Provides form fields for folder name, server URL, base path,
/// and credentials. Includes connection testing functionality.
class VirtualFolderFormScreen extends ConsumerStatefulWidget {
  /// Existing folder to edit (null for creating new).
  final VirtualFolder? editFolder;

  /// Template folder to copy settings from.
  final VirtualFolder? templateFolder;

  const VirtualFolderFormScreen({
    super.key,
    this.editFolder,
    this.templateFolder,
  });

  @override
  ConsumerState<VirtualFolderFormScreen> createState() =>
      _VirtualFolderFormScreenState();
}

class _VirtualFolderFormScreenState
    extends ConsumerState<VirtualFolderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _serverUrlController;
  late TextEditingController _basePathController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  int? _selectedColor;
  ConnectionStatus _connectionStatus = ConnectionStatus.unknown;
  String? _connectionError;
  bool _isSaving = false;
  bool _passwordVisible = false;

  bool get _isEditing => widget.editFolder != null;

  @override
  void initState() {
    super.initState();

    final edit = widget.editFolder;
    final template = widget.templateFolder;

    _nameController = TextEditingController(
      text: edit?.name ?? '',
    );
    _serverUrlController = TextEditingController(
      text: edit?.serverUrl ?? template?.serverUrl ?? '',
    );
    _basePathController = TextEditingController(
      text: edit?.basePath ?? template?.basePath ?? '',
    );
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();

    _selectedColor = edit?.iconColor ?? template?.iconColor;

    // Load credentials for editing
    if (edit != null) {
      _loadCredentials(edit.credentialId);
    } else if (template != null) {
      _loadCredentials(template.credentialId);
    }
  }

  Future<void> _loadCredentials(String credentialId) async {
    final credentialService = ref.read(credentialServiceProvider);
    final credentials = await credentialService.getCredentials(credentialId);

    if (credentials != null && mounted) {
      setState(() {
        _usernameController.text = credentials.username;
        _passwordController.text = credentials.password;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serverUrlController.dispose();
    _basePathController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Folder' : 'Add Folder'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          children: [
            // Folder name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Folder Name',
                hintText: 'My Cloud Storage',
                prefixIcon: Icon(Icons.folder_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a folder name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Color selection
            Text(
              'Folder Color',
              style: AppTheme.labelLarge.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              children: AppTheme.folderColors.map((color) {
                final colorValue = color.toARGB32();
                final isSelected = _selectedColor == colorValue;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorValue;
                    });
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: isSelected
                          ? Border.all(
                              color: AppTheme.textPrimary,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Server section
            const Divider(),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Server Connection',
              style: AppTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Server URL
            TextFormField(
              controller: _serverUrlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'https://cloud.example.com',
                prefixIcon: Icon(Icons.link_rounded),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
              onChanged: (_) => _resetConnectionStatus(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the server URL';
                }
                if (!value.startsWith('http://') &&
                    !value.startsWith('https://')) {
                  return 'URL must start with http:// or https://';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Base path
            TextFormField(
              controller: _basePathController,
              decoration: const InputDecoration(
                labelText: 'Base Path',
                hintText: '/remote.php/dav/files/username',
                prefixIcon: Icon(Icons.folder_open_rounded),
              ),
              autocorrect: false,
              onChanged: (_) => _resetConnectionStatus(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the base path';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Credentials section
            const Divider(),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Credentials',
              style: AppTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Username
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'your-username',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              autocorrect: false,
              onChanged: (_) => _resetConnectionStatus(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your username';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Password
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'your-password',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                  icon: Icon(
                    _passwordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
              obscureText: !_passwordVisible,
              autocorrect: false,
              onChanged: (_) => _resetConnectionStatus(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Connection status
            ConnectionStatusBanner(
              status: _connectionStatus,
              errorMessage: _connectionError,
              onRetry: _testConnection,
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Test connection button
            OutlinedButton.icon(
              onPressed: _connectionStatus == ConnectionStatus.testing
                  ? null
                  : _testConnection,
              icon: _connectionStatus == ConnectionStatus.testing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering_rounded),
              label: Text(
                _connectionStatus == ConnectionStatus.testing
                    ? 'Testing...'
                    : 'Test Connection',
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Save button
            ElevatedButton(
              onPressed: _connectionStatus == ConnectionStatus.connected &&
                      !_isSaving
                  ? _saveFolder
                  : null,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Create Folder'),
            ),

            if (_connectionStatus != ConnectionStatus.connected)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                child: Text(
                  'Test the connection before saving',
                  style: AppTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  void _resetConnectionStatus() {
    if (_connectionStatus != ConnectionStatus.unknown) {
      setState(() {
        _connectionStatus = ConnectionStatus.unknown;
        _connectionError = null;
      });
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _connectionStatus = ConnectionStatus.testing;
      _connectionError = null;
    });

    try {
      final notifier = ref.read(virtualFolderNotifierProvider.notifier);
      final success = await notifier.testConnection(
        serverUrl: _serverUrlController.text.trim(),
        basePath: _basePathController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _connectionStatus =
              success ? ConnectionStatus.connected : ConnectionStatus.failed;
          if (!success) {
            _connectionError = 'Could not connect to server';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionStatus = ConnectionStatus.failed;
          _connectionError = e.toString();
        });
      }
    }
  }

  Future<void> _saveFolder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_connectionStatus != ConnectionStatus.connected) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final notifier = ref.read(virtualFolderNotifierProvider.notifier);

      if (_isEditing) {
        await notifier.updateFolder(
          id: widget.editFolder!.id,
          name: _nameController.text.trim(),
          serverUrl: _serverUrlController.text.trim(),
          basePath: _basePathController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          iconColor: _selectedColor,
        );
      } else {
        await notifier.createFolder(
          name: _nameController.text.trim(),
          serverUrl: _serverUrlController.text.trim(),
          basePath: _basePathController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          iconColor: _selectedColor,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Folder updated' : 'Folder created',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
