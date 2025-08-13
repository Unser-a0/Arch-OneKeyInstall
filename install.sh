#!/bin/bash
# Arch Linux 一键安装脚本 (多语言支持版)
# 支持：中文、日语、英语、韩语

# 检查 root 权限
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root" >&2
    exit 1
fi

# 禁用 Ctrl+C 中断
trap '' SIGINT

# 配置变量
TARGET_DISK=""
EFI_PART=""
ROOT_PART=""
USER_NAME=""
USER_PASSWORD=""
ROOT_PASSWORD=""
HOST_NAME="arch-desktop"
TIMEZONE="Asia/Shanghai"
LOCALE="en_US.UTF-8"
KEYMAP="us"
DESKTOP_ENV=1
LANG_SELECTED="en"

# 字体颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 语言包声明
declare -A LANG_PACKAGES
LANG_PACKAGES=(
    ["zh"]="中文"
    ["ja"]="日本語"
    ["en"]="English"
    ["ko"]="한국어"
)

# 显示标题
show_header() {
    clear
    echo -e "${GREEN}"
    echo "================================================="
    echo "           Arch Linux 一键安装脚本"
    echo "              多语言支持版本"
    echo "================================================="
    echo -e "${NC}"
}

# 语言选择菜单
select_language() {
    show_header
    echo -e "${YELLOW}[*] 请选择安装语言 / Please select language:${NC}"
    
    options=()
    for code in "${!LANG_PACKAGES[@]}"; do
        options+=("$code" "${LANG_PACKAGES[$code]}")
    done
    
    PS3="请选择语言编号 / Select language number: "
    select lang in "${options[@]}"; do
        for code in "${!LANG_PACKAGES[@]}"; do
            if [ "${LANG_PACKAGES[$code]}" = "$lang" ]; then
                LANG_SELECTED=$code
                return
            fi
        done
        echo -e "${RED}无效选择，请重新输入 / Invalid selection, try again${NC}"
    done
}

# 本地化提示信息
localized_msg() {
    case $LANG_SELECTED in
        "zh")
            case $1 in
                "check_network") echo "[*] 检查网络连接...";;
                "network_failed") echo "错误：无法连接到互联网，请检查网络";;
                "select_disk") echo "[*] 检测到以下可用磁盘：";;
                "select_disk_prompt") echo "请选择安装磁盘 (输入编号): ";;
                "disk_selected") echo "[*] 已选择磁盘: ";;
                "partition_tui") echo "[*] 磁盘分区工具";;
                "partition_mode") echo "检测到启动模式: ";;
                "auto_partition") echo "1. 自动分区 (推荐)";;
                "manual_partition") echo "2. 手动分区 (cfdisk)";;
                "partition_prompt") echo "请选择分区方式 [1/2]: ";;
                "auto_partition_msg") echo "[*] 使用自动分区方案";;
                "formatting_msg") echo "[*] 格式化分区...";;
                "user_management") echo "[*] 用户账户设置";;
                "root_pwd") echo "设置 root 密码: ";;
                "root_pwd_confirm") echo "确认 root 密码: ";;
                "user_pwd") echo "设置用户 %s 的密码: ";;
                "user_pwd_confirm") echo "确认密码: ";;
                "hostname_prompt") echo "设置主机名 [默认: %s]: ";;
                "timezone_prompt") echo "设置时区 [默认: %s]: ";;
                "desktop_env_prompt") echo "选择桌面环境:";;
                "optimize_mirrors") echo "[*] 优化镜像源...";;
                "mount_partitions") echo "[*] 挂载分区...";;
                "install_base") echo "[*] 安装基本系统...";;
                "configure_system") echo "[*] 配置基本系统...";;
                "install_desktop") echo "[*] 安装桌面环境...";;
                "install_fonts") echo "[*] 安装语言字体...";;
                "install_locale") echo "[*] 配置本地化设置...";;
                "complete_base") echo "[*] 基础系统安装完成！";;
                "reboot_instructions") echo "您可以重启系统：";;
                "desktop_auto_install") echo "登录后桌面环境将自动安装";;
                "setup_locale") echo "[*] 配置本地化环境...";;
                "lang_font_install") echo "[*] 安装语言字体...";;
                "pwd_mismatch") echo "密码不匹配，请重新输入";;
                "desktop_env_options") echo "1. i3 (X11)\n2. Sway (Wayland)";;
                "desktop_env_select") echo "请输入选择 [1/2, 默认:1]: ";;
                "desktop_complete") echo "[*] 桌面环境安装完成！";;
                "login_instructions") echo "重启后使用以下命令登录：";;
                "desktop_auto_start") echo "启动桌面环境: 登录后自动启动";;
                *) echo "$1";;
            esac
            ;;
        "ja")
            case $1 in
                "check_network") echo "[*] ネットワーク接続を確認しています...";;
                "network_failed") echo "エラー：インターーネットに接続できません。ネットワークを確認してください";;
                "select_disk") echo "[*] 利用可能なディスク：";;
                "select_disk_prompt") echo "インストール先ディスクを選択 (番号入力): ";;
                "disk_selected") echo "[*] 選択されたディスク: ";;
                "partition_tui") echo "[*] ディスクパーーティションツール";;
                "partition_mode") echo "検出された起動モード: ";;
                "auto_partition") echo "1. 自動パーーティション (推奨)";;
                "manual_partition") echo "2. 手動パーーティション (cfdisk)";;
                "partition_prompt") echo "パーーティション方法を選択 [1/2]: ";;
                "auto_partition_msg") echo "[*] 自動パーティションを使用";;
                "formatting_msg") echo "[*] パーーティションをフォーマットしています...";;
                "user_management") echo "[*] ユーザーアカウント設定";;
                "root_pwd") echo "rootパスワードを設定: ";;
                "root_pwd_confirm") echo "rootパスワードを確認: ";;
                "user_pwd") echo "ユーザー %s のパスワードを設定: ";;
                "user_pwd_confirm") echo "パスワードを確認: ";;
                "hostname_prompt") echo "ホスト名を設定 [デフォルト: %s]: ";;
                "timezone_prompt") echo "タイムゾーンを設定 [デフォルト: %s]: ";;
                "desktop_env_prompt") echo "デスクトップ環境を選択:";;
                "optimize_mirrors") echo "[*] ミラーを最適化しています...";;
                "mount_partitions") echo "[*] パーティションをマウントしています...";;
                "install_base") echo "[*] 基本システムをインストールしています...";;
                "configure_system") echo "[*] システムを設定しています...";;
                "install_desktop") echo "[*] デスクトップ環境をインストールしています...";;
                "install_fonts") echo "[*] 言語フォントをインストールしています...";;
                "install_locale") echo "[*] ロケールを設定しています...";;
                "complete_base") echo "[*] 基本システムのインストールが完了しました！";;
                "reboot_instructions") echo "再起動してください：";;
                "desktop_auto_install") echo "ログイン後、デスクトップ環境が自動的にインストールされます";;
                "setup_locale") echo "[*] ロケールを設定しています...";;
                "lang_font_install") echo "[*] 言語フォントをインストールしています...";;
                "pwd_mismatch") echo "パスワードが一致しません。再入力してください";;
                "desktop_env_options") echo "1. i3 (X11)\n2. Sway (Wayland)";;
                "desktop_env_select") echo "選択を入力 [1/2, デフォルト:1]: ";;
                "desktop_complete") echo "[*] デスクトップ環境のインストールが完了しました！";;
                "login_instructions") echo "再起動後、以下でログイン：";;
                "desktop_auto_start") echo "デスクトップ環境: ログイン後自動起動";;
                *) echo "$1";;
            esac
            ;;
        "ko")
            case $1 in
                "check_network") echo "[*] 네트워크 연결 확인 중...";;
                "network_failed") echo "오류: 인터넷에 연결할 수 없습니다. 네트워크를 확인하세요";;
                "select_disk") echo "[*] 사용 가능한 디스크:";;
                "select_disk_prompt") echo "설치할 디스크 선택 (번호 입력): ";;
                "disk_selected") echo "[*] 선택한 디스크: ";;
                "partition_tui") echo "[*] 디스크 파티션 도구";;
                "partition_mode") echo "감지된 부팅 모드: ";;
                "auto_partition") echo "1. 자동 파티션 (권장)";;
                "manual_partition") echo "2. 수동 파티션 (cfdisk)";;
                "partition_prompt") echo "파티션 방법 선택 [1/2]: ";;
                "auto_partition_msg") echo "[*] 자동 파티션 사용";;
                "formatting_msg") echo "[*] 파티션 포맷 중...";;
                "user_management") echo "[*] 사용자 계정 설정";;
                "root_pwd") echo "루트 비밀번호 설정: ";;
                "root_pwd_confirm") echo "루트 비밀번호 확인: ";;
                "user_pwd") echo "사용자 %s 의 비밀번호 설정: ";;
                "user_pwd_confirm") echo "비밀번호 확인: ";;
                "hostname_prompt") echo "호스트명 설정 [기본값: %s]: ";;
                "timezone_prompt") echo "시간대 설정 [기본값: %s]: ";;
                "desktop_env_prompt") echo "데스크탑 환경 선택:";;
                "optimize_mirrors") echo "[*] 미러 최적화 중...";;
                "mount_partitions") echo "[*] 파티션 마운트 중...";;
                "install_base") echo "[*] 기본 시스템 설치 중...";;
                "configure_system") echo "[*] 시스템 구성 중...";;
                "install_desktop") echo "[*] 데스크탑 환경 설치 중...";;
                "install_fonts") echo "[*] 언어 글꼴 설치 중...";;
                "install_locale") echo "[*] 로케일 설정 중...";;
                "complete_base") echo "[*] 기본 시스템 설치 완료!";;
                "reboot_instructions") echo "재부팅하세요:";;
                "desktop_auto_install") echo "로그인 후 데스크탑 환경이 자동으로 설치됩니다";;
                "setup_locale") echo "[*] 로케일 설정 중...";;
                "lang_font_install") echo "[*] 언어 글꼴 설치 중...";;
                "pwd_mismatch") echo "비밀번호가 일치하지 않습니다. 다시 입력하세요";;
                "desktop_env_options") echo "1. i3 (X11)\n2. Sway (Wayland)";;
                "desktop_env_select") echo "선택 입력 [1/2, 기본값:1]: ";;
                "desktop_complete") echo "[*] 데스크탑 환경 설치 완료!";;
                "login_instructions") echo "재부팅 후 로그인:";;
                "desktop_auto_start") echo "데스크탑 환경: 로그인 후 자동 시작";;
                *) echo "$1";;
            esac
            ;;
        *)
            # English (default)
            case $1 in
                "check_network") echo "[*] Checking network connection...";;
                "network_failed") echo "Error: Unable to connect to internet. Please check network";;
                "select_disk") echo "[*] Available disks:";;
                "select_disk_prompt") echo "Select installation disk (enter number): ";;
                "disk_selected") echo "[*] Selected disk: ";;
                "partition_tui") echo "[*] Disk Partition Tool";;
                "partition_mode") echo "Detected boot mode: ";;
                "auto_partition") echo "1. Auto Partition (Recommended)";;
                "manual_partition") echo "2. Manual Partition (cfdisk)";;
                "partition_prompt") echo "Select partitioning method [1/2]: ";;
                "auto_partition_msg") echo "[*] Using auto partitioning";;
                "formatting_msg") echo "[*] Formatting partitions...";;
                "user_management") echo "[*] User Account Setup";;
                "root_pwd") echo "Set root password: ";;
                "root_pwd_confirm") echo "Confirm root password: ";;
                "user_pwd") echo "Set password for user %s: ";;
                "user_pwd_confirm") echo "Confirm password: ";;
                "hostname_prompt") echo "Set hostname [default: %s]: ";;
                "timezone_prompt") echo "Set timezone [default: %s]: ";;
                "desktop_env_prompt") echo "Select desktop environment:";;
                "optimize_mirrors") echo "[*] Optimizing mirrors...";;
                "mount_partitions") echo "[*] Mounting partitions...";;
                "install_base") echo "[*] Installing base system...";;
                "configure_system") echo "[*] Configuring system...";;
                "install_desktop") echo "[*] Installing desktop environment...";;
                "install_fonts") echo "[*] Installing language fonts...";;
                "install_locale") echo "[*] Configuring localization...";;
                "complete_base") echo "[*] Base system installation complete!";;
                "reboot_instructions") echo "You can now reboot:";;
                "desktop_auto_install") echo "Desktop environment will auto-install after login";;
                "setup_locale") echo "[*] Setting up locale...";;
                "lang_font_install") echo "[*] Installing language fonts...";;
                "pwd_mismatch") echo "Passwords do not match, please retry";;
                "desktop_env_options") echo "1. i3 (X11)\n2. Sway (Wayland)";;
                "desktop_env_select") echo "Enter choice [1/2, default:1]: ";;
                "desktop_complete") echo "[*] Desktop environment installation complete!";;
                "login_instructions") echo "After reboot, login with:";;
                "desktop_auto_start") echo "Start desktop: Auto-start after login";;
                *) echo "$1";;
            esac
            ;;
    esac
}

# 显示本地化消息
msg() {
    echo -e "$(localized_msg "$1")"
}

# 检查网络连接
check_network() {
    echo -e "${YELLOW}$(msg check_network)${NC}"
    if ! ping -c 3 archlinux.org &> /dev/null; then
        echo -e "${RED}$(msg network_failed)${NC}"
        exit 1
    fi
}

# 语言字体安装
install_lang_fonts() {
    echo -e "${YELLOW}$(msg lang_font_install)${NC}"
    
    # 安装基础控制台字体
    pacman -Sy --noconfirm console-fonts > /dev/null
    
    # 根据选择的语言安装特定字体
    case $LANG_SELECTED in
        "zh")
            pacman -Sy --noconfirm noto-fonts-cjk ttf-arphic-uming > /dev/null
            setfont ter-g24b  # 推荐中文字体
            ;;
        "ja")
            pacman -Sy --noconfirm otf-ipafont ttf-hanazono > /dev/null
            setfont ter-g24b  # 推荐日文字体
            ;;
        "ko")
            pacman -Sy --noconfirm ttf-baekmuk noto-fonts-cjk > /dev/null
            setfont ter-g24b  # 推荐韩文字体
            ;;
        *)
            setfont ter-v24b  # 通用推荐字体
            ;;
    esac
}

# 配置locale
setup_locale() {
    echo -e "${YELLOW}$(msg setup_locale)${NC}"
    
    # 根据选择的语言设置locale
    case $LANG_SELECTED in
        "zh")
            LOCALE="zh_CN.UTF-8"
            sed -i 's/^#zh_CN.UTF-8/zh_CN.UTF-8/' /etc/locale.gen
            ;;
        "ja")
            LOCALE="ja_JP.UTF-8"
            sed -i 's/^#ja_JP.UTF-8/ja_JP.UTF-8/' /etc/locale.gen
            ;;
        "ko")
            LOCALE="ko_KR.UTF-8"
            sed -i 's/^#ko_KR.UTF-8/ko_KR.UTF-8/' /etc/locale.gen
            ;;
        *)
            sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
            ;;
    esac
    
    # 生成locale
    locale-gen
    echo "LANG=$LOCALE" > /etc/locale.conf
    
    # 设置控制台字体
    echo "FONT=ter-v24b" > /etc/vconsole.conf
    setfont ter-v24b
    
    # 设置键盘布局
    if [ "$LANG_SELECTED" = "ja" ]; then
        KEYMAP="jp106"
        echo "KEYMAP=$KEYMAP" >> /etc/vconsole.conf
        loadkeys jp106
    fi
}

# 选择安装磁盘
select_disk() {
    show_header
    echo -e "${YELLOW}$(msg select_disk)${NC}"
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    echo ""
    
    local disks=($(lsblk -d -n -o NAME))
    
    PS3="$(msg select_disk_prompt) "
    select disk in "${disks[@]}"; do
        if [[ -n "$disk" ]]; then
            TARGET_DISK="/dev/$disk"
            echo -e "${GREEN}$(msg disk_selected)${TARGET_DISK}${NC}"
            sleep 1
            return
        else
            echo -e "${RED}$(msg invalid_selection)${NC}"
        fi
    done
}

# 分区工具
partition_tui() {
    show_header
    echo -e "${YELLOW}$(msg partition_tui)${NC}"
    echo "$(msg partition_mode) $([ -d /sys/firmware/efi ] && echo "UEFI" || echo "BIOS")"
    echo ""
    
    echo "1. $(msg auto_partition)"
    echo "   - UEFI: 512M EFI + Remainder root"
    echo "   - BIOS: 100% root"
    echo "2. $(msg manual_partition)"
    echo ""
    
    read -p "$(msg partition_prompt) " choice
    case $choice in
        2)
            echo -e "${YELLOW}$(msg cfdisk_start)${NC}"
            cfdisk $TARGET_DISK
            ;;
        *)
            echo -e "${GREEN}$(msg auto_partition_msg)${NC}"
            auto_partition
            ;;
    esac
    
    # 获取分区结果
    get_partitions
}

# 自动分区
auto_partition() {
    # 清除分区表
    sgdisk -Z $TARGET_DISK
    partprobe $TARGET_DISK
    
    if [ -d /sys/firmware/efi ]; then # UEFI
        parted -s $TARGET_DISK mklabel gpt
        parted -s $TARGET_DISK mkpart primary fat32 1MiB 513MiB
        parted -s $TARGET_DISK set 1 esp on
        parted -s $TARGET_DISK mkpart primary ext4 513MiB 100%
    else # BIOS
        parted -s $TARGET_DISK mklabel msdos
        parted -s $TARGET_DISK mkpart primary ext4 1MiB 100%
        parted -s $TARGET_DISK set 1 boot on
    fi
    
    partprobe $TARGET_DISK
}

# 获取分区信息
get_partitions() {
    if [ -d /sys/firmware/efi ]; then # UEFI
        EFI_PART="${TARGET_DISK}1"
        ROOT_PART="${TARGET_DISK}2"
    else # BIOS
        ROOT_PART="${TARGET_DISK}1"
    fi
    
    echo -e "${YELLOW}$(msg formatting_msg)${NC}"
    if [ -n "$EFI_PART" ]; then
        mkfs.fat -F32 $EFI_PART
    fi
    mkfs.ext4 -F $ROOT_PART
}

# 用户管理 TUI
user_management() {
    show_header
    echo -e "${YELLOW}$(msg user_management)${NC}"
    
    # Root 密码
    while true; do
        read -sp "$(msg root_pwd)" ROOT_PASSWORD
        echo
        read -sp "$(msg root_pwd_confirm)" password_confirm
        echo
        if [ "$ROOT_PASSWORD" == "$password_confirm" ]; then
            break
        else
            echo -e "${RED}$(msg pwd_mismatch)${NC}"
        fi
    done
    
    # 普通用户
    read -p "$(msg create_user)" USER_NAME
    
    if [ -n "$USER_NAME" ]; then
        while true; do
            read -sp "$(printf "$(msg user_pwd)" "$USER_NAME")" USER_PASSWORD
            echo
            read -sp "$(msg user_pwd_confirm)" password_confirm
            echo
            if [ "$USER_PASSWORD" == "$password_confirm" ]; then
                break
            else
                echo -e "${RED}$(msg pwd_mismatch)${NC}"
            fi
        done
    fi
    
    # 主机名
    read -p "$(printf "$(msg hostname_prompt)" "$HOST_NAME")" input
    HOST_NAME=${input:-$HOST_NAME}
    
    # 时区
    read -p "$(printf "$(msg timezone_prompt)" "$TIMEZONE")" input
    TIMEZONE=${input:-$TIMEZONE}
    
    # 桌面环境
    echo -e "\n$(msg desktop_env_prompt)"
    echo "$(msg desktop_env_options)"
    read -p "$(msg desktop_env_select)" input
    DESKTOP_ENV=${input:-1}
}

# 优化镜像源
optimize_mirrors() {
    echo -e "${YELLOW}$(msg optimize_mirrors)${NC}"
    
    # 根据语言选择合适的镜像区域
    case $LANG_SELECTED in
        "zh") country="China";;
        "ja") country="Japan";;
        "ko") country="Korea";;
        *) country="United_States";;
    esac
    
    reflector --country "$country" --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
    echo "[archlinuxcn]" >> /etc/pacman.conf
    echo "Server = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch" >> /etc/pacman.conf
    pacman -Sy --noconfirm archlinuxcn-keyring > /dev/null
}

# 安装基本系统
install_base() {
    echo -e "${YELLOW}$(msg mount_partitions)${NC}"
    mount $ROOT_PART /mnt
    if [ -n "$EFI_PART" ]; then
        mkdir -p /mnt/boot/efi
        mount $EFI_PART /mnt/boot/efi
    fi
    
    echo -e "${YELLOW}$(msg install_base)${NC}"
    pacstrap /mnt base base-devel linux linux-firmware \
                vim nano git reflector \
                networkmanager grub efibootmgr \
                sudo > /dev/null
    
    genfstab -U /mnt >> /mnt/fstab
    
    # 复制脚本到新系统
    cp "$0" /mnt/arch_install.sh
    chmod +x /mnt/arch_install.sh
}

# 配置基本系统
configure_system() {
    echo -e "${YELLOW}$(msg configure_system)${NC}"
    
    arch-chroot /mnt /bin/bash << EOF
        # 设置时区
        ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
        hwclock --systohc
        
        # 本地化设置
        sed -i "s/^#$LOCALE/$LOCALE/" /etc/locale.gen
        locale-gen
        echo "LANG=$LOCALE" > /etc/locale.conf
        echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
        
        # 主机名
        echo "$HOST_NAME" > /etc/hostname
        echo -e "127.0.0.1 localhost\n::1 localhost\n127.0.1.1 $HOST_NAME.localdomain $HOST_NAME" >> /etc/hosts
        
        # 设置 root 密码
        echo "root:$ROOT_PASSWORD" | chpasswd
        
        # 创建普通用户
        if [ -n "$USER_NAME" ]; then
            useradd -m -G wheel -s /bin/bash $USER_NAME
            echo "$USER_NAME:$USER_PASSWORD" | chpasswd
            sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
        fi
        
        # 安装引导程序
        if [ -d /sys/firmware/efi ]; then
            grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch
        else
            grub-install --target=i386-pc $TARGET_DISK
        fi
        grub-mkconfig -o /boot/grub/grub.cfg
        
        # 启用网络服务
        systemctl enable NetworkManager
        
        # 启动桌面安装
        echo "/arch_install.sh --stage2 $DESKTOP_ENV $LANG_SELECTED" >> /root/.bash_profile
EOF
}

# 安装桌面环境
install_desktop() {
    local env=$1
    local lang=$2
    
    echo -e "${YELLOW}$(msg install_desktop)${NC}"
    
    # 安装语言字体
    echo -e "${YELLOW}$(msg install_fonts)${NC}"
    case $lang in
        "zh")
            pacman -S --noconfirm noto-fonts-cjk adobe-source-han-sans-cn-fonts \
                       ttf-arphic-uming adobe-source-han-serif-cn-fonts > /dev/null
            ;;
        "ja")
            pacman -S --noconfirm otf-ipafont ttf-hanazono \
                       adobe-source-han-sans-jp-fonts adobe-source-han-serif-jp-fonts > /dev/null
            ;;
        "ko")
            pacman -S --noconfirm adobe-source-han-sans-kr-fonts \
                       noto-fonts-cjk ttf-baekmuk > /dev/null
            ;;
        *)
            pacman -S --noconfirm noto-fonts > /dev/null
            ;;
    esac
    
    # 通用字体
    pacman -S --noconfirm ttf-jetbrains-mono-nerd noto-fonts-emoji > /dev/null
    
    # 基础组件
    pacman -S --noconfirm alacritty btop fastfetch eww \
               feh swaybg xorg-server xorg-xinit > /dev/null
    
    # 窗口管理器
    if [ $env -eq 1 ]; then
        pacman -S --noconfirm i3-wm i3status i3lock > /dev/null
    else
        pacman -S --noconfirm sway swaybg swaylock > /dev/null
    fi
    
    # 配置 Alacritty
    mkdir -p /home/$USER_NAME/.config/alacritty
    cat > /home/$USER_NAME/.config/alacritty/alacritty.toml << EOF
[colors]
primary = { foreground = "#cdd6f4", background = "#1e1e2e" }
cursor = { text = "#1e1e2e", cursor = "#cdd6f4" }
selection = { text = "#1e1e2e", background = "#cdd6f4" }

[font]
size = 12.0
family = "JetBrains Mono Nerd Font"
style = "Regular"

[window]
opacity = 0.95
EOF
    
    # 配置桌面启动脚本
    if [ $env -eq 1 ]; then
        mkdir -p /home/$USER_NAME/.config/i3
        cat > /home/$USER_NAME/.config/i3/config << EOF
set \$mod Mod4
bindsym \$mod+Return exec alacritty
exec --no-startup-id feh --bg-fill /usr/share/backgrounds/archlinux/arch-wallpaper.jpg
exec --no-startup-id eww open sidebar
exec --no-startup-id alacritty -e btop
exec --no-startup-id alacritty -e fastfetch
EOF
    else
        mkdir -p /home/$USER_NAME/.config/sway
        cat > /home/$USER_NAME/.config/sway/config << EOF
set \$mod Mod4
bindsym \$mod+Return exec alacritty
exec swaybg -i /usr/share/backgrounds/archlinux/arch-wallpaper.jpg
exec eww open sidebar
exec alacritty -e btop
exec alacritty -e fastfetch
EOF
    fi
    
    # 配置 eww
    mkdir -p /home/$USER_NAME/.config/eww
    cat > /home/$USER_NAME/.config/eww/eww.yaml << EOF
windows:
  - name: sidebar
    anchor: left
    width: 60
    height: 100%
    x: 0
    y: 0
    exclusivity: exclusive
    background: rgba(30,30,46,0.8)
    widgets:
      - layout: vbox
        spacing: 20
        padding: 10
        children:
          - widget: button
            label: " btop"
            on_click: "alacritty -e btop"
            style: |
              font-size: 14px;
              color: #cdd6f4;
              background: #1e1e2e;
              padding: 5px;
              border-radius: 4px;
          - widget: label
            text: "{time}"
            update_interval: 1
            style: |
              font-size: 12px;
              color: #a6adc8;
          - widget: label
            text: " {volume}%"
            update_interval: 1
            style: |
              font-size: 12px;
              color: #a6adc8;
          - widget: label
            text: " {network}"
            update_interval: 1
            style: |
              font-size: 12px;
              color: #a6adc8;
EOF
    
    # 设置壁纸
    mkdir -p /usr/share/backgrounds/archlinux
    wget -q -O /usr/share/backgrounds/archlinux/arch-wallpaper.jpg \
        https://raw.githubusercontent.com/archlinux/artwork/master/wallpapers/arch-wallpaper.jpg
    
    # 设置权限
    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME
    
    # 清理安装脚本
    rm /arch_install.sh
    sed -i '/\/arch_install.sh/d' /root/.bash_profile
    
    # 完成消息
    echo -e "${GREEN}$(msg desktop_complete)${NC}"
    echo "$(msg login_instructions)"
    echo "Username: $USER_NAME"
    echo "Password: $(msg your_password)"
    echo "$(msg desktop_auto_start)"
    echo -e "${NC}"
}

# 主安装流程
main() {
    case $1 in
        --stage2)
            install_desktop $2 $3
            exit
            ;;
        *)
            show_header
            select_language
            install_lang_fonts
            setup_locale
            check_network
            select_disk
            partition_tui
            user_management
            optimize_mirrors
            install_base
            configure_system
            
            echo -e "${GREEN}$(msg complete_base)${NC}"
            echo "$(msg reboot_instructions)"
            echo "  umount -R /mnt"
            echo "  reboot"
            echo "$(msg desktop_auto_install)${NC}"
            ;;
    esac
}

main "$@"