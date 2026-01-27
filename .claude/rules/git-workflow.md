---
description: Git ワークフロー（コミットメッセージ、PR、ブランチ戦略）
alwaysApply: true
---

# Git Workflow

## コミットメッセージフォーマット

```
<type>: <description>

<optional body>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci

例:
```
feat: AnswerUseCase を実装

- 質問をベクトル化
- Top-K 検索
- LLM で回答生成
```

## Pre-commit チェック（自動実行）

コミット前に以下が自動実行される:

1. `ruff format --check` - フォーマットチェック
2. `ruff check` - リントチェック
3. `mypy` - 型チェック
4. `pytest` - テスト実行

**全てパスしないとコミット不可**

## Pull Request ワークフロー

PR 作成時:
1. 全コミット履歴を分析（最新だけでなく全て）
2. `git diff [base-branch]...HEAD` で全変更を確認
3. 包括的な PR サマリーを作成
4. テストプランを含める
5. 新規ブランチなら `-u` フラグでプッシュ

## 機能実装ワークフロー

1. **計画を先に**
   - **planner** エージェントで実装計画を作成
   - 依存関係とリスクを特定
   - フェーズに分解

2. **TDD アプローチ**
   - **tdd-guide** エージェントを使用
   - テストを先に書く（RED）
   - テストを通す実装（GREEN）
   - リファクタリング（REFACTOR）
   - カバレッジ 95%+ を確認

3. **コードレビュー**
   - コード記述後すぐに **code-reviewer** エージェントを使用
   - CRITICAL と HIGH の問題を対処
   - 可能なら MEDIUM も修正

4. **コミット & プッシュ**
   - 詳細なコミットメッセージ
   - Conventional Commits フォーマットに従う

## ブランチ戦略

```
main
  └── feature/xxx
  └── fix/xxx
  └── refactor/xxx
```

- main への直接コミット禁止
- PR 必須
- レビュー必須
