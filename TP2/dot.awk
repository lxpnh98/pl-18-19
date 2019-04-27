# d)

BEGIN {
    FS = ";"
    dot = "graph.dot";
    print "digraph{" > dot;
    print "rankdir = LR" > dot;
}

	  { gsub(/ /, "", $2);
    	split($2, data, ".");
		gsub(/ /, "", $5);
    	split($5, infos, ":");
        if (infos[1] != "" && infos[2] != "") {
            print infos[1] "->" infos[2] "[label=\" "data[3]"-"data[2]"-"data[1]" \"]" > dot;
        }
	  }

END   { print "}" > dot;}
