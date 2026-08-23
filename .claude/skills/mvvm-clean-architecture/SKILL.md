---
name: mvvm-clean-architecture
description: authorization-mobile のレイヤー構成（View→ViewModel→UseCase→Repository→DataSource）・命名規則・Result型/Riverpod/Freezedの使い方を確認するためのリファレンス。新しい画面、API呼び出し、永続化処理、状態管理を追加/変更する前に必ず参照する。「画面を追加して」「新しいAPIを呼ぶ処理を実装して」「ボタンを押したときの処理を書いて」など、lib/ 配下のコード追加・変更を伴うタスクの前に読む。
---

# MVVM + Clean Architecture 規約

このリポジトリのアーキテクチャ規約をまとめたリファレンス。誰が・どのセッションでコードを追加/変更しても、同じ設計方針に基づいた一貫したコードになることを目的とする。判断が分かれうる点は曖昧にせず、断定的に書く。

## 1. レイヤー構成と依存方向

```text
View → ViewModel → UseCase → Repository(interface) → RepositoryImpl → DataSource
```

一方向のみに依存する（逆方向の依存・層の飛び越しは原則禁止）。例外は「6. UDFの原則と意図的なレイヤー越え」で明記する2件のみ。

| 層 | ディレクトリ | 責務 |
|---|---|---|
| Presentation (View) | `lib/ui/<feature>/view/` | UIの描画のみ。ビジネスロジックを持たない。ViewModelの状態を購読し、ユーザー操作をViewModelのメソッド呼び出しに変換する |
| Presentation (ViewModel) | `lib/ui/<feature>/` | 画面の状態（State）を保持・更新する。UseCaseを呼び出し、結果をStateに反映する。`BuildContext`に依存する処理（`showDialog`等）を持たない |
| Application (UseCase) | `lib/domain/usecases/` | 1クラス1責務、`call()`メソッドのみを持つ。Repositoryを呼ぶだけの薄い層 |
| Domain (Entity / Repository interface) | `lib/domain/entities/`, `lib/domain/repositories/` | プラットフォーム非依存のデータ構造と、Data層が実装すべき抽象インターフェース |
| Data (RepositoryImpl / DataSource) | `lib/data/repositories/`, `lib/data/datasources/` | Repositoryインターフェースの実装。DataSourceを呼び、例外を`Result`/`AppException`に変換する |
| Core | `lib/core/` | 横断的関心事（`Result`/`AppException`、設定値）。DIコンテナやビジネスロジックは持たない |

## 2. ディレクトリ構造の例

```text
lib/
  core/
    result.dart
    errors/app_exception.dart
    config/               # AppConfig, kBackends 等の横断的な定数・設定
  domain/
    entities/              # freezedのデータクラス（ClientInfo, BackendOption 等）
    repositories/           # abstract interface class のみ
    usecases/                # 1クラス1責務、call()メソッド
  data/
    datasources/             # instanceベース、DataSource一つにつき1つの外部境界（API/永続化/OS機能）
    repositories/             # Repositoryインターフェースの実装 + @riverpod provider
  ui/
    <feature>/
      <feature>_state.dart    # freezed
      <feature>_view_model.dart  # @riverpod class
      view/
        <feature>_screen.dart
    widgets/                  # 複数画面で共有するUI部品
  app.dart                    # ルートWidget（ProviderScope配下）
  main.dart                   # bootstrapのみ
```

## 3. 命名規則

| 種類 | ファイル名 | クラス/関数名 |
|---|---|---|
| Entity | `snake_case.dart` | `PascalCase`（freezed、`@freezed`） |
| Repository interface | `xxx_repository.dart` | `abstract interface class XxxRepository` |
| Repository実装 | `xxx_repository_impl.dart` | `class XxxRepositoryImpl implements XxxRepository` |
| UseCase | `xxx_usecase.dart` | `class XxxUseCase`、公開メソッドは `call()` のみ |
| DataSource | `xxx_data_source.dart` | `class XxxDataSource` |
| ViewModelの状態 | `xxx_state.dart` | `@freezed class XxxState` |
| ViewModel | `xxx_view_model.dart` | `@riverpod class XxxViewModel extends _$XxxViewModel` |
| View | `view/xxx_screen.dart` | `class XxxScreen` |

Riverpod Providerは自動生成される `xxxProvider`（関数/クラス名 + `Provider`）をそのまま使い、手動でProviderをラップしたり別名を付けたりしない。

## 4. `Result<T>` / `AppException` の使い分け（`lib/core/result.dart` 参照）

- **ネットワーク境界を持つRepository（例: `ClientRepository`）のみ** `Future<Result<T>>` を返す。ローカル永続化のみ（`SharedPreferences`等）で失敗しても実害が小さいRepository（例: `ClientSessionRepository`/`BackendRepository`）は `Result` でラップせず、素の戻り値・素の例外でよい。この非対称性は意図的。
- 具象例外（`ApiException`等）から`AppException`への変換は **Data層のRepository実装（`xxx_repository_impl.dart`）でのみ** 行う。DataSource層は具象例外をそのままthrowしてよい。UseCase層はRepositoryが返した`Result`をそのまま右から左に返すだけで、変換ロジックを持たない。
- Presentation層（ViewModel）で`switch`文によるパターンマッチ（`Ok(:final value) => ..., Err(:final error) => ...`）を行い、UI状態（Stateのフィールド）に変換する。Viewや画面Widgetに`AppException`や`Result`型を直接渡さない。
- `AppException`は3種類（`ApiFailure`/`NetworkException`/`UnknownException`）。`ApiException`（Data層の具象例外）は`ApiFailure`に、`TimeoutException`/`http.ClientException`（実際の通信断・タイムアウト）は`NetworkException`に、それ以外の想定外の失敗（JSONパース失敗等）は`UnknownException`に変換する。`catch (_) { return NetworkException(); }` のようにすべての例外を一括で`NetworkException`に丸めない。

## 5. Riverpod / Freezed のコード生成規約

- Provider・freezedクラスを含むファイルの先頭には必ず `part 'xxx.g.dart';`（Riverpod）や `part 'xxx.freezed.dart';`（freezed。両方使う場合は両方）を書く。
- 生成ファイル（`*.g.dart`/`*.freezed.dart`）は**直接編集しない**（`.claude/settings.json` のPreToolUseフックで編集がガードされている）。生成対象のソース（`@riverpod`/`@freezed`が付いたファイル）を変更したら、必ず以下を実行して再生成する:

  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

- `@riverpod` はトップレベル関数（シンプルな依存性提供、例: DataSource/Repositoryのprovider）か、`@riverpod class Xxx extends _$Xxx`（状態を持つViewModel）のどちらかで使う。
- 外部リソース（`http.Client`等）を自ら生成するDataSourceは、`close()`メソッドを持たせ、対応するProviderで `ref.onDispose(dataSource.close)` を登録する（`ClientRemoteDataSource`/`clientRemoteDataSourceProvider` 参照）。

## 6. UDF（単方向データフロー）の原則と意図的なレイヤー越え（2例のみ）

View → (ユーザー操作) → ViewModel → UseCase → Repository → DataSource → (外部境界) → 結果が同じ経路を逆向きに戻り、ViewModelがStateを更新 → Viewが再描画される。ViewModelは`BuildContext`を持たず、`showDialog`等のUI表示処理を直接呼ばない（エラーはStateのフィールドにセットし、Viewが`ref.listen`等で検知して表示する）。

エラーダイアログを`ref.listen`で表示する際は、**`errorMessage`が実際に変化した場合のみ**表示する（`previous?.errorMessage != next.errorMessage` を確認する）。単に`next.errorMessage != null`だけを条件にすると、`isLoading`等の無関係な状態変化のたびにリスナーが再度発火し、同一エラーのダイアログが二重に表示される。

例外として、以下の2つの**意図的な**レイヤー越えを許容する（新たに層を飛び越す実装を追加する場合は、この2例に倣い、コード上のコメントで理由を明記すること。安易に例外を増やさない）:

- `DeepLinkDataSource`（ディープリンク購読）は、UseCaseを介さず ViewModel から直接呼ぶ。
- `PlatformActionsDataSource`（Clipboard/Share）は、ViewModelを介さず View から直接呼ぶ。

いずれも「外部プラットフォーム機能のハンドルそのもの」であり、ビジネスロジックを含まないための例外。

## 7. テスト方針（層ごと）

| 層 | 配置 | 方法 |
|---|---|---|
| Domain（UseCase） | `test/domain/` | モックライブラリは使わず、Repositoryインターフェースを実装した手書きのFakeクラスを注入して検証する |
| Data（DataSource/RepositoryImpl） | `test/data/` | `http.Client` を `package:http/testing.dart` の `MockClient` に差し替える。永続化系は `SharedPreferences.setMockInitialValues({})` を使う。バックエンド無応答のケースは固定`sleep`ではなく `package:fake_async` の`fakeAsync`で仮想時間を進めて検証する |
| Presentation（ViewModel） | `test/ui/` | `ProviderContainer(overrides: [...])` でUseCase群をフェイク実装に差し替えて状態遷移を検証する |
| View（Widget） | `test/ui/<feature>/` | 画面Widgetを直接インスタンス化し、コールバックをspy（呼び出し記録用の関数）に差し替えて検証する（モックライブラリ不使用）。ViewがRiverpod Providerを参照する場合（`ConsumerWidget`/`ConsumerStatefulWidget`）は、`pumpWidget`に直接渡す引数の中で`ProviderScope`を組み立てる（Widgetを返すだけの別関数に切り出すと、riverpod_lintの`scoped_providers_should_specify_dependencies`がfalse-positiveで警告することがある） |

外部通信を伴う処理には必ずタイムアウトを設定し（`ClientRemoteDataSource`の`_timeout`参照）、無応答時にUIが無期限のローディング状態のままにならないことをテストで検証する。

## 8. 新機能を追加する際の実装順序

新しい機能（例:「新しいAPIエンドポイントを呼んで結果を画面に表示する」）を追加する際は、以下の順序で実装する:

1. **Domain**: 必要であればEntityを追加 → Repositoryインターフェースにメソッドを追加/新設 → UseCaseを追加（1クラス1責務）
2. **Data**: DataSourceにメソッドを追加/新設 → RepositoryImplで具象例外を`AppException`に変換する処理を実装 → `@riverpod` providerを追加
3. **Presentation**: State（freezed）にフィールドを追加 → ViewModelにUseCase呼び出しとStateの更新処理を追加 → Viewでの表示・コールバック接続
4. 各層に対応するテストを追加（7. テスト方針を参照）
5. `dart run build_runner build --delete-conflicting-outputs` を実行し、生成が通ることを確認
6. `dart format --set-exit-if-changed .` / `flutter analyze` / `flutter test` がすべて通ることを確認

## 9. SKILL.md執筆時の検証チェックリスト

本ファイル、および `git-workflow` Skillにコマンド例を追加・変更する場合は、コミット前に以下を確認する（実際に動かして初めて判明する不具合を防ぐため）:

- プレースホルダー構文（`<N>` のような山括弧）をシェルコマンドに直書きしない。シェルからリダイレクトと誤解釈される。変数（例: `$ISSUE_NUMBER`）や別の記法（例: `{issue_number}`）に置き換える。
- 複数のbashコードブロックに分けて手順を書く場合、**各コードブロックは独立したプロセスとして実行され、変数は次のブロックに引き継がれない**ことを前提に書く。1つの操作は1つのコードブロック内で完結させる。
- `echo "$JSON" | jq ...` のように、本文に埋め込まれたJSON文字列をパイプで渡す書き方は、エスケープが原因でパースエラーになることがある。ヒアドキュメント（`jq ... <<'EOF'`）かファイル経由（`jq ... file.json`）で渡す書き方に置き換える。
- `gh run list` はデフォルトで最大20件しか返さない。全件を扱う必要がある手順では `--limit` を明示する。
- 複数のSkillを並行して整備・変更する場合、**一方のSkillが禁止する操作を別のSkillが推奨していないか**を実装前に相互チェックする。
- コミットする前に、埋め込んだコマンド例は `bash -n` コマンド（または該当部分を一時ファイルに書き出して）構文チェックし、可能な範囲でダミーデータを使ってロジックも検証してから確定させる。
