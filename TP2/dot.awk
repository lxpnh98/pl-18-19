# d)

BEGIN { FS = ";"
	    dot = "graph.dot";
	    print "digraph{" > dot;
	    print "rankdir = LR" > dot;
	  }

$5 	  { gsub(/ /, "", $5);
    	split($5, infos, ":");
		escritores[infos[1]]++; // Autores
        escritores[infos[2]]++; // Destinatarios
	    if (escritores[infos[1]] == 1) {
 		    print infos[1] i "[label=" "\"" "Autor" "\"" "]" > dot;
 		    nodos[infos[1]] = ++i;
	    }
	    if (escritores[infos[2]] == 1) {
 		    print infos[2] i "[label=" "\"" "Destinatario" "\"" "]" > dot;
 		    nodos[infos[2]] = i++;
	    }
	    print nodos[infos[1]] i "->" nodos[infos[2]] i "[label=\"Enviou carta a\"]" > dot;
	  }

END   { print "}" > dot;}