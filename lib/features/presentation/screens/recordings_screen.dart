import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  List<FileSystemEntity> recordings = [];
  bool isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingPath;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
    
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _playingPath = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPauseRecording(String filePath) async {
    try {
      if (_playingPath == filePath && _isPlaying) {
        // Pause current recording
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else if (_playingPath == filePath && !_isPlaying) {
        // Resume current recording
        await _audioPlayer.play();
        setState(() => _isPlaying = true);
      } else {
        // Play new recording
        await _audioPlayer.stop();
        await _audioPlayer.setFilePath(filePath);
        await _audioPlayer.play();
        setState(() {
          _playingPath = filePath;
          _isPlaying = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing recording: $e')),
        );
      }
    }
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _playingPath = null;
    });
  }

  Future<void> _loadRecordings() async {
    try {
      setState(() => isLoading = true);
      
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();

      final recordingFiles = files
          .where((file) =>
              file is File &&
              file.path.contains(AppConstants.recordingPrefix) &&
              (file.path.endsWith('.wav') || file.path.endsWith('.m4a')))
          .toList();

      // Sort by modification time (newest first)
      recordingFiles.sort((a, b) {
        final aTime = (a as File).lastModifiedSync();
        final bTime = (b as File).lastModifiedSync();
        return bTime.compareTo(aTime);
      });

      setState(() {
        recordings = recordingFiles;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recordings: $e')),
        );
      }
    }
  }

  Future<void> _deleteRecording(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text('Are you sure you want to delete this recording?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await file.delete();
        _loadRecordings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting recording: $e')),
          );
        }
      }
    }
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  String _getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getFormattedDate(File file) {
    final date = file.lastModifiedSync();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return DateFormat('MMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecordings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recordings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mic_off,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recordings yet',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start the jammer and tap Record\nto create your first recording',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: recordings.length,
                  itemBuilder: (context, index) {
                    final file = recordings[index] as File;
                    final fileName = _getFileName(file.path);
                    final fileSize = _getFileSize(file);
                    final date = _getFormattedDate(file);
                    final isWav = file.path.endsWith('.wav');

                    final isCurrentlyPlaying = _playingPath == file.path && _isPlaying;
                    final isCurrentFile = _playingPath == file.path;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCurrentlyPlaying 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primaryContainer,
                          child: Icon(
                            isWav ? Icons.audiotrack : Icons.music_note,
                            color: isCurrentlyPlaying
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          fileName,
                          style: theme.textTheme.bodyLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('$fileSize • $date'),
                        onTap: () => _playPauseRecording(file.path),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isCurrentlyPlaying
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                                size: 32,
                                color: theme.colorScheme.primary,
                              ),
                              onPressed: () => _playPauseRecording(file.path),
                              tooltip: isCurrentlyPlaying ? 'Pause' : 'Play',
                            ),
                            if (isCurrentFile && _isPlaying)
                              IconButton(
                                icon: const Icon(Icons.stop),
                                onPressed: _stopPlayback,
                                tooltip: 'Stop',
                              ),
                            PopupMenuButton(
                              icon: const Icon(Icons.more_vert),
                              itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline),
                                  SizedBox(width: 12),
                                  Text('Info'),
                                ],
                              ),
                              onTap: () {
                                Future.delayed(Duration.zero, () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Recording Info'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('File: $fileName'),
                                          const SizedBox(height: 8),
                                          Text('Size: $fileSize'),
                                          const SizedBox(height: 8),
                                          Text('Format: ${isWav ? 'WAV (Android)' : 'M4A (iOS)'}'),
                                          const SizedBox(height: 8),
                                          Text('Created: ${DateFormat('MMM d, y - h:mm a').format(file.lastModifiedSync())}'),
                                          const SizedBox(height: 8),
                                          Text('Path: ${file.path}', style: theme.textTheme.bodySmall),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                });
                              },
                            ),
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                              onTap: () => _deleteRecording(file),
                            ),
                          ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

