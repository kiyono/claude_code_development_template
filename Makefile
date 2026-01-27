.PHONY: install lint format typecheck test coverage run clean all

# 依存関係インストール
install:
	uv sync --all-extras

# リント
lint:
	uv run ruff check src/ tests/

# フォーマット
format:
	uv run ruff format src/ tests/
	uv run ruff check src/ tests/ --fix

# 変更ファイルのみフォーマット
format.changed:
	@git diff --name-only HEAD | grep '\.py$$' | xargs -r uv run ruff format
	@git diff --name-only HEAD | grep '\.py$$' | xargs -r uv run ruff check --fix

# 型チェック
typecheck:
	uv run mypy src/

# テスト
test:
	uv run pytest

# カバレッジ
coverage:
	uv run pytest --cov=src --cov-report=term-missing --cov-fail-under=95

# アプリケーション起動
run:
	uv run uvicorn src.main:app --reload --host 0.0.0.0 --port 8000

# クリーンアップ
clean:
	rm -rf .venv .mypy_cache .pytest_cache .ruff_cache .coverage htmlcov

# 全チェック
all: format lint typecheck coverage
