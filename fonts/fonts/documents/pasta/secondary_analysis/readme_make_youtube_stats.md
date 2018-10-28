# make_youtube_stats.rb:

analyze_pcap.rbで出力されたtcp.csvファイルから，YouTubeとのセッションを取り出し，状態遷移表を出力するツール

## 機能仕様

### 利用する前に

動作環境はanalyze_pcap.rbと同じです．詳しくはreadme.txtを参照してください．

### 利用方法

#### 入力ファイル
対象のcsvファイルを引数で指定してください．

#### 出力ファイル

以下のファイルが出力されます．

* *_statetransition_*.csv:状態遷移表
* *_log_*.txt:debug出力

出力ファイル名は，実行日時から適当に決定されます ('*_statetransition_[YYYYMMDD-hhmmss].csv')

## 技術仕様
### YouTubeへのHTTPセッション
* tcp.csvファイルのうち，hostにyoutubeが含まれるHTTPセッションの行のみを解析対象にしています．
* hostにgdataが含まれるものをフィードへのリクエスト，hostにredirectorが含まれるもの、またはpathにwatchが含まれるものを動画として，source_ipaddrで識別したユーザに振り分けています．
* 取得したフィードは[permanent_id, feed_label], [temporary_id, feed_label], [temporary_id, permanent_id]で記憶し，後にtemporary_idをキーにfeed_labelを参照します．
* 他サイトのリンクからYouTubeへ来た動画は，stateにrefererのホスト名が設定されます．
* 動画をリクエスト開始時間でソートし，遷移元フィードの遷移をカウントします．
* 遷移元フィードはredirectorの場合，動画リクエストのクエリ内のelから，watchの場合，youtube_id_mapping辞書(IdMappingDictionary)から，parmanent_idまたは，temporary_idをキーとして取得します．
