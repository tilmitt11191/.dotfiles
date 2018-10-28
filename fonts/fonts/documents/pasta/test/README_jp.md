# pasta テストケース

## TCP評価

###test_tcp_sessions.rb
 - **TCPSession** Class コードカバレッジ
 - **TCPSessions** Class コードカバレッジ
 - **TCPSession** Class と **TCPSessions** Class の振る舞い

* [正常系]
 - TCPセッションの正常動作. ( flags : SYN, ACK, FIN )
 - シーケンス番号とACK番号のループ時. ( flags : SYN, ACK, FIN, PSH )
 - 順序入れ替え時のパケット
 - URG フラグ ON. ( flags : SYN, ACK, FIN, URG )
 - RST フラグ ON. ( flags : SYN, ACK, FIN, RST )
 - セッションが日付をまたいだ場合

***
***
# 未追加の評価
## Ethernet評価
* [正常系]
 - VLAN, EOE, PBBの解析

## IP評価
* [正常系]
 - IPv4, IPv6の解析

## TCP評価
* [正常系]
 - SEQ番号ループ時のキャプチャされたパケット
 - ACK番号ループ時のキャプチャされたパケット

* [異常系]
 - データ長不正
 - ヘッダ長不正
 - ポート番号不正
 - パケットの重複
 - 端末とのやり取りが突然無くなる

## UDP評価
 - **UDPSession** Class コードカバレッジ
 - **UDPSessions** Class コードカバレッジ
 - **UDPSession** Class と **UDPSessions** Class の振る舞い

* [正常系]
 - UDPパケット受信
 - DNSデータ解析

   DNSレコード別(A, AAAA, CNAME, HINFO, MX, NS, PTR, SQA, SRV, TXT)

* [異常系]
 - データ長不正
 
## HTTP評価
 - **HTTPParser** Class コードカバレッジ

* [正常系]
 - HTTP method (GET, HEAD, POST, PUT, DELETE ...)
 - パイプライニング
 - レスポンス名、レスポンスメッセージ取得のパターン
 - video_container_parse
 - parse_tarminal_ids
 - parse_html5
 - parse_youtube_feed