# {PROJECT_NAME} - Claude Code Project

{PROJECT_DESCRIPTION}

**本プロジェクトは全て AI（Claude Code）による開発を前提としています。**

---

## Project Overview

- **目的**: {PROJECT_PURPOSE}
- **技術スタック**: Python 3.11+, FastAPI
- **設計原則**: クリーンアーキテクチャ, TDD

## Critical Rules

### 1. Python コーディング標準

```python
# 全ファイルの先頭に必須
from __future__ import annotations
```

- **uv** でパッケージ管理（pip 直接実行禁止）
- **ruff** でリント・フォーマット
- **mypy --strict** で型チェック
- **pytest** でテスト（カバレッジ 95% 必須）
- **Google Docstring** スタイル

### 2. コード品質

- print() 禁止（structlog を使用）
- 200-400 行/ファイルを目安、800 行以下
- 関数は 50 行以下
- ネスト深度 4 以下

### 3. アーキテクチャ

クリーンアーキテクチャを厳守:

```
domain/          # Entities（外部依存なし）
application/     # Use Cases
infrastructure/  # Frameworks & Drivers
presentation/    # Interface Adapters（FastAPI）
```

依存方向: **外側 → 内側のみ**

### 4. TDD

Red → Green → Refactor サイクルを厳守:

1. 失敗するテストを書く
2. 最小限の実装でテストを通す
3. リファクタリング

### 5. Git Workflow

- Conventional Commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`
- コミット前に必ず: ruff, mypy, pytest を実行
- PR 必須（main への直接コミット禁止）

## File Structure

```
src/
├── domain/           # ドメイン層
│   ├── entities/     # エンティティ
│   └── repositories/ # Repository interface
├── application/      # アプリケーション層
│   └── *_usecase.py  # ユースケース
├── infrastructure/   # インフラ層
│   ├── database/     # DB 実装
│   └── external/     # 外部サービス
└── presentation/     # プレゼンテーション層
    └── api/          # FastAPI routes
```

## Commands

```bash
# 依存関係インストール
uv sync --all-extras

# 開発サーバー起動
uv run uvicorn src.main:app --reload

# リント・フォーマット
uv run ruff format src/ tests/
uv run ruff check src/ tests/ --fix

# 型チェック
uv run mypy src/

# テスト
uv run pytest
uv run pytest --cov=src --cov-fail-under=95
```

## Environment Variables

```bash
# .env
ENV=development
# 必要に応じて追加
```

## Pre-commit Hooks

コミット前に自動実行:

1. `ruff format --check` - フォーマットチェック
2. `ruff check` - リントチェック
3. `mypy` - 型チェック
4. `pytest` - テスト実行

## Documentation

- [docs/development.md](docs/development.md) - 開発環境セットアップ
- [docs/rules/](docs/rules/) - コーディングルール
  - clean_architecture.md
  - tdd.md
  - python_standards.md

## Claude Code Configuration

`.claude/` ディレクトリに Claude Code の設定を配置:

```
.claude/
├── settings.local.json   # 許可されたコマンド
├── hooks.json            # Pre-commit hooks
├── commands/             # カスタムコマンド
│   ├── tdd.md            # /tdd - TDD ワークフロー
│   ├── code-review.md    # /code-review - コードレビュー
│   ├── lint.md           # /lint - リント実行
│   └── test.md           # /test - テスト実行
├── rules/                # 自動適用ルール
│   ├── coding-style.md   # コーディングスタイル
│   ├── git-workflow.md   # Git ワークフロー
│   ├── security.md       # セキュリティ
│   ├── testing.md        # テスト
│   └── architecture.md   # アーキテクチャ
├── agents/               # 専門エージェント
│   ├── code-reviewer.md  # コードレビューア
│   ├── planner.md        # 実装計画
│   ├── tdd-guide.md      # TDD ガイド
│   ├── architect.md      # アーキテクト
│   └── security-reviewer.md  # セキュリティレビュー
└── skills/               # スキル
    └── fix-document/     # ドキュメント整合性チェック
```

### Skills の使い方

Skills は詳細なワークフローとベストプラクティスを提供:

- **/fix-document**: PR マージ前のドキュメント整合性チェック
