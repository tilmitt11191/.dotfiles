# ruby-pcap

## 概要
ruby-pcap は Ruby から LBL の libpcap (Packet Capture library) へアク
セスするための拡張ライブラリです。TCP/IPのヘッダの情報にアクセスするた
めのクラスも含んでいます。

## 必要なもの:
  - ruby-1.9.3
  - libpcap (http://www.tcpdump.org/)
  - rdoc (4.0.1~)

## インストール前に
** 以下のコマンドで旧バージョンのpcap(ruby-pcap)がインストールされていないことを確認して下さい。 **

`gem list`

** インストールされている場合はアンインストールして下さい。 **

`sudo gem uninstall pcap`

** rdocの更新 **

rdocのバージョンが4.0.1未満の場合、riドキュメント生成時に以下のエラーが出力される場合があります。

 - Enclosing class/module 'xxx' for class xxx not known
 - Enclosing class/module 'xxx' for module xxx not known
 - Enclosing class/module 'xxx' for alias xxx xxx not known

rdocのバージョンが4.0.1以上であることを確認し、再度pcapをインストールし直して下さい。

## コンパイル

 * 'rubygems'と'rake'がインストールされてる場合、以下の手順でruby-pcapをインストールできます。
以下の手順でruby-pcapをインストールできます。
 * リファレンスマニュアルが'doc'ディレクトリに生成されます。

`rake`

`rake build`

`sudo gem install pkg/pcap_[yyyymmdd].[hash].gem`

## 使い方

'doc' ディレクトリ以下、またはGemインストール先にあるリファレンスマニュアルを見て下さい。

'examples' ディレクトリに簡単なサンプルスクリプトがあります。

# 作者

福嶋正機 <fukusima@goto.info.waseda.ac.jp>

Andrew Hobson <ahobson@gmail.com>
によって変更された

Tim Jarratt <tjarratt@gmail.com>
によってOS X and Ruby 1.9.2がサポートされた

Ilya Maykovによって、品質改善とその他偉大な貢献がなされた

ruby-pcapは福嶋正機が著作権を保持する free software です。

# ライセンス
ruby-pcapはGPL(GNU GENERAL PUBLIC LICENSE)に従って再配布または
変更することができます。GPLについてはCOPYINGファイルを参照して
ください。

ruby-pcapは無保証です。作者はruby-pcapのバグなどから発生する
いかなる損害に対しても責任を持ちません。詳細については GPL を
参照してください。
