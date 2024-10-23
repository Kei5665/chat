class Openai::ChatsController < ApplicationController
  # セッションリセット
  def reset
    session[:stage] = nil  # セッションのステージをリセット
    puts "セッションをリセット"
    redirect_to new_openai_chat_path  # チャットの最初の画面に戻る
  end

  def new
  end

  def create
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

    # ユーザーからのメッセージを取得
    user_message = params[:message]

     # 最初のセッションは'役割告知'に設定
    session[:stage] ||= '役割告知'  # セッションが未設定の場合に初期化
    # 現在のステージを取得
    current_stage = session[:stage]
    puts "ステージ：#{current_stage}"

    # ステージごとのプロンプトを`system`ロールに設定
    system_prompt = case current_stage
                    when '役割告知'
                      "トークスクリプトに忠実に発言してください。初めまして。PM Agentの〇〇と申します。〇〇様、本日はお時間をいただきありがとうございます。改めてになりますが、私たちはタクシー業界に特化した転職支援サービス『ライドジョブ』を提供しており、求職者様とタクシー会社の間をつなぐサポートをさせていただいております。〇〇様のご希望される働き方をお伺いする前に、いくつか質問させていただいてもよろしいでしょうか。"
                    when '問題提起'
                      "トークスクリプトに忠実に発言してください。ライドジョブにご応募いただく方々の中には、収入の安定性で悩まれている方が多いのですが、〇〇様は何か収入面に関するお悩みなどございますか？"
                    when '課題の深掘り（現在）'
                      "トークスクリプトに忠実に発言してください。原因は何でしょうか？ たとえば、現在働いている職場があまり稼げないなど、具体的な理由を教えてください。"
                    when '課題の深掘り（過去）'
                      "トークスクリプトに忠実に発言してください。その問題はいつ頃からお悩みですか？ 過去の状況を詳しく教えてください。"
                    when '課題の深掘り(気持ち)'
                      "トークスクリプトに忠実に発言してください。その問題に対してどのような気持ちを抱いていますか？ 例えば、ストレスを感じたり、改善したいという強い意志があるなど、感情的な側面を教えてください。"
                    when '理想状態の確認'
                      "トークスクリプトに忠実に発言してください。〇〇様が理想とされる状態はどのような状況でしょうか？ たとえば、安定的に稼げて家族を楽にさせることが理想でしょうか？"
                    when '地獄行き列車'
                      "トークスクリプトに忠実に発言してください。なぜこれまで解決できなかったのでしょうか？"
                    when 'ゴール設定'
                      "トークスクリプトに忠実に発言してください。その問題をいつまでに解決されたいとお考えですか？ 具体的な目標期限をお聞かせください。"
                    when '論点固定'
                      "トークスクリプトに忠実に発言してください。〇〇様のお悩みは、〇〇ヶ月以内に〇〇を解決するという目標でよろしいでしょうか？"
                    else
                      "Guide the conversation based on the user's responses."
                    end
    # OpenAI APIにリクエスト
    response = client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [
          { role: "system", content: system_prompt },  # システムの指示を設定
          { role: "user", content: user_message }       # ユーザーのメッセージを入力
        ]
      }
    )

    puts response

    # AIの応答を取得
    ai_message = response['choices'].first['message']['content']

    # ステージを次に進める
    session[:stage] = next_stage(current_stage)

    # AIの応答をフロントエンドに返す
    render json: { message: ai_message }
  end

  private

  # ステージを進めるロジック
  def next_stage(current_stage)
    case current_stage
    when '役割告知'
      '問題提起'
    when '問題提起'
      '課題の深掘り（現在）'
    when '課題の深掘り（現在）'
      '課題の深掘り（過去）'
    when '課題の深掘り（過去）'
      '課題の深掘り(気持ち)'
    when '課題の深掘り(気持ち)'
      '理想状態の確認'
    when '理想状態の確認'
      '地獄行き列車'
    when '地獄行き列車'
      'ゴール設定'
    when 'ゴール設定'
      '論点固定'
    else
      '完了'
    end
  end
end
