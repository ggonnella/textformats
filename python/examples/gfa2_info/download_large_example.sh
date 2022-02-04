# Download the prebuilt human genome GFA graph from the minigraph FTP
URL="ftp://ftp.dfci.harvard.edu/pub/hli/minigraph"
FN="GRCh38-20-0.10b"
wget $URL/$FN.gfa.gz
gunzip $FN.gfa.gz
gfapy-convert $FN.gfa > $FN.gfa2
