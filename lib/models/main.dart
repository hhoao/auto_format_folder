import 'dart:io';

class DirectoryStats {
  final int fileCount;
  final int totalSize;

  DirectoryStats({required this.fileCount, required this.totalSize});
}

class TabData {
  final String? selectedDirectory;
  final List<File> droppedFiles;
  final DirectoryStats? directoryStats;
  final bool autoProcess;
  final List<String> scannedPaths; // 记录扫描的路径

  const TabData({
    this.selectedDirectory,
    this.droppedFiles = const [],
    this.directoryStats,
    this.autoProcess = true,
    this.scannedPaths = const [],
  });

  TabData copyWith({
    String? selectedDirectory,
    List<File>? droppedFiles,
    DirectoryStats? directoryStats,
    bool? autoProcess,
    List<String>? scannedPaths,
  }) {
    return TabData(
      selectedDirectory: selectedDirectory ?? this.selectedDirectory,
      droppedFiles: droppedFiles ?? this.droppedFiles,
      directoryStats: directoryStats ?? this.directoryStats,
      autoProcess: autoProcess ?? this.autoProcess,
      scannedPaths: scannedPaths ?? this.scannedPaths,
    );
  }
}
