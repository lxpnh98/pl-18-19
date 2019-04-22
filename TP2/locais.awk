# a)

BEGIN {FS=";"}

$3 ~ /\w+/ {
    gsub(/^ +/, "", $3);
    gsub(/ +$/, "", $3);
    split($3, locais, ", ");
    gsub(/ /, "", $2);
    split($2, data, ".");
    for (l in locais) {
        gsub(/]/, "", locais[l]);
        conta[locais[l]][data[1]]++;
    }
}
$3 ~ /^\s*$/ && $2 ~ /[0-9.]+/{
    gsub(/ /, "", $2);
    split($2, data, ".");
    conta["NIL"][data[1]]++
}

END {
    for (k in conta) {
        print k ": " conta_datas(conta[k]);
        for (d in conta[k]) {
            print d " - " conta[k][d]
        }
    }
}

function conta_datas(lst) {
    total = 0
    for (d in lst) {
        total += lst[d]
    }
    return total
}
