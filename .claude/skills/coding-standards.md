---
name: coding-standards
description: Python コーディング標準とベストプラクティス。型ヒント、docstring、命名規則、コード品質のガイドライン。
---

# Python コーディング標準

全プロジェクト共通の Python コーディング標準。

## 基本原則

### 1. 可読性優先
- コードは書くより読まれる回数が多い
- 明確な変数名・関数名
- コメントより自己文書化コード
- 一貫したフォーマット

### 2. KISS (Keep It Simple, Stupid)
- 動く最もシンプルな解決策
- 過剰エンジニアリングを避ける
- 早すぎる最適化をしない
- 理解しやすいコード > 賢いコード

### 3. DRY (Don't Repeat Yourself)
- 共通ロジックを関数に抽出
- 再利用可能なコンポーネントを作成
- コピペプログラミングを避ける

### 4. YAGNI (You Aren't Gonna Need It)
- 必要になる前に機能を作らない
- 推測的な汎用化を避ける
- 必要になったら複雑さを追加

## 必須ルール

### 1. Future Annotations

```python
# 全ファイルの先頭に必須
from __future__ import annotations
```

### 2. 型ヒント

```python
# OK: 全ての引数と戻り値に型ヒント
def process_document(
    doc_id: str,
    content: str,
    *,
    max_length: int = 1000,
) -> Document:
    ...


# OK: 複雑な型
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from collections.abc import Sequence


def process_documents(
    documents: Sequence[Document],
) -> list[ProcessedDocument]:
    ...


# NG: 型ヒントなし
def process_document(doc_id, content, max_length=1000):
    ...
```

### 3. Docstring (Google スタイル)

```python
def search_documents(
    query: str,
    *,
    top_k: int = 10,
    threshold: float = 0.5,
) -> list[SearchResult]:
    """ドキュメントをセマンティック検索する.

    クエリをベクトル化し、類似度が閾値以上のドキュメントを返す。

    Args:
        query: 検索クエリ文字列
        top_k: 返す最大件数
        threshold: 類似度の閾値 (0.0-1.0)

    Returns:
        類似度順にソートされた検索結果のリスト

    Raises:
        ValueError: query が空の場合
        ExternalServiceError: Embedding サービスが利用不可の場合

    Example:
        >>> results = search_documents("RAG とは", top_k=5)
        >>> print(results[0].content)
        'RAG は Retrieval-Augmented Generation の略で...'
    """
    ...
```

### 4. 不変パターン (frozen dataclass)

```python
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime


@dataclass(frozen=True)
class Document:
    """ドキュメントエンティティ.

    Attributes:
        id: ドキュメントの一意識別子
        content: ドキュメントの内容
        source: ソースファイルのパス
        created_at: 作成日時
    """

    id: str
    content: str
    source: str
    created_at: datetime

    def __post_init__(self) -> None:
        if not self.content:
            raise ValueError("content cannot be empty")


# OK: 新しいインスタンスを作成
from dataclasses import replace

updated_doc = replace(doc, content="新しい内容")

# NG: 直接変更
doc.content = "新しい内容"  # FrozenInstanceError
```

## 命名規則

### 変数名

```python
# OK: 説明的な名前
document_content = "..."
is_authenticated = True
total_count = 100
user_ids = ["1", "2", "3"]

# NG: 不明確な名前
d = "..."
flag = True
x = 100
lst = ["1", "2", "3"]
```

### 関数名

```python
# OK: 動詞-名詞パターン
async def fetch_document(doc_id: str) -> Document:
    ...

def calculate_similarity(a: list[float], b: list[float]) -> float:
    ...

def is_valid_email(email: str) -> bool:
    ...

# NG: 不明確または名詞のみ
async def document(id: str):
    ...

def similarity(a, b):
    ...
```

### クラス名

```python
# OK: PascalCase、名詞
class DocumentRepository:
    ...

class AnswerUseCase:
    ...

class SearchResult:
    ...

# NG: 不適切な命名
class document_repository:  # snake_case
    ...

class DoSearch:  # 動詞
    ...
```

### 定数

```python
# OK: UPPER_SNAKE_CASE
MAX_RETRIES = 3
DEFAULT_TIMEOUT_SECONDS = 30
EMBEDDING_DIMENSION = 1024
```

## エラーハンドリング

### OK: 包括的なエラーハンドリング

```python
async def fetch_data(url: str) -> dict:
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(url)
            response.raise_for_status()
            return response.json()
    except httpx.HTTPStatusError as e:
        logger.warning("HTTP error", status=e.response.status_code, url=url)
        raise ExternalServiceError(f"HTTP {e.response.status_code}") from e
    except httpx.RequestError as e:
        logger.error("Request failed", error=str(e), url=url)
        raise ExternalServiceError("Request failed") from e
```

### NG: エラーハンドリングなし

```python
async def fetch_data(url: str) -> dict:
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        return response.json()
```

## 非同期処理

### OK: 並列実行

```python
# 独立した処理は並列実行
results = await asyncio.gather(
    fetch_documents(),
    fetch_embeddings(),
    fetch_settings(),
)
```

### NG: 不必要な直列実行

```python
# 依存関係がないのに直列実行
documents = await fetch_documents()
embeddings = await fetch_embeddings()
settings = await fetch_settings()
```

## import の順序

```python
# 1. 標準ライブラリ
from __future__ import annotations

import asyncio
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING

# 2. サードパーティ
import structlog
from fastapi import APIRouter, Depends
from pydantic import BaseModel

# 3. ローカルアプリケーション
from src.domain.entities import Document
from src.domain.repositories import DocumentRepository

# 4. 型チェック専用
if TYPE_CHECKING:
    from collections.abc import Sequence
```

## コード臭の検出

### 1. 長い関数

```python
# NG: 関数が 50 行以上
def process_data():
    # 100 行のコード
    ...

# OK: 小さな関数に分割
def process_data():
    validated = validate_data()
    transformed = transform_data(validated)
    return save_data(transformed)
```

### 2. 深いネスト

```python
# NG: 4 レベル以上のネスト
if user:
    if user.is_admin:
        if document:
            if document.is_active:
                if has_permission:
                    # 処理
                    ...

# OK: 早期リターン
if not user:
    return
if not user.is_admin:
    return
if not document:
    return
if not document.is_active:
    return
if not has_permission:
    return

# 処理
```

### 3. マジックナンバー

```python
# NG: 説明なしの数値
if retry_count > 3:
    ...
await asyncio.sleep(0.5)

# OK: 名前付き定数
MAX_RETRIES = 3
RETRY_DELAY_SECONDS = 0.5

if retry_count > MAX_RETRIES:
    ...
await asyncio.sleep(RETRY_DELAY_SECONDS)
```

### 4. 重複コード

```python
# NG: コピペコード
def process_user(user):
    validate(user)
    transform(user)
    save(user)

def process_document(doc):
    validate(doc)
    transform(doc)
    save(doc)

# OK: 共通関数を抽出
def process_entity(entity, validator, transformer, saver):
    validator(entity)
    transformed = transformer(entity)
    saver(transformed)
```

## テスト命名

```python
# OK: 説明的なテスト名
def test_returns_empty_list_when_no_documents_match_query():
    ...

def test_raises_error_when_api_key_is_missing():
    ...

def test_falls_back_to_default_when_config_invalid():
    ...

# NG: 曖昧なテスト名
def test_works():
    ...

def test_search():
    ...
```

## ログ出力

```python
import structlog

logger = structlog.get_logger()

# OK: 構造化ログ
logger.info(
    "Document processed",
    doc_id=doc.id,
    source=doc.source,
    duration_ms=duration,
)

logger.error(
    "Processing failed",
    doc_id=doc.id,
    error=str(e),
    exc_info=True,
)

# NG: print 文
print(f"Processing document {doc.id}")  # 使用禁止
```

## 禁止事項

1. **print() 文の使用** - structlog を使用
2. **type: ignore の乱用** - 型を正しく定義
3. **any 型の使用** - 具体的な型を使用
4. **グローバル変数** - 依存性注入を使用
5. **TODO/FIXME コメント** - Issue で管理
6. **未使用の import** - ruff で自動削除
7. **ハードコードされた秘密** - 環境変数を使用

## ツール設定

### ruff

```toml
# pyproject.toml
[tool.ruff]
target-version = "py311"
line-length = 88

[tool.ruff.lint]
select = ["E", "F", "W", "I", "N", "UP", "B", "A", "C4", "PT", "RUF"]
ignore = ["E501"]

[tool.ruff.lint.isort]
known-first-party = ["src"]
```

### mypy

```toml
# pyproject.toml
[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_ignores = true
disallow_untyped_defs = true
```

### pytest

```toml
# pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
addopts = "-v --tb=short"

[tool.coverage.run]
source = ["src"]
branch = true

[tool.coverage.report]
fail_under = 95
```

## コマンド

```bash
# フォーマット
uv run ruff format src/ tests/

# リント
uv run ruff check src/ tests/

# リント（自動修正）
uv run ruff check --fix src/ tests/

# 型チェック
uv run mypy src/

# テスト
uv run pytest

# カバレッジ
uv run pytest --cov=src --cov-report=term-missing --cov-fail-under=95
```

---

**重要**: コード品質は妥協不可。明確で保守性の高いコードが、迅速な開発と安心なリファクタリングを可能にする。
