This example demostrate the use of TextFormat for defining new bioinformatics
formats and compares it to writing an ad-hoc parser using Python.

Here a format is defined, named EGC ("Expected Genomic Content"). As the name
suggests, the goal of the format is to describe the expected content of genomes
in terms of values of given attributes (such as sequence statistics or feature
counts), depending on the membership of the organism (to which the genome
belong) to taxonomic or phenotypic groups.

The format is similar to GFA in its structure:
- each non-comment line (i.e. not starting with the hash symbol) is a record
- a record consists of fields separated by tabs
- the first field is a single uppercase letter coding for the record type
- the record type determines the number and semantics of the following fields

Record types:
- A --> attribute line: defines a measurable attribute (name, datatype,
        unit of measurement); links to an external ontology; optionally
        allows to collect attributes into groups
- P --> phenotypic group line: describes a phenotype; links to an external
        ontology
- T --> taxon line: names a taxonomic group; links to the NCBI taxonomy DB
- E --> expectation line; associates a taxonomic or phenotypic group to
        an expected value of an attribute (equal to a given boolean or
        numeric value; or, for numeric values, lower/higher than a
        given threshold or in a given range); links to a publication
        or other document or database record, which documents the expectation
        using Pubmed ID, DDOI or unique identifiers (UUID).

The field order in each record type and the datatypes of each field are given
in the TFSL specification file `egc.yaml`.
