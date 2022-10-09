prefix='(?<![\p{Ll}_\p{Lu}\p{Lt}'"'"'])'
suffix='(?![\p{Ll}_\p{Lu}\p{Lt}\p{Nd}'"'"'])'
oppfx='(?<![\p{S}\p{P}](?<![(),;\[\]`{}_"'"'"']))'
opsfx='(?![\p{S}\p{P}](?<![(),;\[\]`{}_"'"'"']))'

temp=$(mktemp)

write() {
  local dst="syntaxes/$1.tmLanguage.json"
  local script="."
  shift 1
  local num=$(($# - 1))
  for i in `seq 0 $num`; do
    script="$script | .patterns[$i].match = \$ARGS.positional[$i]"
  done
  jq "$script" "$dst" --args "$@" > "$temp"
  cat "$temp" > "$dst"
}

ghci="$(ghci <<< ":browse Prelude" 2>&1)"

go() {
  local res="$(sed -rn "$1" <<< "$ghci" | sort | tr '\n' '|')"
  local prefix=${2:-$prefix}
  local suffix=${3:-$suffix}
  echo "$prefix(${res%|})$suffix"
}

write "functions" "$(go '/^\s*\w+ ::/ {s/^\s*//; s/\s*::.*$//; p}')"

write "operators" "$(go '/^\s*\(/ {s/^\s*\(//; s/\)\s*::.*$//; s/[.*+|^$]/\\\0/g; p}' "$oppfx" "$opsfx")"

# classes
cls=$(go '/^type .* :: .* Constraint$/ {s/^\s*type\s*//; s/\s*::.*$//; p}')
# data types and aliases
typ=$(go '/^type.*::.*\*$/ {s/^\s*type\s*//; s/\s*::.*$//; p}')
# promoted data constructors
datac='/^(data|newtype) .* =/ {/#/ d;s/^.*=//; s/\s+[a-z]\s*//g; s/ //g; p}'
dat=$(go "$datac" "$prefix'?")

write "types" "$cls" "$typ" "$dat"

# data constructors
dat=$(go "$datac")

write "ctors" "$dat"

#############
# char kind #
#############

basicChar="[^']"
escapeChar='\\(NUL|SOH|STX|ETX|EOT|ENQ|ACK|BEL|BS|HT|LF|VT|FF|CR|SO|SI|DLE|DC1|DC2|DC3|DC4|NAK|SYN|ETB|CAN|EM|SUB|ESC|FS|GS|RS|US|SP|DEL|[abfnrtv\\"'"'"'&])'
octalChar='(\\o[0-7]+)'
hexChar='(\\x[0-9A-Fa-f]+)'
controlChar='(\\\^[A-Z@\[\]\\^_])'
character="(?:$basicChar|$escapeChar|$octalChar|$hexChar|$controlChar|$operatorChar)"

write "charkind" "$prefix(')$character(')"
