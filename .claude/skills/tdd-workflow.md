---
name: tdd-workflow
description: Python/pytest による TDD ワークフロー。新機能、バグ修正、リファクタリング時に使用。95%+ カバレッジ必須。
---

# TDD ワークフロー (Python/pytest)

## 起動条件

- 新機能の実装時
- バグ修正時
- リファクタリング時
- API エンドポイント追加時
- UseCase/Repository 追加時

## 基本原則

### 1. テストファースト
**必ず**テストを先に書き、実装はテストを通すために行う。

### 2. カバレッジ要件
- 最低 95% カバレッジ（単体 + 統合 + E2E）
- 全エッジケースをカバー
- エラーシナリオをテスト
- 境界条件を検証

### 3. テストの種類

| 種類 | 対象 | ツール |
|------|------|--------|
| 単体テスト | UseCase, Entity, Utility | pytest + Mock |
| 統合テスト | Repository, API | pytest + TestClient |
| E2E テスト | 重要なユーザーフロー | pytest + httpx |

## TDD サイクル

### Step 1: RED - 失敗するテストを書く

```python
# tests/unit/application/test_answer_usecase.py
import pytest
from unittest.mock import AsyncMock, Mock

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
        """質問に対して引用付きの回答を返す"""
        # Arrange
        mock_deps["embedder"].embed.return_value = [[0.1] * 1024]
        mock_deps["vector_repo"].search.return_value = ["doc_1"]
        mock_deps["document_repo"].find_by_ids.return_value = [
            Document(id="doc_1", content="関連情報")
        ]
        mock_deps["llm"].generate.return_value = "回答です"

        usecase = AnswerUseCase(**mock_deps)

        # Act
        answer = await usecase.execute("質問")

        # Assert
        assert answer.content == "回答です"
        assert len(answer.citations) == 1

    async def test_execute_returns_unknown_when_no_similar_docs(self, mock_deps):
        """類似ドキュメントがない場合は不明と回答"""
        # Arrange
        mock_deps["embedder"].embed.return_value = [[0.1] * 1024]
        mock_deps["vector_repo"].search.return_value = []

        usecase = AnswerUseCase(**mock_deps)

        # Act
        answer = await usecase.execute("存在しない情報")

        # Assert
        assert "不明" in answer.content
```

### Step 2: テスト実行 - 失敗を確認

```bash
uv run pytest tests/unit/application/test_answer_usecase.py -v
# FAILED - Not implemented
```

### Step 3: GREEN - 最小限の実装

```python
# src/application/answer_usecase.py
from __future__ import annotations

from dataclasses import dataclass

from src.domain.entities import Answer, Citation


@dataclass(frozen=True)
class AnswerUseCase:
    document_repo: DocumentRepository
    vector_repo: VectorRepository
    embedder: Embedder
    llm: LLM

    async def execute(self, question: str) -> Answer:
        """質問に回答する."""
        query_vector = self._embedder.embed([question])[0]
        doc_ids = await self._vector_repo.search(query_vector, top_k=5)

        if not doc_ids:
            return Answer(content="不明です", citations=[])

        documents = await self._document_repo.find_by_ids(doc_ids)
        prompt = self._build_prompt(question, documents)
        response = self._llm.generate(prompt)

        return Answer(
            content=response,
            citations=[Citation(doc) for doc in documents],
        )
```

### Step 4: テスト実行 - 成功を確認

```bash
uv run pytest tests/unit/application/test_answer_usecase.py -v
# PASSED
```

### Step 5: REFACTOR - コード改善

テストを維持しながらコード品質を改善：
- 重複排除
- 命名改善
- パフォーマンス最適化

### Step 6: カバレッジ確認

```bash
uv run pytest --cov=src --cov-report=term-missing --cov-fail-under=95
```

## テストパターン

### 単体テスト (pytest)

```python
# tests/unit/domain/test_document.py
from __future__ import annotations

import pytest

from src.domain.entities import Document


class TestDocument:
    def test_create_with_valid_data(self):
        """有効なデータでドキュメントを作成できる"""
        doc = Document(id="1", content="テスト内容", source="test.pdf")

        assert doc.id == "1"
        assert doc.content == "テスト内容"
        assert doc.source == "test.pdf"

    def test_content_cannot_be_empty(self):
        """空のコンテンツは許可されない"""
        with pytest.raises(ValueError, match="content cannot be empty"):
            Document(id="1", content="", source="test.pdf")

    @pytest.mark.parametrize(
        "content,expected_length",
        [
            ("短い", 2),
            ("これは長いコンテンツです", 12),
        ],
    )
    def test_content_length(self, content: str, expected_length: int):
        """コンテンツの長さを正しく計算"""
        doc = Document(id="1", content=content, source="test.pdf")
        assert doc.content_length == expected_length
```

### 統合テスト (FastAPI TestClient)

```python
# tests/integration/test_webhook.py
from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from src.main import app


@pytest.fixture
def client():
    return TestClient(app)


class TestWebhookEndpoint:
    def test_webhook_returns_answer(self, client: TestClient):
        """Webhook が回答を返す"""
        response = client.post(
            "/webhook",
            json={"message": "質問", "is_mention": True},
        )

        assert response.status_code == 200
        data = response.json()
        assert "content" in data

    def test_webhook_ignores_non_mention(self, client: TestClient):
        """メンションなしは無視"""
        response = client.post(
            "/webhook",
            json={"message": "質問", "is_mention": False},
        )

        assert response.status_code == 200
        assert response.json()["content"] is None

    def test_webhook_validates_input(self, client: TestClient):
        """無効な入力を拒否"""
        response = client.post(
            "/webhook",
            json={"invalid": "data"},
        )

        assert response.status_code == 422
```

### E2E テスト

```python
# tests/e2e/test_search_flow.py
from __future__ import annotations

import pytest
import httpx


@pytest.mark.e2e
class TestSearchFlow:
    async def test_user_can_search_and_get_answer(self):
        """ユーザーが検索して回答を取得できる"""
        async with httpx.AsyncClient(base_url="http://localhost:8000") as client:
            # 質問を送信
            response = await client.post(
                "/webhook",
                json={"message": "RAG とは何ですか？", "is_mention": True},
            )

            assert response.status_code == 200
            data = response.json()
            assert data["content"] is not None
            assert len(data["citations"]) > 0
```

## Mock パターン

### Repository Mock

```python
@pytest.fixture
def mock_document_repo():
    repo = AsyncMock(spec=DocumentRepository)
    repo.find_by_ids.return_value = [
        Document(id="1", content="テスト", source="test.pdf")
    ]
    return repo
```

### 外部サービス Mock

```python
@pytest.fixture
def mock_llm():
    llm = Mock(spec=LLM)
    llm.generate.return_value = "生成された回答"
    return llm


@pytest.fixture
def mock_embedder():
    embedder = Mock(spec=Embedder)
    embedder.embed.return_value = [[0.1] * 1024]
    return embedder
```

## テストディレクトリ構成

```
tests/
├── conftest.py              # 共通 fixture
├── unit/                    # 単体テスト
│   ├── domain/
│   │   └── test_document.py
│   └── application/
│       └── test_answer_usecase.py
├── integration/             # 統合テスト
│   ├── test_webhook.py
│   └── test_repository.py
└── e2e/                     # E2E テスト
    └── test_search_flow.py
```

## pytest 設定

```toml
# pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
markers = [
    "unit: Unit tests",
    "integration: Integration tests",
    "e2e: End-to-end tests",
]
addopts = "-v --tb=short"

[tool.coverage.run]
source = ["src"]
branch = true

[tool.coverage.report]
fail_under = 95
show_missing = true
exclude_lines = [
    "pragma: no cover",
    "if TYPE_CHECKING:",
    "raise NotImplementedError",
]
```

## 避けるべきアンチパターン

### NG: 実装詳細をテスト

```python
# DON'T: 内部状態をテスト
assert usecase._internal_state == expected
```

### OK: 振る舞いをテスト

```python
# DO: 結果をテスト
assert answer.content == expected
```

### NG: テスト間の依存

```python
# DON'T: テストが前のテストに依存
def test_create_user(): ...
def test_update_same_user(): ...  # 前のテストに依存
```

### OK: テストの独立

```python
# DO: 各テストが独立
def test_create_user():
    user = create_test_user()
    ...

def test_update_user():
    user = create_test_user()  # 独自にセットアップ
    ...
```

## コマンド一覧

```bash
# 全テスト実行
uv run pytest

# 単体テストのみ
uv run pytest tests/unit/ -v

# 統合テストのみ
uv run pytest tests/integration/ -v

# カバレッジ付き
uv run pytest --cov=src --cov-report=term-missing --cov-fail-under=95

# 特定のテスト
uv run pytest tests/unit/application/test_answer_usecase.py -v

# Watch モード（pytest-watch）
uv run ptw
```

---

**重要**: テストなしのコードは存在しない。TDD サイクルは RED → GREEN → REFACTOR。
