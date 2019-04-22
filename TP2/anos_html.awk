# b)
# $2 - data
# $4 - título
# $6 - resumo

BEGIN {FS=";"}

$2 ~ /[0-9.]+/ {
    gsub(/ /, "", $2);
    split($2, data, ".");
    gsub(/^ */, "", $4);
    anos[data[1]][size[data[1]]] = $4
    size[data[1]]++
}

END {
    for (a in anos) {
        print a;
        for (i in anos[a]) {
            print "\t- " anos[a][i]
        }
    }
}

