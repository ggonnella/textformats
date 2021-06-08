#/usr/bin/env bash
git apply parse_cigars.profiling.patch
nim --profiler:on --stacktrace:on --linetrace:on c parse_cigars
