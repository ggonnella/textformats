#!/usr/bin/env python3
import nimporter
import parse_cigars_lib as pcl
pcl.run_decode("../../data/cigars/cigar.datatypes.yaml", "cigar", "../../data/cigars/100k_cigars_len100")
