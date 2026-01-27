# Python コーディング標準

本リポジトリにおける Python コーディングルール。Python 3.11+ を対象とする。

---

## 1. パッケージ管理

### 1.1 pyproject.toml で一元管理

**requirements.txt は使用しない。全ての依存関係は pyproject.toml で管理する。**

```toml
[project]
name = "rag-bot"
version = "0.1.0"
requires-python = ">=3.11"

dependencies = [
    "fastapi>=0.110.0",
    "uvicorn[standard]>=0.27.0",
    # ... 本番依存
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "ruff>=0.3.0",
    "mypy>=1.8.0",
    # ... 開発依存
]
```

### 1.2 uv によるパッケージ管理

**本プロジェクトでは uv を使用する。pip 直接実行は禁止。**

```bash
# 依存関係のインストール
uv sync --all-extras

# パッケージ追加
uv add fastapi
uv add --dev pytest

# スクリプト実行
uv run python src/main.py
uv run pytest
```

詳細は [docs/development.md](../development.md) を参照。

### 1.3 禁止事項

| 禁止 | 理由 |
|------|------|
| `requirements.txt` | pyproject.toml に統一 |
| `setup.py` | pyproject.toml に統一 |
| `setup.cfg` | pyproject.toml に統一 |
| `pip install` 直接実行 | uv を使用 |
| `python -m venv` | uv が自動管理 |
| バージョン指定なし | 再現性のため最低バージョンは必須 |

### 1.4 バージョン指定ルール

```toml
dependencies = [
    # OK: 最低バージョン指定（推奨）
    "fastapi>=0.110.0",

    # OK: 互換バージョン指定
    "pydantic>=2.6.0,<3.0.0",

    # NG: バージョン指定なし
    "fastapi",

    # NG: 完全固定（ロックファイルで管理すべき）
    "fastapi==0.110.0",
]
```

### 1.5 ロックファイル

uv は `uv.lock` を自動生成・管理する。

```bash
# uv.lock は uv sync 時に自動生成
uv sync

# ロックファイルを更新
uv lock --upgrade
```

`uv.lock` はリポジトリにコミットすること。

### 1.6 依存関係の分類

```toml
[project]
dependencies = [
    # === Web フレームワーク ===
    "fastapi>=0.110.0",
    "uvicorn[standard]>=0.27.0",

    # === LLM / Embedding ===
    "openai>=1.12.0",
    "sentence-transformers>=2.5.0",
    "tiktoken>=0.6.0",

    # === データベース ===
    "duckdb>=0.10.0",

    # === ファイルパース ===
    "pypdf>=4.0.0",

    # === ユーティリティ ===
    "pydantic>=2.6.0",
    "pydantic-settings>=2.2.0",
    "httpx>=0.27.0",
    "structlog>=24.1.0",
]

[project.optional-dependencies]
dev = [
    # === テスト ===
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "pytest-cov>=4.1.0",

    # === 静的解析 ===
    "ruff>=0.3.0",
    "mypy>=1.8.0",
]
```

---

## 2. 必須設定

### 2.1 全ファイル共通ヘッダー

```python
from __future__ import annotations

# 以下、通常の import
```

**理由**:
- PEP 563 に基づく遅延評価アノテーション
- 循環参照を回避
- 型ヒントのパフォーマンス向上
- 前方参照を文字列なしで記述可能

```python
# from __future__ import annotations あり
class Node:
    def get_parent(self) -> Node:  # OK: 文字列不要
        ...

# from __future__ import annotations なし
class Node:
    def get_parent(self) -> "Node":  # 文字列が必要
        ...
```

---

## 2. 静的解析ツール

### 2.1 Ruff（リンター・フォーマッター）

#### インストール

```bash
pip install ruff
```

#### 設定（pyproject.toml）

```toml
[tool.ruff]
target-version = "py311"
line-length = 88
src = ["src", "tests"]

[tool.ruff.lint]
select = [
    "E",      # pycodestyle errors
    "W",      # pycodestyle warnings
    "F",      # Pyflakes
    "I",      # isort
    "B",      # flake8-bugbear
    "C4",     # flake8-comprehensions
    "UP",     # pyupgrade
    "ARG",    # flake8-unused-arguments
    "SIM",    # flake8-simplify
    "TCH",    # flake8-type-checking
    "PTH",    # flake8-use-pathlib
    "ERA",    # eradicate (commented-out code)
    "PL",     # Pylint
    "RUF",    # Ruff-specific rules
]
ignore = [
    "PLR0913",  # Too many arguments
    "PLR2004",  # Magic value comparison
]

[tool.ruff.lint.per-file-ignores]
"tests/**/*.py" = [
    "ARG",      # Unused arguments in tests (fixtures)
    "PLR2004",  # Magic values in tests are OK
]

[tool.ruff.lint.isort]
known-first-party = ["src"]
force-single-line = true

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
skip-magic-trailing-comma = false
line-ending = "auto"
```

#### 実行コマンド

```bash
# リント
ruff check src/ tests/

# 自動修正
ruff check src/ tests/ --fix

# フォーマット
ruff format src/ tests/

# フォーマットチェック（CI用）
ruff format src/ tests/ --check
```

---

### 2.2 mypy（型チェック）

#### インストール

```bash
pip install mypy
```

#### 設定（pyproject.toml）

```toml
[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true
warn_redundant_casts = true
warn_unused_ignores = true
show_error_codes = true
show_column_numbers = true
pretty = true

# プロジェクト設定
mypy_path = "src"
namespace_packages = true
explicit_package_bases = true

# サードパーティライブラリ
[[tool.mypy.overrides]]
module = [
    "duckdb.*",
    "sentence_transformers.*",
    "tiktoken.*",
]
ignore_missing_imports = true
```

#### 実行コマンド

```bash
# 型チェック
mypy src/

# キャッシュクリア
mypy src/ --no-incremental
```

#### strict モードで有効になるオプション

```
--warn-unused-configs
--disallow-any-generics
--disallow-subclassing-any
--disallow-untyped-calls
--disallow-untyped-defs
--disallow-incomplete-defs
--check-untyped-defs
--disallow-untyped-decorators
--warn-redundant-casts
--warn-unused-ignores
--warn-return-any
--no-implicit-reexport
--strict-equality
--strict-concatenate
```

---

## 3. テストカバレッジ

### 3.1 カバレッジ 95% 必須

**最低カバレッジ: 95%**

```toml
[tool.coverage.run]
source = ["src"]
branch = true
omit = [
    "src/__main__.py",
    "src/config.py",
]

[tool.coverage.report]
fail_under = 95
show_missing = true
exclude_lines = [
    "pragma: no cover",
    "if TYPE_CHECKING:",
    "if __name__ == .__main__.:",
    "@abstractmethod",
    "raise NotImplementedError",
]
```

#### 実行コマンド

```bash
# カバレッジ付きテスト
pytest --cov=src --cov-report=term-missing --cov-fail-under=95

# HTML レポート生成
pytest --cov=src --cov-report=html

# XML レポート（CI用）
pytest --cov=src --cov-report=xml
```

### 3.2 カバレッジ除外ルール

以下のみ除外を許可:

| 除外対象 | 理由 |
|---------|------|
| `if TYPE_CHECKING:` | 型チェック専用ブロック |
| `@abstractmethod` | 抽象メソッドは実装なし |
| `raise NotImplementedError` | 意図的な未実装 |
| `if __name__ == "__main__":` | エントリーポイント |

```python
# 明示的な除外（最小限に）
def platform_specific_code():  # pragma: no cover
    # OS固有の処理
    ...
```

---

## 4. Docstring（Google スタイル）

### 4.1 基本フォーマット

```python
from __future__ import annotations

def calculate_similarity(
    vector_a: list[float],
    vector_b: list[float],
    *,
    normalize: bool = True,
) -> float:
    """2つのベクトル間のコサイン類似度を計算する.

    Args:
        vector_a: 比較元のベクトル.
        vector_b: 比較先のベクトル.
        normalize: 正規化するかどうか. Defaults to True.

    Returns:
        コサイン類似度（-1.0 から 1.0 の範囲）.

    Raises:
        ValueError: ベクトルの次元が異なる場合.

    Examples:
        >>> calculate_similarity([1, 0], [0, 1])
        0.0
        >>> calculate_similarity([1, 0], [1, 0])
        1.0
    """
    if len(vector_a) != len(vector_b):
        raise ValueError("Vector dimensions must match")
    ...
```

### 4.2 クラスの Docstring

```python
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime


@dataclass(frozen=True)
class Document:
    """ドキュメントエンティティ.

    チャットログやファイルから抽出されたテキストドキュメントを表す.

    Attributes:
        id: ドキュメントの一意識別子.
        source_type: データソースの種類（'chat', 'gdrive', 'fileforce'）.
        content: ドキュメントの本文.
        created_at: 作成日時.
        metadata: 追加のメタデータ.

    Examples:
        >>> doc = Document(
        ...     id="doc_001",
        ...     source_type="chat",
        ...     content="テスト内容",
        ...     created_at=datetime.now(),
        ...     metadata={"channel": "#general"},
        ... )
    """

    id: str
    source_type: str
    content: str
    created_at: datetime
    metadata: dict[str, str]
```

### 4.3 モジュールの Docstring

```python
"""ドキュメントリポジトリの実装.

SQLite を使用したドキュメントの永続化を提供する.

Example:
    >>> repo = SQLiteDocumentRepository("./data/documents.db")
    >>> await repo.save(document)
    >>> doc = await repo.find_by_id("doc_001")
"""
from __future__ import annotations
```

### 4.4 Docstring 必須箇所

| 対象 | 必須 |
|------|------|
| 公開モジュール | 必須 |
| 公開クラス | 必須 |
| 公開関数/メソッド | 必須 |
| プライベートメソッド（`_`） | 推奨 |
| 内部関数（`__`） | 任意 |

---

## 5. 型ヒント

### 5.1 必須ルール

```python
from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from collections.abc import Callable
    from collections.abc import Sequence


# OK: 全ての引数と戻り値に型ヒント
def process_documents(
    documents: Sequence[Document],
    filter_fn: Callable[[Document], bool] | None = None,
) -> list[Document]:
    ...


# NG: 型ヒントなし
def process_documents(documents, filter_fn=None):
    ...
```

### 5.2 Python 3.11+ の型ヒント

```python
from __future__ import annotations

from typing import Self
from typing import TypeVar
from typing import TypeAlias

# 組み込み型をそのまま使用（typing.List 等は不要）
def get_items() -> list[str]:
    ...

def get_mapping() -> dict[str, int]:
    ...

def get_optional() -> str | None:  # Optional[str] より推奨
    ...

# Self 型（Python 3.11+）
class Builder:
    def with_name(self, name: str) -> Self:
        self.name = name
        return self

# TypeAlias
Vector: TypeAlias = list[float]
Embedding: TypeAlias = list[float]

def calculate_distance(a: Vector, b: Vector) -> float:
    ...
```

### 5.3 TYPE_CHECKING ガード

実行時に不要な import は TYPE_CHECKING 内に記述。

```python
from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from domain.entities import Document
    from domain.repositories import DocumentRepository


class AnswerUseCase:
    def __init__(self, document_repo: DocumentRepository) -> None:
        self._document_repo = document_repo
```

---

## 6. Python 3.11+ 固有機能

### 6.1 推奨機能

```python
from __future__ import annotations

# tomllib（標準ライブラリ）
import tomllib

with open("pyproject.toml", "rb") as f:
    config = tomllib.load(f)


# ExceptionGroup（複数例外の同時処理）
try:
    async with asyncio.TaskGroup() as tg:
        tg.create_task(task1())
        tg.create_task(task2())
except* ValueError as eg:
    for exc in eg.exceptions:
        print(f"ValueError: {exc}")
except* TypeError as eg:
    for exc in eg.exceptions:
        print(f"TypeError: {exc}")


# match 文（構造的パターンマッチング）
def handle_response(response: dict) -> str:
    match response:
        case {"status": "success", "data": data}:
            return f"Success: {data}"
        case {"status": "error", "message": msg}:
            return f"Error: {msg}"
        case _:
            return "Unknown response"


# f-string の改善（Python 3.12+）
# クォートのネストが可能
name = "world"
message = f"Hello {name.upper()}"
```

### 6.2 dataclass の活用

```python
from __future__ import annotations

from dataclasses import dataclass
from dataclasses import field
from datetime import datetime


@dataclass(frozen=True, slots=True)
class Document:
    """不変のドキュメントエンティティ.

    frozen=True で不変性を保証.
    slots=True でメモリ効率を改善.
    """

    id: str
    content: str
    created_at: datetime = field(default_factory=datetime.now)
    metadata: dict[str, str] = field(default_factory=dict)


@dataclass(kw_only=True)  # Python 3.10+
class Config:
    """キーワード引数のみを許可."""

    host: str
    port: int = 8000
```

### 6.3 Enum の活用

```python
from __future__ import annotations

from enum import Enum
from enum import auto
from enum import StrEnum  # Python 3.11+


class SourceType(StrEnum):
    """データソースの種類."""

    CHAT = auto()
    GDRIVE = auto()
    FILEFORCE = auto()


# 使用例
source = SourceType.CHAT
print(source)  # "chat"
print(source == "chat")  # True
```

---

## 7. 非同期処理

### 7.1 async/await の使用

```python
from __future__ import annotations

import asyncio
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from collections.abc import Sequence


async def process_documents(
    documents: Sequence[Document],
) -> list[ProcessedDocument]:
    """ドキュメントを並列処理する."""
    async with asyncio.TaskGroup() as tg:
        tasks = [
            tg.create_task(process_single(doc))
            for doc in documents
        ]
    return [task.result() for task in tasks]


async def process_single(document: Document) -> ProcessedDocument:
    """単一ドキュメントを処理する."""
    ...
```

### 7.2 Repository の非同期化

```python
from __future__ import annotations

from abc import ABC
from abc import abstractmethod


class DocumentRepository(ABC):
    """ドキュメントリポジトリのインターフェース."""

    @abstractmethod
    async def save(self, document: Document) -> None:
        """ドキュメントを保存する."""
        ...

    @abstractmethod
    async def find_by_id(self, doc_id: str) -> Document | None:
        """ID でドキュメントを検索する."""
        ...
```

---

## 8. プロジェクト設定（pyproject.toml 完全版）

```toml
[project]
name = "rag-bot"
version = "0.1.0"
description = "社内向け RAG ヘルプチャット Bot"
readme = "README.md"
requires-python = ">=3.11"
license = { text = "MIT" }
authors = [{ name = "Your Name", email = "your.email@example.com" }]

dependencies = [
    "fastapi>=0.110.0",
    "uvicorn[standard]>=0.27.0",
    "openai>=1.12.0",
    "sentence-transformers>=2.5.0",
    "tiktoken>=0.6.0",
    "duckdb>=0.10.0",
    "pypdf>=4.0.0",
    "pydantic>=2.6.0",
    "pydantic-settings>=2.2.0",
    "httpx>=0.27.0",
    "structlog>=24.1.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "pytest-cov>=4.1.0",
    "ruff>=0.3.0",
    "mypy>=1.8.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

# === Ruff ===
[tool.ruff]
target-version = "py311"
line-length = 88
src = ["src", "tests"]

[tool.ruff.lint]
select = [
    "E",      # pycodestyle errors
    "W",      # pycodestyle warnings
    "F",      # Pyflakes
    "I",      # isort
    "B",      # flake8-bugbear
    "C4",     # flake8-comprehensions
    "UP",     # pyupgrade
    "ARG",    # flake8-unused-arguments
    "SIM",    # flake8-simplify
    "TCH",    # flake8-type-checking
    "PTH",    # flake8-use-pathlib
    "ERA",    # eradicate
    "PL",     # Pylint
    "RUF",    # Ruff-specific
    "D",      # pydocstyle
]
ignore = [
    "D100",     # Missing docstring in public module
    "D104",     # Missing docstring in public package
    "D107",     # Missing docstring in __init__
    "PLR0913",  # Too many arguments
    "PLR2004",  # Magic value comparison
]

[tool.ruff.lint.per-file-ignores]
"tests/**/*.py" = [
    "ARG",
    "PLR2004",
    "D",        # Docstring not required in tests
]

[tool.ruff.lint.pydocstyle]
convention = "google"

[tool.ruff.lint.isort]
known-first-party = ["src"]
force-single-line = true

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
skip-magic-trailing-comma = false
line-ending = "auto"
docstring-code-format = true

# === mypy ===
[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true
warn_redundant_casts = true
warn_unused_ignores = true
show_error_codes = true
show_column_numbers = true
pretty = true
mypy_path = "src"
namespace_packages = true
explicit_package_bases = true

[[tool.mypy.overrides]]
module = [
    "duckdb.*",
    "sentence_transformers.*",
    "tiktoken.*",
]
ignore_missing_imports = true

# === pytest ===
[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
addopts = "-v --tb=short --strict-markers"
markers = [
    "unit: 単体テスト",
    "integration: 統合テスト",
    "e2e: E2Eテスト",
    "slow: 実行時間の長いテスト",
]

# === coverage ===
[tool.coverage.run]
source = ["src"]
branch = true
omit = [
    "src/__main__.py",
    "src/config.py",
]

[tool.coverage.report]
fail_under = 95
show_missing = true
exclude_lines = [
    "pragma: no cover",
    "if TYPE_CHECKING:",
    "if __name__ == .__main__.:",
    "@abstractmethod",
    "raise NotImplementedError",
]
```

---

## 9. CI/CD チェック

### 9.1 pre-commit 設定

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.3.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.8.0
    hooks:
      - id: mypy
        additional_dependencies:
          - pydantic>=2.6.0
```

### 9.2 Makefile

```makefile
.PHONY: lint format typecheck test coverage all

lint:
	ruff check src/ tests/

format:
	ruff format src/ tests/
	ruff check src/ tests/ --fix

typecheck:
	mypy src/

test:
	pytest tests/

coverage:
	pytest --cov=src --cov-report=term-missing --cov-fail-under=95

all: format lint typecheck coverage
```

### 9.3 GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Install dependencies
        run: |
          pip install -e ".[dev]"

      - name: Ruff lint
        run: ruff check src/ tests/

      - name: Ruff format check
        run: ruff format src/ tests/ --check

      - name: Type check
        run: mypy src/

      - name: Test with coverage
        run: pytest --cov=src --cov-report=xml --cov-fail-under=95

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: coverage.xml
```

---

## 10. チェックリスト

### 10.1 コードレビュー時

- [ ] `from __future__ import annotations` がファイル先頭にあるか
- [ ] 全ての公開関数/クラスに Docstring（Google スタイル）があるか
- [ ] 全ての引数と戻り値に型ヒントがあるか
- [ ] `ruff check` が通るか
- [ ] `ruff format --check` が通るか
- [ ] `mypy --strict` が通るか
- [ ] テストカバレッジが 95% 以上か

### 10.2 PR マージ前

```bash
# 全チェック実行
make all
```

---

## 11. 参考資料

- [PEP 8 -- Style Guide for Python Code](https://peps.python.org/pep-0008/)
- [PEP 257 -- Docstring Conventions](https://peps.python.org/pep-0257/)
- [PEP 484 -- Type Hints](https://peps.python.org/pep-0484/)
- [PEP 563 -- Postponed Evaluation of Annotations](https://peps.python.org/pep-0563/)
- [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)
- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [mypy Documentation](https://mypy.readthedocs.io/)
