---
description: TDD（テスト駆動開発）ワークフローを実行。テストを先に書き、実装、リファクタリングの順で進める。
---

# TDD Command

Red → Green → Refactor サイクルでコードを実装する。

## ワークフロー

### Step 1: インターフェース定義

```python
from __future__ import annotations

from abc import ABC, abstractmethod

class DocumentRepository(ABC):
    @abstractmethod
    async def save(self, document: Document) -> None:
        """ドキュメントを保存する."""
        ...
```

### Step 2: 失敗するテストを書く（RED）

```python
import pytest
from unittest.mock import AsyncMock

class TestAnswerUseCase:
    async def test_execute_returns_answer_with_citations(self):
        # Arrange
        mock_repo = AsyncMock()
        mock_repo.find_by_ids.return_value = [Document(...)]
        usecase = AnswerUseCase(mock_repo, ...)

        # Act
        answer = await usecase.execute("質問")

        # Assert
        assert answer.content is not None
        assert len(answer.citations) > 0
```

### Step 3: テスト実行 - 失敗を確認

```bash
uv run pytest tests/unit/application/test_answer_usecase.py -v
```

### Step 4: 最小限の実装（GREEN）

```python
class AnswerUseCase:
    async def execute(self, question: str) -> Answer:
        # 最小限の実装
        documents = await self._document_repo.find_by_ids([...])
        return Answer(content="回答", citations=[...])
```

### Step 5: テスト実行 - 成功を確認

```bash
uv run pytest tests/unit/application/test_answer_usecase.py -v
```

### Step 6: リファクタリング（REFACTOR）

テストを維持しながらコードを改善。

### Step 7: カバレッジ確認

```bash
uv run pytest --cov=src --cov-report=term-missing --cov-fail-under=95
```

## チェックリスト

- [ ] テストを先に書いた
- [ ] テストが失敗することを確認した
- [ ] 最小限の実装でテストを通した
- [ ] リファクタリングした
- [ ] カバレッジ 95% 以上を達成した
- [ ] ruff, mypy がパスする

## 注意

- **絶対にテストを書く前に実装しない**
- エッジケース（None, 空, 境界値）をテストに含める
- 実装詳細ではなく振る舞いをテストする
