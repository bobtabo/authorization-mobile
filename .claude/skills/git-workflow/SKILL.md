---
name: git-workflow
description: authorization-mobile のブランチ運用・PR運用・コミットメッセージ規約。新しい作業を始める、ブランチを作る、コミットする、PRを作成する、PRのCI/レビュー対応をする、Issueをクローズする、developをmainにリリースする、といったgit操作の前に必ず参照する。
---

# Git-Flow 規約

このリポジトリのブランチ運用・PR運用・コミットメッセージ規約をまとめたリファレンス。誰が・どのセッションでgit操作を行っても同じ運用になることを目的とする。曖昧な裁量を残さず、断定的に書く。

## 1. 通常のIssue対応のブランチ運用（これが標準。特別な指示がない限りこれに従う）

- ブランチは `develop` から作成する。名前は `feature/issue-<Issue番号>`（Issue番号は対応するGitHub Issueの番号と一致させる）。
- 実装が完了したら `develop` を base branch としたPRを作成する。PRタイトルは `<type>(#<Issue番号>): <日本語の要約>`。PR本文には `Closes #<Issue番号>` を含める（後述の注意点はあるが、トレーサビリティのため記載は必須）。
- 例外的に、複数Issueにまたがる大きな作業のために別途「統合ブランチ」を使う指示があった場合のみ、`develop` の代わりにその統合ブランチを起点・マージ先にする。この判断はユーザーからの明示的な指示がある場合に限り、Claude Codeが自発的に統合ブランチを作らないこと。

## 2. `develop` → `main` のリリースPR

- `develop` の変更を `main` に反映する際は、`develop` を head、`main` を base としたPRを作成する。PRタイトルは `release: developの変更をmainに反映`。
- このリリースPRを作成・マージするタイミングは、都度ユーザーからの明示的な指示があった場合のみとする（Claude Codeが自動的に判断してリリースPRを作らないこと）。

## 3. レビュー監視・対応（CI/CodeRabbit）

PRを作成した後、マージ可能な状態になるまで以下の手順で監視・対応する。ユーザーから明示的にこの監視・対応を指示された場合に行う（PR作成だけを指示された場合はここまで自発的に進めない）。

### 3-1. CI完了を待つ

**前提（重要）**: `.github/workflows/ci.yml` は `pull_request: branches: [main]` かつ `push: branches-ignore: ['feature/issue-*']` の構成になっている。そのため `feature/issue-<Issue番号>` → `develop` という通常のIssue対応PRでは、**GitHub ActionsのCIはPR上で一度も実行されない**（`develop` へのマージ後、pushトリガーで初めて実行される）。CIが実際にPR上で実行されるのは `develop` → `main` のリリースPR（2章）の場合のみ。この前提差をこの章の手順に反映せず「CIを待つ」とだけ書くと、通常のIssue対応PRでは待っても何も現れず手順が成立しない。

- 通常のIssue対応PR（`feature/issue-N` → `develop`）: PR上のCIチェックは存在しない。代わりに、PR作成前にローカルで `dart format --set-exit-if-changed .` / `flutter analyze` / `flutter test` がすべて通ることを確認しておく（これが実質的なゲート）。
- リリースPR（`develop` → `main`）: 以下の通りPR上のCI完了を待つ。

固定の `sleep` でブロックしない。バックグラウンド実行かポーリングで、全チェックが完了するまで待つ。

```bash
gh pr checks $PR_NUMBER --repo bobtabo/authorization-mobile --watch
```

`--watch` が使えない環境や途中経過を都度確認したい場合は、以下のように個別にポーリングする（1回ごとに独立したコマンドとして実行してよい。前回の結果を変数に持ち越す必要はない）。

```bash
gh pr checks $PR_NUMBER --repo bobtabo/authorization-mobile
```

いずれかのチェックが `FAIL`/`ERROR`/`CANCELLED` になっていたら、ログを確認して原因を報告する（`gh run view $RUN_ID --log-failed` 等）。すべて `PASS`/成功になるまで次のステップに進まない。

### 3-2. 未返信のCodeRabbitコメントを抽出する

CodeRabbitのコメントは2種類の経路で付く。どちらも確認する。

1. **レビュー本文にまとめられたコメント**（GitHubへのインラインコメント投稿が失敗した場合に本文へ集約される。実際にこのリポジトリで繰り返し発生している）。CodeRabbitのレビューは `author.login` が `coderabbitai`（`[bot]` サフィックスは付かない。`gh pr view --json reviews/comments` で実際に確認済み）。

   ```bash
   gh pr view $PR_NUMBER --repo bobtabo/authorization-mobile --json reviews \
     --jq '[.reviews[] | select(.author.login == "coderabbitai")] | last | .body' \
     > /tmp/coderabbit_latest_review.txt
   ```

   `.reviews[-1]` のように単純に「最後のレビュー」を取ると、間に人間のレビューが挟まった場合にCodeRabbit以外のレビューを拾ってしまう。必ず `author.login == "coderabbitai"` で絞り込んでから最後の1件を取る。

   本文を取得したら、「Actionable comments」「Outside diff range comments」「Nitpick comments」の各項目を1件ずつ確認する。JSON本文をシェルへ直接パイプで渡すと本文中のバッククォートやダブルクォートのエスケープが原因で `jq` がパースエラーになることがあるため、`--jq` フィルタで必要なフィールドだけを抽出するか、いったんファイルに保存してから `jq` にかける（上記コマンドはファイル出力済み）。

2. **行に直接付いたインラインコメント**（投稿が成功した場合。1と両方存在することもある）。`pulls/comments` エンドポイントから一覧を取得する。

   **注意**: このエンドポイントは `gh api`（REST API）で直接叩くため、`gh pr view --json`（GraphQL経由、ログイン名から `[bot]` サフィックスが除かれる）とは異なり、ボットのユーザー名に `[bot]` サフィックスが付く（`coderabbitai[bot]`。実データで確認済み）。また一覧系エンドポイントは既定で1ページ目（最大30件）しか返らないため `--paginate` を付ける。`--paginate` は `--jq` と併用する場合 `--slurp` を同時指定できない（実行して確認済みのエラー）ため、`--jq` 側は配列でまとめず `.[] | ...` の形で1件ずつ出力し、ページをまたいで結果を連結する。

   ```bash
   gh api --paginate repos/bobtabo/authorization-mobile/pulls/$PR_NUMBER/comments \
     --jq '.[] | select(.user.login == "coderabbitai[bot]") | .id' > /tmp/coderabbit_comment_ids.txt
   ```

   **`in_reply_to_id` による未返信判定の限界**: 理屈の上では、全コメントの `in_reply_to_id` の集合を取り、上記のCodeRabbitコメントIDのうち集合に含まれないものが「誰からもスレッド内で返信されていない」コメントになる。

   ```bash
   gh api --paginate repos/bobtabo/authorization-mobile/pulls/$PR_NUMBER/comments \
     --jq '.[] | .in_reply_to_id | select(. != null)' > /tmp/all_reply_to_ids.txt
   ```

   ただし、このリポジトリの実際の運用（3-3参照）はインラインコメントへのスレッド返信ではなく、**PRへのトップレベルコメント1件で対応内容をまとめて返信する**方式であるため、上記の突き合わせをすると実際には対応済みのコメントも「未返信」として検出される（実際に検証済み）。したがって、この差分（`coderabbit_comment_ids.txt` の一覧）は「見落としがないかの確認用リスト」として使い、実際に対応済みかどうかは3-3のトップレベル返信コメントの内容と突き合わせて人間/Claude Codeが判断する。未対応かどうかの最終判定は本節の差分ではなく、3-5の収束条件（新規actionableコメントが0件、かつ `mergeable` が `MERGEABLE`、かつ `mergeStateStatus` が `CLEAN`）で行う。

### 3-3. 指摘を検証し、修正して返信する

抽出した指摘を1件ずつ、現在のコードに対してまだ妥当か確認する（コード側で既に別の理由で解消されている場合や、意図的な設計判断と衝突する場合は、対応しない理由を明確にした上で見送ってよい）。妥当な指摘は修正してpushし、対応内容をPRにコメントで返信する。

```bash
# FILES には実際に修正したファイルパスをスペース区切りで指定する
git add $FILES
git commit -m "fix: CodeRabbitの指摘に対応（#$ISSUE_NUMBER）"
git push origin $BRANCH_NAME
```

対応内容の返信は、指摘ごとに何を直した/見送ったかが分かるように書く（「対応しました」だけで終わらせない）。

### 3-4. 自動レビューが一時停止している場合の再トリガー

新しいコミットをpushした後、CodeRabbitの自動レビューが `reviews paused` の状態で止まっている場合のみ、以下のコメントを投稿して再開させる。

```bash
gh pr comment $PR_NUMBER --repo bobtabo/authorization-mobile --body "@coderabbitai review"
```

自動レビューが既に走っている（一時停止していない）場合、このコマンドは "Already reviewed" のように応答するだけで何も起こらない。これは仕様通りであり、異常ではない。PR全体をゼロから再評価させたい場合は代わりに `@coderabbitai full review` を投稿する。

### 3-5. 収束条件と打ち切り目安

以下の両方を満たしたら収束とみなし、監視・対応ループを終了する。

- 新規のactionableコメントが0件（3-2の抽出結果が空、または既にすべて返信済み）
- 以下のコマンドの結果が `mergeable: MERGEABLE` かつ `mergeStateStatus: CLEAN`

```bash
gh pr view $PR_NUMBER --repo bobtabo/authorization-mobile --json mergeable,mergeStateStatus
```

3-1〜3-4の往復が5ラウンド前後で収束しない場合は、無限ループを避けるためユーザーに状況を報告し、判断を仰ぐ（Claude Codeが自律的に往復を続けない）。

この章はあくまで「PRをマージ可能な状態にする」ところまでが対象であり、`develop` へのマージそのものは「1. 通常のIssue対応のブランチ運用」の方針通り、ユーザーからの明示的な指示があるまで行わない。

## 4. コミットメッセージ規約

- 形式は `<type>(#<Issue番号>): <日本語の要約>`。`type` は Conventional Commits 由来で、少なくとも `feat`（新機能）/`fix`（バグ修正）/`refactor`（挙動を変えないコード変更）/`docs`（ドキュメントのみ）/`chore`（ビルド・設定・雑務）/`test`（テストのみ）/`style`（フォーマットのみ）を使い分ける。
- Issue番号に紐付かない変更（例: 単純なタイポ修正）の場合は `(#<Issue番号>)` を省略してよい。

## 5. マージ方法

- PRのマージは常に通常のマージコミット（GitHubの「Create a merge commit」、`gh pr merge --merge`）を使う。squash・rebaseマージは使わない（各コミットの意図を保持し、`git log --oneline` でIssue単位の作業が追えるようにするため）。
- マージ後、head branchが `feature/issue-<N>` の場合は削除してよい（`gh pr merge --delete-branch` 等）。統合ブランチ自体は明示的な指示があるまで削除しない。

## 6. Issueのクローズについての重要な注意（このリポジトリ特有の落とし穴）

- このリポジトリのデフォルトブランチは `main` である。GitHubの `Closes #N` によるIssue自動クローズは、**PRがデフォルトブランチ（`main`）にマージされた場合にのみ発動する**。
- 通常のIssue対応PRは `develop` にマージされる（`main` ではない）ため、PR本文に `Closes #N` と書いても**自動クローズされない**。マージ後は以下のように**手動でクローズすること**。

```bash
gh issue close $ISSUE_NUMBER --repo bobtabo/authorization-mobile --comment "PR #$PR_NUMBER をマージしました"
```

- `develop` → `main` のリリースPRがマージされた時点で初めて自動クローズが有効な状況になるが、その時点でリリースPRの `Closes` キーワードがどのIssueを指すかは通常書かれていない（リリースPRは複数Issueの集合のため）ので、結局これも当てにしない。**Issueのクローズは、対応するIssue PRがマージされた直後に毎回手動で行う運用とする**。

## 7. pushの権限に関する注意

`.github/workflows/*.yml` を変更するPRをpushするには、GitHub CLI (`gh`) のOAuthトークンに `workflow` スコープが必要（`repo` スコープだけでは `refusing to allow an OAuth App to create or update workflow` エラーで拒否される）。スコープが不足している場合は以下でブラウザ経由の認可が必要になる（この操作はユーザーによるブラウザ操作が必須で、Claude Codeが代行できない）。

```bash
gh auth refresh -h github.com -s workflow
```

## 8. SKILL.md執筆時の検証チェックリスト

本ファイル、および `mvvm-clean-architecture` Skillにコマンド例を追加・変更する場合は、コミット前に以下を確認する（実際に動かして初めて判明する不具合を防ぐため）:

- プレースホルダー構文（`<N>` のような山括弧）をシェルコマンドに直書きしない。シェルからリダイレクトと誤解釈される。本ファイルでは `$ISSUE_NUMBER`/`$PR_NUMBER`/`$BRANCH_NAME` のような変数名で統一している。
- 複数のbashコードブロックに分けて手順を書く場合、**各コードブロックは独立したプロセスとして実行され、変数は次のブロックに引き継がれない**ことを前提に書く。1つの操作は1つのコードブロック内で完結させる。
- `echo "$JSON" | jq ...` のように、本文に埋め込まれたJSON文字列をパイプで渡す書き方は、エスケープが原因でパースエラーになることがある。ヒアドキュメントかファイル経由で渡す書き方に置き換える。
- `gh run list` はデフォルトで最大20件しか返さない。全件を扱う必要がある手順では `--limit` を明示する。
- 複数のSkillを並行して整備・変更する場合、**一方のSkillが禁止する操作を別のSkillが推奨していないか**を実装前に相互チェックする（本Skillと `mvvm-clean-architecture` Skillの間に矛盾がないことを確認済み）。
- コミットする前に、埋め込んだコマンド例は `bash -n` コマンド（または該当部分を一時ファイルに書き出して）構文チェックし、可能な範囲でダミーデータを使ってロジックも検証してから確定させる。
