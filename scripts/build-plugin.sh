#!/bin/sh
# Build a host-specific archive without including the build script.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
for dependency in jq zip; do
    command -v "$dependency" >/dev/null 2>&1 || {
        printf 'Erreur : %s doit être installé.\n' "$dependency" >&2
        exit 1
    }
done

printf 'Pour quelle plateforme générer le ZIP ?\n  1. Codex / OpenAI\n  2. Claude\n'
while :; do
    printf 'Votre choix [1/2] : '
    if ! IFS= read -r choice; then
        printf '\nGénération annulée.\n' >&2
        exit 1
    fi
    case "$choice" in
        1|codex|openai) target=codex; break ;;
        2|claude) target=claude; break ;;
        *) printf 'Entrez 1 (Codex/OpenAI) ou 2 (Claude).\n' ;;
    esac
done

cd "$ROOT"
manifest=".$target-plugin/plugin.json"
version=$(jq -er '.version | strings | select(test("^[A-Za-z0-9][A-Za-z0-9.+-]*$"))' "$manifest")
name=$(jq -er '.name | strings | select(length > 0)' "$manifest")
jq -e . .mcp.json >/dev/null

# Validate Codex listing fields before generating an upload archive.
if [ "$target" = codex ]; then
    if ! jq -e '
        def text($limit): type == "string" and test("\\S") and length <= $limit;
        .interface |
        (.displayName | text(30)) and
        (.shortDescription | text(30)) and
        (.longDescription | text(4000)) and
        (.developerName | text(80)) and
        (.category | text(120)) and
        (.composerIcon | text(1024)) and
        (.logo | text(1024)) and
        (.capabilities | type == "array" and length <= 20 and all(.[]; text(120)))
    ' "$manifest" >/dev/null; then
        printf 'Erreur : métadonnées interface Codex manquantes ou invalides dans %s.\n' "$manifest" >&2
        exit 1
    fi
fi

# Reject symlinks before copying, including links to directories outside the repo.
for source in skills ".$target-plugin" .claude-plugin .mcp.json; do
    if [ -n "$(find "$source" -type l -print)" ]; then
        printf 'Erreur : lien symbolique dans %s.\n' "$source" >&2
        exit 1
    fi
done
set -- skills/*/SKILL.md
[ -f "$1" ] || { printf 'Erreur : aucun skill trouvé.\n' >&2; exit 1; }

mkdir -p dist
staging=$(mktemp -d "$ROOT/dist/.build-XXXXXX")
trap 'rm -rf "$staging"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
package="$staging/arcads"
mkdir -p "$package/.$target-plugin"
cp "$manifest" "$package/$manifest"
cp .mcp.json "$package/.mcp.json"
cp -R skills "$package/skills"
find "$package/skills" \( -name '.*' -o -name __MACOSX -o -name __pycache__ \) -prune -exec rm -rf {} +

# Copy the icons referenced by the selected manifest, preserving relative paths.
jq -r '[.icon, .interface.composerIcon, .interface.logo] | map(select(. != null)) | unique[]' "$manifest" > "$staging/icons"
while IFS= read -r icon; do
    case "$icon" in
        ./*) relative=${icon#./} ;;
        *) printf 'Erreur : chemin d’icône invalide : %s\n' "$icon" >&2; exit 1 ;;
    esac
    case "/$relative/" in
        */../*) printf 'Erreur : icône hors du plugin.\n' >&2; exit 1 ;;
    esac
    [ -f "$relative" ] || { printf 'Erreur : icône manquante : %s\n' "$relative" >&2; exit 1; }
    mkdir -p "$package/$(dirname -- "$relative")"
    cp "$relative" "$package/$relative"
done < "$staging/icons"

output="$ROOT/dist/arcads-$target-$version.zip"
(cd "$staging" && zip -qr archive.zip arcads)
mv "$staging/archive.zip" "$output"
printf '\nZIP généré : %s\nIdentifiant : %s\n' "$output" "$name"
