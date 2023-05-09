#!/usr/bin/env python3

import sys
import statistics
import typing as t

def iter_fields(file: t.TextIO, fieldnames: t.Sequence[str]) -> t.Iterator[t.Tuple[float, ...]]:
    columns = None
    for line in file:
        print(line, end="")
        if line.startswith("  ") and ',' in line:
            if line[2].isdigit():
                assert columns is not None
                fields = line.split(",")
                yield tuple(float(fields[c]) for c in columns)
            elif columns is None:
                column_names = [s.strip() for s in line.split(",")]
                columns = [column_names.index(f) for f in fieldnames]

def main(args):
    if args:
        qos_target = int(args[0])
    else:
        qos_target = 10

    rpsdata = []
    elapsed: t.Optional[float] = None
    for (timeDiff, rps, lat) in iter_fields(sys.stdin, ("timeDiff", "rps", "95th",)):
        if elapsed is None: # first line has a bogus time stamp
            elapsed = 0.0
        else:
            elapsed += timeDiff

        if elapsed > 30: # give time to stabilise
            rpsdata.append(rps)
            if qos_target > 0 and lat >= qos_target:
                print(f"QoS failed: 95% latency {lat} exceeded {qos_target}ms target", file=sys.stderr)
                sys.exit(1)

    if qos_target > 0:
        print("QoS target met", file=sys.stderr)

    print(f"mean RPS {statistics.mean(rpsdata)}", file=sys.stderr)

if __name__ == "__main__":
    main(sys.argv[1:])
