# a)
# TODO: relacionar com ano de escrita (para cada local, pôr uma lista dos anos em que forão escritas as cartas?)

BEGIN {FS=";"}

$3 ~ /\w+/ {
    gsub(/^ +/, "", $3);
    gsub(/ +$/, "", $3);
    split($3, locais, ", ");
    for (l in locais) {
        gsub(/]/, "", locais[l]);
        conta[locais[l]]++;
    }
}
$3 ~ /^\s*$/ {conta["NIL"]++}

END {for (k in conta) {print k ": " conta[k]}}

