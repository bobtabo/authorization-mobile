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

---

## :iphone: 画面構成

| 画面 | 説明 |
|:---|:---|
| SplashScreen | 起動画面・QRスキャン開始ボタン |
| QRScannerScreen | カメラでQRコードをスキャン |
| ActivationConfirmScreen | クライアント情報の確認・利用開始実行 |
| TokenDisplayScreen | アクセストークン表示・コピー・シェア |
| HomeScreen | 利用状態確認・利用停止／再開操作 |

---

## :building_construction: 技術スタック

| 用途 | パッケージ |
|:---|:---|
| QRスキャン | `mobile_scanner` |
| ディープリンク（カスタムURLスキーム） | `app_links` |
| HTTP通信 | `http` |
| アニメーション | `flutter_animate` |
| SVG表示 | `flutter_svg` |
| シェア | `share_plus` |
| 環境設定 | `flutter_dotenv` |
| 永続化 | `shared_preferences` |

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
# .env を編集して接続先バックエンドのURLを設定

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

`.env` でバックエンドの接続先を管理します。<br>
※変更しなくても利用可能です。

```env
BASE_URL=https://ample-precise-knee.ngrok-free.dev
```

| 変数 | 説明 |
|:---|:---|
| `BASE_URL` | APIゲートウェイのベースURL |

アプリ内のバックエンド切替プルダウンで、接続先スラッグ（`/function/{slug}/api`）を変更できます。

---

## :link: ディープリンク

カスタムURLスキーム `authgateway://` を使用します。外部QRスキャナーアプリでQRコードを読み取ると、本アプリが自動起動します。

| プラットフォーム | 方式 | 設定ファイル |
|:---|:---|:---|
| iOS | カスタムURLスキーム | `ios/Runner/Info.plist` |
| Android | カスタムURLスキーム | `android/app/src/main/AndroidManifest.xml` |

### QRコードのURL形式

```
authgateway://clients/{identifier}/info
```

### ディープリンクのテスト

```bash
# Android
adb shell am start -a android.intent.action.VIEW -d "authgateway://clients/{identifier}/info"

# iOS Simulator
xcrun simctl openurl booted "authgateway://clients/{identifier}/info"
```

---

## :arrows_counterclockwise: セッション復元

利用開始した端末はローカルにクライアント識別子を保存します。  
次回起動時にバックエンドへステータスを確認し、利用中／停止中であればホーム画面へ直行します。

| 状態 | 起動時の遷移先 |
|:---|:---|
| 利用中 / 停止中 | ホーム画面 |
| 未利用 / セッションなし | スプラッシュ画面 |

---

## :books: 関連リポジトリ

| リポジトリ | 説明 |
|:---|:---|
| [bobtabo/authorization](https://github.com/bobtabo/authorization) | 認可サーバー（OAuth2/OIDC）・管理画面 |
| bobtabo/authorization-mobile | 本リポジトリ：クライアント操作用モバイルアプリ |
