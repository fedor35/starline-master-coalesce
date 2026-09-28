#!/bin/sh
# Публикация: GitHub (код + тег) и AUR (PKGBUILD + .SRCINFO).
# Нужно: SSH-ключ ~/.ssh/id_ed25519.pub добавлен в GitHub и в аккаунт AUR;
#        на GitHub уже создан пустой репозиторий <user>/starline-master-coalesce.
# Использование: aur/publish.sh <github-user>
set -e
# GitHub уже опубликован 28.09.2026; скрипт идемпотентен, повторный запуск пушит только AUR-часть.
USER=${1:?github user}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
sed -i "s|GITHUB_USER|$USER|" aur/PKGBUILD
git add aur/PKGBUILD && git commit -qm "PKGBUILD: github url" || true
git remote get-url origin >/dev/null 2>&1 || git remote add origin "git@github.com:$USER/starline-master-coalesce.git"
git push -u origin main --tags

# AUR: отдельный репозиторий, в нём только PKGBUILD и .SRCINFO
AURDIR=$ROOT/../starline-master-coalesce-aur
[ -d "$AURDIR/.git" ] || git clone ssh://aur@aur.archlinux.org/starline-master-coalesce.git "$AURDIR"
cp aur/PKGBUILD "$AURDIR/PKGBUILD"
cd "$AURDIR"
updpkgsums                       # тянет тег с GitHub и проставляет sha256
makepkg --printsrcinfo > .SRCINFO
makepkg -f --noconfirm           # контрольная сборка
git add PKGBUILD .SRCINFO
git commit -m "starline-master-coalesce 1.0.0-1"
git push -u origin master
cp PKGBUILD "$ROOT/aur/PKGBUILD"; cp .SRCINFO "$ROOT/aur/.SRCINFO"
cd "$ROOT" && git add aur && git commit -qm "aur: sha256 + .SRCINFO" && git push
