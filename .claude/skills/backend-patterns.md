---
name: backend-patterns
description: Python/FastAPI/クリーンアーキテクチャのバックエンドパターン。API 設計、データベース最適化、サーバーサイドのベストプラクティス。
---

# バックエンドパターン (Python/FastAPI/クリーンアーキテクチャ)

スケーラブルなサーバーサイドアプリケーションのためのアーキテクチャパターンとベストプラクティス。

## API 設計パターン

### RESTful API 構造

```python
# src/presentation/api/router.py
from fastapi import APIRouter

router = APIRouter(prefix="/api/v1")

# リソースベースの URL
@router.get("/documents")                # リソース一覧
@router.get("/documents/{doc_id}")       # 単一リソース取得
@router.post("/documents")               # リソース作成
@router.put("/documents/{doc_id}")       # リソース置換
@router.patch("/documents/{doc_id}")     # リソース部分更新
@router.delete("/documents/{doc_id}")    # リソース削除

# クエリパラメータでフィルタリング、ソート、ページネーション
# GET /api/v1/documents?status=active&sort=created_at&limit=20&offset=0
```

### Repository パターン

```python
# src/domain/repositories/document_repository.py
from __future__ import annotations

from abc import ABC, abstractmethod
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from src.domain.entities import Document


class DocumentRepository(ABC):
    """ドキュメントリポジトリのインターフェース."""

    @abstractmethod
    async def find_all(
        self,
        *,
        status: str | None = None,
        limit: int = 100,
        offset: int = 0,
    ) -> list[Document]:
        """全ドキュメントを取得."""
        ...

    @abstractmethod
    async def find_by_id(self, doc_id: str) -> Document | None:
        """ID でドキュメントを取得."""
        ...

    @abstractmethod
    async def save(self, document: Document) -> Document:
        """ドキュメントを保存."""
        ...

    @abstractmethod
    async def delete(self, doc_id: str) -> None:
        """ドキュメントを削除."""
        ...
```

```python
# src/infrastructure/database/sqlite_document_repository.py
from __future__ import annotations

import sqlite3
from typing import TYPE_CHECKING

from src.domain.entities import Document
from src.domain.repositories import DocumentRepository

if TYPE_CHECKING:
    from pathlib import Path


class SQLiteDocumentRepository(DocumentRepository):
    """SQLite を使用した DocumentRepository 実装."""

    def __init__(self, db_path: Path) -> None:
        self._db_path = db_path

    async def find_all(
        self,
        *,
        status: str | None = None,
        limit: int = 100,
        offset: int = 0,
    ) -> list[Document]:
        with sqlite3.connect(self._db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()

            query = "SELECT * FROM documents"
            params: list = []

            if status:
                query += " WHERE status = ?"
                params.append(status)

            query += " LIMIT ? OFFSET ?"
            params.extend([limit, offset])

            cursor.execute(query, params)
            rows = cursor.fetchall()

            return [Document(**dict(row)) for row in rows]

    async def find_by_id(self, doc_id: str) -> Document | None:
        with sqlite3.connect(self._db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute(
                "SELECT * FROM documents WHERE id = ?",
                [doc_id],
            )
            row = cursor.fetchone()
            return Document(**dict(row)) if row else None

    # ... 他のメソッド
```

### UseCase パターン

```python
# src/application/answer_usecase.py
from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from src.domain.entities import Answer, Citation

if TYPE_CHECKING:
    from src.domain.repositories import DocumentRepository, VectorRepository
    from src.infrastructure.embedding import Embedder
    from src.infrastructure.llm import LLM


@dataclass(frozen=True)
class AnswerUseCase:
    """質問に回答する UseCase."""

    document_repo: DocumentRepository
    vector_repo: VectorRepository
    embedder: Embedder
    llm: LLM

    async def execute(self, question: str) -> Answer:
        """質問に対して回答を生成する.

        Args:
            question: ユーザーからの質問

        Returns:
            引用付きの回答
        """
        # 1. 質問をベクトル化
        query_vector = self.embedder.embed([question])[0]

        # 2. 類似ドキュメントを検索
        doc_ids = await self.vector_repo.search(query_vector, top_k=5)

        if not doc_ids:
            return Answer(
                content="申し訳ありませんが、関連する情報が見つかりませんでした。",
                citations=[],
            )

        # 3. ドキュメント取得
        documents = await self.document_repo.find_by_ids(doc_ids)

        # 4. プロンプト構築と回答生成
        prompt = self._build_prompt(question, documents)
        response = self.llm.generate(prompt)

        return Answer(
            content=response,
            citations=[Citation.from_document(doc) for doc in documents],
        )

    def _build_prompt(self, question: str, documents: list) -> str:
        context = "\n\n".join(doc.content for doc in documents)
        return f"""以下のコンテキストを参考に質問に回答してください。

コンテキスト:
{context}

質問: {question}

回答:"""
```

### 依存性注入パターン (FastAPI Depends)

```python
# src/presentation/api/dependencies.py
from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from fastapi import Depends

from src.application.answer_usecase import AnswerUseCase
from src.infrastructure.database.sqlite_document_repository import (
    SQLiteDocumentRepository,
)
from src.infrastructure.database.duckdb_vector_repository import (
    DuckDBVectorRepository,
)
from src.infrastructure.embedding.e5_embedder import E5Embedder
from src.infrastructure.llm.sakura_llm import SakuraLLM


@lru_cache
def get_document_repo() -> SQLiteDocumentRepository:
    return SQLiteDocumentRepository(Path("data/documents.db"))


@lru_cache
def get_vector_repo() -> DuckDBVectorRepository:
    return DuckDBVectorRepository(Path("data/vectors.duckdb"))


@lru_cache
def get_embedder() -> E5Embedder:
    return E5Embedder()


@lru_cache
def get_llm() -> SakuraLLM:
    return SakuraLLM()


def get_answer_usecase(
    document_repo: SQLiteDocumentRepository = Depends(get_document_repo),
    vector_repo: DuckDBVectorRepository = Depends(get_vector_repo),
    embedder: E5Embedder = Depends(get_embedder),
    llm: SakuraLLM = Depends(get_llm),
) -> AnswerUseCase:
    return AnswerUseCase(
        document_repo=document_repo,
        vector_repo=vector_repo,
        embedder=embedder,
        llm=llm,
    )
```

```python
# src/presentation/api/webhook.py
from __future__ import annotations

from fastapi import APIRouter, Depends

from src.application.answer_usecase import AnswerUseCase
from src.presentation.api.dependencies import get_answer_usecase
from src.presentation.api.schemas import WebhookRequest, WebhookResponse

router = APIRouter()


@router.post("/webhook", response_model=WebhookResponse)
async def webhook(
    request: WebhookRequest,
    answer_usecase: AnswerUseCase = Depends(get_answer_usecase),
) -> WebhookResponse:
    if not request.is_mention:
        return WebhookResponse(content=None, citations=[])

    answer = await answer_usecase.execute(request.message)

    return WebhookResponse(
        content=answer.content,
        citations=[c.to_dict() for c in answer.citations],
    )
```

## データベースパターン

### クエリ最適化

```python
# OK: 必要なカラムのみ選択
cursor.execute(
    "SELECT id, content, source FROM documents WHERE status = ? LIMIT ?",
    [status, limit],
)

# NG: 全カラム選択
cursor.execute("SELECT * FROM documents")
```

### N+1 クエリ防止

```python
# NG: N+1 クエリ問題
documents = await get_documents()
for doc in documents:
    doc.chunks = await get_chunks(doc.id)  # N 回のクエリ

# OK: バッチフェッチ
documents = await get_documents()
doc_ids = [doc.id for doc in documents]
chunks = await get_chunks_by_doc_ids(doc_ids)  # 1 回のクエリ
chunk_map = {c.doc_id: c for c in chunks}

for doc in documents:
    doc.chunks = chunk_map.get(doc.id, [])
```

### トランザクションパターン

```python
import sqlite3
from contextlib import contextmanager


@contextmanager
def transaction(db_path: Path):
    conn = sqlite3.connect(db_path)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


# 使用例
async def ingest_document(doc: Document, chunks: list[Chunk]) -> None:
    with transaction(db_path) as conn:
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO documents (id, content, source) VALUES (?, ?, ?)",
            [doc.id, doc.content, doc.source],
        )
        cursor.executemany(
            "INSERT INTO chunks (id, doc_id, content) VALUES (?, ?, ?)",
            [(c.id, c.doc_id, c.content) for c in chunks],
        )
```

## エラーハンドリングパターン

### カスタム例外

```python
# src/domain/exceptions.py
from __future__ import annotations


class DomainError(Exception):
    """ドメイン層の基底例外."""

    def __init__(self, message: str) -> None:
        self.message = message
        super().__init__(message)


class DocumentNotFoundError(DomainError):
    """ドキュメントが見つからない."""

    def __init__(self, doc_id: str) -> None:
        super().__init__(f"Document not found: {doc_id}")
        self.doc_id = doc_id


class ValidationError(DomainError):
    """バリデーションエラー."""


class ExternalServiceError(DomainError):
    """外部サービスエラー."""
```

### グローバルエラーハンドラ

```python
# src/presentation/api/error_handlers.py
from __future__ import annotations

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import structlog

from src.domain.exceptions import (
    DomainError,
    DocumentNotFoundError,
    ValidationError,
)

logger = structlog.get_logger()


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(DocumentNotFoundError)
    async def document_not_found_handler(
        request: Request,
        exc: DocumentNotFoundError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=404,
            content={"success": False, "error": exc.message},
        )

    @app.exception_handler(ValidationError)
    async def validation_error_handler(
        request: Request,
        exc: ValidationError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=400,
            content={"success": False, "error": exc.message},
        )

    @app.exception_handler(Exception)
    async def global_exception_handler(
        request: Request,
        exc: Exception,
    ) -> JSONResponse:
        logger.error("Unhandled exception", error=str(exc), exc_info=True)
        return JSONResponse(
            status_code=500,
            content={
                "success": False,
                "error": "An internal error occurred. Please try again.",
            },
        )
```

### リトライパターン

```python
import asyncio
from typing import TypeVar, Callable, Awaitable

T = TypeVar("T")


async def with_retry(
    fn: Callable[[], Awaitable[T]],
    max_retries: int = 3,
    base_delay: float = 1.0,
) -> T:
    """指数バックオフでリトライ."""
    last_error: Exception | None = None

    for attempt in range(max_retries):
        try:
            return await fn()
        except Exception as e:
            last_error = e
            if attempt < max_retries - 1:
                delay = base_delay * (2 ** attempt)
                await asyncio.sleep(delay)

    raise last_error  # type: ignore


# 使用例
result = await with_retry(lambda: external_api.call())
```

## ログパターン

### 構造化ログ (structlog)

```python
# src/infrastructure/logging.py
import structlog


def configure_logging() -> None:
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.JSONRenderer(),
        ],
        wrapper_class=structlog.stdlib.BoundLogger,
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )


# 使用例
logger = structlog.get_logger()

logger.info(
    "Processing request",
    request_id=request_id,
    user_id=user_id,
    endpoint="/webhook",
)

logger.error(
    "External API failed",
    error=str(e),
    service="sakura_ai",
    retry_count=3,
)
```

## レスポンス形式

### 統一レスポンス構造

```python
# src/presentation/api/schemas.py
from __future__ import annotations

from pydantic import BaseModel
from typing import Generic, TypeVar

T = TypeVar("T")


class ApiResponse(BaseModel, Generic[T]):
    """統一 API レスポンス."""

    success: bool
    data: T | None = None
    error: str | None = None
    meta: dict | None = None


class PaginatedResponse(ApiResponse[T], Generic[T]):
    """ページネーション付きレスポンス."""

    meta: dict = {
        "total": 0,
        "page": 1,
        "limit": 10,
        "has_next": False,
    }


# 使用例
@router.get("/documents", response_model=ApiResponse[list[DocumentSchema]])
async def list_documents():
    documents = await repo.find_all()
    return ApiResponse(
        success=True,
        data=[DocumentSchema.from_entity(d) for d in documents],
    )
```

## 設定管理

```python
# src/infrastructure/config.py
from __future__ import annotations

from functools import lru_cache
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """アプリケーション設定."""

    # 環境
    environment: str = "development"
    debug: bool = False

    # データベース
    database_path: str = "data/documents.db"
    vector_db_path: str = "data/vectors.duckdb"

    # LLM
    llm_base_url: str = "http://localhost:8080"
    llm_api_key: str = ""
    llm_model: str = "gpt-oss-120b"

    # Embedding
    embedding_model: str = "multilingual-e5-large"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache
def get_settings() -> Settings:
    return Settings()
```

---

**重要**: バックエンドパターンはスケーラブルで保守性の高いサーバーサイドアプリケーションを実現する。複雑さに応じて適切なパターンを選択すること。
