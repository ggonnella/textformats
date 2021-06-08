#/usr/bin/env bash
git apply parse_cigars.noprofiling.patch
nim --d:danger --gc:mark_and_sweep c parse_cigars
