import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_statistics/main_area.dart';
import 'package:image_statistics/models/main.dart';
import 'package:image_statistics/widgets/tab_button.dart';
import 'package:image_statistics/widgets/window_button.dart';
import 'package:path/path.dart' as path;
import 'package:window_manager/window_manager.dart';

class TabManager extends StatefulWidget {
  const TabManager({super.key});

  @override
  State<TabManager> createState() => _TabManagerState();
}

class _TabManagerState extends State<TabManager> with TickerProviderStateMixin {
  late TabController _tabController;
  final List<TabData> _tabData = [];

  // 窗口管理相关
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _tabData.add(const TabData());
    _tabController = TabController(length: _tabData.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addNewTab() {
    setState(() {
      _tabData.add(const TabData());
      _tabController = TabController(
        length: _tabData.length,
        vsync: this,
        initialIndex: _tabData.length - 1,
      );
    });
  }

  void _removeTab(int index) {
    setState(() {
      if (_tabData.length > 1) {
        // 多个tab时，删除指定tab
        _tabData.removeAt(index);
        _tabController = TabController(
          length: _tabData.length,
          vsync: this,
          initialIndex: index > 0 ? index - 1 : 0,
        );
      } else {
        // 只有一个tab时，删除当前tab并创建新tab
        _tabData.clear();
        _tabData.add(const TabData());
        _tabController = TabController(
          length: _tabData.length,
          vsync: this,
          initialIndex: 0,
        );
      }
    });
  }

  Widget _buildWindowButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? hoverColor,
    Color? activeColor,
    Color? iconColor,
  }) {
    return WindowButton(
      icon: icon,
      onTap: onTap,
      hoverColor: hoverColor,
      activeColor: activeColor,
      iconColor: iconColor,
    );
  }

  Widget _buildCustomTitleBar() {
    return GestureDetector(
      onPanUpdate: (details) async {
        if (Platform.isLinux) {
          await windowManager.startDragging();
        }
      },
      child: Container(
        height: 40,
        color: Theme.of(context).colorScheme.inversePrimary,
        child: Row(
          children: [
            // 标题区域
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.folder_open, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '格式化文件夹',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 窗口控制按钮
            Row(
              children: [
                // 最小化按钮
                _buildWindowButton(
                  icon: Icons.remove,
                  onTap: () async {
                    if (Platform.isLinux) {
                      await windowManager.minimize();
                    }
                  },
                  hoverColor: Colors.grey.withValues(alpha: 0.2),
                  activeColor: Colors.grey.withValues(alpha: 0.3),
                ),

                // 最大化/还原按钮
                _buildWindowButton(
                  icon: _isMaximized
                      ? Icons.crop_square
                      : Icons.crop_square_outlined,
                  onTap: () async {
                    if (Platform.isLinux) {
                      if (_isMaximized) {
                        await windowManager.unmaximize();
                      } else {
                        await windowManager.maximize();
                      }
                      setState(() {
                        _isMaximized = !_isMaximized;
                      });
                    }
                  },
                  hoverColor: Colors.grey.withValues(alpha: 0.2),
                  activeColor: Colors.grey.withValues(alpha: 0.3),
                ),

                // 关闭按钮
                _buildWindowButton(
                  icon: Icons.close,
                  onTap: () async {
                    if (Platform.isLinux) {
                      await windowManager.close();
                    } else {
                      exit(0);
                    }
                  },
                  hoverColor: Colors.red.withValues(alpha: 0.2),
                  activeColor: Colors.red.withValues(alpha: 0.3),
                  iconColor: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.keyT &&
              HardwareKeyboard.instance.isControlPressed) {
            _addNewTab();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 主要内容
            Column(
              children: [
                // 自定义窗口控制栏
                if (Platform.isLinux) _buildCustomTitleBar(),

                // 标签栏
                Container(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  child: Row(
                    children: [
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        padding: EdgeInsets.zero,
                        labelPadding: EdgeInsets.zero,
                        indicator: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelStyle: const TextStyle(fontSize: 12),
                        unselectedLabelStyle: const TextStyle(fontSize: 12),
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.black,
                        tabAlignment: TabAlignment.start,
                        tabs: [
                          ...List.generate(_tabData.length, (index) {
                            final tabData = _tabData[index];
                            final tabName = tabData.selectedDirectory != null
                                ? path.basename(tabData.selectedDirectory!)
                                : '文件夹 ${index + 1}';

                            return Tab(
                              child: TabButton(
                                onTap: () => _tabController.animateTo(index),
                                onClose: () => _removeTab(index),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.folder,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        tabName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    WindowButton(
                                      icon: Icons.close,
                                      onTap: () => _removeTab(index),
                                      hoverColor: Colors.grey.withValues(
                                        alpha: 0.4,
                                      ),
                                      activeColor: Colors.grey.withValues(
                                        alpha: 0.2,
                                      ),
                                      iconColor: Colors.black,
                                      containerSize: 20,
                                      iconSize: 18,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      // 添加新标签页按钮
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TabButton(
                          onTap: _addNewTab,
                          child: const Icon(
                            Icons.add,
                            size: 20,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ...List.generate(_tabData.length, (index) {
                        return UploadFileArea(
                          key: ValueKey('tab_$index'),
                          tabData: _tabData[index],
                          onTabDataChanged: (tabData) {
                            setState(() {
                              _tabData[index] = tabData;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
