#!/bin/bash

# 回收站系统卸载脚本
# 此脚本会安全地移除回收站系统并恢复原始rm命令

INSTALL_DIR="$HOME/.local/bin"
BACKUP_DIR="$HOME/.trash-system-backup"
TRASH_DIR="$HOME/.trash"
INFO_FILE="$HOME/.trash-system-info.txt"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 回收站系统卸载程序 ===${NC}"
echo ""

# 显示帮助信息
show_help() {
    echo "回收站系统卸载工具"
    echo ""
    echo "用法: ./uninstall-trash-system.sh [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help       显示此帮助信息"
    echo "  -f, --force      强制卸载，不询问确认"
    echo "  -k, --keep-trash 保留回收站内容"
    echo "  -c, --clean-all  完全清理所有相关文件"
    echo ""
    echo "示例:"
    echo "  ./uninstall-trash-system.sh        # 交互式卸载"
    echo "  ./uninstall-trash-system.sh -f     # 强制卸载"
    echo "  ./uninstall-trash-system.sh -k     # 卸载但保留回收站内容"
}

# 检查安装状态
check_installation() {
    local installed_files=()
    
    # 检查安装的脚本
    for script in trash trash-list trash-restore trash-empty rm; do
        if [[ -f "$INSTALL_DIR/$script" ]]; then
            installed_files+=("$script")
        fi
    done
    
    if [[ ${#installed_files[@]} -eq 0 ]]; then
        echo -e "${YELLOW}未检测到已安装的回收站系统${NC}"
        return 1
    fi
    
    echo -e "${GREEN}检测到已安装的回收站系统:${NC}"
    for file in "${installed_files[@]}"; do
        echo "  ✓ $INSTALL_DIR/$file"
    done
    echo ""
    
    return 0
}

# 显示回收站统计信息
show_trash_stats() {
    if [[ ! -d "$TRASH_DIR" ]]; then
        echo -e "${YELLOW}回收站目录不存在${NC}"
        return
    fi
    
    local count=0
    local total_size=0
    
    if [[ -d "$TRASH_DIR/info" ]]; then
        for info_file in "$TRASH_DIR/info"/*.trashinfo; do
            if [[ -f "$info_file" ]]; then
                ((count++))
                local trash_name=$(basename "$info_file" .trashinfo)
                local trash_file="$TRASH_DIR/files/$trash_name"
                
                if [[ -e "$trash_file" ]]; then
                    if [[ -d "$trash_file" ]]; then
                        local dir_size=$(du -sb "$trash_file" 2>/dev/null | cut -f1 || echo 0)
                        total_size=$((total_size + dir_size))
                    else
                        local file_size=$(stat -c%s "$trash_file" 2>/dev/null || echo 0)
                        total_size=$((total_size + file_size))
                    fi
                fi
            fi
        done
    fi
    
    if [[ $count -gt 0 ]]; then
        # 格式化大小
        local size_str
        if [[ $total_size -lt 1024 ]]; then
            size_str="${total_size}B"
        elif [[ $total_size -lt 1048576 ]]; then
            size_str="$(( total_size / 1024 ))K"
        elif [[ $total_size -lt 1073741824 ]]; then
            size_str="$(( total_size / 1048576 ))M"
        else
            size_str="$(( total_size / 1073741824 ))G"
        fi
        
        echo -e "${BLUE}回收站统计信息:${NC}"
        echo "  文件数量: $count 个"
        echo "  总大小: $size_str"
        echo ""
    else
        echo -e "${GREEN}回收站为空${NC}"
        echo ""
    fi
}

# 移除安装的脚本
remove_scripts() {
    echo -e "${BLUE}移除已安装的脚本...${NC}"
    
    local removed=0
    local failed=0
    
    for script in trash trash-list trash-restore trash-empty rm; do
        if [[ -f "$INSTALL_DIR/$script" ]]; then
            if rm -f "$INSTALL_DIR/$script" 2>/dev/null; then
                echo "  ✓ 已移除: $script"
                ((removed++))
            else
                echo -e "  ${RED}✗ 移除失败: $script${NC}"
                ((failed++))
            fi
        fi
    done
    
    echo "移除完成: 成功 $removed 个, 失败 $failed 个"
    echo ""
}

# 清理shell配置
clean_shell_config() {
    echo -e "${BLUE}清理shell配置...${NC}"
    
    for config_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [[ -f "$config_file" ]]; then
            local shell_name=$(basename "$config_file" | tr '[:lower:]' '[:upper:]')
            
            # 检查是否有回收站系统配置
            if grep -q "# 回收站系统配置" "$config_file"; then
                # 创建临时文件
                local temp_file=$(mktemp)
                
                # 移除回收站系统配置段落
                awk '
                /# 回收站系统配置/ { skip=1; next }
                skip && /^$/ && getline && /^[^#]/ { skip=0 }
                skip && /^[^#]/ { skip=0 }
                !skip { print }
                ' "$config_file" > "$temp_file"
                
                # 替换原文件
                if mv "$temp_file" "$config_file"; then
                    echo "  ✓ 已清理: $shell_name"
                else
                    echo -e "  ${RED}✗ 清理失败: $shell_name${NC}"
                    rm -f "$temp_file"
                fi
            else
                echo "  - 跳过: $shell_name (无相关配置)"
            fi
        fi
    done
    echo ""
}

# 恢复配置文件备份
restore_backups() {
    echo -e "${BLUE}恢复配置文件备份...${NC}"
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo "  - 无备份文件需要恢复"
        return
    fi
    
    local restored=0
    
    for backup_file in "$BACKUP_DIR"/*.backup; do
        if [[ -f "$backup_file" ]]; then
            local original_name=$(basename "$backup_file" .backup)
            local original_path="$HOME/$original_name"
            
            echo -n "  恢复 $original_name? [y/N]: "
            read -r response
            case "$response" in
                [yY]|[yY][eE][sS])
                    if cp "$backup_file" "$original_path"; then
                        echo "  ✓ 已恢复: $original_name"
                        ((restored++))
                    else
                        echo -e "  ${RED}✗ 恢复失败: $original_name${NC}"
                    fi
                    ;;
                *)
                    echo "  - 跳过: $original_name"
                    ;;
            esac
        fi
    done
    
    if [[ $restored -gt 0 ]]; then
        echo "恢复完成: $restored 个文件"
    fi
    echo ""
}

# 清理回收站内容
clean_trash() {
    local keep_trash="$1"
    
    if [[ "$keep_trash" == "true" ]]; then
        echo -e "${YELLOW}保留回收站内容${NC}"
        return
    fi
    
    if [[ ! -d "$TRASH_DIR" ]]; then
        echo -e "${GREEN}回收站目录不存在，无需清理${NC}"
        return
    fi
    
    echo -e "${BLUE}清理回收站内容...${NC}"
    
    # 再次确认
    echo -e "${RED}警告: 这将永久删除回收站中的所有文件！${NC}"
    echo -n "确定要删除回收站内容吗? [y/N]: "
    read -r response
    case "$response" in
        [yY]|[yY][eE][sS])
            if rm -rf "$TRASH_DIR"; then
                echo "  ✓ 回收站已清空"
            else
                echo -e "  ${RED}✗ 清理回收站失败${NC}"
            fi
            ;;
        *)
            echo "  - 保留回收站内容"
            ;;
    esac
    echo ""
}

# 清理其他文件
clean_other_files() {
    echo -e "${BLUE}清理其他相关文件...${NC}"
    
    # 清理信息文件
    if [[ -f "$INFO_FILE" ]]; then
        rm -f "$INFO_FILE" && echo "  ✓ 已删除: .trash-system-info.txt"
    fi
    
    # 清理备份目录
    if [[ -d "$BACKUP_DIR" ]]; then
        echo -n "  删除备份目录? [y/N]: "
        read -r response
        case "$response" in
            [yY]|[yY][eE][sS])
                if rm -rf "$BACKUP_DIR"; then
                    echo "  ✓ 已删除备份目录"
                else
                    echo -e "  ${RED}✗ 删除备份目录失败${NC}"
                fi
                ;;
            *)
                echo "  - 保留备份目录"
                ;;
        esac
    fi
    echo ""
}

# 验证卸载结果
verify_uninstall() {
    echo -e "${BLUE}验证卸载结果...${NC}"
    
    local remaining_files=()
    
    # 检查是否还有安装的脚本
    for script in trash trash-list trash-restore trash-empty rm; do
        if [[ -f "$INSTALL_DIR/$script" ]]; then
            remaining_files+=("$INSTALL_DIR/$script")
        fi
    done
    
    if [[ ${#remaining_files[@]} -eq 0 ]]; then
        echo -e "${GREEN}✓ 卸载成功！所有脚本文件已移除${NC}"
    else
        echo -e "${RED}✗ 卸载不完整，以下文件仍然存在:${NC}"
        for file in "${remaining_files[@]}"; do
            echo "  - $file"
        done
    fi
    
    # 检查PATH
    if which rm >/dev/null 2>&1; then
        local rm_path=$(which rm)
        if [[ "$rm_path" == "/bin/rm" || "$rm_path" == "/usr/bin/rm" ]]; then
            echo -e "${GREEN}✓ rm命令已恢复为系统默认版本${NC}"
        else
            echo -e "${YELLOW}⚠ rm命令路径: $rm_path${NC}"
        fi
    fi
    echo ""
}

# 主函数
main() {
    local force=false
    local keep_trash=false
    local clean_all=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -k|--keep-trash)
                keep_trash=true
                shift
                ;;
            -c|--clean-all)
                clean_all=true
                shift
                ;;
            -*)
                echo -e "${RED}错误: 未知选项 '$1'${NC}" >&2
                echo "使用 './uninstall-trash-system.sh --help' 查看帮助信息"
                exit 1
                ;;
            *)
                echo -e "${RED}错误: 不支持的参数 '$1'${NC}" >&2
                exit 1
                ;;
        esac
    done
    
    # 检查安装状态
    if ! check_installation; then
        exit 0
    fi
    
    # 显示回收站信息
    show_trash_stats
    
    # 确认卸载
    if [[ "$force" != "true" ]]; then
        echo -e "${YELLOW}这将卸载回收站系统并恢复原始的rm命令${NC}"
        echo -n "确定要继续吗? [y/N]: "
        read -r response
        case "$response" in
            [yY]|[yY][eE][sS])
                ;;
            *)
                echo "卸载已取消"
                exit 0
                ;;
        esac
        echo ""
    fi
    
    # 执行卸载步骤
    remove_scripts
    clean_shell_config
    
    if [[ "$force" != "true" ]]; then
        restore_backups
    fi
    
    if [[ "$clean_all" == "true" ]]; then
        clean_trash "false"
    else
        clean_trash "$keep_trash"
    fi
    
    clean_other_files
    verify_uninstall
    
    echo -e "${GREEN}=== 卸载完成 ===${NC}"
    echo ""
    echo -e "${BLUE}重要提醒:${NC}"
    echo "1. 请重新打开终端或运行 'source ~/.bashrc' 使配置生效"
    echo "2. rm命令已恢复为系统默认行为（永久删除）"
    if [[ "$keep_trash" == "true" || "$clean_all" != "true" ]]; then
        echo "3. 回收站内容仍在 $TRASH_DIR 中，可手动删除"
    fi
    echo ""
    echo -e "${GREEN}感谢使用回收站系统！${NC}"
}

# 执行主函数
main "$@" 