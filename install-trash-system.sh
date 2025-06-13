#!/bin/bash

# 回收站系统安装脚本
# 此脚本会配置系统使rm命令使用回收站

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
BACKUP_DIR="$HOME/.trash-system-backup"

echo "=== 回收站系统安装程序 ==="
echo ""

# 创建安装目录
echo "创建安装目录..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$BACKUP_DIR"

# 检查PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "警告: $INSTALL_DIR 不在PATH中"
    echo "将在shell配置文件中添加PATH设置"
fi

# 复制脚本到安装目录
echo "安装回收站脚本..."
for script in trash trash-list trash-restore trash-empty; do
    if [[ -f "$SCRIPT_DIR/$script" ]]; then
        cp "$SCRIPT_DIR/$script" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/$script"
        echo "  已安装: $script"
    else
        echo "  错误: 找不到脚本 $script"
        exit 1
    fi
done

# 检查是否存在真正的rm命令
REAL_RM=$(which rm)
if [[ -z "$REAL_RM" ]]; then
    echo "错误: 找不到系统的rm命令"
    exit 1
fi

# 创建rm替代脚本
echo "创建rm替代脚本..."
cat > "$INSTALL_DIR/rm" << 'EOF'
#!/bin/bash

# rm命令的安全替代脚本
# 使用回收站系统替代直接删除

# 获取真正的rm命令路径
REAL_RM="/bin/rm"

# 特殊情况：如果检测到是系统或脚本调用，使用真正的rm
if [[ "$1" == "--force-real-rm" ]]; then
    shift
    exec "$REAL_RM" "$@"
fi

# 检查是否需要使用真正的rm
use_real_rm=false

# 解析参数，查看是否有特殊情况
for arg in "$@"; do
    case "$arg" in
        --real-rm)
            use_real_rm=true
            ;;
        /tmp/*|/var/tmp/*|/proc/*|/sys/*|/dev/*)
            # 系统临时目录或特殊目录，使用真正的rm
            use_real_rm=true
            ;;
    esac
done

# 如果需要使用真正的rm
if [[ "$use_real_rm" == "true" ]]; then
    # 过滤掉--real-rm参数
    filtered_args=()
    for arg in "$@"; do
        if [[ "$arg" != "--real-rm" ]]; then
            filtered_args+=("$arg")
        fi
    done
    exec "$REAL_RM" "${filtered_args[@]}"
fi

# 转换rm参数为trash参数
trash_args=()
files=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            trash_args+=("--force")
            shift
            ;;
        -r|-R|--recursive)
            trash_args+=("--recursive")
            shift
            ;;
        -v|--verbose)
            trash_args+=("--verbose")
            shift
            ;;
        -i|--interactive)
            # trash默认就是交互式的，忽略此选项
            shift
            ;;
        --)
            shift
            files+=("$@")
            break
            ;;
        -*)
            echo "警告: 选项 '$1' 将被忽略，使用回收站模式" >&2
            shift
            ;;
        *)
            files+=("$1")
            shift
            ;;
    esac
done

# 如果没有文件参数，显示错误
if [[ ${#files[@]} -eq 0 ]]; then
    echo "rm: 缺少操作数" >&2
    echo "尝试执行 'rm --help' 来获取更多信息。" >&2
    echo "" >&2
    echo "提示: 现在rm使用回收站系统" >&2
    echo "  查看回收站: trash-list" >&2
    echo "  恢复文件: trash-restore" >&2
    echo "  清空回收站: trash-empty" >&2
    echo "  使用真正的rm: rm --real-rm <文件>" >&2
    exit 1
fi

# 调用trash命令
exec trash "${trash_args[@]}" "${files[@]}"
EOF

chmod +x "$INSTALL_DIR/rm"
echo "  已创建: rm (回收站版本)"

# 更新shell配置
update_shell_config() {
    local config_file="$1"
    local shell_name="$2"
    
    if [[ -f "$config_file" ]]; then
        # 备份原配置文件
        cp "$config_file" "$BACKUP_DIR/$(basename "$config_file").backup"
        
        # 检查是否已经有相关配置
        if grep -q "# 回收站系统配置" "$config_file"; then
            echo "  $shell_name: 配置已存在，跳过"
            return
        fi
        
        # 添加配置
        cat >> "$config_file" << EOF

# 回收站系统配置 - 由install-trash-system.sh添加
if [[ -d "$INSTALL_DIR" ]]; then
    export PATH="$INSTALL_DIR:\$PATH"
fi

# 回收站系统别名
alias trash-help='echo "回收站系统命令:"; echo "  trash <文件>     - 移动文件到回收站"; echo "  trash-list       - 查看回收站内容"; echo "  trash-restore    - 恢复文件"; echo "  trash-empty      - 清空回收站"; echo "  rm --real-rm     - 使用真正的rm命令"'
alias ll-trash='trash-list -l -s'
alias real-rm='command rm'

EOF
        echo "  $shell_name: 已更新配置"
    fi
}

echo "更新shell配置..."
update_shell_config "$HOME/.bashrc" "Bash"
update_shell_config "$HOME/.zshrc" "Zsh"

# 创建说明文件
cat > "$HOME/.trash-system-info.txt" << EOF
回收站系统安装完成！

安装位置: $INSTALL_DIR

主要命令:
  rm <文件>           - 安全删除（移到回收站）
  trash-list          - 查看回收站内容
  trash-restore       - 恢复文件
  trash-empty         - 清空回收站

特殊用法:
  rm --real-rm <文件> - 使用真正的rm命令永久删除
  trash-help          - 显示帮助信息

回收站位置: $HOME/.trash

配置文件备份: $BACKUP_DIR

要使新配置生效，请重新打开终端或执行：
  source ~/.bashrc   # 对于bash用户
  source ~/.zshrc    # 对于zsh用户

卸载说明:
要卸载回收站系统，请运行：
  rm -rf $INSTALL_DIR/{trash,trash-list,trash-restore,trash-empty,rm}
然后从 ~/.bashrc 或 ~/.zshrc 中删除相关配置
EOF

echo ""
echo "=== 安装完成! ==="
echo ""
echo "安装详情:"
echo "  脚本位置: $INSTALL_DIR"
echo "  配置文件: ~/.bashrc 和 ~/.zshrc (如果存在)"
echo "  备份位置: $BACKUP_DIR"
echo ""
echo "主要功能:"
echo "  🗑️  rm命令现在会将文件移到回收站"
echo "  📋  trash-list 查看回收站内容"
echo "  ↩️  trash-restore 恢复删除的文件"
echo "  🧹  trash-empty 清空回收站"
echo ""
echo "要使配置生效，请运行以下命令之一："
echo "  source ~/.bashrc"
echo "  source ~/.zshrc"
echo "  或重新打开终端"
echo ""
echo "测试建议:"
echo "  1. 创建测试文件: touch test.txt"
echo "  2. 删除测试文件: rm test.txt"
echo "  3. 查看回收站: trash-list"
echo "  4. 恢复测试文件: trash-restore test.txt"
echo ""
echo "如需使用真正的rm命令，请使用: rm --real-rm <文件>"
echo ""
echo "详细信息保存在: ~/.trash-system-info.txt" 