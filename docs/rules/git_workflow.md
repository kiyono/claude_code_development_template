# Git Workflow

本プロジェクトの Git 運用ルール。

---

## 1. コミットメッセージ

### 1.1 フォーマット（Conventional Commits）

```
<type>: <description>

<optional body>
```

### 1.2 Type 一覧

| Type | 用途 | 例 |
|------|------|-----|
| `feat` | 新機能追加 | `feat: ユーザー認証機能を追加` |
| `fix` | バグ修正 | `fix: ログイン時のエラーを修正` |
| `refactor` | リファクタリング（機能変更なし） | `refactor: DocumentRepository を分割` |
| `docs` | ドキュメントのみの変更 | `docs: README に環境構築手順を追加` |
| `test` | テストの追加・修正 | `test: AnswerUseCase のテストを追加` |
| `chore` | ビルド、CI、設定などの変更 | `chore: GitHub Actions を設定` |
| `perf` | パフォーマンス改善 | `perf: クエリを最適化` |
| `ci` | CI/CD 関連の変更 | `ci: テストカバレッジレポートを追加` |

### 1.3 コミットメッセージの書き方

**良い例:**

```
feat: AnswerUseCase を実装

- 質問をベクトル化
- Top-K 検索で関連ドキュメントを取得
- LLM で回答を生成
```

```
fix: 検索結果が空の場合のエラーを修正

検索結果が0件の場合にIndexErrorが発生していた問題を修正。
空の場合は空のリストを返すように変更。
```

**悪い例:**

```
# NG: type がない
ユーザー認証機能を追加

# NG: 曖昧な説明
fix: バグ修正

# NG: 英語と日本語が混在（統一すること）
feat: Add user authentication
```

---

## 2. ブランチ戦略

### 2.1 ブランチ構成

```
main                    # 本番環境（直接コミット禁止）
  └── feature/xxx       # 新機能開発
  └── fix/xxx           # バグ修正
  └── refactor/xxx      # リファクタリング
  └── docs/xxx          # ドキュメント更新
```

### 2.2 ブランチ命名規則

| 種類 | 形式 | 例 |
|------|------|-----|
| 新機能 | `feature/<機能名>` | `feature/user-authentication` |
| バグ修正 | `fix/<issue番号または説明>` | `fix/login-error` |
| リファクタリング | `refactor/<対象>` | `refactor/document-repository` |
| ドキュメント | `docs/<内容>` | `docs/setup-guide` |

### 2.3 ルール

- **main への直接コミット禁止**
- **PR（Pull Request）必須**
- **レビュー必須**

---

## 3. Pre-commit チェック

コミット時に以下が自動実行される（全てパス必須）:

| 順序 | チェック | コマンド |
|------|----------|---------|
| 1 | フォーマット | `ruff format --check` |
| 2 | リント | `ruff check` |
| 3 | 型チェック | `mypy` |
| 4 | テスト | `pytest` |

### 3.1 チェックに失敗した場合

```bash
# フォーマットエラーの場合
uv run ruff format src/ tests/

# リントエラーの場合
uv run ruff check src/ tests/ --fix

# 型エラーの場合
# エラーメッセージを確認し、型ヒントを修正

# テスト失敗の場合
# 失敗したテストを確認し、コードまたはテストを修正
```

---

## 4. Pull Request ワークフロー

### 4.1 PR 作成手順

1. 機能ブランチを作成

   ```bash
   git checkout -b feature/new-feature
   ```

2. 実装・コミット

   ```bash
   git add <files>
   git commit -m "feat: 新機能を実装"
   ```

3. リモートにプッシュ

   ```bash
   git push -u origin feature/new-feature
   ```

4. GitHub で PR を作成

### 4.2 PR の内容

- **タイトル**: 簡潔に変更内容を記述（70文字以内）
- **説明**: 変更の背景、内容、テスト方法を記載

```markdown
## Summary
- ユーザー認証機能を追加
- JWT トークンによる認証を実装

## Test plan
- [ ] 正常系: 有効な認証情報でログイン成功
- [ ] 異常系: 無効な認証情報でエラー
- [ ] 異常系: トークン期限切れでエラー
```

### 4.3 マージ条件

- [ ] 全ての CI チェックがパス
- [ ] レビュー承認を取得
- [ ] コンフリクトなし

---

## 5. 機能実装ワークフロー

### 5.1 推奨フロー

1. **計画** - 実装計画を作成（複雑な機能の場合）
2. **ブランチ作成** - `feature/xxx` ブランチを作成
3. **TDD** - テストを先に書いて実装
4. **コードレビュー** - レビューを実施
5. **コミット** - Conventional Commits でコミット
6. **PR 作成** - GitHub で PR を作成
7. **レビュー対応** - 指摘事項を修正
8. **マージ** - 承認後にマージ

### 5.2 コミットの粒度

- **1 コミット = 1 論理的な変更**
- 大きすぎるコミットは分割する
- 関連のない変更は別コミットにする

---

## 6. 禁止事項

| 禁止事項 | 理由 |
|---------|------|
| `git push --force` | 履歴破壊のリスク |
| `git reset --hard` (共有ブランチ) | 他者の変更を破壊 |
| main への直接プッシュ | レビュープロセスのバイパス |
| 機密情報のコミット | セキュリティリスク |

---

## 7. よくある操作

### 7.1 直前のコミットメッセージを修正

```bash
git commit --amend -m "fix: 正しいメッセージ"
```

### 7.2 コミット前の変更を取り消し

```bash
# ステージングを取り消し
git restore --staged <file>

# 変更を破棄
git restore <file>
```

### 7.3 ブランチを最新の main に追従

```bash
git checkout main
git pull
git checkout feature/xxx
git rebase main
```

### 7.4 コンフリクトの解消

```bash
# コンフリクトを解消後
git add <resolved-files>
git rebase --continue
```

---

## 8. 参考資料

- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Flow](https://docs.github.com/en/get-started/quickstart/github-flow)
