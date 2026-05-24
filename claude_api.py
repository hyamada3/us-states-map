import anthropic

client = anthropic.Anthropic()

SYSTEM_PROMPT = """あなたは親切なアシスタントです。
質問に対して丁寧かつ簡潔に日本語で答えてください。"""


def simple_chat(user_message: str) -> str:
    """シンプルな1回のメッセージ送受信"""
    response = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1024,
        system=[
            {
                "type": "text",
                "text": SYSTEM_PROMPT,
                "cache_control": {"type": "ephemeral"},  # システムプロンプトをキャッシュ
            }
        ],
        messages=[{"role": "user", "content": user_message}],
    )
    return response.content[0].text


def streaming_chat(user_message: str) -> str:
    """ストリーミングでリアルタイムに出力"""
    print("アシスタント: ", end="", flush=True)
    with client.messages.stream(
        model="claude-sonnet-4-6",
        max_tokens=1024,
        system=[
            {
                "type": "text",
                "text": SYSTEM_PROMPT,
                "cache_control": {"type": "ephemeral"},
            }
        ],
        messages=[{"role": "user", "content": user_message}],
    ) as stream:
        for text in stream.text_stream:
            print(text, end="", flush=True)
        print()
        return stream.get_final_message().content[0].text


def multi_turn_chat():
    """マルチターン会話"""
    messages = []
    print("Claude との会話を開始します。'終了' と入力すると終了します。\n")

    while True:
        user_input = input("あなた: ").strip()
        if user_input in ("終了", "exit", "quit"):
            print("会話を終了します。")
            break
        if not user_input:
            continue

        messages.append({"role": "user", "content": user_input})

        response = client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=1024,
            system=[
                {
                    "type": "text",
                    "text": SYSTEM_PROMPT,
                    "cache_control": {"type": "ephemeral"},
                }
            ],
            messages=messages,
        )

        assistant_text = response.content[0].text
        messages.append({"role": "assistant", "content": assistant_text})
        print(f"アシスタント: {assistant_text}\n")


if __name__ == "__main__":
    # --- シンプルな呼び出し ---
    print("=== シンプルな呼び出し ===")
    answer = simple_chat("アメリカ合衆国で最も人口が多い州はどこですか？")
    print(f"回答: {answer}\n")

    # --- ストリーミング ---
    print("=== ストリーミング ===")
    streaming_chat("東海岸と西海岸の主要な州を3つずつ教えてください。")
    print()

    # --- マルチターン会話 ---
    print("=== マルチターン会話 ===")
    multi_turn_chat()
