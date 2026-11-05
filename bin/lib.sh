# Funções compartilhadas pelos scripts do crew. Use com `source`.

CREW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MARKETPLACE="crew"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m ok\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merro\033[0m %s\n' "$*" >&2; exit 1; }

require() {
  command -v "$1" >/dev/null 2>&1 || die "'$1' não encontrado no PATH. $2"
}

# Mescla o JSON de $2 dentro do arquivo $1, sem apagar nada que já exista.
# Objetos são mesclados recursivamente; listas viram a união (sem duplicar);
# valores escalares do template prevalecem. Guarda backup em $1.bak, exceto
# com $3 = nobackup (arquivos versionados no git, onde o próprio git é o backup).
merge_json() {
  local target="$1" template="$2" mode="${3:-}" tmp
  mkdir -p "$(dirname "$target")"
  if [ ! -s "$target" ]; then
    echo '{}' > "$target"
    mode=nobackup
  fi
  jq empty "$target" 2>/dev/null || die "$target não é JSON válido; corrija antes de continuar."
  tmp="$(mktemp)"
  jq -s '
    def merge($a; $b):
      if ($a|type) == "object" and ($b|type) == "object" then
        reduce ($b|keys_unsorted[]) as $k ($a; .[$k] = merge($a[$k]; $b[$k]))
      elif ($a|type) == "array" and ($b|type) == "array" then
        $a + ($b - $a)
      elif $b == null then $a
      else $b end;
    merge(.[0]; .[1])
  ' "$target" "$template" > "$tmp"
  if jq -S . "$target" | cmp -s - <(jq -S . "$tmp"); then
    rm -f "$tmp"
    ok "$target já estava atualizado"
  elif [ "$mode" = nobackup ]; then
    mv -f "$tmp" "$target"
    ok "$target atualizado"
  else
    cp -f "$target" "$target.bak"
    mv -f "$tmp" "$target"
    ok "$target atualizado (backup em $target.bak)"
  fi
}

plugin_installed() {
  claude plugin list 2>/dev/null | grep -q "❯ $1\$"
}

marketplace_known() {
  claude plugin marketplace list 2>/dev/null | grep -qw "$1"
}
