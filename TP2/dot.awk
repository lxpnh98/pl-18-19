# d)

BEGIN {
    FS = ";"
    dot = "graph.dot";
    print "digraph{" > dot;
    print "rankdir = LR" > dot;
}

$5 	  { gsub(/ /, "", $5);
    	split($5, infos, ":");
    	gsub(/ /, "", $2);
    	split($2, data, ".");
		escritores[infos[1]]++; // Autores
        escritores[infos[2]]++; // Destinatarios
	    if (escritores[infos[1]] == 1) {
 		    nodos[infos[1]] = ++i;
	    }
	    if (escritores[infos[2]] == 1) {
 		    nodos[infos[2]] = i++;
	    }
	    if (nodos[infos[1]] != "" || nodos[infos[2]] != "") {
	    	print infos[1] nodos[infos[1]] "->" infos[2] nodos[infos[2]] "[label=\" "data[3]"-"data[2]"-"data[1]" \"]" > dot;
	    }
	  }

END   { print "}" > dot;}
