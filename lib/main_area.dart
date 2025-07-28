import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:image_statistics/models/main.dart';
import 'package:path/path.dart' as path;

class UploadFileArea extends StatefulWidget {
  final TabData tabData;
  final Function(TabData) onTabDataChanged;

  const UploadFileArea({
    super.key,
    required this.tabData,
    required this.onTabDataChanged,
  });

  @override
  State<UploadFileArea> createState() => _UploadFileAreaState();
}

class _UploadFileAreaState extends State<UploadFileArea> {
  bool isDragOver = false;
  bool isProcessing = false;
  bool isScanning = false;

  TabData get tabData => widget.tabData;
  String? get selectedDirectory => tabData.selectedDirectory;
  List<File> get droppedFiles => tabData.droppedFiles;
  DirectoryStats? get directoryStats => tabData.directoryStats;
  bool get autoProcess => tabData.autoProcess;

  void _updateTabData(TabData newTabData) {
    widget.onTabDataChanged(newTabData);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _updateDirectoryStats();
    _startPeriodicStatsUpdate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startPeriodicStatsUpdate() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _updateDirectoryStats();
        _startPeriodicStatsUpdate();
      }
    });
  }

  // 递归获取文件夹内的所有文件
  Future<List<File>> _getAllFilesFromDirectory(Directory directory) async {
    List<File> allFiles = [];

    try {
      // 检查目录是否存在
      if (!await directory.exists()) {
        return allFiles;
      }

      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          allFiles.add(entity);
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('文件夹扫描完成，共找到 ${allFiles.length} 个文件'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning directory ${directory.path}: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    return allFiles;
  }

  Future<void> selectDirectory() async {
    String? result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择目标目录',
    );

    if (result != null) {
      _updateTabData(tabData.copyWith(selectedDirectory: result));
      _updateDirectoryStats();
    }
  }

  Future<void> _updateDirectoryStats() async {
    if (selectedDirectory == null) return;

    try {
      final directory = Directory(selectedDirectory!);
      if (!await directory.exists()) return;

      int fileCount = 0;
      int totalSize = 0;

      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          fileCount++;
          totalSize += await entity.length();
        }
      }

      _updateTabData(
        tabData.copyWith(
          directoryStats: DirectoryStats(
            fileCount: fileCount,
            totalSize: totalSize,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating directory stats: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _processFilesWithData(TabData data) async {
    if (data.selectedDirectory == null || data.droppedFiles.isEmpty) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final directory = Directory(data.selectedDirectory!);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      int existingFileCount = 0;
      await for (final entity in directory.list()) {
        if (entity is File) {
          existingFileCount++;
        }
      }

      int processedCount = 0;
      List<String> errors = [];

      for (int i = 0; i < data.droppedFiles.length; i++) {
        try {
          final file = data.droppedFiles[i];
          if (!await file.exists()) {
            errors.add('文件不存在: ${path.basename(file.path)}');
            continue;
          }

          final extension = path.extension(file.path);
          final newFileName = 'file_${existingFileCount + i + 1}$extension';
          final newFilePath = path.join(data.selectedDirectory!, newFileName);

          final targetFile = File(newFilePath);
          if (await targetFile.exists()) {
            errors.add('文件已存在: $newFileName');
            continue;
          }

          await file.copy(newFilePath);
          processedCount++;
        } catch (e) {
          errors.add(
            '处理文件失败: ${path.basename(data.droppedFiles[i].path)} - $e',
          );
        }
      }

      await _updateDirectoryStats();

      _updateTabData(data.copyWith(droppedFiles: [], scannedPaths: []));

      if (errors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功处理 $processedCount 个文件'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('处理完成: $processedCount 个成功, ${errors.length} 个失败'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '查看详情',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('处理详情'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: errors.length,
                        itemBuilder: (context, index) => ListTile(
                          title: Text(errors[index]),
                          leading: const Icon(Icons.error, color: Colors.red),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('关闭'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('处理文件时出错: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> processDroppedFiles() async {
    if (selectedDirectory == null || droppedFiles.isEmpty) return;
    await _processFilesWithData(tabData);
  }

  Widget _buildSelectFolderView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '请先选择目标文件夹',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '选择文件夹后即可开始拖拽文件',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: selectDirectory,
            icon: const Icon(Icons.folder_open),
            label: const Text('选择文件夹'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragDropView() {
    return DropTarget(
      onDragDone: (detail) async {
        setState(() {
          isScanning = true;
        });

        List<File> allFiles = [];

        try {
          List<String> scannedPaths = [];

          for (final file in detail.files) {
            try {
              // 尝试作为文件处理
              final fileEntity = File(file.path);
              if (await fileEntity.exists()) {
                // 检查是否是文件夹
                final stat = await fileEntity.stat();

                if (stat.type == FileSystemEntityType.directory) {
                  // 如果是文件夹，递归获取所有文件
                  scannedPaths.add(file.path);
                  final directoryFiles = await _getAllFilesFromDirectory(
                    Directory(file.path),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('文件夹中扫描到 ${directoryFiles.length} 个文件'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  allFiles.addAll(directoryFiles);
                } else {
                  allFiles.add(fileEntity);
                }
              } else {
                // 尝试作为文件夹处理
                final directoryEntity = Directory(file.path);
                if (await directoryEntity.exists()) {
                  scannedPaths.add(file.path);
                  final directoryFiles = await _getAllFilesFromDirectory(
                    directoryEntity,
                  );
                  allFiles.addAll(directoryFiles);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('文件不存在: ${file.path}'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('处理文件时出错: ${file.path} - $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }

          // 显示扫描结果
          if (allFiles.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('未找到任何文件。请检查拖拽的路径是否正确。'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('成功扫描到 ${allFiles.length} 个文件'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }

          final newTabData = tabData.copyWith(
            droppedFiles: [...droppedFiles, ...allFiles],
            scannedPaths: [...tabData.scannedPaths, ...scannedPaths],
          );
          _updateTabData(newTabData);

          if (autoProcess && selectedDirectory != null) {
            await _processFilesWithData(newTabData);
          }
        } finally {
          setState(() {
            isScanning = false;
          });
        }
      },
      onDragEntered: (detail) {
        setState(() {
          isDragOver = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          isDragOver = false;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDragOver
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          border: Border.all(
            color: isDragOver ? Colors.blue : Colors.grey,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isScanning)
                const Column(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(strokeWidth: 4),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '正在扫描文件夹...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                )
              else
                Icon(
                  isDragOver ? Icons.cloud_download : Icons.cloud_upload,
                  size: 64,
                  color: isDragOver ? Colors.blue : Colors.grey,
                ),
              const SizedBox(height: 16),
              Text(
                isDragOver ? '释放文件到此处' : '拖拽文件或文件夹到此处',
                style: TextStyle(
                  fontSize: 18,
                  color: isDragOver ? Colors.blue : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '支持文件夹递归扫描',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text('或点击选择文件', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(allowMultiple: true);

                      if (result != null) {
                        setState(() {
                          isScanning = true;
                        });

                        try {
                          List<File> allFiles = [];
                          List<String> scannedPaths = [];

                          for (final file in result.files) {
                            if (file.path != null) {
                              final fileEntity = File(file.path!);
                              if (await fileEntity.exists()) {
                                // 检查是否是文件夹
                                final stat = await fileEntity.stat();
                                if (stat.type ==
                                    FileSystemEntityType.directory) {
                                  // 如果是文件夹，递归获取所有文件
                                  scannedPaths.add(file.path!);
                                  final directoryFiles =
                                      await _getAllFilesFromDirectory(
                                        Directory(file.path!),
                                      );
                                  allFiles.addAll(directoryFiles);
                                } else {
                                  // 如果是文件，直接添加
                                  allFiles.add(fileEntity);
                                }
                              }
                            }
                          }

                          final newTabData = tabData.copyWith(
                            droppedFiles: [...droppedFiles, ...allFiles],
                            scannedPaths: [
                              ...tabData.scannedPaths,
                              ...scannedPaths,
                            ],
                          );
                          _updateTabData(newTabData);

                          if (autoProcess && selectedDirectory != null) {
                            await _processFilesWithData(newTabData);
                          }
                        } finally {
                          setState(() {
                            isScanning = false;
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.file_upload),
                    label: const Text('选择文件'),
                  ),

                  // 查看文件列表按钮
                  if (droppedFiles.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('扫描到的文件'),
                            content: SizedBox(
                              width: double.maxFinite,
                              height: 400,
                              child: Column(
                                children: [
                                  // 扫描的文件夹信息
                                  if (tabData.scannedPaths.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.folder_open,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '扫描了 ${tabData.scannedPaths.length} 个文件夹',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // 文件列表
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: droppedFiles.length,
                                      itemBuilder: (context, index) {
                                        final file = droppedFiles[index];
                                        return ListTile(
                                          leading: const Icon(
                                            Icons.insert_drive_file,
                                          ),
                                          title: Text(
                                            path.basename(file.path),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Text(
                                            file.path,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          trailing: Text(
                                            filesize(file.lengthSync()),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('关闭'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.list),
                      label: Text('查看文件 (${droppedFiles.length})'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 主要内容区域 - 根据是否选择文件夹显示不同内容
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: selectedDirectory == null
                  ? _buildSelectFolderView()
                  : _buildDragDropView(),
            ),
          ),
        ),

        // 底部状态栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              // 目录选择按钮
              ElevatedButton.icon(
                onPressed: selectDirectory,
                icon: const Icon(Icons.folder_open, size: 16),
                label: Text(
                  selectedDirectory != null
                      ? path.basename(selectedDirectory!)
                      : '选择目录',
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text(
                    '自动处理',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Switch(
                    value: autoProcess,
                    onChanged: (value) {
                      _updateTabData(tabData.copyWith(autoProcess: value));
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // 统计信息
              if (directoryStats != null) ...[
                Text(
                  '文件: ${directoryStats!.fileCount}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Text(
                  '大小: ${filesize(directoryStats!.totalSize)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 12),
              ],

              // 待处理文件数量
              if (droppedFiles.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.file_present,
                        size: 14,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${droppedFiles.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // 扫描状态
              if (isScanning) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '扫描中...',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // 扫描的文件夹信息
              if (tabData.scannedPaths.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.folder_open,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${tabData.scannedPaths.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],

              const Spacer(),

              // 手动处理按钮
              if (!autoProcess && droppedFiles.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: isProcessing ? null : processDroppedFiles,
                  icon: isProcessing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow, size: 16),
                  label: Text(
                    isProcessing ? '处理中...' : '开始处理',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
