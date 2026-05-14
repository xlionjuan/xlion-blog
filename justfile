# 預設
default: build

# 本地開發伺服器（含 draft、區網可存取）
serve:
    hugo server -D --bind 0.0.0.0

# 建置生產版（清理 + 壓縮）
build:
    hugo --gc --minify

# 拉取最新（含 submodule）
pull:
    git pull --recurse-submodules

# 完整清理
clean:
    rm -rf public
    rm -rf resources/_gen
    hugo --gc
