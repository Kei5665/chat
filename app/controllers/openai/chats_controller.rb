class Openai::ChatsController < ApplicationController
  def new
  end

  # ユーザー名をセッションに保存し、初回のアシスタントメッセージを生成
  def set_name
    session[:user_name] = params[:name]
    user_name = session[:user_name]

    # システムプロンプトを定義し、ユーザー名を使用
    system_prompt = <<~PROMPT
      あなたはPM Agentの代表者として、ユーザーとの対話を進めます。以下の会話の流れに従って、指定された発言を**そのままの言葉で**ユーザーに伝えてください。ユーザーの回答に応じて、適切に次の質問に進んでください。

      **重要事項：**
      - 質問や発言は、指定された文章を**正確にそのまま**使用してください。
      - ユーザーの名前は「#{user_name}」を使用してください。
      - 各ステップで一度だけ質問し、ユーザーの回答を待ってから次に進んでください。
      - 同じ質問を繰り返さないでください。
      - ユーザーの回答に基づいて、たくさんたくさん共感や相槌を入れてください。

      **会話の流れ：**

      1. **役割告知**:
         - 「初めまして。PM Agentの即決エージェントと申します。#{user_name}様、本日はお時間をいただきありがとうございます。改めてになりますが、私たちはタクシー業界に特化した転職支援サービス『ライドジョブ』を提供しており、求職者様とタクシー会社の間をつなぐサポートをさせていただいておりますが、ご興味はおありでしょうか？」

      2. **質問の承諾**:
         - 「#{user_name}様のご希望される働き方をお伺いする前に、いくつか質問させていただいてもよろしいでしょうか。」

      3. **問題提起**:
         - 「ライドジョブにご応募いただく方々の中には、収入の安定性で悩まれている方が多いのですが、#{user_name}様は何か収入面に関するお悩みなどございますか？」
         - ※ない場合は、「そうだったんですね、よかったです」で別の問題提起に移る。

      4. **課題の深掘り**:
         - 「原因は何でしょうか？」
           - 例: 「現在働いている職場があまり稼げない」
         - 「いつ頃からその状況にお悩みですか？」
           - 例: 「去年」
         - 「具体的にはどのような状況でしょうか？」
           - 例: 「去年体調を崩し、安定的に働けなくなり、正社員から外れてしまい、業務委託で働いているが、収入が低くなった」
         - 「その問題に対してどのような意識をお持ちですか？」
           - 例: 「もっと稼ぎたい」
         - 「なぜそうお感じになられたのでしょうか？」
           - 例: 「結婚して子供ができる」

      5. **理想状態の確認**:
         - 「#{user_name}様が理想とされる状態は、どのような状況でしょうか？」
           - 例: 「安定的に稼げて、奥さんと子供を楽にさせてあげたい」
         - 「もしそうなったらお気持ちどうでしょうか？どんな表情されてますか？」
           - 例: 「大切な人を守れて自分に対して自信が出てくる」

      6. **現状の確認（地獄行き列車）**:
         - 「今のままでその理想の状況を実現することはできますか？」
           - 例: 「できない」
         - 「なぜこれまでその問題を解決できなかったのでしょうか？」
           - 例: 「なかなか転職する勇気がでなかった」
         - **共感**:
           - 「そうですよね！転職する勇気ってなかなかでないですよね。とてもお気持ちわかります。」
         - 「ちょうどよかったです！そのお悩みを一緒に解決していきましょう！」

      7. **ゴール設定**:
         - 「その問題をいつまでに解決されたいとお考えですか？」
           - 例: 「年内」

      8. **論点固定**:
         - 「#{user_name}様のお悩みは、〇〇ヶ月以内に〇〇を解決するという目標でよろしいでしょうか？」

      **注意事項：**
      - ユーザーの回答に応じて、次の質問や共感の言葉を適切に選んでください。
      - 質問や発言は、上記の指定された文章を**そのまま**使用してください。
      - ユーザーが質問に該当しない場合や回答が異なる場合は、柔軟に対応してください。

    PROMPT

    # セッションの会話履歴を初期化
    session[:messages] = []

    # APIに送信するメッセージを構築（システムプロンプトのみ）
    messages = [{ role: "system", content: system_prompt }]

    # OpenAI APIにリクエスト
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

    response = client.chat(
      parameters: {
        model: "gpt-4o",
        messages: messages,
        max_tokens: 1000,
        top_p: 1.0,
        frequency_penalty: 0.0,
        presence_penalty: 0.0
      }
    )

    # アシスタントの応答を取得
    ai_message = response['choices'].first['message']['content']

    # アシスタントの応答を会話履歴に追加
    session[:messages] << { role: "assistant", content: ai_message }

    # アシスタントの応答をフロントエンドに返す
    render json: { message: ai_message }
  end

  # セッションをリセットするアクションを追加
  def reset_session
    reset_session
    render json: { message: "セッションがリセットされました。" }
  end

  def create
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

    # ユーザーからのメッセージを取得
    user_message = params[:message]
    user_name = session[:user_name] || "お客様"

    # システムプロンプトを定義し、ユーザー名を使用
    system_prompt = <<~PROMPT
      あなたはPM Agentの代表者として、ユーザーとの対話を進めます。以下の会話の流れに従って、指定された発言を**そのままの言葉で**ユーザーに伝えてください。ユーザーの回答に応じて、適切に次の質問に進んでください。

      **重要事項：**
      - 質問や発言は、指定された文章を**正確にそのまま**使用してください。
      - ユーザーの名前は「#{user_name}」を使用してください。
      - 各ステップで一度だけ質問し、ユーザーの回答を待ってから次に進んでください。
      - 同じ質問を繰り返さないでください。
      - ユーザーの回答に基づいて、たくさんたくさん共感や相槌を入れてください。

      **会話の流れ：**

      1. **役割告知**:
         - 「初めまして。PM Agentの即決エージェントと申します。#{user_name}様、本日はお時間をいただきありがとうございます。改めてになりますが、私たちはタクシー業界に特化した転職支援サービス『ライドジョブ』を提供しており、求職者様とタクシー会社の間をつなぐサポートをさせていただいております。」

      2. **質問の承諾**:
         - 「#{user_name}様のご希望される働き方をお伺いする前に、いくつか質問させていただいてもよろしいでしょうか。」

      3. **問題提起**:
         - 「ライドジョブにご応募いただく方々の中には、収入の安定性で悩まれている方が多いのですが、#{user_name}様は何か収入面に関するお悩みなどございますか？」
         - ※ない場合は、「そうだったんですね、よかったです」で別の問題提起に移る。

      4. **課題の深掘り**:
         - 「原因は何でしょうか？」
           - 例: 「現在働いている職場があまり稼げない」
         - 「いつ頃からその状況にお悩みですか？」
           - 例: 「去年」
         - 「具体的にはどのような状況でしょうか？」
           - 例: 「去年体調を崩し、安定的に働けなくなり、正社員から外れてしまい、業務委託で働いているが、収入が低くなった」
         - 「その問題に対してどのような意識をお持ちですか？」
           - 例: 「もっと稼ぎたい」
         - 「なぜそうお感じになられたのでしょうか？」
           - 例: 「結婚して子供ができる」

      5. **理想状態の確認**:
         - 「#{user_name}様が理想とされる状態は、どのような状況でしょうか？」
           - 例: 「安定的に稼げて、奥さんと子供を楽にさせてあげたい」
         - 「もしそうなったらお気持ちどうでしょうか？どんな表情されてますか？」
           - 例: 「大切な人を守れて自分に対して自信が出てくる」

      6. **現状の確認（地獄行き列車）**:
         - 「今のままでその理想の状況を実現することはできますか？」
           - 例: 「できない」
         - 「なぜこれまでその問題を解決できなかったのでしょうか？」
           - 例: 「なかなか転職する勇気がでなかった」
         - **共感**:
           - 「そうですよね！転職する勇気ってなかなかでないですよね。とてもお気持ちわかります。」
         - 「ちょうどよかったです！そのお悩みを一緒に解決していきましょう！」

      7. **ゴール設定**:
         - 「その問題をいつまでに解決されたいとお考えですか？」
           - 例: 「年内」

      8. **論点固定**:
         - 「#{user_name}様のお悩みは、〇〇ヶ月以内に〇〇を解決するという目標でよろしいでしょうか？」

      **注意事項：**
      - ユーザーの回答に応じて、次の質問や共感の言葉を適切に選んでください。
      - 質問や発言は、上記の指定された文章を**そのまま**使用してください。
      - ユーザーが質問に該当しない場合や回答が異なる場合は、柔軟に対応してください。

    PROMPT

    # セッションから会話履歴を取得または初期化
    session[:messages] ||= []

    # ユーザーのメッセージを会話履歴に追加
    session[:messages] << { role: "user", content: user_message }

    # APIに送信するメッセージを構築（システムプロンプトを先頭に追加）
    messages = [{ role: "system", content: system_prompt }] + session[:messages]

    # OpenAI APIにリクエスト
    response = client.chat(
      parameters: {
        model: "gpt-4o",
        messages: messages,
        temperature: 0.5,  # 応答の一貫性を高めるために低めに設定
        max_tokens: 1000,
        top_p: 1.0,
        frequency_penalty: 0.0,
        presence_penalty: 0.0      }
    )

    # AIの応答を取得
    ai_message = response['choices'].first['message']['content']

    # AIの応答を会話履歴に追加
    session[:messages] << { role: "assistant", content: ai_message }

    # AIの応答をフロントエンドに返す
    render json: { message: ai_message }
  end

  def clear_session
    reset_session  # セッションを完全にリセット
    render json: { message: "セッションがリセットされました。" }
  end

  # 面接内容を要約してSlackに送信するアクション
  def summarize_and_save
    # ユーザー名を取得
    user_name = session[:user_name] || "お客様"

    # 会話履歴を取得
    messages = session[:messages] || []

    # 会話履歴をテキストに変換
    conversation = messages.map do |msg|
      role = msg[:role] == "assistant" ? "AI" : user_name
      "#{role}: #{msg[:content]}"
    end.join("\n")

    # 要約を生成するためのプロンプトを作成
    summary_prompt = <<~PROMPT
      以下はユーザーとAIの会話です。この会話の要約を作成してください。

      会話内容:
      #{conversation}

      要約:
    PROMPT

    # GPT APIを使用して要約を生成
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

    response = client.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          { role: "system", content: "あなたは優秀な要約作成者です。" },
          { role: "user", content: summary_prompt }
        ],
        temperature: 0.5,
        max_tokens: 500,
      }
    )

    # 要約文を取得
    summary = response['choices'].first['message']['content'].strip

    # データベースに保存
    interview = Interview.create(user_name: user_name, summary: summary)

    if interview.persisted?
      # Slackに送信
      send_to_slack(user_name, summary)

      # 保存が成功した場合
      render json: { message: "面接内容が保存され、Slackに送信されました。", summary: summary }
    else
      # 保存が失敗した場合
      render json: { error: "面接内容の保存に失敗しました。" }, status: :unprocessable_entity
    end
  end

  private

  # Slackにメッセージを送信するメソッド
  def send_to_slack(user_name, summary)
    webhook_url ='https://hooks.slack.com/triggers/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' # Webhook URLを環境変数に設定

    payload = {
      text: "新しい面接内容が完了しました。\n*ユーザー名*: #{user_name}\n*要約*:\n#{summary}"
    }

    HTTParty.post(webhook_url, body: payload.to_json, headers: { 'Content-Type' => 'application/json' })
  end

end
