#!/bin/bash

# 通用AppImage构建脚本
# 支持本地和CI/CD环境

set -e

# 配置变量
APP_NAME="auto_format_folder"
APP_VERSION="1.0.0"
APP_DESCRIPTION="自动格式化添加进文件夹的文件或文件夹"
APP_ID="auto-format-folder"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查环境
check_environment() {
    log_info "检查构建环境..."
    
    # 检查Flutter
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter未安装或不在PATH中"
        exit 1
    fi
    
    # 检查是否在CI环境
    if [ -n "$CI" ]; then
        log_info "检测到CI环境"
        CI_MODE=true
    else
        log_info "本地构建模式"
        CI_MODE=false
    fi
}

# 检查并下载appimagetool
check_appimagetool() {
    if ! command -v appimagetool &> /dev/null; then
        log_warn "appimagetool未安装，正在下载..."
        wget -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
        chmod +x appimagetool-x86_64.AppImage
        if [ "$CI_MODE" = true ]; then
            sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool
        else
            sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool
        fi
        log_info "appimagetool安装完成"
    fi
}

# 构建Flutter应用
build_flutter() {
    log_info "构建Flutter Linux应用..."
    
    if [ "$CI_MODE" = false ]; then
        flutter clean
    fi
    
    flutter pub get
    flutter build linux --release
}

# 创建AppDir结构
create_appdir() {
    log_info "创建AppDir结构..."
    
    # 清理之前的AppDir
    rm -rf AppDir
    
    # 创建目录结构
    mkdir -p AppDir/usr/bin
    mkdir -p AppDir/usr/share/applications
    mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps
    mkdir -p AppDir/usr/share/metainfo
    
    # 复制Flutter构建的应用
    cp -r build/linux/x64/release/bundle/* AppDir/usr/bin/
    
    # 复制桌面文件
    cp assets/desktop/auto-format-folder.desktop AppDir/usr/share/applications/
    cp assets/desktop/auto-format-folder.desktop AppDir/
    
    
    # 复制应用图标
    cp assets/icon.png AppDir/usr/share/icons/hicolor/256x256/apps/auto-format-folder.png
    cp assets/icon.png AppDir/auto-format-folder.png

    
    cp assets/metainfo/com.github.hhoao.auto-format-folder.appdata.xml AppDir/usr/share/metainfo/

    
    cp assets/scripts/AppRun AppDir/AppRun
    chmod +x AppDir/AppRun

}

# 创建AppImage
create_appimage() {
    log_info "创建AppImage..."
    
    # 使用appimagetool创建AppImage
    appimagetool AppDir auto-format-folder-x86_64.AppImage
    
    if [ -f "auto-format-folder-x86_64.AppImage" ]; then
        log_info "AppImage创建成功: auto-format-folder-x86_64.AppImage"
        chmod +x auto-format-folder-x86_64.AppImage
        
        # 显示文件信息
        ls -lh auto-format-folder-x86_64.AppImage
    else
        log_error "AppImage创建失败"
        exit 1
    fi
}

# 清理临时文件
cleanup() {
    if [ "$CI_MODE" = false ]; then
        log_info "清理临时文件..."
        rm -rf AppDir/
    fi
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  --no-cleanup   不清理临时文件"
    echo "  --skip-build   跳过Flutter构建步骤"
    echo ""
    echo "示例:"
    echo "  $0              # 完整构建"
    echo "  $0 --no-cleanup # 构建但不清理临时文件"
    echo "  $0 --skip-build # 跳过Flutter构建，直接创建AppImage"
}

# 解析命令行参数
SKIP_BUILD=false
NO_CLEANUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --no-cleanup)
            NO_CLEANUP=true
            shift
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 主函数
main() {
    log_info "开始AppImage构建..."
    
    check_environment
    check_appimagetool
    
    if [ "$SKIP_BUILD" = false ]; then
        build_flutter
    fi
    
    create_appdir
    create_appimage
    
    if [ "$NO_CLEANUP" = false ]; then
        cleanup
    fi
    
    log_info "AppImage构建完成！"
    log_info "生成的文件: auto-format-folder-x86_64.AppImage"
}

# 运行主函数
main "$@"