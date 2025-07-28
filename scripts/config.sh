#!/bin/bash

# AppImage构建配置文件
# 集中管理应用信息和构建配置

# 应用基本信息
export APP_NAME="auto_format_folder"
export APP_VERSION="1.0.0"
export APP_DESCRIPTION="自动格式化添加进文件夹的文件或文件夹"
export APP_ID="auto-format-folder"
export APP_DISPLAY_NAME="格式化文件夹"

# 开发者信息
export DEVELOPER_NAME="hhoao"
export HOMEPAGE_URL="https://github.com/hhoao/auto_format_folder"
export BUGTRACKER_URL="https://github.com/hhoao/auto_format_folder/issues"
export HELP_URL="https://github.com/hhoao/auto_format_folder"

# 许可证信息
export LICENSE="MIT"

# 应用分类
export APP_CATEGORIES="Utility;FileManager;"

# 功能特性
export APP_FEATURES=(
    "文件夹递归扫描"
    "批量文件处理"
    "自动重命名"
    "多标签页管理"
    "拖拽操作"
)

# 构建配置
export BUILD_ARCH="x86_64"
export BUILD_TYPE="release"

# 文件路径配置
export DESKTOP_FILE_PATH="assets/desktop/auto-format-folder.desktop"
export METADATA_FILE_PATH="assets/metainfo/auto-format-folder.appdata.xml"
export APPRUN_SCRIPT_PATH="assets/scripts/AppRun"
export ICON_FILE_PATH="assets/icon.png"
export CONFIG_FILE_PATH="assets/config/app-info.json"

# 输出文件配置
export OUTPUT_APPIMAGE="auto-format-folder-x86_64.AppImage"
export OUTPUT_DIR="build/appimage"

# 颜色配置
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# 验证配置
validate_config() {
    log_info "验证构建配置..."
    
    # 检查必要的变量
    local required_vars=(
        "APP_NAME"
        "APP_VERSION"
        "APP_DESCRIPTION"
        "APP_ID"
        "DEVELOPER_NAME"
        "HOMEPAGE_URL"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "配置变量 $var 未设置"
            return 1
        fi
    done
    
    log_info "配置验证通过"
    return 0
}

# 获取版本信息
get_version_info() {
    echo "应用名称: $APP_DISPLAY_NAME"
    echo "版本: $APP_VERSION"
    echo "应用ID: $APP_ID"
    echo "开发者: $DEVELOPER_NAME"
    echo "许可证: $LICENSE"
    echo "主页: $HOMEPAGE_URL"
}

# 导出所有配置
export -f log_info log_warn log_error log_debug validate_config get_version_info 