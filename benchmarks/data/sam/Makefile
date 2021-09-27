default: 100000.lines.sam

NA06984.454.MOSAIK.SRP000033.2009_11.sam: NA06984.454.MOSAIK.SRP000033.2009_11.bam
	samtools view -h $< -o $@

NA06984.454.MOSAIK.SRP000033.2009_11.bam:
	wget http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/pilot_data/data/NA06984/alignment/NA06984.454.MOSAIK.SRP000033.2009_11.bam

%.lines.sam: NA06984.454.MOSAIK.SRP000033.2009_11.sam
	head -n $* $< > $@

clean:
	rm -f NA06984*

cleanup: clean
	rm -f *.lines.sam
