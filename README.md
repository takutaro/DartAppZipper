# DartAppZipper

Dartアプリケーション(DartVM用や、JavaScriptにbuildされたWEBアプリ)をzipファイルに固めます。  
依存パッケージを含むため `pub get`が不要となり、オフライン環境へのDartアプリケーション配布が容易になります。

## Installation

```sh
$ pub global activate --source git https://github.com/takutaro/DartAppZipper.git
```

`pub global activate`でインストールしたコマンドを実行するには、コマンドへのPATHが通っている必要があります。下記を参照して、PATHの設定を実施して下さい（既に実施されている場合は不要です）。

* https://www.dartlang.org/tools/pub/cmd/pub-global#running-a-script-from-your-path

なおDartアプリケーション配布先の環境には、DartVMが予めインストールされている前提とします。

* https://www.dartlang.org/tools/sdk (通常(公式)はこちらの方法でインストール)
* https://github.com/takutaro/DartSdkInstallerMaker (Windows用インストーラによるオフラインインストール)

## Usage

```sh
$ dartappzipper --target <your-dartapp-directory>
```

上記を実行すると、カレントディレクトリにzipファイルが作成されます。  

## Anything Else

いくつか前提条件や制約があります。

* AngularDart等、`webdev build`にてWEBアプリをbuildする際の出力先指定(`--output`)は行わない前提とします（指定無しのデフォルト値は`--output web:build`です）。つまり、buildディレクトリ配下にはDartファイルが配置されない前提ということです。関連して、
  * webディレクトリはzipファイルから除外します（buildファイル内にコンパイルされているため）
  * build/packagesディレクトリはzipファイルから除外します（使用されていない(はず・・の)ため）
  * ドットファイル、ドットディレクトリはzipファイルから除外します（使用されないため）。  
    なお`.packages`ファイルは再構成されてzipファイルに追加されます。

* dartappzipperコマンドに`--no-dev`オプションを指定すると、`pubspec.yaml`の`dev_dependncies:`に指定したパッケージはzipファイルから除外されるため、サイズを小さくする事ができます。
  * なおDartは`dependncies:`に記述の無いバッケージでも、依存パッケージが使用しているパッケージならimport出来てしまいます。この場合`--no-dev`オプションを指定すると当該パッケージをzipファイル含める事が出来ない為、ご注意下さい（`dependncies:`にすべて記述するか、`--no-dev`オプションを使わない）。

* 様々なOSや環境での確認が十分ではありません。特にmacOSでの確認は出来ていません。すみません

## Author

[@takutaro09](https://twitter.com/takutaro09)
