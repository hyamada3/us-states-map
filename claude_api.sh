#!/bin/bash
# Claude API をcurlで呼び出すスクリプト
# 使い方: ./claude_api.sh "質問内容"

set -euo pipefail

API_KEY="${ANTHROPIC_API_KEY:-}"
MODEL="claude-sonnet-4-6"
MAX_TOKENS=1024

# APIキー確認
if [[ -z "$API_KEY" ]]; then
  echo "エラー: ANTHROPIC_API_KEY が設定されていません。" >&2
  echo "  export ANTHROPIC_API_KEY='sk-ant-...'" >&2
  exit 1
fi

# 引数確認
if [[ $# -eq 0 ]]; then
  echo "使い方: $0 \"質問内容\"" >&2
  echo "例:     $0 \"アメリカで最も大きい州はどこですか？\"" >&2
  exit 1
fi

USER_MESSAGE="$*"

# JSONを組み立てる（jqがある場合は安全なエスケープ処理）
if command -v jq &>/dev/null; then
  PAYLOAD=$(jq -n \
    --arg model "$MODEL" \
    --argjson max_tokens "$MAX_TOKENS" \
    --arg msg "$USER_MESSAGE" \
    '{
      model: $model,
      max_tokens: $max_tokens,
      messages: [{ role: "user", content: $msg }]
    }')
else
  # jqがない場合は手動でエスケープ
  ESCAPED=$(printf '%s' "$USER_MESSAGE" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/g' | tr -d '\n' | sed 's/\\n$//')
  PAYLOAD="{\"model\":\"$MODEL\",\"max_tokens\":$MAX_TOKENS,\"messages\":[{\"role\":\"user\",\"content\":\"$ESCAPED\"}]}"
fi

# API 呼び出し
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "https://api.anthropic.com/v1/messages" \
  -H "x-api-key: $API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "$PAYLOAD")

# HTTPステータスコードとボディを分離
HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

# ネットワークエラー確認
if [[ -z "$BODY" ]]; then
  echo "エラー: レスポンスが空です。ネットワーク接続を確認してください。" >&2
  exit 1
fi

# HTTPエラー確認（2xx以外はエラー）
if [[ "$HTTP_STATUS" -lt 200 || "$HTTP_STATUS" -ge 300 ]]; then
  if command -v jq &>/dev/null; then
    ERROR_MSG=$(echo "$BODY" | jq -r '.error.message // "不明なエラー"')
  else
    ERROR_MSG=$(echo "$BODY" | grep -o '"message":"[^"]*"' | head -1 | sed 's/"message":"//;s/"//')
  fi
  echo "APIエラー (HTTP $HTTP_STATUS): $ERROR_MSG" >&2
  exit 1
fi

# レスポンスからテキストを取り出す
if command -v jq &>/dev/null; then
  echo "$BODY" | jq -r '.content[0].text'
else
  # jqがない場合は簡易パース
  echo "$BODY" | grep -o '"text":"[^"]*"' | head -1 | sed 's/"text":"//;s/"$//' | sed 's/\\n/\n/g'
fi
