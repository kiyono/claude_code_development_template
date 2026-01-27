---
description: テスト要件（TDD、カバレッジ95%、テスト構成）
globs:
  - "tests/**/*.py"
  - "**/test_*.py"
  - "**/*_test.py"
alwaysApply: false
---

# Testing Requirements

## 最低テストカバレッジ: 95%

テストタイプ（全て必須）:
1. **単体テスト** - 個々の関数、ユーティリティ、クラス
2. **統合テスト** - API エンドポイント、データベース操作
3. **E2E テスト** - クリティカルなユーザーフロー

## TDD（テスト駆動開発）

**必須**ワークフロー:
1. テストを先に書く（RED）
2. テスト実行 - 失敗することを確認
3. 最小限の実装を書く（GREEN）
4. テスト実行 - 成功することを確認
5. リファクタリング（REFACTOR）
6. カバレッジ確認（95%+）

## テスト構成

```
tests/
├── conftest.py          # 共通 fixtures
├── unit/                # 単体テスト
│   ├── domain/
│   ├── application/
│   └── infrastructure/
├── integration/         # 統合テスト
└── e2e/                 # E2E テスト
```

## テストの書き方

```python
import pytest
from unittest.mock import AsyncMock

class TestAnswerUseCase:
    @pytest.fixture
    def mock_deps(self):
        return {
            "document_repo": AsyncMock(),
            "vector_repo": AsyncMock(),
            "embedder": Mock(),
            "llm": Mock(),
        }

    async def test_execute_returns_answer_with_citations(self, mock_deps):
        # Arrange
        mock_deps["vector_repo"].search.return_value = ["doc_1"]
        mock_deps["document_repo"].find_by_ids.return_value = [Document(...)]
        mock_deps["llm"].generate.return_value = "回答"
        usecase = AnswerUseCase(**mock_deps)

        # Act
        answer = await usecase.execute("質問")

        # Assert
        assert answer.content == "回答"
        assert len(answer.citations) == 1
```

## テスト失敗時のトラブルシューティング

1. **tdd-guide** エージェントを使用
2. テストの独立性を確認
3. Mock が正しいか確認
4. 実装を修正（テストが間違っていない限り）

## エージェントサポート

- **tdd-guide** - 新機能で PROACTIVELY に使用、テストファーストを強制
- **code-reviewer** - コードレビューでテストカバレッジを確認

## 実行コマンド

```bash
# 全テスト
uv run pytest

# カバレッジ付き
uv run pytest --cov=src --cov-fail-under=95

# 特定のテスト
uv run pytest tests/unit/application/test_answer_usecase.py -v
```
