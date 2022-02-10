SPEC=../../../spec/gfa/gfa1.yaml
GFAPY_VALIDATE=gfapy-validate
BANDAGE=Bandage

run: gfapy.checked bandage.checked
	@echo "Example usage of TextFormats to correct a non-standard-compliant file"
	@echo
	@echo "(1) extraction of a subgraph of 'complete_graph.gfa' using Bandage"
	${BANDAGE} reduce complete_graph.gfa subgraph --scope aroundnodes --distance 3 --nodes S30
	@echo
	@echo "(2) the resulting file, subgraph.gfa, is invalid"
	${GFAPY_VALIDATE} subgraph.gfa || (echo "--> Invalid GFA1" && true)
	@echo
	@echo "(3) identify invalid lines using TextFormats (show the first 10)"
	./gfa1_show_invalid_lines.py subgraph.gfa ${SPEC} | head -n 10
	@echo
	@echo "(4) use TextFormats to correct the issues"
	./gfa1_fix.py subgraph.gfa ${SPEC} invalid_gfa1.yaml > fixed_subgraph.gfa
	@echo
	@echo "(5) the resulting file is standard-compliant"
	${GFAPY_VALIDATE} fixed_subgraph.gfa && echo "--> Valid GFA1, no issues found."
	@echo

gfapy.checked:
	@echo -n "- checking if the GfaPy Python library is installed..."
	@((which ${GFAPY_VALIDATE} > /dev/null 2> /dev/null) \
	   && echo " gfapy-validate found") \
		 || (echo -e " Gfapy not found\n\n" \
		          "  To install the library run:\n"\
							"    pip install gfapy\n\n" \
	          	"  If already installed, either:\n" \
							"  - add the bin directory of GfaPy to the PATH, or\n" \
							"  - pass the location of gfapy-validate using:\n" \
						  "       make GFAPY_VALIDATE=...\n" \
							&& false)

bandage.checked:
	@echo -n "- checking if Bandage is installed..."
	@((which ${BANDAGE} > /dev/null 2> /dev/null) \
		&& echo " Bandage found") \
		|| (echo -e " Bandage not found\n\n" \
		           "  To install it, refer to the Bandage website:\n" \
	             "    https://rrwick.github.io/Bandage/\n\n" \
	          	 "  If already installed, either:\n" \
							 "  - add the directory of the Bandage binary to the PATH, or\n" \
							 "  - pass the location of Bandage using:\n" \
						   "       make BANDAGE=...\n" \
							 && false)
	@echo
