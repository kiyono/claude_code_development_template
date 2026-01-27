# {PROJECT_NAME}

{PROJECT_DESCRIPTION}

## Overview

本テンプレートは **AI（Claude Code）による開発を前提とした** Python/FastAPI プロジェクトのテンプレートです。

Claude Code が効率的に開発を行うための設定（commands, agents, skills, hooks）が組み込まれており、高品質なコードを自動的に生成・維持できます。

## Features

- **AI 開発最適化**: Claude Code 用の commands, agents, skills, hooks
- **クリーンアーキテクチャ**: Robert C. Martin の原則に従った設計
- **TDD（テスト駆動開発）**: Red-Green-Refactor サイクル
- **95% テストカバレッジ必須**: 品質担保
- **静的解析**: ruff, mypy による型チェック
- **自動品質チェック**: コミット時の自動検証

## Tech Stack

| カテゴリ | 技術 |
|---------|------|
| 言語 | Python 3.11+ |
| Web フレームワーク | FastAPI |
| パッケージ管理 | uv |
| リンター | ruff |
| 型チェック | mypy |
| テスト | pytest |
| ロギング | structlog |

---

## Quick Start

### 1. テンプレートのセットアップ

```bash
# 1. リポジトリをクローン
git clone {REPOSITORY_URL}
cd {PROJECT_NAME}

# 2. プレースホルダーを置換
# 以下のファイル内の {PROJECT_NAME}, {PROJECT_DESCRIPTION} 等を置換:
# - README.md
# - .claude/CLAUDE.md
# - pyproject.toml
# - docs/ 内のファイル

# 3. 依存関係インストール
uv sync --all-extras

# 4. 環境変数設定
cp env.example .env

# 5. 動作確認
uv run pytest
```

### 2. Claude Code で開発開始

```bash
# Claude Code を起動
claude

# TDD で新機能を実装
/tdd AnswerUseCase を実装してください

# コードレビュー
/code-review

# テスト実行
/test

# リント実行
/lint
```

---

## AI 開発（Claude Code）

### 利用可能な Commands

| コマンド | 用途 | タイミング |
|---------|------|-----------|
| `/tdd` | TDD ワークフローを開始 | 新機能実装時 |
| `/lint` | ruff + mypy を実行 | コード変更後 |
| `/test` | pytest を実行 | 実装完了後 |
| `/code-review` | コードレビューを実行 | コミット前 |
| `/fix-document` | ドキュメント整合性チェック | PR 作成前 |

### 利用可能な Agents

| エージェント | 専門性 | 自動起動条件 |
|-------------|--------|-------------|
| **code-reviewer** | コード品質、セキュリティ | コード変更後 |
| **tdd-guide** | テスト駆動開発 | 新機能、バグ修正時 |
| **planner** | 実装計画 | 複雑な機能実装時 |
| **architect** | システム設計 | アーキテクチャ変更時 |
| **security-reviewer** | セキュリティ | 認証、入力処理変更時 |

### 自動実行 Hooks

| タイミング | 動作 |
|-----------|------|
| `git commit` 前 | ruff, mypy, pytest を自動実行（失敗時ブロック） |
| `git push` 前 | カバレッジチェック |
| Python ファイル編集後 | ruff, mypy を自動実行 |
| セッション終了時 | 変更ファイルの最終監査 |

### 使用例

```
# 新機能を TDD で実装
/tdd DocumentRepository に find_by_tag メソッドを追加してください

# 複雑な機能は計画から
この機能の実装計画を作成してください：
- ユーザー認証機能
- JWT を使用

# コードレビュー
/code-review 今回の変更をレビューしてください

# PR 前のドキュメントチェック
/fix-document
```

詳細は [docs/development.md](docs/development.md) を参照。

---

## Development

### 日常の開発コマンド

```bash
# フォーマット
uv run ruff format src/ tests/

# リント
uv run ruff check src/ tests/ --fix

# 型チェック
uv run mypy src/

# テスト
uv run pytest

# カバレッジ付きテスト
uv run pytest --cov=src --cov-fail-under=95

# 全チェック
make all

# 開発サーバー起動
uv run uvicorn src.main:app --reload
```

### Makefile コマンド

| コマンド | 説明 |
|---------|------|
| `make install` | 依存関係インストール |
| `make format` | フォーマット実行 |
| `make lint` | リント実行 |
| `make typecheck` | 型チェック実行 |
| `make test` | テスト実行 |
| `make coverage` | カバレッジ付きテスト |
| `make all` | 全チェック実行 |
| `make run` | 開発サーバー起動 |

---

## Project Structure

```
{project_name}/
├── src/
│   ├── domain/           # ドメイン層（Entities）
│   │   ├── entities/     # エンティティ
│   │   └── repositories/ # Repository interface
│   ├── application/      # アプリケーション層（Use Cases）
│   ├── infrastructure/   # インフラ層（Frameworks & Drivers）
│   │   ├── database/     # DB 実装
│   │   └── external/     # 外部サービス
│   └── presentation/     # プレゼンテーション層（FastAPI）
│       └── api/          # API routes
├── tests/
│   ├── conftest.py       # 共通 fixtures
│   ├── unit/             # 単体テスト
│   ├── integration/      # 統合テスト
│   └── e2e/              # E2E テスト
├── docs/
│   ├── development.md    # 開発環境セットアップ & AI 開発ガイド
│   └── rules/            # コーディングルール
├── .claude/              # Claude Code 設定
│   ├── CLAUDE.md         # プロジェクト固有の指示
│   ├── settings.local.json
│   ├── hooks.json
│   ├── commands/         # スラッシュコマンド
│   ├── rules/            # 自動適用ルール
│   ├── agents/           # 専門エージェント
│   └── skills/           # 詳細ワークフロー
├── .env.example
├── .gitignore
├── pyproject.toml
├── Makefile
└── README.md
```

### アーキテクチャ（依存方向）

```
Presentation → Application → Domain ← Infrastructure
                   ↓
              Domain (interface)
                   ↑
              Infrastructure (実装)

依存方向: 外側 → 内側のみ
```

---

## Claude Code Configuration

`.claude/` ディレクトリに含まれる設定:

| ディレクトリ/ファイル | 内容 |
|---------------------|------|
| `CLAUDE.md` | プロジェクト固有の指示（最重要） |
| `settings.local.json` | 許可されたコマンド |
| `hooks.json` | 自動実行フック |
| `commands/` | スラッシュコマンド（/tdd, /lint, /test, /code-review） |
| `rules/` | 自動適用ルール（コーディングスタイル、セキュリティ等） |
| `agents/` | 専門エージェント（コードレビュー、TDD ガイド等） |
| `skills/` | スキル（ドキュメント整合性チェック等） |

---

## Documentation

| ドキュメント | 内容 |
|------------|------|
| [.claude/CLAUDE.md](.claude/CLAUDE.md) | Claude Code プロジェクト設定 |
| [docs/development.md](docs/development.md) | 開発環境セットアップ & AI 開発ガイド |
| [docs/rules/clean_architecture.md](docs/rules/clean_architecture.md) | クリーンアーキテクチャ |
| [docs/rules/tdd.md](docs/rules/tdd.md) | TDD |
| [docs/rules/python_standards.md](docs/rules/python_standards.md) | Python コーディング標準 |

---

## プレースホルダー一覧

テンプレート使用時に置換が必要なプレースホルダー:

| プレースホルダー | 説明 | 対象ファイル |
|----------------|------|-------------|
| `{PROJECT_NAME}` | プロジェクト名 | README.md, CLAUDE.md |
| `{PROJECT_DESCRIPTION}` | プロジェクト説明 | README.md, CLAUDE.md, pyproject.toml |
| `{PROJECT_PURPOSE}` | プロジェクト目的 | CLAUDE.md |
| `{REPOSITORY_URL}` | リポジトリ URL | README.md |
| `{project-name}` | パッケージ名（kebab-case） | pyproject.toml |
| `{project_name}` | ディレクトリ名（snake_case） | docs 内 |

---

## License

MIT License
