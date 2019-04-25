# b)
# $2 - data
# $4 - título
# $6 - resumo

BEGIN {FS=";"}

$2 ~ /[0-9.]+/ {
    gsub(/ /, "", $2);
    split($2, data, ".");
    gsub(/^ */, "", $4);
    gsub(/^ */, "", $6);
    gsub(/ +/, " ", $6);
    anos[data[1]][size[data[1]]] = "<h1>"$4"</h1>\n" "<p>"$6"</p>\n"
    size[data[1]]++
}

END {
    print "<!DOCTYPE html>\n<html>\n<body>\n" > "index.html"
    print "<head>\n\t<meta charset=\"UTF-8\">\n" > "index.html"
    for (a in anos) {
        print "<p><a href=" a ".html" ">" a "</a></p>\n" > "index.html";
        for (i in anos[a]) {
            print anos[a][i] > a ".html"
        }
    }
    print "</html>\n</body>\n" > "index.html"
}

