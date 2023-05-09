#!/usr/bin/env python3

import glob
import math
import os.path
import statistics
import sys
import typing as t


class Benchmark:
    label: str

    def process(self, datapath: str, config: str) -> t.Tuple[float, t.Optional[float]]:
        """Returns tuple of data point, and optional error."""
        raise NotImplementedError


def iter_fields(filepath: str, fieldnames: t.Sequence[str]) -> t.Iterator[t.Tuple[float, ...]]:
    with open(filepath) as fh:
        columns = None
        for line in fh:
            if line.startswith("  ") and ',' in line:
                if line[2].isdigit():
                    assert columns is not None
                    fields = line.split(",")
                    yield tuple(float(fields[c]) for c in columns)
                elif columns is None:
                    column_names = [s.strip() for s in line.split(",")]
                    columns = [column_names.index(f) for f in fieldnames]


class DataCachingPeak(Benchmark):
    label = "Data caching (peak)"

    def process(self, datapath: str, config: str) -> t.Tuple[float, float]:
        # retrieve all the RPS measurements
        rpsdata = list(map(
                lambda r: r[0],
                iter_fields(os.path.join(datapath, "data-caching", config, "peak.log"), ("rps",))))
        return (statistics.median(rpsdata), statistics.variance(rpsdata))


class DataCachingLocal(Benchmark):
    label = "Data caching (local)"

    def process(self, datapath: str, config: str) -> t.Tuple[float, float]:
        # retrieve all the RPS measurements
        rpsdata = list(map(
                lambda r: r[0],
                iter_fields(os.path.join(datapath, "data-caching.local", config, "peak.log"), ("rps",))))
        return (statistics.median(rpsdata), statistics.variance(rpsdata))


class DataCachingQos(Benchmark):
    label = "Data caching (QoS)"

    def process(self, datapath: str, config: str) -> t.Tuple[float, float]:
        rpsdata = []
        elapsed: t.Optional[float] = None
        for (timeDiff, rps, lat) in iter_fields(os.path.join(datapath, "data-caching", config, "qos.log"), ("timeDiff", "rps", "95th")):
            if elapsed is None: # first line has a bogus time stamp
                elapsed = 0.0
            else:
                elapsed += timeDiff

            if elapsed > 30: # give time to stabilise
                if lat >= 10:
                    print(f"Error: 95% latency {lat} exceeded target for {config} data-caching", file=sys.stderr)
                    sys.exit(1)
                rpsdata.append(rps)
        return (statistics.median(rpsdata), statistics.variance(rpsdata))


def find_first_line_with_prefix_in_files(filepattern: str, prefix: str) -> t.Iterator[str]:
    found_file = False
    for fname in glob.glob(filepattern):
        found_file = True
        with open(fname) as fh:
            found = False
            for line in fh:
                if line.startswith(prefix):
                    found = True
                    yield line[len(prefix):]
                    break
            if not found:
                raise ValueError(f"Invalid log file {fname}")

    if not found_file:
        raise RuntimeError(f"No files found matching {filepattern}")


class DataServing(Benchmark):
    label = "Data serving"

    def process(self, datapath: str, config: str) -> t.Tuple[float, None]:
        PREFIX = "[OVERALL], Throughput(ops/sec), "
        data = list(find_first_line_with_prefix_in_files(os.path.join(datapath, "data-serving", config, "*.log"), PREFIX))
        #assert len(data) == 1
        return (float(data[0]), None)


class GraphAnalytics(Benchmark):
    label = "Graph analytics"

    def process(self, datapath: str, config: str) -> t.Tuple[float, float]:
        PREFIX = "Running time = "
        # invert results from runtime to a performance metric
        data = [1 / float(s) for s in find_first_line_with_prefix_in_files(os.path.join(datapath, "graph-analytics", config, "*.log"), PREFIX)]
        return (statistics.median(data), statistics.variance(data))


class InMemoryAnalytics(Benchmark):
    label = "In-memory analytics"

    def process(self, datapath: str, config: str) -> t.Tuple[float, float]:
        PREFIX = "Benchmark execution time: "
        data = []
        for line in find_first_line_with_prefix_in_files(os.path.join(datapath, "in-memory-analytics", config, "*.log"), PREFIX):
            assert line.endswith("ms\n")
            # invert results from runtime to a performance metric
            data.append(1 / float(line[:-3]))
        return (statistics.median(data), statistics.variance(data))


class MediaStreaming(Benchmark):
    label = "Media Streaming"

    def process(self, datapath: str, config: str) -> t.Tuple[float, None]:
        PREFIX = "Benchmark succeeded for maximum sessions: "
        data = list(find_first_line_with_prefix_in_files(os.path.join(datapath, "media-streaming", config, "*.log"), PREFIX))
        assert len(data) == 1
        return (float(data[0]), None)

BENCHMARKS = [GraphAnalytics, DataCachingPeak, DataCachingQos, DataServing]
CONFIGS=[('slice', 'Slice'), ('vm2m', 'VM (2M)'), ('vm1g', 'VM (1G)')]
BASELINE_CONFIG = 'native'

def main(datapath: str) -> None:
    print("Workload", *(label for (_, label) in CONFIGS), sep="\t")

    for benchmark_cls in BENCHMARKS:
        benchmark = benchmark_cls()
        baseline, _ = benchmark.process(datapath, BASELINE_CONFIG)
        values = []
        errors = []
        for config, _ in CONFIGS:
            value, error = benchmark.process(datapath, config)
            values.append(100 * value / baseline)
            if error is None:
                errors.append(math.nan)
            else:
                # variance scales quadratically, we want std dev
                errors.append(math.sqrt(((100 / baseline) ** 2) * error))
        print(benchmark.label, *map(str, values), *map(str, errors), sep='\t')


if __name__ == "__main__":
    import sys
    main(sys.argv[1])
