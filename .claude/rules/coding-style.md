---
description: Python コーディングスタイルルール（不変性、エラーハンドリング、ファイル構成など）
globs:
  - "**/*.py"
alwaysApply: false
---

# Coding Style

Python コーディングスタイルルール。

## 必須ヘッダー（CRITICAL）

全ての Python ファイルは以下で開始する:

```python
from __future__ import annotations
```

## 不変性（Immutability）

ALWAYS frozen dataclass を使用、NEVER mutate:

```python
# WRONG: Mutable dataclass
@dataclass
class Document:
    content: str
    tags: list[str]

doc.tags.append("new")  # MUTATION!

# CORRECT: Immutable dataclass
@dataclass(frozen=True)
class Document:
    content: str
    tags: tuple[str, ...]  # immutable

new_doc = Document(
    content=doc.content,
    tags=(*doc.tags, "new")
)
```

## ファイル構成

MANY SMALL FILES > FEW LARGE FILES:
- 高凝集、低結合
- 200-400 行が標準、800 行以下
- 大きなモジュールからユーティリティを抽出
- 機能/ドメインで整理（型別ではない）

## エラーハンドリング

ALWAYS 包括的にエラーをハンドリング:

```python
try:
    result = await risky_operation()
    return result
except SpecificError as e:
    logger.error("Operation failed", error=str(e))
    raise DomainError("User-friendly message") from e
```

## 入力バリデーション

ALWAYS Pydantic でバリデーション:

```python
from pydantic import BaseModel, EmailStr, Field

class UserInput(BaseModel):
    email: EmailStr
    age: int = Field(ge=0, le=150)

validated = UserInput.model_validate(input_data)
```

## print() 禁止

NEVER print() を使用、ALWAYS structlog:

```python
# WRONG
print(f"Processing {item}")

# CORRECT
import structlog
logger = structlog.get_logger()
logger.info("Processing item", item_id=item.id)
```

## コード品質チェックリスト

作業完了前に確認:
- [ ] `from __future__ import annotations` がある
- [ ] 全ての関数/クラスに型ヒントがある
- [ ] 公開 API に Docstring（Google スタイル）がある
- [ ] 関数は 50 行以下
- [ ] ファイルは 800 行以下
- [ ] ネスト深度 4 以下
- [ ] エラーハンドリングが適切
- [ ] print() 文がない
- [ ] ハードコード値がない
- [ ] 不変パターンを使用
