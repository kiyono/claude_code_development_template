# 開発環境セットアップ

本プロジェクトの開発環境構築手順。

---

## 1. 前提条件

| ツール | バージョン | 用途 |
|--------|-----------|------|
| Python | 3.11+ | 実行環境 |
| uv | 最新 | パッケージ管理・実行 |
| Docker | 最新 | インフラ（必要に応じて） |
| Docker Compose | v2+ | コンテナオーケストレーション |

---

## 2. Python 実行環境

### 2.1 uv を使用（venv 不要）

**本プロジェクトでは uv を使用するため、仮想環境（venv, virtualenv, conda 等）の手動作成は不要。**

uv が自動的に `.venv` を管理する。

#### uv のインストール

```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Homebrew
brew install uv

# pip（非推奨）
pip install uv
```

#### 依存関係のインストール

```bash
# 依存関係をインストール（.venv が自動作成される）
uv sync

# 開発依存を含む
uv sync --all-extras
```

#### スクリプト実行

```bash
# uv run で実行（自動的に .venv を使用）
uv run python src/main.py

# uv run pytest
uv run pytest

# uv run でコマンド実行
uv run ruff check src/
uv run mypy src/
```

### 2.2 禁止事項

| 禁止 | 理由 |
|------|------|
| `python -m venv .venv` | uv が管理 |
| `virtualenv` | uv が管理 |
| `conda` | uv に統一 |
| `pip install` 直接実行 | `uv sync` を使用 |

### 2.3 新しいパッケージの追加

```bash
# 本番依存を追加
uv add fastapi

# 開発依存を追加
uv add --dev pytest

# バージョン指定
uv add "pydantic>=2.6.0"
```

pyproject.toml が自動更新される。

---

## 3. 開発ワークフロー

### 3.1 初回セットアップ

```bash
# 1. リポジトリをクローン
git clone <repository-url>
cd {project_name}

# 2. uv で依存関係をインストール
uv sync --all-extras

# 3. 環境変数を設定
cp env.example env
# env を編集

# 4. 動作確認
uv run pytest
```

### 3.2 日常の開発

```bash
# コード変更後
uv run ruff format src/ tests/
uv run ruff check src/ tests/ --fix
uv run mypy src/
uv run pytest

# アプリケーション起動
uv run uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

### 3.3 Makefile

```makefile
.PHONY: install lint format typecheck test coverage run clean all

# 依存関係インストール
install:
	uv sync --all-extras

# リント
lint:
	uv run ruff check src/ tests/

# フォーマット
format:
	uv run ruff format src/ tests/
	uv run ruff check src/ tests/ --fix

# 型チェック
typecheck:
	uv run mypy src/

# テスト
test:
	uv run pytest

# カバレッジ
coverage:
	uv run pytest --cov=src --cov-report=term-missing --cov-fail-under=95

# アプリケーション起動
run:
	uv run uvicorn src.main:app --reload --host 0.0.0.0 --port 8000

# クリーンアップ
clean:
	rm -rf .venv .mypy_cache .pytest_cache .ruff_cache .coverage htmlcov

# 全チェック
all: format lint typecheck coverage
```

---

## 4. ディレクトリ構成（データ）

```
{project_name}/
├── data/                    # 永続化データ（gitignore）
├── env                     # 環境変数（gitignore）
├── env.example             # 環境変数テンプレート
└── ...
```

---

## 5. 環境変数

### 5.1 env.example

```bash
# 環境
ENV=development  # development | production

# サーバー
HOST=0.0.0.0
PORT=8000

# 必要に応じて追加
# DATABASE_URL=...
# API_KEY=...
```

---

## 6. トラブルシューティング

### 6.1 uv が見つからない

```bash
# パスを通す
export PATH="$HOME/.cargo/bin:$PATH"

# または再インストール
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### 6.2 ポートが競合

```bash
# 使用中のポートを確認
lsof -i :8000

# プロセスを停止
kill -9 <PID>
```

### 6.3 依存関係の問題

```bash
# ロックファイルを再生成
uv lock --upgrade

# .venv を削除して再作成
rm -rf .venv
uv sync --all-extras
```

---

## 7. AI 開発（Claude Code）

本プロジェクトは Claude Code による AI 開発を前提としている。以下に AI 開発の手法と tips を記載する。

### 7.1 Claude Code 設定ディレクトリ

```
.claude/
├── CLAUDE.md              # プロジェクト固有の指示（最重要）
├── settings.local.json    # 許可されたコマンド
├── hooks.json             # 自動実行フック
├── commands/              # スラッシュコマンド
├── rules/                 # 自動適用ルール
├── agents/                # 専門エージェント定義
└── skills/                # 詳細なワークフロー
```

### 7.2 Commands（スラッシュコマンド）の使い方

スラッシュコマンドは Claude Code に特定のワークフローを実行させるショートカット。

#### 利用可能なコマンド

| コマンド | 用途 | タイミング |
|---------|------|-----------|
| `/tdd` | TDD ワークフローを開始 | 新機能実装時 |
| `/lint` | ruff + mypy を実行 | コード変更後 |
| `/test` | pytest を実行 | 実装完了後 |
| `/code-review` | コードレビューを実行 | コミット前 |

#### 使用例

```
# TDD で新機能を実装
/tdd AnswerUseCase を実装してください

# コードレビュー
/code-review 今回の変更をレビューしてください

# リント実行
/lint

# テスト実行
/test
```

#### コマンドの効果

コマンドを実行すると、`.claude/commands/` 内の対応するマークダウンファイルが読み込まれ、Claude Code がそのワークフローに従って動作する。

### 7.3 Agents（専門エージェント）の使い方

エージェントは特定の専門性を持つ Claude Code のペルソナ。Task ツールで起動される。

#### 利用可能なエージェント

| エージェント | 専門性 | 自動起動条件 |
|-------------|--------|-------------|
| **code-reviewer** | コード品質、セキュリティ | コード変更後 |
| **tdd-guide** | テスト駆動開発 | 新機能、バグ修正時 |
| **planner** | 実装計画 | 複雑な機能実装時 |
| **architect** | システム設計 | アーキテクチャ変更時 |
| **security-reviewer** | セキュリティ | 認証、入力処理変更時 |

#### エージェントの起動方法

エージェントは通常、Claude Code が必要に応じて自動的に起動する（PROACTIVELY）。

手動で起動する場合は、以下のように依頼する：

```
# コードレビューエージェントを起動
コードレビューを実行してください

# 実装計画エージェントを起動
この機能の実装計画を作成してください

# TDD ガイドエージェントを起動
TDD でこの機能を実装したいです
```

#### エージェントの特徴

- **planner**: 実装前に詳細な計画を作成。依存関係、リスク、フェーズ分けを提案
- **tdd-guide**: Red-Green-Refactor サイクルを強制。テストを書く前に実装させない
- **code-reviewer**: CRITICAL/HIGH/MEDIUM/LOW の問題を分類してレポート
- **security-reviewer**: OWASP Top 10 を含むセキュリティチェックを実施
- **architect**: クリーンアーキテクチャの原則に従った設計をレビュー

### 7.4 Skills（スキル）の使い方

スキルはより詳細なワークフローとベストプラクティスを提供する。

#### 利用可能なスキル

| スキル | 用途 | 起動方法 |
|-------|------|---------|
| `/fix-document` | PR 前のドキュメント整合性チェック | スラッシュコマンド |
| `tdd-workflow` | TDD の詳細手順 | 参照用 |
| `coding-standards` | コーディング標準 | 参照用 |
| `backend-patterns` | バックエンドパターン | 参照用 |
| `security-review` | セキュリティレビュー手順 | 参照用 |

#### /fix-document の使い方

PR マージ前にドキュメントの更新漏れをチェック：

```
/fix-document

# または引数付き
/fix-document 決済機能の追加に関するドキュメント確認
```

このスキルは以下を行う：
1. git diff で変更内容を分析
2. 仕様書（docs/specs/）の更新要否を判定
3. ADR（docs/adrs/）の作成要否を判定
4. ユーザーにヒアリングしながらドキュメントを更新

### 7.5 Hooks（自動実行フック）

Hooks は特定のアクション時に自動実行されるスクリプト。

#### 設定されているフック

**PreToolUse（ツール実行前）**

| トリガー | 動作 |
|---------|------|
| `git commit` | ruff format, ruff check, mypy, pytest を実行。失敗時はブロック |
| `git push` | カバレッジチェック（警告のみ） |
| Python ファイル作成 | `from __future__ import annotations` の欠如を警告 |

**PostToolUse（ツール実行後）**

| トリガー | 動作 |
|---------|------|
| Python ファイル編集 | ruff check, mypy を自動実行 |
| Python ファイル編集 | print() 文の使用を警告 |
| PR 作成 | PR URL をログ出力 |

**Stop（セッション終了時）**

| トリガー | 動作 |
|---------|------|
| セッション終了 | 変更された Python ファイルの最終監査 |

#### フックの効果

- コミット時に品質チェックを強制
- print() 文の混入を防止
- `from __future__ import annotations` の欠如を検出

---

## 8. AI 開発のベストプラクティス

### 8.1 効果的な指示の出し方

#### 具体的な指示を出す

```
# NG: 曖昧な指示
検索機能を作ってください

# OK: 具体的な指示
DocumentRepository に find_by_content メソッドを追加してください。
- 入力: 検索クエリ（文字列）
- 出力: マッチしたドキュメントのリスト
- 部分一致検索を実装
- TDD で実装
```

#### コンテキストを共有する

```
# 背景情報を提供
現在 src/domain/entities/document.py に Document エンティティがあります。
これに「タグ」機能を追加したいです。

要件：
- タグは複数付けられる
- タグで検索できる
- 既存のテストが壊れないように
```

#### 制約を明示する

```
# 制約を明確に
この機能を実装する際の制約：
- 既存の API 互換性を維持
- カバレッジ 95% 以上
- パフォーマンス劣化なし（O(n) 以下）
```

### 8.2 TDD ワークフローの活用

**必ず TDD で実装する：**

1. `/tdd` コマンドを使用
2. テストを先に書く
3. 最小限の実装でテストを通す
4. リファクタリング
5. カバレッジ確認

```
/tdd AnswerUseCase を実装してください

# Claude Code は以下の順序で実装する：
# 1. テストファイルを作成
# 2. 失敗するテストを書く
# 3. テスト実行（RED）
# 4. 最小限の実装
# 5. テスト実行（GREEN）
# 6. リファクタリング
# 7. カバレッジ確認
```

### 8.3 コードレビューの活用

**コミット前に必ずレビュー：**

```
/code-review

# Claude Code は以下をチェック：
# - CRITICAL: セキュリティ問題
# - HIGH: 型ヒント欠如、アーキテクチャ違反
# - MEDIUM: テスト不足
# - LOW: ベストプラクティス違反
```

### 8.4 計画的な実装

**複雑な機能は計画から：**

```
この機能の実装計画を作成してください：
- ユーザー認証機能
- JWT を使用
- リフレッシュトークン対応

# planner エージェントが以下を作成：
# - フェーズ分け（Domain → Application → Infrastructure → Presentation）
# - 各ステップの詳細
# - 依存関係
# - リスクと軽減策
# - テスト戦略
```

### 8.5 セキュリティレビューの活用

**認証・入力処理後は必ず：**

```
セキュリティレビューを実行してください

# security-reviewer エージェントがチェック：
# - ハードコードされた秘密情報
# - SQL インジェクション
# - パストラバーサル
# - 入力バリデーション
# - 認証・認可
```

---

## 9. AI 開発のアンチパターン

### 9.1 避けるべきパターン

| アンチパターン | 問題点 | 対策 |
|--------------|--------|------|
| **曖昧な指示** | 期待と異なる実装 | 具体的な要件を明示 |
| **テスト後付け** | TDD の原則違反 | `/tdd` コマンドを使用 |
| **レビューなしコミット** | 品質低下 | `/code-review` を実行 |
| **計画なし実装** | 手戻り発生 | planner エージェントを使用 |
| **print() デバッグ** | 本番混入リスク | structlog を使用 |

### 9.2 よくある失敗と対処法

#### テストが先に書かれない

```
# Claude Code が実装を先に始めた場合
「テストを先に書いてください。TDD で進めます」と指示

# または最初から明示
/tdd TDD でこの機能を実装してください
```

#### アーキテクチャ違反

```
# Domain 層に外部依存が入った場合
「Domain 層は外部ライブラリに依存できません。
 インターフェースを定義して Infrastructure 層で実装してください」
```

#### カバレッジ不足

```
# カバレッジが 95% 未満の場合
「カバレッジが 95% 未満です。以下のケースのテストを追加してください：
 - エッジケース（null, 空）
 - エラーケース
 - 境界値」
```

---

## 10. セッション管理

### 10.1 長時間セッション

Claude Code のコンテキストには限界がある。以下を心がける：

- **1 機能 = 1 セッション** を目安に
- 複雑な機能は計画を先に作成し、フェーズごとにセッションを分ける
- セッション終了前に作業状況を確認

### 10.2 引き継ぎ

セッションをまたぐ場合：

```
# セッション終了前
現在の作業状況をまとめてください：
- 完了したタスク
- 未完了のタスク
- 次にやるべきこと

# 新セッション開始時
前回のセッションで以下を実装しました：
[前回のまとめを貼り付け]

続きから作業してください。
```

### 10.3 コンテキストの節約

```
# 大量のコードを読ませない
「src/application/ 以下のファイル構成を確認してください」
（全ファイルを読ませるより効率的）

# 必要な情報のみ共有
「このエラーを修正してください：
 [エラーメッセージのみ貼り付け]」
```

---

## 11. トラブルシューティング（AI 開発）

### 11.1 フックがブロックする

```
# コミット時にブロックされた場合
[Hook] BLOCKED: Code is not formatted.

# 対処
uv run ruff format src/ tests/
uv run ruff check src/ tests/ --fix
# その後再度コミット
```

### 11.2 エージェントが期待通り動かない

```
# より具体的に指示
「code-reviewer エージェントとして、以下のファイルをレビューしてください：
 - src/application/answer_usecase.py

 特に以下をチェック：
 - 型ヒントの完全性
 - エラーハンドリング」
```

### 11.3 TDD サイクルが崩れる

```
# 実装が先に進んでしまった場合
「一度実装を消して、テストから書き直してください。
 TDD の RED-GREEN-REFACTOR サイクルで進めます」
```

### 11.4 コンテキストが足りない

```
# Claude Code が既存コードを把握していない場合
「まず以下のファイルを確認してください：
 - src/domain/entities/document.py
 - src/domain/repositories/document_repository.py

 確認後、新しいメソッドを追加します」
```

---

## 12. 参考資料

- [uv Documentation](https://docs.astral.sh/uv/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [pytest Documentation](https://docs.pytest.org/)
- [ruff Documentation](https://docs.astral.sh/ruff/)
- [mypy Documentation](https://mypy.readthedocs.io/)
- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
