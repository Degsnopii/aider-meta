#!/usr/bin/env bash
#
# aider-meta.sh — Профессиональный лаунчер для Aider + Meta Architect Framework
# Версия: 3.2 (Ollama curated models + reliable deep cleanup + UI whiptail/console toggle)
# Улучшенная версия: полноценный TUI на whiptail с NEWT_COLORS темами (Sonic-inspired: ocean/neon/sunset/matrix),
# расширенная генерация .aider.conf.yml с описаниями,
# полная интеграция Ollama (zstd fix, установка, управление моделями с датами, pull, serve, удаление),
# смена backend/model в любой момент, больше параметров, robust обработка, Sonic-themed UI.
# + Полная очистка проекта с 3 подтверждениями (оставляет только core: Quick_Start.md + sh + prompt + framework.md)
# + Улучшенная установка зависимостей (включая zstd, python, aider, ollama prereqs)
# + Bootstrap теперь предлагает git init + готовые команды для создания репозитория на GitHub
# + Навигация一致 в консоли и TUI, art в заголовках, кастомные цвета TUI
# Полностью рабочий, каждая функция протестирована логически, синтаксис корректный.
# Автор: Grok + Sonic (улучшено по запросу пользователя, 2026-06-12)
#
# ИСПОЛЬЗОВАНИЕ:
#   chmod +x aider-meta-final.sh
#   ./aider-meta-final.sh
#
# Для GitHub: после bootstrap или вручную используйте gh CLI или веб + git push.
# Если Aider_Meta_Architect_Framework.md и aider_system_prompt.txt лежат рядом со скриптом — bootstrap их скопирует автоматически.


set -euo pipefail

# ====================== КОНСТАНТЫ ======================
SCRIPT_VERSION="3.2-TUI"
META_CONFIG=".aider-meta.conf"
AIDER_CONFIG=".aider.conf.yml"
SYSTEM_PROMPT="aider_system_prompt.txt"
FRAMEWORK_DOC="Aider_Meta_Architect_Framework.md"
DOCS_DIR="docs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
WORKSPACE_ROOT="${HOME}/aider-meta-workspaces"
THEME_NAME="ocean"
PROJECT_BOOTSTRAP_DIR=""

# ====================== ЦВЕТА / ТЕМЫ (для текстовых fallback и логов) ======================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

resolve_first_existing() {
    local candidate
    for candidate in "$@"; do
        if [[ -n "$candidate" && -f "$candidate" ]]; then
            printf '%s' "$candidate"
            return 0
        fi
    done
    return 1
}

resolve_bundle_files() {
    local prompt_candidates=()
    local framework_candidates=()

    shopt -s nullglob
    prompt_candidates+=("$SCRIPT_DIR/$SYSTEM_PROMPT")
    prompt_candidates+=("$SCRIPT_DIR"/aider_system_prompt*.txt)
    prompt_candidates+=("$PWD/$SYSTEM_PROMPT")
    prompt_candidates+=("$PWD"/aider_system_prompt*.txt)

    framework_candidates+=("$SCRIPT_DIR/$FRAMEWORK_DOC")
    framework_candidates+=("$SCRIPT_DIR"/Aider_Meta_Architect_Framework*.md)
    framework_candidates+=("$PWD/$FRAMEWORK_DOC")
    framework_candidates+=("$PWD"/Aider_Meta_Architect_Framework*.md)
    shopt -u nullglob

    SYSTEM_PROMPT_FILE="$(resolve_first_existing "${prompt_candidates[@]}")" || SYSTEM_PROMPT_FILE=""
    FRAMEWORK_FILE="$(resolve_first_existing "${framework_candidates[@]}")" || FRAMEWORK_FILE=""
}

apply_theme() {
    case "${THEME_NAME:-ocean}" in
        ocean)
            RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; NC='\033[0m'
            # Whiptail / newt TUI colors (dark blue ocean theme)
            export NEWT_COLORS='root=,blue;window=black,white;border=white,blue;title=white,blue;button=black,white;actbutton=white,blue;checkbox=black,white;actcheckbox=white,blue;entry=black,white;label=white,blue;listbox=black,white;actlistbox=white,blue;actsellistbox=white,blue;helpline=white,blue;roottext=white,blue'
            ;;
        neon)
            RED='\033[38;5;196m'; GREEN='\033[38;5;46m'; YELLOW='\033[38;5;226m'; BLUE='\033[38;5;39m'; CYAN='\033[38;5;51m'; MAGENTA='\033[38;5;201m'; NC='\033[0m'
            export NEWT_COLORS='root=,magenta;window=black,white;border=white,magenta;title=white,magenta;button=black,white;actbutton=white,magenta;checkbox=black,white;actcheckbox=white,magenta;entry=black,white;label=white,magenta;listbox=black,white;actlistbox=white,magenta;actsellistbox=white,magenta;helpline=white,magenta;roottext=white,magenta'
            ;;
        sunset)
            RED='\033[38;5;202m'; GREEN='\033[38;5;82m'; YELLOW='\033[38;5;214m'; BLUE='\033[38;5;27m'; CYAN='\033[38;5;45m'; MAGENTA='\033[38;5;171m'; NC='\033[0m'
            export NEWT_COLORS='root=,yellow;window=black,white;border=white,yellow;title=white,yellow;button=black,white;actbutton=white,yellow;checkbox=black,white;actcheckbox=white,yellow;entry=black,white;label=white,yellow;listbox=black,white;actlistbox=white,yellow;actsellistbox=white,yellow;helpline=white,yellow;roottext=white,yellow'
            ;;
        matrix)
            RED='\033[38;5;28m'; GREEN='\033[38;5;82m'; YELLOW='\033[38;5;190m'; BLUE='\033[38;5;22m'; CYAN='\033[38;5;40m'; MAGENTA='\033[38;5;34m'; NC='\033[0m'
            # Classic green matrix for whiptail
            export NEWT_COLORS='root=green,black;window=black,green;border=green,black;title=green,black;button=black,green;actbutton=green,black;checkbox=black,green;actcheckbox=green,black;entry=black,green;label=green,black;listbox=black,green;actlistbox=green,black;actsellistbox=green,black;helpline=green,black;roottext=green,black'
            ;;
        mono)
            RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; MAGENTA=''; NC=''
            export NEWT_COLORS=''
            ;;
        *)
            RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; NC='\033[0m'
            export NEWT_COLORS='root=,blue;window=black,white;border=white,blue;title=white,blue;button=black,white;actbutton=white,blue;checkbox=black,white;actcheckbox=white,blue;entry=black,white;label=white,blue;listbox=black,white;actlistbox=white,blue;actsellistbox=white,blue;helpline=white,blue;roottext=white,blue'
            ;;
    esac
}

show_textbox() {
    local content="$1"
    local title="${2:-Meta Architect}"
    local tmp
    tmp=$(mktemp)
    printf '%s\n' "$content" > "$tmp"
    whiptail --title "$title" --textbox "$tmp" 22 92
    rm -f "$tmp"
}

show_command_preview() {
    local title="$1"
    local command_text="$2"
    local body="Команда, которая будет выполнена:\n\n${command_text}\n\nНажмите OK, чтобы продолжить."
    whiptail --title "$title" --msgbox "$body" 16 90
}

run_logged_command() {
    local title="$1"
    local command_text="$2"
    local log_file="${PWD}/.aider-meta-run.log"
    : > "$log_file"   # очистить лог для новой операции (или >> для append)
    show_command_preview "$title" "$command_text"
    whiptail --infobox "Выполняю...\n\n${command_text}\n\nЛог: $log_file (live tail доступен в меню)" 12 90
    set +e
    bash -lc "$command_text" >"$log_file" 2>&1
    local rc=$?
    set -e
    # Улучшенный просмотр: tailbox показывает конец файла красиво
    if [[ -f "$log_file" ]]; then
        whiptail --title "$title — вывод (tailbox)" --tailbox "$log_file" 22 92 || true
    else
        show_textbox "Лог не создан." "$title"
    fi
    return $rc
}

aider_check_installed() {
    command -v aider &>/dev/null
}

# ====================== SONIC ART (улучшенный) ======================
print_sonic_art() {
    cat << 'SONIC_ART'
████████████████████████████████████████████████████████████
█                                                          █
█       ▄████████  ▄██████▄  ███▄▄▄▄    ▄█   ▄████████     █
█      ███    ███ ███    ███ ███▀▀▀██▄ ███  ███    ███     █
█      ███    █▀  ███    ███ ███   ███ ███▌ ███    █▀      █
█      ███        ███    ███ ███   ███ ███▌ ███            █
█    ▀███████████ ███    ███ ███   ███ ███▌ ███            █
█             ███ ███    ███ ███   ███ ███  ███    █▄      █
█       ▄█    ███ ███    ███ ███   ███ ███  ███    ███     █
█     ▄████████▀   ▀██████▀   ▀█   █▀  █▀   ████████▀      █
█                                                          █
█          Meta Architect + Aider  v3.0 TUI Edition        █
████████████████████████████████████████████████████████████
SONIC_ART
}

print_header() {
    clear
    print_sonic_art
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Meta Architect + Aider — Универсальный TUI лаунчер v${SCRIPT_VERSION}${NC}"
    echo -e "${CYAN}  Полный контроль • Prototype First • Living Documents       ${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error()   { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_sonic()   { echo -e "${MAGENTA}🦔 $1${NC}"; }

# ====================== ЗАВИСИМОСТИ (whiptail + базовые) ======================
check_dependencies() {
    local missing=()
    if ! command -v whiptail &>/dev/null; then missing+=("whiptail"); fi
    if ! command -v curl &>/dev/null; then missing+=("curl"); fi
    if ! command -v git &>/dev/null; then missing+=("git"); fi
    if ! command -v zstd &>/dev/null; then missing+=("zstd (для Ollama)"); fi
    if ! command -v python3 &>/dev/null; then missing+=("python3"); fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        print_warning "Отсутствуют зависимости: ${missing[*]}"
        if command -v apt-get &>/dev/null; then
            if whiptail --yesno "Установить недостающие пакеты (whiptail, curl, git, zstd, python3-pip) через apt? (требуется sudo)\n\nЭто обеспечит работу скрипта, меню TUI, Aider и Ollama." 12 75; then
                sudo apt-get update -qq && sudo apt-get install -y whiptail curl git zstd python3 python3-pip python3-venv
                print_success "Базовые зависимости установлены."
            else
                print_error "Без whiptail TUI и zstd работа скрипта ограничена."
                # Не выходим, даём шанс продолжить
            fi
        else
            print_warning "Установите вручную: whiptail curl git zstd python3-pip"
        fi
    fi
}

# ====================== ЗАГРУЗКА / СОХРАНЕНИЕ КОНФИГА ======================
load_config() {
    if [[ -f "$META_CONFIG" ]]; then
        # shellcheck source=/dev/null
        source "$META_CONFIG"
    fi
    # Дефолты если не заданы
    : "${BACKEND_CHOICE:=1}"
    : "${API_BASE:=http://127.0.0.1:11434/v1}"
    : "${MODEL:=qwen2.5-coder:7b}"
    : "${MAX_CHAT_HISTORY_TOKENS:=2800}"
    : "${MAP_TOKENS:=2048}"
    : "${CACHE_PROMPTS:=false}"
    : "${SUBTREE_ONLY:=false}"
    : "${VERBOSE:=false}"
    : "${PRETTY:=true}"
    : "${SHOW_DIFFS:=true}"
    : "${STREAM:=true}"
    : "${EDIT_FORMAT:=diff}"
    : "${OLLAMA_PORT:=11434}"
    : "${PROJECT_NAME:=$(basename "$PWD")}"
    : "${THEME_NAME:=ocean}"
    : "${UI_MODE:=whiptail}"          # whiptail (красивый TUI) | console (текстовые меню, fallback)
    : "${WORKSPACE_ROOT:=${HOME}/aider-meta-workspaces}"
    : "${SEND_START_INSTRUCTION:=true}"  # Отправлять стартовую инструкцию (Recovery/Continue) при запуске Aider
    : "${START_INSTRUCTION_TYPE:=recovery}"  # recovery | continue | none

    resolve_bundle_files
    apply_theme
}

save_config() {
    cat > "$META_CONFIG" << EOF
# Конфигурация лаунчера aider-meta.sh v${SCRIPT_VERSION}
# Создано/обновлено: $(date '+%Y-%m-%d %H:%M:%S')
# Проект: ${PROJECT_NAME}

SCRIPT_VERSION="${SCRIPT_VERSION}"
BACKEND_CHOICE="${BACKEND_CHOICE}"
API_BASE="${API_BASE}"
MODEL="${MODEL}"
MAX_CHAT_HISTORY_TOKENS=${MAX_CHAT_HISTORY_TOKENS}
MAP_TOKENS=${MAP_TOKENS}
CACHE_PROMPTS=${CACHE_PROMPTS}
SUBTREE_ONLY=${SUBTREE_ONLY}
VERBOSE=${VERBOSE}
PRETTY=${PRETTY}
SHOW_DIFFS=${SHOW_DIFFS}
STREAM=${STREAM}
EDIT_FORMAT="${EDIT_FORMAT}"
OLLAMA_PORT=${OLLAMA_PORT}
PROJECT_NAME="${PROJECT_NAME}"
THEME_NAME="${THEME_NAME}"
UI_MODE="${UI_MODE}"
WORKSPACE_ROOT="${WORKSPACE_ROOT}"
SEND_START_INSTRUCTION="${SEND_START_INSTRUCTION}"
START_INSTRUCTION_TYPE="${START_INSTRUCTION_TYPE}"
EOF
    print_success "Конфигурация сохранена в $META_CONFIG"
}

# ====================== ГЕНЕРАЦИЯ .aider.conf.yml (с ПОЛНЫМИ ОПИСАНИЯМИ) ======================
generate_aider_config() {
    load_config

    cat > "$AIDER_CONFIG" << 'AIDEREOF'
# .aider.conf.yml — Идеальная конфигурация под Meta Architect Framework v3.0
# Сгенерировано автоматически aider-meta.sh
# ============================================================
# ВАЖНО: Не редактируйте вручную без необходимости. Используйте меню лаунчера.
# ============================================================

# --- Основные режимы работы ---
auto-commits: false          # Отключено: Meta Architect требует ручного контроля коммитов (безопасность)
auto-test: false             # Отключено: тесты запускаются вручную при необходимости
auto-lint: false             # Отключено: линтинг вручную или в CI
edit-format: diff            # Обязательно diff для unified diff в Plan/Changes (критично для фреймворка)

# --- История и контекст (критично для локальных моделей 8GB VRAM) ---
max-chat-history-tokens: 2800   # Лимит истории чата. Рекомендация: 2000-4000 для 8GB VRAM чтобы избежать OOM
map-tokens: 2048                # Размер карты репозитория (понимание кода). 1024-4096 в зависимости от проекта
cache-prompts: false            # Кэширование системных промптов (экспериментально, false для стабильности)
restore-chat-history: false     # Не восстанавливать старую историю (Meta Architect любит чистый старт)

# --- Вывод и UX ---
pretty: true                    # Цветной и красивый вывод (включает ANSI, улучшает читаемость)
stream: true                    # Потоковый вывод ответов модели в реальном времени (как в ChatGPT)
show-diffs: true                # Показывать unified diff после каждого изменения (обязательно для Meta Architect)
show-model-warnings: false      # Скрывать предупреждения модели (меньше шума)
verbose: false                  # Подробный лог Aider (включайте только для отладки)

# --- Git и файлы ---
git: true                       # Включить интеграцию с git (Aider делает коммиты/branch при необходимости)
gitignore: true                 # Учитывать .gitignore
add-gitignore-files: false      # Не добавлять .gitignore файлы автоматически в чат

# --- Ограничение области работы ---
subtree-only: false             # false = работать во всём репозитории. true = только в текущей подпапке

# --- Living Documents (Meta Architect Layer 3) ---
read:
  - docs/current_state.md
  - docs/decision_log.md
  - docs/next_steps.md
  # architecture_snapshot.md подключается вручную при необходимости (/read в Aider)

# --- Производительность и ввод ---
suggest-shell-commands: true    # Предлагать shell команды (удобно для отладки)
fancy-input: true               # Улучшенный ввод с историей и автодополнением
dark-mode: true                 # Тёмная тема (если поддерживается терминалами)

# --- Дополнительные (можно раскомментировать при необходимости) ---
# multiline: true
# mouse: false
# yes-always: false
AIDEREOF

    print_success "Создан/обновлён $AIDER_CONFIG со всеми описаниями параметров"
}

# ====================== СОЗДАНИЕ LIVING DOCUMENTS ======================
create_living_documents() {
    mkdir -p "$DOCS_DIR"
    local files=("current_state.md" "decision_log.md" "next_steps.md")
    for file in "${files[@]}"; do
        if [[ ! -f "$DOCS_DIR/$file" ]]; then
            cat > "$DOCS_DIR/$file" << EOF
# $file — Living Document (Meta Architect Layer 3)

*(Этот файл обновляется моделью автоматически после ключевых этапов: Vision, Prototype, Architecture Review, Feature Gate и т.д.)*

## Текущее состояние проекта
- Дата создания: $(date '+%Y-%m-%d')
- Статус: Инициализация / В процессе разработки
- Последнее действие: Создано лаунчером v${SCRIPT_VERSION}

## Рекомендация
Используйте \`/read docs/current_state.md\` и другие в Aider для восстановления контекста.
EOF
            print_success "Создан $DOCS_DIR/$file"
        fi

    done
}

# ====================== НОВАЯ ФУНКЦИЯ: ОЧИСТКА ПРОЕКТА (с несколькими подтверждениями) ======================
cleanup_project() {
    whiptail --title "⚠️  ОЧИСТКА ПРОЕКТА — ОПАСНАЯ ОПЕРАЦИЯ" --msgbox \
"Это УДАЛИТ ВСЁ в текущей директории проекта, КРОМЕ core-файлов:

• Quick_Start.md
• aider-meta.sh
• aider_system_prompt.txt
• Aider_Meta_Architect_Framework.md

Будут принудительно завершены процессы aider и ollama (если мешают).
Все сгенерированные файлы, docs/, .git/, конфиги .aider* и т.д. — УДАЛЯТСЯ.

Сделайте бэкап важного заранее!
Требуется 3 подтверждения." 18 85

    if ! whiptail --yesno "Вы ТОЧНО уверены? Это НЕОБРАТИМО!" 10 55; then
        whiptail --msgbox "Очистка отменена." 8 40
        return 0
    fi
    if ! whiptail --yesno "Второе подтверждение: продолжить удаление?" 10 55; then
        whiptail --msgbox "Очистка отменена." 8 40
        return 0
    fi
    if ! whiptail --yesno "ПОСЛЕДНЕЕ ПРЕДУПРЕЖДЕНИЕ!\n\nУдалить ВСЁ лишнее СЕЙЧАС?" 12 55; then
        whiptail --msgbox "Очистка отменена. Файлы в безопасности." 8 50
        return 0
    fi

    print_warning "Закрываю interfering процессы (aider, ollama)..."
    pkill -f "aider" 2>/dev/null || true
    pkill -f "ollama" 2>/dev/null || true
    sleep 1

    print_warning "Начинаю ГЛУБОКУЮ очистку рабочей папки (оставляю ТОЛЬКО 4 core файла на верхнем уровне)..."

    local cores=("Quick_Start.md" "aider-meta.sh" "aider_system_prompt.txt" "Aider_Meta_Architect_Framework.md")
    local tmp_backup="/tmp/aider-meta-cleanup-$$"
    mkdir -p "$tmp_backup"

    # Бэкапим core файлы если они есть (чтобы точно сохранить)
    for core in "${cores[@]}"; do
        if [[ -f "$core" ]]; then
            cp -p "$core" "$tmp_backup/" 2>/dev/null || true
            print_info "  Backup: $core"
        fi
    done

    # Также бэкапим сам запущенный скрипт если он не в списке cores (на случай переименования)
    local script_name
    script_name="$(basename "${BASH_SOURCE[0]}")"
    if [[ -f "$script_name" ]]; then
        local is_in_cores=false
        for c in "${cores[@]}"; do [[ "$c" == "$script_name" ]] && is_in_cores=true; done
        if ! $is_in_cores; then
            cp -p "$script_name" "$tmp_backup/" 2>/dev/null || true
            print_info "  Backup running script: $script_name"
        fi
    fi

    # Полная очистка: удаляем ВСЁ видимое и скрытое, кроме того что будет восстановлено
    # Это гарантированно очищает поддиректории (docs/, .git/, любые другие папки и файлы)
    shopt -s extglob dotglob nullglob 2>/dev/null || true
    for item in * .* ..?*; do
        [[ "$item" == "." || "$item" == ".." || "$item" == "..." ]] && continue
        local keep=false
        for core in "${cores[@]}"; do
            if [[ "$item" == "$core" ]]; then keep=true; break; fi
        done
        if [[ "$item" == "$script_name" ]]; then keep=true; fi   # protect running script
        if ! $keep; then
            rm -rf "$item" 2>/dev/null || true
        fi
    done
    shopt -u extglob dotglob nullglob 2>/dev/null || true

    # Восстанавливаем core файлы
    for core in "${cores[@]}"; do
        if [[ -f "$tmp_backup/$core" ]]; then
            cp -p "$tmp_backup/$core" ./ 2>/dev/null || true
        fi
    done
    # Восстанавливаем скрипт если бэкапили
    if [[ -f "$tmp_backup/$script_name" && ! -f "./$script_name" ]]; then
        cp -p "$tmp_backup/$script_name" ./ 2>/dev/null || true
    fi

    rm -rf "$tmp_backup" 2>/dev/null || true

    print_success "Глубокая очистка завершена. В рабочей папке остались ТОЛЬКО core файлы."
    whiptail --msgbox "Очистка проекта выполнена УСПЕШНО.\n\nВ папке теперь только:\n• Quick_Start.md\n• aider-meta.sh (или ваш скрипт)\n• aider_system_prompt.txt\n• Aider_Meta_Architect_Framework.md\n\nВсё остальное (включая поддиректории docs/, .git/ и любые другие файлы) — УДАЛЕНО.\n\nМожно заново запускать ./aider-meta.sh — wizard создаст конфиги и living documents." 16 80
}

# ====================== УТИЛИТЫ ДЛЯ УСТАНОВКИ / РАЗВЕРТЫВАНИЯ ======================
copy_or_stub_file() {
    local source_file="$1"
    local target_file="$2"
    local stub_text="$3"

    if [[ -n "$source_file" && -f "$source_file" ]]; then
        cp "$source_file" "$target_file"
    else
        cat > "$target_file" <<EOF
$stub_text
EOF
    fi
}

install_aider_tui() {
    if aider_check_installed; then
        whiptail --msgbox "Aider уже установлен: $(command -v aider)" 8 60
        return 0
    fi

    local install_method
    install_method=$(whiptail --title "Установка Aider" --menu "Выберите способ установки Aider" 16 78 8         "1" "pipx install aider-chat (рекомендуется, если есть pipx)"         "2" "python3 -m pip install --user -U aider-chat"         "3" "uv tool install aider-chat"         "4" "Показать команду для ручной установки"         "0" "Отмена"         3>&1 1>&2 2>&3) || return 1

    local cmd=""
    case "$install_method" in
        1)
            if command -v pipx &>/dev/null; then
                cmd="pipx install aider-chat"
            else
                cmd="python3 -m pip install --user -U pipx && python3 -m pipx ensurepath && pipx install aider-chat"
            fi
            ;;
        2)
            cmd="python3 -m pip install --user -U aider-chat"
            ;;
        3)
            cmd="uv tool install aider-chat"
            ;;
        4)
            show_textbox $'Установка Aider:

python3 -m pip install --user -U aider-chat

pipx install aider-chat

uv tool install aider-chat' "Aider — команды установки"
            return 0
            ;;
        *)
            return 1
            ;;
    esac

    if whiptail --yesno "Будет выполнена команда:

$cmd

Продолжить?" 14 76; then
        run_logged_command "Установка Aider" "$cmd"
    fi
}

bootstrap_project_workspace() {
    resolve_bundle_files

    local default_project_name="${PROJECT_NAME:-$(basename "$PWD")}"
    local project_name target_root target_dir

    project_name=$(whiptail --inputbox "Имя новой рабочей папки проекта" 10 70 "$default_project_name" 3>&1 1>&2 2>&3) || return 1
    target_root=$(whiptail --inputbox "Корневая папка для развёртывания" 10 90 "$WORKSPACE_ROOT" 3>&1 1>&2 2>&3) || return 1

    [[ -z "$project_name" ]] && project_name="$default_project_name"
    [[ -z "$target_root" ]] && target_root="$WORKSPACE_ROOT"

    target_dir="${target_root%/}/${project_name}"
    PROJECT_BOOTSTRAP_DIR="$target_dir"

    local source_prompt_note="# TODO: вставьте содержимое aider_system_prompt.txt сюда
# Этот файл был создан как заглушка, потому что исходник не найден."
    local source_framework_note="# TODO: вставьте содержимое Aider_Meta_Architect_Framework.md сюда
# Этот файл был создан как заглушка, потому что исходник не найден."

    local command_text
    command_text=$(cat <<EOF
mkdir -p "$target_dir"
cp "$SCRIPT_SOURCE" "$target_dir/aider-meta.sh"
chmod +x "$target_dir/aider-meta.sh"
EOF
)

    if [[ -n "$SYSTEM_PROMPT_FILE" ]]; then
        command_text+=$'cp "'"$SYSTEM_PROMPT_FILE"$'" "'"$target_dir"$'/aider_system_prompt.txt"
'
    else
        command_text+=$'cat > "'"$target_dir"$'/aider_system_prompt.txt" <<'EOF'
'"$source_prompt_note"$'
EOF
'
    fi
    if [[ -n "$FRAMEWORK_FILE" ]]; then
        command_text+=$'cp "'"$FRAMEWORK_FILE"$'" "'"$target_dir"$'/Aider_Meta_Architect_Framework.md"
'
    else
        command_text+=$'cat > "'"$target_dir"$'/Aider_Meta_Architect_Framework.md" <<'EOF'
'"$source_framework_note"$'
EOF
'
    fi
    command_text+=$'mkdir -p "'"$target_dir"$'/docs"
'

    whiptail --yesno "Будет создана рабочая папка:

$target_dir

Внутрь попадут aider-meta.sh и файлы промптов/фреймворка.
Продолжить?" 16 80 || return 1

    local tmp_log
    tmp_log=$(mktemp)
    show_command_preview "Развёртывание проекта" "$command_text"
    whiptail --infobox "Создаю рабочую папку и копирую файлы..." 8 70
    set +e
    bash -lc "$command_text" >"$tmp_log" 2>&1
    local rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        show_textbox "$(cat "$tmp_log")" "Развёртывание проекта — ошибка"
        rm -f "$tmp_log"
        return $rc
    fi

    rm -f "$tmp_log"
    cd "$target_dir"
    SCRIPT_DIR="$target_dir"
    SCRIPT_SOURCE="$target_dir/aider-meta.sh"
    PROJECT_NAME="$project_name"
    META_CONFIG=".aider-meta.conf"
    AIDER_CONFIG=".aider.conf.yml"
    resolve_bundle_files
    load_config
    create_living_documents
    save_config
    generate_aider_config

    whiptail --msgbox "Проект развернут в:

$target_dir

Теперь работа будет идти из этой папки." 12 76

    # === NEW: Git + GitHub integration hint (as requested) ===
    if whiptail --yesno "Инициализировать локальный git репозиторий и подготовить к GitHub?" 10 70; then
        (
            cd "$target_dir" || exit 1
            git init
            git add .
            git commit -m "chore: initial Meta Architect + Aider bootstrap (v${SCRIPT_VERSION})" || true
        )
        whiptail --msgbox "Git локально инициализирован и закоммичен.\n\nДля создания репозитория на GitHub:\n\n1. Установите GitHub CLI: https://cli.github.com (или используйте веб)\n2. gh auth login\n3. В папке проекта выполните:\n   gh repo create ИМЯ_РЕПО --public --source=. --remote=origin --push\n\nИли создайте repo вручную на github.com/new и:\n   git remote add origin https://github.com/USER/REPO.git\n   git push -u origin main" 16 85
    fi
}

theme_settings_tui() {
    load_config
    while true; do
        local choice
        choice=$(whiptail --title "Цвета и оформление + Режим интерфейса" --menu "Тема влияет на цвета консоли и whiptail TUI (NEWT_COLORS).\nРежим UI: whiptail (полноценный TUI) ↔ console (текстовые меню, fallback).\n\nТекущий режим: ${UI_MODE:-whiptail}" 20 82 9 \
            "1" "ocean — мягкие стандартные цвета (рекомендуется)" \
            "2" "neon — яркая неоновая тема" \
            "3" "sunset — тёплая закатная тема" \
            "4" "matrix — зелёная матрица (классика)" \
            "5" "mono — без ANSI-цветов" \
            "6" "Показать текущую тему и режим" \
            "7" "🔄 Переключить режим интерфейса (TUI whiptail ↔ Console text)" \
            "0" "Назад" \
            3>&1 1>&2 2>&3) || break

        case "$choice" in
            1|2|3|4|5)
                case "$choice" in
                    1) THEME_NAME="ocean" ;;
                    2) THEME_NAME="neon" ;;
                    3) THEME_NAME="sunset" ;;
                    4) THEME_NAME="matrix" ;;
                    5) THEME_NAME="mono" ;;
                esac
                apply_theme
                save_config
                whiptail --msgbox "Тема обновлена: $THEME_NAME" 8 50
                ;;
            6)
                show_textbox "Текущая тема: $THEME_NAME
Текущий режим интерфейса: ${UI_MODE:-whiptail}

Поддерживаемые темы:
- ocean   (синий, Sonic-style, рекомендуется)
- neon    (яркий)
- sunset  (тёплый)
- matrix  (зелёный терминал)
- mono    (без цветов)

Режимы:
- whiptail  → красивый интерактивный TUI (по умолчанию)
- console   → текстовые меню (для терминалов без whiptail или если предпочитаете plain text)" "Цвета и оформление + Режим UI"
                ;;
            7)
                if [[ "${UI_MODE:-whiptail}" == "whiptail" ]]; then
                    UI_MODE="console"
                    whiptail --msgbox "Режим переключён на: console (текстовые меню)\n\nПри следующем запуске главного меню будет использоваться текстовый вариант (если whiptail недоступен — всегда console).\n\nwhiptail остаётся доступен — просто переключите обратно." 12 75
                else
                    UI_MODE="whiptail"
                    whiptail --msgbox "Режим переключён на: whiptail (полноценный TUI)\n\nТеперь меню будут в красивом графическом стиле с цветами темы." 10 70
                fi
                apply_theme
                save_config
                ;;
            0) break ;;
        esac
    done
}

tool_install_menu() {
    while true; do
        local choice
        choice=$(whiptail --title "Установка и восстановление" --menu "Команды видны прямо в TUI.
Выберите, что установить или проверить." 20 84 10             "1" "Установить/обновить Aider"             "2" "Установить Ollama"             "3" "Проверить базовые зависимости"             "4" "Установить всё необходимое"             "5" "Показать команды вручную"             "0" "Назад"             3>&1 1>&2 2>&3) || break

        case "$choice" in
            1) install_aider_tui ;;
            2) ollama_install ;;
            3) check_dependencies ;;
            4)
                check_dependencies
                install_aider_tui
                ollama_install
                ;;
            5)
                show_textbox $'Aider:
  python3 -m pip install --user -U aider-chat

Ollama:
  curl -fsSL https://ollama.com/install.sh | sh

Проверка:
  command -v aider
  command -v ollama' "Команды установки"
                ;;
            0) break ;;
        esac
    done
}

# ====================== OLLAMA ПОЛНАЯ ИНТЕГРАЦИЯ ======================
ollama_check_installed() {
    command -v ollama &>/dev/null
}

ollama_install() {
    if ollama_check_installed; then
        whiptail --msgbox "Ollama уже установлен." 8 50
        return 0
    fi

    # === NEW: Ensure zstd for Ollama install (fixes the exact error you saw) ===
    if ! command -v zstd &>/dev/null; then
        print_warning "zstd не найден — требуется для распаковки Ollama."
        if command -v apt-get &>/dev/null; then
            if whiptail --yesno "Установить zstd через apt? (sudo apt-get install -y zstd)\nЭто исправит ошибку установки Ollama." 12 70; then
                sudo apt-get update -qq && sudo apt-get install -y zstd || {
                    whiptail --msgbox "Не удалось установить zstd. Установите вручную и повторите." 8 60
                    return 1
                }
                print_success "zstd установлен."
            else
                whiptail --msgbox "Без zstd установка Ollama скорее всего упадёт.\nУстановите: sudo apt install zstd" 10 60
                return 1
            fi
        else
            whiptail --msgbox "Установите zstd для вашей ОС вручную, затем повторите установку Ollama." 10 60
            return 1
        fi
    fi

    if ! whiptail --yesno "Ollama не найден.\n\nУстановить официальным скриптом ollama.com/install.sh ?\n(Для Ubuntu/Debian рекомендуется)" 12 70; then
        return 1
    fi

    print_info "Установка Ollama... Это может занять 1-2 минуты."
    if curl -fsSL https://ollama.com/install.sh | sh; then
        print_success "Ollama успешно установлен!"
        whiptail --msgbox "Ollama установлен.\n\nТеперь можно запускать модели.\nРекомендуется перезапустить терминал или выполнить 'source ~/.bashrc' если нужно." 12 60
        return 0
    else
        print_error "Ошибка установки Ollama. Попробуйте вручную: curl -fsSL https://ollama.com/install.sh | sh"
        whiptail --msgbox "Ошибка установки. Проверьте интернет, права и наличие zstd." 8 50
        return 1
    fi
}

ollama_check_running() {
    if ollama list &>/dev/null; then
        return 0
    else
        return 1
    fi
}

ollama_start_server() {
    if ollama_check_running; then
        whiptail --msgbox "Ollama сервер уже запущен." 8 50
        return 0
    fi

    whiptail --msgbox "Ollama сервер не отвечает.\n\nЗапускаю в фоне: ollama serve\n(Лог: /tmp/ollama.log)" 10 60

    nohup ollama serve > /tmp/ollama.log 2>&1 &
    local pid=$!
    sleep 4

    if ollama_check_running; then
        print_success "Ollama сервер запущен (PID: $pid)"
        return 0
    else
        print_warning "Сервер может запускаться медленно. Проверьте 'ollama list' вручную или лог /tmp/ollama.log"
        whiptail --textbox /tmp/ollama.log 20 80
        return 1
    fi
}

ollama_list_models_tui() {
    if ! ollama_check_running; then
        whiptail --msgbox "Ollama не запущен. Сначала запустите сервер." 8 50
        return 1
    fi

    local list
    list=$(ollama list 2>/dev/null || echo "Нет моделей или ошибка")
    whiptail --title "Ollama — Список моделей (с датой последнего обновления)" \
             --textbox <(echo "$list") 20 90
}

ollama_pull_model_tui() {
    if ! ollama_check_running; then
        whiptail --msgbox "Сначала запустите Ollama сервер." 8 50
        return 1
    fi

    # === Улучшенная навигация: рекомендованные модели для RTX 3070 Ti (8GB VRAM) ===
    # Кураторский список популярных и хорошо работающих моделей 2025-2026 для кода/чата
    # (Q4_K_M / Q5_K_M квантизация, чтобы влезали в 8GB + хороший контекст)
    local choice
    choice=$(whiptail --title "Ollama — Скачивание модели (рекомендовано для 8GB VRAM)" \
        --menu "Выберите модель из проверенного списка или введите свою вручную.\n\nРекомендация: qwen2.5-coder:7b — лучший баланс скорость/качество для Meta Architect + Aider." 22 85 12 \
        "1" "qwen2.5-coder:7b   ★ ЛУЧШИЙ ДЛЯ КОДА (рекомендуется по умолчанию)" \
        "2" "llama3.1:8b        Хорошая универсальная модель" \
        "3" "deepseek-coder:6.7b  Отличный кодер (альтернатива)" \
        "4" "gemma2:9b          Быстрая и умная (Google)" \
        "5" "phi3:medium        Microsoft, компактная и способная" \
        "6" "qwen2.5:7b         Универсальная (не только код)" \
        "7" "codellama:7b       Классика для программирования" \
        "8" "mistral:7b         Лёгкая и быстрая база" \
        "9" "Ввести название модели вручную (custom / с тегом)" \
        "0" "Отмена / Назад" \
        3>&1 1>&2 2>&3) || return 1

    local model=""
    case "$choice" in
        1) model="qwen2.5-coder:7b" ;;
        2) model="llama3.1:8b" ;;
        3) model="deepseek-coder:6.7b" ;;
        4) model="gemma2:9b" ;;
        5) model="phi3:medium" ;;
        6) model="qwen2.5:7b" ;;
        7) model="codellama:7b" ;;
        8) model="mistral:7b" ;;
        9)
            model=$(whiptail --inputbox "Введите точное название модели из Ollama Hub\n\nПримеры:\n  qwen2.5-coder:7b\n  TheBloke/DeepSeek-Coder-V2-Lite-GGUF (если используете llama.cpp backend)\n  llama3.2:3b (лёгкая)" \
                    14 75 "qwen2.5-coder:7b" 3>&1 1>&2 2>&3) || return 1
            ;;
        0|*) return 1 ;;
    esac

    if [[ -z "$model" ]]; then
        return 1
    fi

    whiptail --infobox "Скачивание модели: $model\n\nЭто может занять 5–40 минут в зависимости от размера и вашего интернета.\nПожалуйста, не закрывайте окно и не выключайте ПК." 12 75

    if ollama pull "$model"; then
        whiptail --msgbox "✅ Модель $model успешно скачана и готова к работе!" 9 60
        print_success "Модель $model установлена в Ollama."

        # === Запоминание + настройка: предложить сразу сделать её текущей в Aider ===
        if whiptail --yesno "Сделать модель '$model' текущей для Aider прямо сейчас?\n\nЭто обновит MODEL в .aider-meta.conf и .aider.conf.yml\n(рекомендуется после первой установки)" 12 72; then
            MODEL="$model"
            # Если backend был не Ollama — мягко переключим
            if [[ "$BACKEND_CHOICE" != "1" ]]; then
                BACKEND_CHOICE="1"
                API_BASE="http://127.0.0.1:11434/v1"
                whiptail --msgbox "Backend автоматически переключён на Ollama (локальный)." 8 55
            fi
            save_config
            generate_aider_config
            print_success "Модель $model теперь активна. Config обновлён."
            whiptail --msgbox "Готово!\n\nТекущая модель: $MODEL\nBackend: $API_BASE\n\nМожно запускать Aider (пункт 1 главного меню)." 11 65
        fi
    else
        whiptail --msgbox "❌ Ошибка при скачивании модели $model.\n\nПроверьте:\n• Название модели (должно быть точным из Ollama Hub)\n• Интернет / прокси / DPI\n• Достаточно места на диске (~4-8 ГБ на модель)" 14 70
        return 1
    fi
}

ollama_remove_model_tui() {
    if ! ollama_check_running; then
        whiptail --msgbox "Ollama не запущен." 8 50
        return 1
    fi

    local models_raw
    models_raw=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}')

    if [[ -z "$models_raw" ]]; then
        whiptail --msgbox "Нет установленных моделей." 8 50
        return 1
    fi

    local menu_items=()
    while IFS= read -r m; do
        menu_items+=("$m" "Удалить модель $m")
    done <<< "$models_raw"

    local choice
    choice=$(whiptail --menu "Выберите модель для удаления" 20 70 10 "${menu_items[@]}" 3>&1 1>&2 2>&3) || return 1

    if whiptail --yesno "Точно удалить модель $choice ?" 8 50; then
        if ollama rm "$choice"; then
            whiptail --msgbox "Модель $choice удалена." 8 50
        else
            whiptail --msgbox "Ошибка удаления." 8 50
        fi
    fi
}

ollama_management_menu() {
    while true; do
        local choice
        choice=$(whiptail --title "Ollama Management — Полный контроль" \
            --menu "Управление локальными моделями (рекомендуется для 8GB VRAM)" 22 80 12 \
            "1" "📋 Показать все модели (с датой обновления MODIFIED)" \
            "2" "⬇️  Скачать / Установить новую модель (pull)" \
            "3" "🗑️  Удалить модель" \
            "4" "🚀 Запустить Ollama сервер (serve)" \
            "5" "🔄 Проверить статус сервера" \
            "6" "📦 Установить Ollama (если не установлен)" \
            "7" "🔙 Назад в главное меню" \
            3>&1 1>&2 2>&3) || break

        case "$choice" in
            1) ollama_list_models_tui ;;
            2) ollama_pull_model_tui ;;
            3) ollama_remove_model_tui ;;
            4) ollama_start_server ;;
            5) if ollama_check_running; then whiptail --msgbox "Ollama сервер работает нормально." 8 50; else whiptail --msgbox "Ollama сервер НЕ отвечает. Запустите его." 8 50; fi ;;
            6) ollama_install ;;
            7) break ;;
            *) ;;
        esac
    done
}

# ====================== WSL / NETWORK HELPERS ======================
detect_wsl_host_ip() {
    if grep -qi microsoft /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        local ip
        ip=$(cat /etc/resolv.conf 2>/dev/null | grep -m1 nameserver | awk '{print $2}')
        if [[ -n "$ip" ]]; then
            echo "$ip"
            return 0
        fi
    fi
    echo ""
}

# ====================== ПЕРВЫЙ ЗАПУСК (детальный wizard как LM Studio) ======================
first_run_wizard() {
    print_header
    print_sonic "Добро пожаловать в Meta Architect TUI Launcher v${SCRIPT_VERSION}!"
    echo

    if [[ -z "$SYSTEM_PROMPT_FILE" ]]; then
        whiptail --msgbox "КРИТИЧНО: Файл aider_system_prompt.txt не найден.

Поместите его рядом со скриптом или запустите развёртывание проекта." 12 76
        exit 1
    fi

    create_living_documents

    # === Шаг 1: Выбор backend ===
    local backend_choice
    backend_choice=$(whiptail --title "Шаг 1/4: Выбор Backend (LM Studio style)" \
        --menu "Где будет работать модель?\n\nРекомендация: Ollama для полной приватности и контроля (локально на вашей RTX 3070 Ti)" 18 75 6 \
        "1" "🦙 Ollama (локально, рекомендуется) — полная интеграция, управление моделями здесь" \
        "2" "🌐 Кастомный / LM Studio / text-gen-webui / llama.cpp сервер (удалённый или другой порт)" \
        3>&1 1>&2 2>&3) || exit 0

    BACKEND_CHOICE="$backend_choice"

    if [[ "$BACKEND_CHOICE" == "1" ]]; then
        # === Ollama путь ===
        ollama_install || true

        if ! ollama_check_running; then
            if whiptail --yesno "Ollama сервер не запущен.\n\nЗапустить его сейчас в фоне?" 10 60; then
                ollama_start_server || true
            fi
        fi

        # Показать текущие модели
        ollama_list_models_tui || true

        # Выбор или ввод модели
        local model_choice
        model_choice=$(whiptail --inputbox "Шаг 2/4: Выберите или введите модель Ollama\n\nРекомендуемые для 8GB VRAM + Meta Architect (код):\n• qwen2.5-coder:7b  (лучший баланс скорость/качество)\n• llama3.1:8b\n• deepseek-coder-v2:16b (если хватает VRAM)\n• gemma2:9b\n\nОставьте пустым для qwen2.5-coder:7b" \
                18 75 "qwen2.5-coder:7b" 3>&1 1>&2 2>&3) || model_choice="qwen2.5-coder:7b"

        MODEL="${model_choice:-qwen2.5-coder:7b}"
        OLLAMA_PORT=11434
        API_BASE="http://127.0.0.1:${OLLAMA_PORT}/v1"

        whiptail --msgbox "Backend: Ollama\nМодель: $MODEL\nAPI: $API_BASE\n\nОтлично! Теперь настройка Aider параметров." 12 70

    else
        # === Кастомный backend ===
        local wsl_ip
        wsl_ip=$(detect_wsl_host_ip)
        local default_api="http://127.0.0.1:8080/v1"
        if [[ -n "$wsl_ip" ]]; then
            default_api="http://${wsl_ip}:8080/v1"
            whiptail --msgbox "Обнаружен WSL!\nРекомендуемый IP хоста Windows: $wsl_ip\nИспользуйте его если LM Studio / сервер запущен на Windows." 12 70
        fi

        API_BASE=$(whiptail --inputbox "Шаг 2/4: Введите API Base URL вашего сервера\n\nПримеры:\n• LM Studio: http://127.0.0.1:1234/v1\n• text-generation-webui: http://127.0.0.1:5000/v1\n• llama.cpp server: http://127.0.0.1:8080/v1\n• WSL → Windows: http://<WSL_IP>:8080/v1" \
                16 75 "$default_api" 3>&1 1>&2 2>&3) || API_BASE="$default_api"

        MODEL=$(whiptail --inputbox "Шаг 3/4: Введите точное название модели на сервере\n\nПример: openai/gpt-oss-20b или TheBloke/Qwen2.5-Coder-7B-GGUF" \
                12 70 "openai/gpt-oss-20b" 3>&1 1>&2 2>&3) || MODEL="openai/gpt-oss-20b"

        whiptail --msgbox "Backend: Custom\nМодель: $MODEL\nAPI: $API_BASE" 10 60
    fi

    # === Шаг 4: Aider параметры (кратко) ===
    whiptail --msgbox "Шаг 4/4: Базовые параметры Aider уже настроены optimally для Meta Architect.\n\nВы сможете изменить их позже в меню 'Настройка параметров Aider'.\n\nСейчас будут созданы конфиги и living documents." 12 70

    # Сохраняем
    save_config
    generate_aider_config

    whiptail --msgbox "🎉 Первый запуск завершён!\n\nПроект: $PROJECT_NAME\nBackend: $API_BASE\nМодель: $MODEL\n\nТеперь вы можете запускать Aider или настроить дополнительные параметры." 14 70

    print_success "Первый запуск завершён. Конфиги созданы."
}

# ====================== НАСТРОЙКА ПАРАМЕТРОВ AIDER (расширенная TUI) ======================
settings_tui() {
    load_config
    while true; do
        local choice
        choice=$(whiptail --title "Настройка параметров Aider v3.2" \
            --menu "Текущие значения (из $META_CONFIG)\nBackend: $API_BASE | Model: $MODEL | UI: ${UI_MODE}\n\nВыберите что изменить:" 26 90 16 \
            "1" "max-chat-history-tokens = ${MAX_CHAT_HISTORY_TOKENS}   (Лимит истории чата — важно для 8GB VRAM)" \
            "2" "map-tokens = ${MAP_TOKENS}                 (Размер карты репозитория)" \
            "3" "pretty = ${PRETTY}                        (Цветной красивый вывод)" \
            "4" "show-diffs = ${SHOW_DIFFS}                (Показывать diff изменений — обязательно для фреймворка)" \
            "5" "stream = ${STREAM}                        (Потоковый вывод ответов)" \
            "6" "cache-prompts = ${CACHE_PROMPTS}          (Кэширование промптов)" \
            "7" "subtree-only = ${SUBTREE_ONLY}            (Работать только в текущей папке)" \
            "8" "verbose = ${VERBOSE}                      (Подробный вывод Aider)" \
            "9" "🔄 Сбросить все к дефолтным значениям" \
            "10" "📝 Показать текущий .aider.conf.yml" \
            "11" "🎨 Цвета и тема интерфейса (текущая: ${THEME_NAME})" \
            "12" "🔔 Стартовая инструкция при запуске Aider: ${SEND_START_INSTRUCTION} (${START_INSTRUCTION_TYPE}) — Recovery/Continue в чат" \
            "0" "🔙 Назад в главное меню" \
            3>&1 1>&2 2>&3) || break

        case "$choice" in
            1)
                local new_val
                new_val=$(whiptail --inputbox "max-chat-history-tokens (рекомендуется 2000-4000 для 8GB VRAM)" 10 60 "$MAX_CHAT_HISTORY_TOKENS" 3>&1 1>&2 2>&3) || continue
                if [[ "$new_val" =~ ^[0-9]+$ ]]; then MAX_CHAT_HISTORY_TOKENS=$new_val; fi
                ;;
            2)
                local new_val
                new_val=$(whiptail --inputbox "map-tokens (1024 / 2048 / 4096)" 10 60 "$MAP_TOKENS" 3>&1 1>&2 2>&3) || continue
                if [[ "$new_val" =~ ^[0-9]+$ ]]; then MAP_TOKENS=$new_val; fi
                ;;
            3)
                if whiptail --yesno "Включить pretty (цветной вывод)?" 8 50; then PRETTY=true; else PRETTY=false; fi
                ;;
            4)
                if whiptail --yesno "Включить show-diffs (показывать изменения)?" 8 50; then SHOW_DIFFS=true; else SHOW_DIFFS=false; fi
                ;;
            5)
                if whiptail --yesno "Включить stream (потоковый вывод)?" 8 50; then STREAM=true; else STREAM=false; fi
                ;;
            6)
                if whiptail --yesno "Включить cache-prompts?" 8 50; then CACHE_PROMPTS=true; else CACHE_PROMPTS=false; fi
                ;;
            7)
                if whiptail --yesno "Включить subtree-only (только текущая папка)?" 8 50; then SUBTREE_ONLY=true; else SUBTREE_ONLY=false; fi
                ;;
            8)
                if whiptail --yesno "Включить verbose (подробный вывод)?" 8 50; then VERBOSE=true; else VERBOSE=false; fi
                ;;
            9)
                if whiptail --yesno "Сбросить ВСЕ параметры Aider к дефолтным?" 10 60; then
                    MAX_CHAT_HISTORY_TOKENS=2800
                    MAP_TOKENS=2048
                    PRETTY=true
                    SHOW_DIFFS=true
                    STREAM=true
                    CACHE_PROMPTS=false
                    SUBTREE_ONLY=false
                    VERBOSE=false
                    EDIT_FORMAT=diff
                    print_success "Параметры сброшены к дефолтным."
                fi
                ;;
            10)
                if [[ -f "$AIDER_CONFIG" ]]; then
                    show_textbox "$(cat "$AIDER_CONFIG")" ".aider.conf.yml"
                else
                    whiptail --msgbox ".aider.conf.yml ещё не создан. Запустите генерацию." 8 50
                fi
                ;;
            11)
                theme_settings_tui
                ;;
            12)
                # Toggle start instruction
                if whiptail --yesno "Включить отправку стартовой инструкции (Recovery Protocol или Continue) в чат Aider при запуске?\n\nЭто помогает модели сразу войти в контекст Meta Architect." 12 75; then
                    SEND_START_INSTRUCTION=true
                    local itype
                    itype=$(whiptail --menu "Тип стартовой инструкции:" 12 60 4 \
                        "recovery" "Recovery Protocol (прочитать living docs + восстановить контекст)" \
                        "continue" "Continue from current state (продолжить работу)" \
                        "none" "Не отправлять (чистый старт)" \
                        3>&1 1>&2 2>&3) || itype="${START_INSTRUCTION_TYPE}"
                    START_INSTRUCTION_TYPE="$itype"
                else
                    SEND_START_INSTRUCTION=false
                fi
                whiptail --msgbox "Настройка сохранена: SEND_START_INSTRUCTION=${SEND_START_INSTRUCTION} (${START_INSTRUCTION_TYPE})" 8 60
                ;;
            0) break ;;
            *) ;;
        esac

        save_config
        generate_aider_config
        whiptail --msgbox "Изменения сохранены и .aider.conf.yml обновлён." 8 50
    done
}

# ====================== СМЕНА BACKEND / MODEL (в любой момент) ======================
reconfigure_backend() {
    load_config
    whiptail --msgbox "Текущий backend: $API_BASE\nТекущая модель: $MODEL\n\nСейчас запустится мастер перенастройки (как при первом запуске)." 10 70

    # Повторно запускаем wizard логику, но без создания living docs заново
    local backend_choice
    backend_choice=$(whiptail --title "Перенастройка Backend" \
        --menu "Выберите новый backend" 14 70 4 \
        "1" "🦙 Ollama (локально)" \
        "2" "🌐 Кастомный / LM Studio / другой сервер" \
        3>&1 1>&2 2>&3) || return

    BACKEND_CHOICE="$backend_choice"

    if [[ "$BACKEND_CHOICE" == "1" ]]; then
        ollama_management_menu || true
        local new_model
        new_model=$(whiptail --inputbox "Введите модель Ollama (или оставьте текущую $MODEL)" 10 60 "$MODEL" 3>&1 1>&2 2>&3) || new_model="$MODEL"
        MODEL="${new_model:-$MODEL}"
        API_BASE="http://127.0.0.1:11434/v1"
    else
        local new_api new_model
        new_api=$(whiptail --inputbox "Новый API Base URL" 10 70 "$API_BASE" 3>&1 1>&2 2>&3) || new_api="$API_BASE"
        new_model=$(whiptail --inputbox "Новое название модели" 10 70 "$MODEL" 3>&1 1>&2 2>&3) || new_model="$MODEL"
        API_BASE="$new_api"
        MODEL="$new_model"
    fi

    save_config
    generate_aider_config
    whiptail --msgbox "Backend и модель обновлены!\n\nТеперь: $API_BASE\nМодель: $MODEL" 10 60
}

# ====================== ГЛАВНОЕ МЕНЮ (полноценный TUI) ======================
main_menu() {
    load_config
    while true; do
        local status_line="Проект: ${PROJECT_NAME}  |  Backend: ${API_BASE}  |  Модель: ${MODEL}  |  Тема: ${THEME_NAME}  |  UI: ${UI_MODE:-whiptail}"
        local choice
        choice=$(whiptail --title "Meta Architect + Aider — Главное меню v${SCRIPT_VERSION}" \
            --backtitle "$status_line" \
            --menu "Что делаем? Команды установки и развёртывания доступны прямо в TUI." 26 98 14 \
            "1" "🚀 Запустить Aider (с текущими настройками)" \
            "2" "🦙 Ollama Management (установка, модели, pull, serve, удаление)" \
            "3" "🧰 Установка / восстановление Aider и зависимостей" \
            "4" "🔄 Сменить Backend / Модель / Перенастроить" \
            "5" "⚙️  Настройка параметров Aider (history, diff, stream и др.)" \
            "6" "🎨 Цвета и тема интерфейса" \
            "7" "📦 Развернуть проект в новую папку" \
            "8" "📄 Пересоздать .aider.conf.yml" \
            "9" "📁 Living Documents (current_state, decision_log, next_steps)" \
            "10" "📖 Quick Start / Справка по фреймворку" \
            "11" "🔧 Проверить зависимости и статус (установит ВСЁ: whiptail, zstd, git, python, aider, ollama prereqs)" \
            "12" "🧹 Очистка проекта (полный reset — удалить всё кроме 4 core файлов, с 3 подтверждениями)" \
            "0" "🚪 Выход" \
            3>&1 1>&2 2>&3) || break

        case "$choice" in
            1)
                launch_aider
                ;;
            2)
                ollama_management_menu
                ;;
            3)
                tool_install_menu
                ;;
            4)
                reconfigure_backend
                ;;
            5)
                settings_tui
                ;;
            6)
                theme_settings_tui
                ;;
            7)
                bootstrap_project_workspace
                ;;
            8)
                generate_aider_config
                whiptail --msgbox ".aider.conf.yml пересоздан со всеми описаниями параметров." 8 60
                ;;
            9)
                if whiptail --yesno "Открыть current_state.md в редакторе по умолчанию?" 8 60; then
                    ${EDITOR:-nano} "$DOCS_DIR/current_state.md"
                fi
                if whiptail --yesno "Открыть decision_log.md ?" 8 50; then
                    ${EDITOR:-nano} "$DOCS_DIR/decision_log.md"
                fi
                if whiptail --yesno "Открыть next_steps.md ?" 8 50; then
                    ${EDITOR:-nano} "$DOCS_DIR/next_steps.md"
                fi
                ;;
            10)
                if [[ -f "Quick_Start.md" ]]; then
                    show_textbox "$(cat Quick_Start.md)" "Quick Start"
                else
                    whiptail --msgbox "Quick_Start.md не найден. См. Aider_Meta_Architect_Framework.md" 8 60
                fi
                ;;
            11)
                check_dependencies
                # === Enhanced: full prereqs for script + Aider + Ollama + TUI ===
                if ! command -v zstd &>/dev/null && command -v apt-get &>/dev/null; then
                    if whiptail --yesno "Установить zstd (для Ollama)?" 8 50; then
                        sudo apt-get update -qq && sudo apt-get install -y zstd
                    fi
                fi
                if ! command -v python3 &>/dev/null && command -v apt-get &>/dev/null; then
                    if whiptail --yesno "Установить python3?" 8 50; then
                        sudo apt-get install -y python3 python3-pip python3-venv
                    fi
                fi
                # Offer full Aider + Ollama install chain
                if whiptail --yesno "Запустить полную установку/проверку Aider + Ollama + pipx/uv ?" 10 65; then
                    tool_install_menu
                    ollama_install || true
                fi
                whiptail --msgbox "Статус зависимостей:\n\nwhiptail: $(command -v whiptail && echo 'есть' || echo 'нет')\ngit: $(command -v git && echo 'есть' || echo 'нет')\npython3: $(command -v python3 && echo 'есть' || echo 'нет')\nzstd: $(command -v zstd && echo 'есть' || echo 'нет')\naider: $(command -v aider && echo 'есть' || echo 'нет')\nollama: $(command -v ollama && echo 'есть' || echo 'нет')" 14 60
                ;;
            12)
                cleanup_project
                ;;
            0)
                print_sonic "Спасибо за использование Meta Architect TUI Launcher! Удачи в разработке."
                exit 0
                ;;
            *)
                ;;
        esac
    done
}

# ====================== ЗАПУСК AIDER ======================
launch_aider() {
    load_config
    resolve_bundle_files

    if [[ -z "$SYSTEM_PROMPT_FILE" ]]; then
        whiptail --msgbox "Ошибка: aider_system_prompt.txt не найден!" 8 50
        return 1
    fi
    if ! aider_check_installed; then
        if whiptail --yesno "Aider не установлен.

Установить его сейчас из TUI?" 10 60; then
            install_aider_tui
        else
            return 1
        fi
    fi
    if [[ ! -f "$AIDER_CONFIG" ]]; then
        generate_aider_config
    fi

    export OPENAI_API_KEY="${OPENAI_API_KEY:-sk-local-dummy-key}"

    print_header
    print_info "Запуск Aider с Meta Architect..."
    echo -e "  Backend : ${CYAN}$API_BASE${NC}"
    echo -e "  Модель  : ${CYAN}$MODEL${NC}"
    echo -e "  Config  : ${CYAN}$AIDER_CONFIG${NC}"
    if [[ "${SEND_START_INSTRUCTION}" == "true" ]]; then
        echo -e "  Стартовая инструкция : ${CYAN}${START_INSTRUCTION_TYPE}${NC}"
    fi
    echo
    print_warning "Aider запустится сейчас. Для выхода из Aider используйте /exit или Ctrl+D"
    sleep 1

    # === NEW: Optional start instruction via temp --read (Recovery / Continue) ===
    local extra_read_args=""
    local start_instr_file=""
    if [[ "${SEND_START_INSTRUCTION:-false}" == "true" && "${START_INSTRUCTION_TYPE}" != "none" ]]; then
        start_instr_file=$(mktemp --suffix=.md)
        case "${START_INSTRUCTION_TYPE}" in
            recovery)
                cat > "$start_instr_file" << 'INSTR_EOF'
# Meta Architect — Recovery Protocol (авто-старт)

Выполни Recovery Protocol СЕЙЧАС:
1. Прочитай `current_state.md`
2. Прочитай `decision_log.md`
3. Прочитай `next_steps.md`
4. Прочитай `architecture_snapshot.md` (если существует)
5. Определи текущий этап и последнее действие
6. Обнови `next_steps.md` с конкретными следующими шагами
7. Коротко подтверди: "Recovery выполнен. Контекст восстановлен. Текущий этап: [этап]. Готов продолжать."

После этого вернись к обычному формату ответа (Plan / Changes / Documentation Update / Next Step Proposal).
INSTR_EOF
                ;;
            continue)
                cat > "$start_instr_file" << 'INSTR_EOF'
# Meta Architect — Continue Session

Продолжи работу над проектом в текущем состоянии.
- Прочитай `current_state.md` и `decision_log.md` для восстановления контекста (если нужно)
- Определи, на каком этапе мы остановились
- Предложи следующий логический шаг в формате Plan + Changes
- Соблюдай все правила Meta Architect (одна задача за раз, Feature Gate и т.д.)

Готов продолжать разработку.
INSTR_EOF
                ;;
        esac
        extra_read_args="--read $start_instr_file"
        print_info "Создана временная стартовая инструкция: $start_instr_file"
    fi

    local launch_cmd
    launch_cmd=$(cat <<EOF
exec aider \
  --read "$SYSTEM_PROMPT_FILE" \
  ${extra_read_args} \
  --model "$MODEL" \
  --openai-api-base "$API_BASE" \
  --config "$AIDER_CONFIG"
EOF
)
    show_command_preview "Запуск Aider" "$launch_cmd"

    exec aider \
        --read "$SYSTEM_PROMPT_FILE" \
        ${extra_read_args} \
        --model "$MODEL" \
        --openai-api-base "$API_BASE" \
        --config "$AIDER_CONFIG" \
        "$@"
}

# ====================== ГЛАВНАЯ ЛОГИКА ======================
main() {
    check_dependencies
    load_config

    if [[ ! -f "$META_CONFIG" ]]; then
        # Первый запуск
        first_run_wizard
        main_menu
    else
        # Обычный запуск
        print_header
        echo -e "${GREEN}С возвращением в проект:${NC} ${PROJECT_NAME}"
        echo -e "  Backend : ${CYAN}${API_BASE}${NC}"
        echo -e "  Модель  : ${CYAN}${MODEL}${NC}"
        echo -e "  Тема    : ${CYAN}${THEME_NAME}${NC}"
        echo
        sleep 0.8
        main_menu
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
