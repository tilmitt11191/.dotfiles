# 一次処理ツール (analyze_pcap.rb)

pcapファイルから，tcp/http/ssl session, udp session, 単位時間毎の通信量を分析し，csv形式で出力するツールです．

## 機能仕様

### 利用する前に

本ツールはruby 1.9.3で動作確認をしています．

ruby 1.9.3以外のバージョンでの動作は保証されません．ruby 1.8.xではおそらく動作しません．ruby 2.0.xはruby 1.9.xとの互換を重視しているためおそらく動作しますが未確認です．

実行時にはruby-pcapがインストールされている必要があります．ruby-pcap/ より取得してください．

実行時にはhpricotがインストールされている必要があります．hpricot/ より取得してください．

実行時にFacterがインストールされている場合，CPUコア数を自動的に取得し，最適な数の子プロセスを生成します．ただし，-c/--max-child-processesオプションが指定されていた場合はそちらを優先します．またメモリ量は考慮されません．

実行時にはanalyze_pcap.rbと同じディレクトリに以下のファイルを置く必要があります．

* tcp_sessions.rb
* http_parser.rb
* video_container_parser.rb
* udp_sessions.rb
* dns_parser.rb
* traffic_volume.rb
* gtp_parser.rb
* gtp_ie_parser.rb
* gtp_msg_parser.rb

### 利用方法

#### 基本的な利用方法

基本的な利用方法は以下の通りです．

    Usage: analyze_pcap.rb [options] pcapfiles
        -h, --help                       show help
        -c processes,                    set number of maximum child processes
            --max-child-processes
        -d, --output-debug-file          enable debug output
        -f, --omit-field-names           omit field names in first row
        -i time,                         set timeout check interval in sec
            --timeout-check-interval
        -l, --file-prefix-label prefix   specify file prefix
        -o, --half-close-timeout time    set half close timeout in sec
        -p, --http-ports ports           set destination ports for HTTP in comma separated format
        -q, --ssl-ports ports            set destination ports for HTTP/SSL in comma separated format
        -r, --cancel-remaining-sessions  cancel remaining sessions at the end of process
        -s, --sampling-ratio ratio       enable source IP address based sampling
        -t, --tcp-timeout time           set tcp timeout in sec
        -u, --udp-timeout time           set udp timeout in sec
        -v [time],                       output traffic volume time. time unit can be set in sec
            --output-traffic-volume
            --no-corresponding-response  output results even if corresponding response is not found
            --plain-text                 do not hash source ip addresses
            --parse-html                 enable html5 analysis
            --on-the-fly-threshold packets
                                         set on-the-fly threshold
            --missing-threshold packets  set missing threshold
            --ipv4-subnet-prefix-length length
                                         set subnet prefix length for IPv4
            --ipv6-subnet-prefix-length length
                                         set subnet prefix length for IPv6
            --gtp-all                    output all gtp parameter
            --version                    show version

#### 入力ファイル

対象となるpcapファイル群は引数で与えられます．引数で与えた順序とは無関係に，辞書順でソートされた後に処理されます．そのため，入力pcapファイルは辞書順と時刻順が一致することが期待されます

#### 出力ファイル

標準では以下のファイルが出力されます．

* log_*.txt: 実行ログ
* tcp_*.csv: tcp/http/ssl分析結果
* udp_*.csv: udp分析結果
* gtp_*.csv: gtp分析結果
* debug_*.txt: debug用出力 (-d/--output-debug-file オプションを指定した場合のみ出力されます)
* volume_*.csv: 単位時間毎の通信量 (-v/--output-traffic-volume オプションを指定した場合のみ出力されます)

ファイル出力に関する仕様は以下の通りです．

* デフォルトでは出力ファイルはカレントディレクトリに作成されます．また，出力ファイル名は実行日時から適当に決定されます ('tcp_[YYYYMMDD-hhmmss].csv', 'log_[YYYYMMDD-hhmmss].txt', など)
    * ファイルに任意のprefixを付与したり，出力先ディレクトリを指定したい場合は， -l/--file-prefix-label オプションを使用して下さい
* -d/--output-debug-file オプションを使用することで，HTTPのbody部の生データを出力することができます ('debug_[YYYYMMDD-hhmmss].csv') ．ただし，この場合に生成されるファイルは巨大となるため，ストレージの残り容量には十分に注意して下さい．また，body部は個人情報を含みうるため，出力ファイルの扱いには細心の注意を払って下さい．
* デフォルトでは実行ログを除く全ての分析結果にヘッダ行が付加されます．ヘッダ行を省略する場合は -f/--omit-field-names オプションを指定して下さい
* 個人情報として扱われるIPアドレスはsaltを付加したハッシュ処理が行われます．--plain-text オプションにより，ハッシュ処理を無効化しIPアドレスを平文で出力することができますが，出力ファイルの扱いには十分に注意して下さい．
    * ユーザのIPアドレス空間による分析を事後的に行うため，subnet prefixが出力されています．subnet prefix lengthはデフォルトではIPv4が19bit，IPv6が64bitですが，--ipv4-subnet-prefix-lengthオプション及び--ipv6-subnet-prefix-lengthオプションにより任意の値が設定可能です．

#### 解析対象の指定

analyze_pcap.rbは，デフォルトではHTTP/SSLを含む全てのTCPセッションと全てのUDPセッションを対象とします．ただし，HTTP以外はTCP/UDPレイヤまでの情報のみ出力され，それより上位レイヤの解析は行われません

* -p/--http-ports オプションにより，HTTPとして認識するポート番号を明示的に指定できます．-p/--http-ports オプションを指定しない場合はポート番号80, 8080をHTTPとして扱います
* -q/--ssl-ports オプションにより，SSLとして認識するポート番号を明示的に指定できます．-q/--ssl-ports オプションを指定しない場合はポート番号443, 8443をSSLとして扱います
* UDPのポート番号指定を行うオプションはありません

デフォルトでは全てのセッションを解析対象としますが，-s/--sampling-ratio オプションが指定されていた場合は，指定されたサンプリング率によってhandshake時にサンプリングが行われます．サンプリングは乱数ではなくIPアドレスのハッシュ値に基づいて行われます．そのため，繰り返し実行しても結果が変化することはありません．また，利用時にpcapファイルに含まれるIPアドレス空間を意識する必要もありません．なお，TCPの場合は初回のsynパケットの送信元IPアドレスが，UDPの場合はセッションの最初のパケットの送信元IPアドレスが，それぞれサンプリング率の決定に利用されます．

#### TCPセッションの扱いについて

一定期間パケットの送受信が行われなかったTCPセッションは終了したものと見なされます．-t/--tcp-timeout time オプションでタイムアウトまでの時刻を，-i/--timeout-check-interval でタイムアウト判定を行う間隔をそれぞれ指定できます．

キャプチャ時のパケット抜け等によりシーケンス番号抜けが発生し，シーケンス番号が連続していないパケットが一定数以上蓄積された場合，それ以降の解析を諦めます．--missing-threshold で、諦めるまでのパケット数を指定できます．

half-close状態で一定期間パケットの送受信が行われなかったTCPセッションも終了したものと見なされます．このタイムアウト値は，上述のタイムアウト値とは独立で，-o/--half-close-timeout オプションで指定できます

デフォルトでは全pcapファイルを読み終わった時点で残っているTCPセッションは強制的に終了したものと見なして解析されます．これらを解析対象とせずに単に破棄する場合は -r/--cancel-remaining-sessions オプションを使用して下さい

#### UDPセッションの扱いについて

本来はUDPにセッションの概念はありませんが，一定期間を空けずに同一のIPアドレス組，ポート番号組で連続的に送受信されている一群のUDPパケットを便宜上UDPセッションとして扱っています．セッションの切れ目のタイムアウト判定する閾値は -u/--udp-timeout オプションで指定できます．なお，タイムアウト判定を行う間隔は，TCPと共通の値が用いられ，-i/--timeout-check-interval オプションで指定できます．

デフォルトでは全pcapファイルを読み終わった時点で残っているUDPセッションは強制的に終了したものと見なして出力されます．これらを解析対象とせずに単に破棄する場合は -r/--cancel-remaining-sessions オプションを使用して下さい．このオプションはTCPと兼用です．片方だけを破棄することはできません．

上り方向と下り方向の識別は，syn及びsyn+ackパケットの出現頻度により自動的に行われます．そのため，解析開始直後や回線切替直後などは方向の誤判別が発生する可能性があります．

#### トラヒック量の扱いについて

-v/--output-traffic-volume オプションを指定することで，トラヒック量を一定間隔毎，IPアドレス毎で集計して出力することができます．集計間隔は標準では1.0secですが，-v/--output-traffic-volume オプションに続けてsec単位のfloat値を指定することができます．

単位時間当たりの集計となるため，先頭及び末尾の単位時間のトラヒック量は信頼できません．

上り方向と下り方向の識別は，syn及びsyn+ackパケットの出現頻度により自動的に行われます．そのため，解析開始直後や回線切替直後などは方向の誤判別が発生する可能性があります．

#### 並列処理

TCPセッションの処理は，複数の子プロセスにより並列して実行されます．用いる最大の子プロセス数は -c/--max-child-processes により指定できます．

* 子プロセス数として0以下を指定した場合は，子プロセスを生成せずに親プロセスのみで処理を行います
* 子プロセスはそれぞれ独立にファイルアクセスを試みるため，ストレージのパフォーマンスが十分でない環境で子プロセス数を増やしすぎると大幅にパフォーマンスが低下します
* 子プロセスは個別に処理中のTCPセッションの情報をメモリ上に保持するため，メモリが十分にない環境で子プロセス数を増やし過ぎると動作が不安定となる可能性があります
    * analyze_pcap.rbは特別なメモリ管理を行っていません．メモリ管理はOSおよびrubyに依存しています

入力ファイル群は最初に子プロセス数のleading_filesに分割され，並列してTCPセッションの走査が開始されます．与えられたファイル群の走査が完了した時点で残存TCPセッションがあった場合は，全てのTCPセッションが完了するまで続くファイル (following_files) を読み続けます．following_filesを処理中は，新たなTCPセッションが検出されても単に無視します．

TCPセッション以外の処理 (UDPセッションの処理やトラヒック量の処理) は分割せずに親プロセス中で行われます．これは，先頭から末尾まで連続で処理する必要があるためです．

## 技術仕様

### ドキュメント

主要なクラス及びモジュールはYARD形式のドキュメントが準備されています．詳細仕様が必要な場合はそちらを参照して下さい．

### TCPセッションの再構築

analyze_pcap.rbは，最初にTCPセッションの再構築を行います．

* 対象となるpcapファイル群の内部でhandshakeが行われたTCPセッションのみを解析対象とします．pcapファイル開始時点で既にhandshakeを終えていたTCPセッションは単に無視されます．また，handshake中のパケットがdropしていたセッションは破棄されます
* 全てのTCPセッションを一度メモリ上に保持するため，処理対象のpcapファイルによっては大量のメモリが必要となります
* TCPセッション内でパケットの再送が行われた場合，最初に観測されたパケットのみが使用されます．重複したパケットもカウントしており，その総量は通常のデータ量とは別に出力されます．
* 再送であることが確認できない不正なsequence numberをもったパケットもカウントされ，破損データとして出力されます．
* TCPセッション内でパケットの順序入れ替えが起こった場合，その再構築は自動的に行われます．SACK等により，一部のパケットのみが再送された場合も対応しています．順序入れ替えが起こった場合，各HTTPセッションの終了時刻は，同セッション中で最も遅く到着したパケットに依存します
* 各HTTPセッションの最終sequence numberに対応するACKが観測された時刻を終了ack時刻として出力します．この際にSACKは考慮されません
* half-closeを考慮し，双方向のfin/rstが観測された時点でそのTCPセッションが終了したものと見なし，HTTP parserにかけます．half-close状態で一定時間が経過しても対抗方向のfin/rstが観測されない場合はタイムアウト判定を行います

### HTTPのparse

TCPセッション完了後に，HTTP parserにかけ，その結果がcsvファイルに出力されます．

* 出力されるcsvファイルのフォーマットはhttp_csv_format.xlsxを参照してください
* HTTP parserはrequest/responseの組が確認できた段階でファイル出力を行います．requestのみが観測され，response headerが観測されない場合は出力されません．response headerが観測された後，responseのbodyを送信中にTCPセッションが中断された場合は，その時点までの情報を出力します
    * --no-corresponding-response オプションを付与することで，responseが観測されないrequestのみのHTTPセッションも出力します
* 一定時間毎に，直近の一定期間パケットが流れていないセッションを打ち切るタイムアウト処理を行い，TCPセッションが完了したものと見なします
* SSLコネクションはTCPレイヤの情報のみ出力します．HTTPレイヤの情報は空欄となります．また，request方向のパケットのみが観測され，response方向のパケットが観測されなかったセッションは単に破棄されます

### GTPv2-Cのparse

UDPパケットにおいて,宛先ポート番号がGTPポート番号(2123)を使用している場合,GTPv2-Cパケットの解析を行います．
GTPv2-Cパケットは,UDPパケット同様セッションの概念が存在しないため,同一シーケンス番号にてrequest/responseの組を1セッションとして扱います．
* 出力されるcsvファイルのフォーマットはoutput_csv_format.xlsxを参照してください
* --gtp-all オプションを指定することで,詳細な解析結果が出力されます
* 個人情報として扱われるIPアドレス(PAA),端末識別子(IMSI_MSIN)はsaltを付加したハッシュ処理が行われます．--plain-text オプションにより，ハッシュ処理を無効化しIPアドレス,端末識別子を平文で出力することができますが，出力ファイルの扱いには十分に注意して下さい．
* 解析対象であるメッセージタイプは, Create Session Request/Response, Modify Bearer Request/Response です．対象外のメッセージは無視されます．
* GTP parserはrequest/responseの組が確認できた段階でファイル出力を行います．デフォルトでは全pcapファイルを読み終わった時点で残っているGTPセッションは強制的に終了したものと見なして出力されます．-r/--cancel-remaining-sessions オプションにて有効/無効設定が可能です．

### その他

#### 位置情報の抽出

原則として，request path の query 部のみを走査対象としています

* bodyやrequest path以外のヘッダは対象外です．
* equest path の中でも path や fragment等も対象外です

走査は，以下の方法により順次行われます．

* EZWeb の location で送出される位置情報
    * ‘datum’, ‘unit’, ‘lat’, ‘lon’, の各queryが存在し，‘datum’ が ‘tokyo であるもの
* EZWeb の gpsone で送出される位置情報
    * ‘ver’, ‘datum’, ‘unit’, ‘lat’, ‘lon’, ‘alt’, ‘time’, ‘smaj’, ‘smin’, ‘vert’, ‘majaa’, ‘fm’ の各queryが存在するもの
* コンマで区切られた2つの浮動小数点の値を含む query
    * /\|?([0-9\.\/]+),([0-9\.\/]+)/ に該当するものを抽出
    * 2つの数値を以下のいずれかの座標形式と見なして解析
        * degree形式
            * 例: 139.123456
            * /^[0-9]+\.[0-9]+$/
        * msec形式
            * 例: 500000000 
            * /^[0-9]+$/
        * dms形式
            * 例: 139.123.456.789, 139/123/456.789, 139/123/456
            * /^[0-9]+[\.\/][0-9]+[\.\/][0-9]+(\.[0-9]+)?$/
    * 上で得られた座標が日本国内であるかを検証
        * 20.4252777777778 <= 緯度 <= 45.5571861111111 && 122.933611111111 <= 経度 <=153.986388888889
* 任意の2つの query の値を取り出し，上と同様の処理

#### IMSI/MEID情報の抽出

request path, HTTP headers, HTTP bodyを走査対象とします．
ただし，Content-Type: からテキストであると推定されない場合は，HTTP bodyの走査は行いません．また，HTTP bodyは無制限に走査対象とはされず，一定サイズで打ち切られます．詳細は BODY_RETENTION_RULES を参照して下さい．

IMSI/MEIDはそれぞれ以下の形式で走査されます．

* 'IMSI' => /((^|[^0-9])(44(00[78]|05[0-6]|07[0-9]|08[89]|170)[0-9]{10})($|[^0-9]))/
* 'MEID' => /((^|[^0-9a-fA-F])([a-fA-F][0-9a-fA-F]{13})($|[^0-9a-fA-F]))/

#### HTML5 関連技術の週出

hpricot_klabs がインストールされており、かつ --parse-html オプションが付加された場合に限り，HTTPセッション内の HTML5 関連技術を抽出し tcp_*.csv の html5 フィールドに当該技術の識別子を出力します．抽出する HTML5 関連技術は http_parser.rb 内 HTML5_REGEX_RES_BODY 及び HTML5_REGEX_HEADER を参照してください．HTML5_REGEX_RES_BODY は 再構築した HTTP セッション内 response にのみ適用されます．また，HTML5_REGEX_HEADER は request, response 両方に適用されます．

http_parser.rb にて再構築した HTTP セッションに HTML5 関連技術が複数含まれる場合は，'/' (スラッシュ)区切りでそれぞれの関連技術を出力し，tcp_*.csv の html5 フィールドに出力します．

hpricot_klabs がインストールされていない場合は，本機能は動作しません．従って，出力された tcp_*.csv の html5 フィールドは空欄となります．

#### 動画情報の抽出

ISO/IEC 14496-12 (ISO base media file format) 及び ISO/IEC 13818-1 (MPEG-2 TS/TTSのみ．MPEG-2 PSは対象外) に準拠した動画の解析を行い，情報を抽出します．

解析の際はHTTP bodyを走査します．Content-Type: から動画であることが推測される場合は，一定サイズ (65,536 byte) まで走査します．その後に宣言された情報は単に無視されます．また，Range: や moof (movie fragment) による分割ダウンロードを行った場合など，動画情報が含まれない場合も単に無視します．


# 二次処理ツール

一次処理結果を用いて高度な集計を行うツール群です。

secondary_analysis/ 配下に収められています。

## make_stats.rb

一次処理により作成された tcp_*.csv から統計情報を出力します．

### Fingerprintの利用

OSの識別においては，User-Agentのみならず，Fingerprintも利用されます．
通常は1回目のcsvファイル走査でFingerprint辞書を作成し，2回目の走査でFingerprint辞書を利用した処理を行いますが，-f オプションにより外部のFingerprint辞書ファイルを取り込むことで，1回目のファイル走査を省略することが可能です．

### 出力ファイル

作成されるファイルは以下の通りです．

* [元ファイル名]_other_os.csv: 辞書作成の際に，OS識別ルールに引っかからなかったUser-Agent名とその出現回数です
* [元ファイル名]_dictionary.csv: Fingerprint辞書です
* [元ファイル名]_stats_response_content_type.csv: Content-Type種別毎の下り総バイト数と出現回数です
* [元ファイル名]_stats_request_user_agent.csv: User-Agent種別毎の下り総バイト数と出現回数です
* [元ファイル名]_stats_protocol_operating_system.csv: プロトコル種別とFingerprintをいて推測したOS種別の組毎の下り総バイト数と出現回数です
* [元ファイル名]_stats_protocol_explicit_operating_system: プロトコル種別とFingerprintを用いずにUser-Agent名称のみから推測したOS種別の組毎の下り総バイト数と出現回数です
* [元ファイル名]_stats_protocol.csv: プロトコル種別毎の下り総バイト数と出現回数です
* [元ファイル名]_stats_operating_system.csv: Fingerprintをいて推測したOS種別毎の下り総バイト数と出現回数です
* [元ファイル名]_stats_explicit_operating_system.csv: Fingerprintを用いずにUser-Agent名称のみから推測したOS種別毎の下り総バイト数と出現回数です

## make_video_stats.rb

一次処理により作成された tcp_*.csv から動画情報を集計し，出力します．

一般に一つの動画視聴は複数のHTTP/TCPセッションにより構成されます．本ツールは，それらのHTTP/TCPセッションを動画視聴単位に名寄せするものです．

