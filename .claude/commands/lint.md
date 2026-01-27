---
description: ruff と mypy を実行してコード品質をチェック。
---

# Lint Command

静的解析ツールを実行してコード品質をチェックする。

## 実行コマンド

```bash
# フォーマットチェック
uv run ruff format src/ tests/ --check

# フォーマット実行（自動修正）
uv run ruff format src/ tests/

# リントチェック
uv run ruff check src/ tests/

# リント自動修正
uv run ruff check src/ tests/ --fix

# 型チェック
uv run mypy src/

# 全て実行
make lint typecheck
```

## チェック内容

### ruff

- pycodestyle (E, W)
- Pyflakes (F)
- isort (I)
- flake8-bugbear (B)
- flake8-comprehensions (C4)
- pyupgrade (UP)
- flake8-simplify (SIM)
- flake8-type-checking (TCH)
- pydocstyle (D) - Google スタイル
- Pylint (PL)

### mypy

- strict モード有効
- 全ての引数と戻り値に型ヒント必須
- Any 型の使用を警告

## エラー対応

### ruff エラー

```bash
# 特定のエラーを確認
uv run ruff check src/ --select=E501

# 自動修正可能なエラーを修正
uv run ruff check src/ --fix

# 特定のエラーを無視（非推奨）
# pyproject.toml の ignore に追加
```

### mypy エラー

```python
# 型エラーの例と修正

# NG: 型ヒントなし
def process(data):
    return data

# OK: 型ヒントあり
def process(data: dict[str, str]) -> dict[str, str]:
    return data

# NG: Any を返す可能性
def get_value(d: dict) -> str:
    return d.get("key")  # None を返す可能性

# OK: Optional を明示
def get_value(d: dict[str, str]) -> str | None:
    return d.get("key")
```

## CI での実行

```yaml
- name: Lint
  run: |
    uv run ruff check src/ tests/
    uv run ruff format src/ tests/ --check
    uv run mypy src/
```
