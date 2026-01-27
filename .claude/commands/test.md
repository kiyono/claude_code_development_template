---
description: pytest を実行してテストとカバレッジを確認。
---

# Test Command

テストを実行してカバレッジを確認する。

## 実行コマンド

```bash
# 全テスト実行
uv run pytest

# 詳細出力
uv run pytest -v

# 特定のテストファイル
uv run pytest tests/unit/application/test_answer_usecase.py

# 特定のテストケース
uv run pytest tests/unit/application/test_answer_usecase.py::TestAnswerUseCase::test_execute

# マーカー指定
uv run pytest -m unit
uv run pytest -m "not slow"

# カバレッジ付き
uv run pytest --cov=src --cov-report=term-missing

# カバレッジ 95% 必須
uv run pytest --cov=src --cov-fail-under=95

# HTML レポート
uv run pytest --cov=src --cov-report=html
```

## テストマーカー

```python
import pytest

@pytest.mark.unit
def test_document_creation():
    ...

@pytest.mark.integration
def test_repository_save():
    ...

@pytest.mark.e2e
def test_webhook_flow():
    ...

@pytest.mark.slow
def test_large_data_processing():
    ...
```

## カバレッジ要件

- **最低**: 95%
- **除外対象**:
  - `if TYPE_CHECKING:`
  - `@abstractmethod`
  - `raise NotImplementedError`
  - `pragma: no cover`

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

## Fixtures 例

```python
# tests/conftest.py
import pytest
from unittest.mock import AsyncMock, Mock

@pytest.fixture
def mock_document_repo():
    return AsyncMock(spec=DocumentRepository)

@pytest.fixture
def mock_embedder():
    embedder = Mock(spec=Embedder)
    embedder.embed.return_value = [[0.1] * 1024]
    return embedder
```

## 失敗時の対応

```bash
# 失敗したテストのみ再実行
uv run pytest --lf

# 最初の失敗で停止
uv run pytest -x

# デバッグ出力
uv run pytest -s

# pdb でデバッグ
uv run pytest --pdb
```
