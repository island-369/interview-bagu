#!/bin/bash
# append.sh — 追加精炼 Q 条目到八股文档
# 用法: bash append.sh "LLM应用架构.md" "## Q5: 新问题\n\n内容..."
# 处理: 路径含冒号、自动递增Q序号、插入到"持续更新中"之前

set -euo pipefail

FILENAME="${1:?用法: append.sh <文件名.md> <内容>}"
CONTENT="${2:?缺少追加内容}"

# 定位八股目录（绕过路径含 : 的 Bash 限制）
DIR=$(find /Users/xqy/Documents -maxdepth 2 -type d -name "*八股*" 2>/dev/null | head -1)

if [ -z "$DIR" ]; then
    echo "错误: 找不到八股目录" >&2
    exit 1
fi

FILE="$DIR/$FILENAME"

# 如果文件不存在，创建带标题的新文件
if [ ! -f "$FILE" ]; then
    TITLE="${FILENAME%.md}"
    printf "# %s\n\n*持续更新中…*\n" "$TITLE" > "$FILE"
    echo "新建文件: $FILE"
fi

# 计算下一个 Q 序号
LAST_Q=$(grep -oP '^## Q\K\d+' "$FILE" 2>/dev/null | sort -n | tail -1)
NEXT_Q=$(( ${LAST_Q:-0} + 1 ))

# 替换内容中的 {N} 占位符为实际序号
CONTENT=$(echo -e "$CONTENT" | sed "s/{N}/$NEXT_Q/g")

# 插入到 "*持续更新中*" 之前；如果没有这个标记就追加到末尾
if grep -q "持续更新中" "$FILE"; then
    # 用 awk 在标记行前插入
    awk -v content="$CONTENT" '
        /持续更新中/ && !inserted {
            printf "%s\n\n", content
            inserted=1
        }
        {print}
    ' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
else
    printf "\n%s\n" "$CONTENT" >> "$FILE"
fi

echo "✓ 已追加 Q$NEXT_Q 到 $FILENAME"
