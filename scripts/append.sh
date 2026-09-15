#!/bin/bash
# append.sh — 追加内容到八股文档（v2：层级编号 + macOS 兼容 + stdin 输入）
#
# 用法：
#   1) 追加内容（从 stdin 读，推荐）：
#      cat <<'EOF' | bash append.sh "LLM应用架构.md"
#      ### 8.7 新小节
#      ...markdown 内容（可含 ``` 代码围栏）...
#      EOF
#
#   2) 查询下一个可用编号：
#      bash append.sh "LLM应用架构.md" --next
#      输出：
#        next_topic=N          （下一个可用的主题编号）
#        last_topic=N          （当前最后一个主题编号）
#        next_subsection=N.M   （最后一个主题下的下一个小节编号）
#        file_lines=X
#
#   3) 列出现有主题+每个主题的小节数：
#      bash append.sh "LLM应用架构.md" --list
#
# 特性：
#   - macOS BSD 兼容（用 awk 而非 grep -oP）
#   - 路径含 `:` 自动 find 定位
#   - 修改前自动备份到 workspace/backup/
#   - 自动处理 `*持续更新中…*` footer（去 → 追加 → 补回）
#   - stdin 输入避免多层引号地狱

set -euo pipefail

FILENAME="${1:?用法: append.sh <文件名.md> [--next|--list]  或  cat content | append.sh <文件名.md>}"
MODE="${2:-append}"

# ---- 定位八股目录（绕过路径含 : 的 Bash 限制）----
DIR=$(find /Users/xqy/Documents -maxdepth 3 -type d -name "*八股*" 2>/dev/null | head -1)
if [ -z "$DIR" ]; then
    echo "错误: 找不到八股目录（*八股*）" >&2
    exit 1
fi
FILE="$DIR/$FILENAME"

# ---- 模式 2: --next 查询下一编号 ----
if [ "$MODE" = "--next" ]; then
    if [ ! -f "$FILE" ]; then
        echo "next_topic=1"
        echo "last_topic=0"
        echo "next_subsection=1.1"
        echo "file_lines=0"
        exit 0
    fi
    # 抽取所有 "## 主题 N:" 里的 N，取最大
    LAST_TOPIC=$(awk '
        /^##[[:space:]]+主题[[:space:]]+[0-9]+/ {
            # 匹配 "## 主题 N: ..." — 提取第三字段（可能带冒号）
            tok = $3
            gsub(/[^0-9]/, "", tok)
            if (tok+0 > max+0) max = tok
        }
        END { print max+0 }
    ' "$FILE")
    NEXT_TOPIC=$((LAST_TOPIC + 1))

    # 抽取最后一个主题下所有 "### N.M" 里的 M，取最大
    LAST_SUB=$(awk -v lt="$LAST_TOPIC" '
        BEGIN { max=0 }
        $0 ~ "^###[[:space:]]+" lt "\\.[0-9]+" {
            # 匹配 "### N.M ..."
            split($2, a, ".")
            if (a[2]+0 > max+0) max=a[2]
        }
        END { print max+0 }
    ' "$FILE")
    NEXT_SUB=$((LAST_SUB + 1))

    LINES=$(wc -l < "$FILE" | tr -d ' ')

    echo "next_topic=$NEXT_TOPIC"
    echo "last_topic=$LAST_TOPIC"
    echo "next_subsection=${LAST_TOPIC}.${NEXT_SUB}"
    echo "file_lines=$LINES"
    exit 0
fi

# ---- 模式 3: --list 列主题 ----
if [ "$MODE" = "--list" ]; then
    if [ ! -f "$FILE" ]; then
        echo "(文件不存在: $FILENAME)"
        exit 0
    fi
    awk '
        /^##[[:space:]]+主题[[:space:]]+[0-9]+/ {
            if (topic != "") printf "%s  [%d 小节, %d 行]\n", topic, sub_count, NR - topic_start
            topic = $0
            topic_start = NR
            sub_count = 0
            next
        }
        /^###[[:space:]]+[0-9]+\.[0-9]+/ { sub_count++ }
        END {
            if (topic != "") printf "%s  [%d 小节]\n", topic, sub_count
        }
    ' "$FILE"
    exit 0
fi

# ---- 模式 1: 追加内容 ----
# 从 stdin 读内容
CONTENT=$(cat)
if [ -z "$(echo "$CONTENT" | tr -d '[:space:]')" ]; then
    echo "错误: stdin 内容为空" >&2
    exit 1
fi

# 如果文件不存在，创建带标题的新文件
if [ ! -f "$FILE" ]; then
    TITLE="${FILENAME%.md}"
    printf "# %s\n\n*持续更新中…*\n" "$TITLE" > "$FILE"
    echo "新建文件: $FILE"
fi

# 备份到稳定路径（跨 session 保留，用户可回溯）
BACKUP_DIR="${BAGU_BACKUP_DIR:-$HOME/.qoderwork/backup/interview-bagu}"
mkdir -p "$BACKUP_DIR"
BACKUP="$BACKUP_DIR/${FILENAME%.md}.$(date +%Y%m%d_%H%M%S).md"
cp "$FILE" "$BACKUP"

# 用 Python 处理 footer + 追加（避免 awk/sed 对多行 markdown 的转义地狱）
TMPFILE=$(mktemp)
printf '%s' "$CONTENT" > "$TMPFILE"

python3 - "$FILE" "$TMPFILE" <<'PYEOF'
import sys, re
main_path, content_path = sys.argv[1], sys.argv[2]
with open(main_path, 'r', encoding='utf-8') as f:
    doc = f.read()
with open(content_path, 'r', encoding='utf-8') as f:
    new = f.read()

# 抽出 footer（*持续更新中…* 那行）
footer_pat = re.compile(r'\n?\*持续更新中[^\n]*\*\s*\n?')
m = footer_pat.search(doc)
footer = m.group(0).strip() if m else '*持续更新中…*'
doc_no_footer = footer_pat.sub('', doc).rstrip()

# 确保新内容和文档之间有空行
new_block = new.strip()
merged = doc_no_footer + '\n\n' + new_block + '\n\n' + footer + '\n'

with open(main_path, 'w', encoding='utf-8') as f:
    f.write(merged)
PYEOF

rm -f "$TMPFILE"

echo "✓ 已追加到 $FILENAME"
echo "  备份: $BACKUP"
