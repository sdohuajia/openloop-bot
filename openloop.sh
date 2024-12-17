#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/openloop.sh"

# 检查是否以 root 用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以 root 用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到 root 用户，然后再次运行此脚本。"
    exit 1
fi

# 检查依赖
function check_dependencies() {
    local deps=(git npm screen)
    for dep in "${deps[@]}"; do
        if ! command -v $dep &>/dev/null; then
            echo "未找到必要程序: $dep"
            echo "正在安装..."
            apt install -y $dep || { echo "安装 $dep 失败"; exit 1; }
        fi
    done
}

# 安装必要的软件包
function start_openloop() {
    # 检查openloop目录是否已存在
    if [ -d "openloop" ]; then
        echo "检测到已存在openloop目录,正在删除..."
        rm -rf openloop
    fi

    echo "正在更新系统包列表..."
    apt update || { echo "更新包列表失败"; exit 1; }
    
    echo "正在安装必要的 npm 包..."
    npm install -g node-fetch@2 global-agent https-proxy-agent socks-proxy-agent || { 
        echo "安装npm包失败"; 
        exit 1; 
    }
 
    echo "正在克隆 Openloop 仓库..."
    git clone https://github.com/sdohuajia/openloop.git || {
        echo "克隆仓库失败";
        exit 1;
    }
    
    echo "进入项目目录并安装依赖..."
    cd openloop || { echo "进入目录失败"; exit 1; }
    npm install || { echo "安装项目依赖失败"; exit 1; }
    
    echo "设置启动脚本执行权限..."
    chmod +x start.sh

    echo "请配置用户信息："
    read -p "请输入邮箱: " email
    read -p "请输入密码: " password
    read -p "请输入代理地址(格式如 http://127.0.0.1:7890): " proxy
    
    echo "$email,$password,$proxy" > user.txt

    echo "配置完成,正在后台启动程序..."
    tmux new-session -d -s openloop './start.sh' || {
    echo "启动程序失败";
    exit 1;
}

   echo "程序已在 tmux 会话 'openloop' 中启动"
   echo "使用 'tmux attach -t openloop' 可以查看运行状态"
 
   read -p "按任意键返回主菜单..."
}

# 查看日志
function view_logs() {
    if ! tmux ls 2>/dev/null | grep -q "openloop"; then
        echo "未找到运行中的openloop会话"
        return 1
    fi
    echo "正在连接到tmux会话查看日志..."
    echo "提示: 使用 Ctrl+B 然后按 D 组合键可以退出日志查看"
    tmux attach -t openloop
}

# 停止程序
function stop_openloop() {
    if tmux ls 2>/dev/null | grep -q "openloop"; then
        tmux kill-session -t openloop
        echo "已停止openloop程序"
    else
        echo "未发现正在运行的openloop程序"
    fi
    read -p "按任意键返回主菜单..."
}

# 主菜单函数
function main_menu() {
    # 首次运行检查依赖
    check_dependencies

    while true; do
        clear
        echo "================================================================"
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "新建了一个电报群，方便大家交流：t.me/Sdohua"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1. 启动 Openloop"
        echo "2. 查看日志"
        echo "3. 停止程序" 
        echo "4. 退出脚本"
        echo "================================================================"
        
        read -p "请输入选项 [1-4]: " choice
        
        case $choice in
            1)
                start_openloop
                ;;
            2)
                view_logs
                ;;
            3)
                stop_openloop
                ;;
            4)
                echo "退出脚本。"
                exit 0
                ;;
            *)
                echo "无效的选项，请重新选择"
                sleep 2
                ;;
        esac
    done
}

# 运行主菜单
main_menu
