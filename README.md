<p align="center">
<a href="https://flutter.dev/" target="_blank"><img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/flutter/flutter-original.svg" height="72" alt="Flutter"></a>
&nbsp;&nbsp;
<a href="https://dart.dev/" target="_blank"><img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/dart/dart-original.svg" height="72" alt="Dart"></a>
&nbsp;&nbsp;
<a href="https://developer.apple.com/ios/" target="_blank"><img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/apple/apple-original.svg" height="72" alt="iOS"></a>
&nbsp;&nbsp;
<a href="https://developer.android.com/" target="_blank"><img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/android/android-original.svg" height="72" alt="Android"></a>
</p>

<p align="center">
<a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-3.41.9-02569B?logo=flutter&logoColor=white" alt="Flutter"></a>
<a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-3.11.5-0175C2?logo=dart&logoColor=white" alt="Dart"></a>
<a href="https://developer.apple.com/ios/"><img src="https://img.shields.io/badge/iOS-13.0+-000000?logo=apple&logoColor=white" alt="iOS"></a>
<a href="https://developer.android.com/"><img src="https://img.shields.io/badge/Android-5.0%2B%20(API%2021)-3DDC84?logo=android&logoColor=white" alt="Android"></a>
</p>

---

# <img src="assets/icon.svg" height="25" style="margin-top:-4px;vertical-align:middle;" alt="Authorization Gateway"> Authorization Gateway Mobile

[認可サーバー](https://github.com/bobtabo/authorization) と連携する Flutter 製モバイルアプリです。  
担当者がクライアントを登録した後、クライアントが自身のAPIアクセスを利用開始・停止するための操作端末として機能します。  
アクセストークンの発行は認可サーバーが行います。

> 関連 Issue: [#67 認可フローの改善（スマホ対応）](https://github.com/bobtabo/authorization/issues/67)

---

## :iphone: 画面構成

| 画面 | 説明 |
|:---|:---|
| SplashScreen | 起動画面・QRスキャン開始ボタン |
| QRScannerScreen | カメラでQRコードをスキャン |
| ActivationConfirmScreen | クライアント情報の確認・アクティベート実行 |
| TokenDisplayScreen | アクセストークン表示・コピー・シェア |
| HomeScreen | 認証ステータス確認・利用停止操作 |

---

## :building_construction: 技術スタック

| 用途 | パッケージ |
|:---|:---|
| QRスキャン | `mobile_scanner` |
| ディープリンク（Universal Links / App Links） | `app_links` |
| アニメーション | `flutter_animate` |
| SVG表示 | `flutter_svg` |
| シェア | `share_plus` |
| 環境設定 | `flutter_dotenv` |

---

## :hammer_and_wrench: 開発環境構築

### 前提

- Flutter 3.41.9 以上
- Xcode（iOS ビルド）
- Android Studio / Android SDK（Android ビルド）

> [!NOTE]
> iOS Simulator / Android エミュレーターのセットアップは各自で行ってください。

### セットアップ

```bash
git clone git@github.com:bobtabo/authorization-mobile.git
cd authorization-mobile

# 環境設定ファイルを作成
cp .env.example .env
# .env を編集して接続先バックエンドを設定

flutter pub get
```

### 起動

**エミュレーター／シミュレーターの起動**

```bash
# Android（Pixel 9 / API 35）
~/Library/Android/sdk/emulator/emulator -avd Pixel_9_API35_Camera &

# iOS Simulator
open -a Simulator
```

**アプリの起動**

```bash
# 接続デバイスを確認
flutter devices

# デバイスを指定して起動
flutter run -d emulator-5554   # Android
flutter run -d iPhone          # iOS Simulator
```

---

## :gear: 環境設定

`.env` でバックエンドの接続先を管理します。`.env` は Git 管理対象外です。

```env
BASE_URL=https://apis.authorization-php.dev
```

| 変数 | 説明 |
|:---|:---|
| `BASE_URL` | 認可サーバーのベースURL |

バックエンドを切り替える場合は `.env` の `BASE_URL` を変更してください。  
（複数バックエンドの切り替えオペレーションは今後対応予定）

---

## :link: ディープリンク（Universal Links / App Links）

外部QRスキャナーアプリでQRコードを読み取ると、本アプリが自動で起動し、アクティベーション確認画面に遷移します。

| プラットフォーム | 方式 | 設定ファイル |
|:---|:---|:---|
| iOS | Universal Links | `ios/Runner/Runner.entitlements` |
| Android | App Links | `android/app/src/main/AndroidManifest.xml` |

### サーバー側に必要な対応

本アプリの App Links / Universal Links が正常に動作するには、認可サーバー側に以下のファイルの配置が必要です。

**iOS**
```
https://apis.authorization-php.dev/.well-known/apple-app-site-association
```

**Android**
```
https://apis.authorization-php.dev/.well-known/assetlinks.json
```

> QRコードに含まれるURLの形式はバックエンド設計確定後に更新予定。  
> 現在の仮実装: `https://apis.authorization-php.dev/activate?client_id={id}`

---

## :books: 関連リポジトリ

| リポジトリ | 説明 |
|:---|:---|
| [bobtabo/authorization](https://github.com/bobtabo/authorization) | 認可サーバー（OAuth2/OIDC）・管理画面 |
| bobtabo/authorization-mobile | 本リポジトリ：クライアント操作用モバイルアプリ |
