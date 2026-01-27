---
description: コードレビューを実行。セキュリティ、コード品質、ベストプラクティスをチェック。
---

# Code Review Command

変更されたファイルの包括的なレビューを実行する。

## レビュー手順

### 1. 変更ファイルの取得

```bash
git diff --name-only HEAD
```

### 2. チェック項目

#### セキュリティ（CRITICAL）

- [ ] ハードコードされた認証情報、API キー
- [ ] SQL インジェクション脆弱性
- [ ] パストラバーサルリスク
- [ ] 入力バリデーションの欠如
- [ ] 機密情報のログ出力

#### Python コード品質（HIGH）

- [ ] `from __future__ import annotations` の欠如
- [ ] 型ヒントの欠如
- [ ] Docstring の欠如（公開関数/クラス）
- [ ] 関数が 50 行超
- [ ] ファイルが 800 行超
- [ ] ネスト深度 4 以上
- [ ] print() 文の使用
- [ ] エラーハンドリングの欠如

#### アーキテクチャ（HIGH）

- [ ] クリーンアーキテクチャ違反
  - domain 層が外部ライブラリに依存
  - application 層が infrastructure に直接依存
  - presentation 層にビジネスロジック
- [ ] 循環参照
- [ ] 不適切なレイヤー配置

#### テスト（MEDIUM）

- [ ] 新規コードにテストがない
- [ ] テストカバレッジ 95% 未満
- [ ] テストが実装詳細に依存

#### ベストプラクティス（LOW）

- [ ] TODO/FIXME コメント
- [ ] 未使用の import
- [ ] マジックナンバー

### 3. 静的解析の実行

```bash
# ruff チェック
uv run ruff check src/ tests/

# mypy チェック
uv run mypy src/

# カバレッジチェック
uv run pytest --cov=src --cov-fail-under=95
```

### 4. レポート生成

```markdown
## Code Review Report

### CRITICAL Issues
- なし

### HIGH Issues
- src/application/answer_usecase.py:45 - 型ヒントが欠如

### MEDIUM Issues
- tests/unit/test_document.py - エッジケースのテストが不足

### Recommendations
- ...
```

## 自動チェック

以下は自動的にチェックされる:

- `ruff check` - リント
- `ruff format --check` - フォーマット
- `mypy --strict` - 型チェック
- `pytest --cov` - テストとカバレッジ

## コミット可否

- **CRITICAL / HIGH** がある場合: コミット不可
- **MEDIUM** のみ: 修正推奨だがコミット可
- **LOW** のみ: コミット可
