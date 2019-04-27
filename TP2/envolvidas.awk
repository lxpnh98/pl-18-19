# c)

BEGIN {
    FS = ";"
}

    {
    gsub(/ /, "", $1);
    gsub(/ /, "", $5);
    split($5, envolv, ":");
    for (e in envolv) {
        if (envolv[e] !~ /^ *$/) {
            print $1 " : " envolv[e]
        }
    }
}
