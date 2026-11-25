# Stock reorder batch

A free-format COBOL program that reads fixed-width inventory records and produces a CSV reorder report. A stock quantity below its minimum triggers an order up to the target quantity. Stock exactly at the minimum produces no order.

```sh
make test
./stock-reorder fixtures/stock.txt
```

Requires GnuCOBOL and Python 3 for the executable test harness. Ubuntu setup: `sudo apt-get install gnucobol python3 make`.

Each input line has 28 content characters:

| Columns | Field | Format |
|---|---|---|
| 1–10 | SKU | Uppercase letters, digits, hyphens and padding spaces |
| 11–16 | Current stock | Six zero-padded digits |
| 17–22 | Minimum | Six zero-padded digits |
| 23–28 | Target | Six zero-padded digits |

Quantities range from 0 to 999999. Targets below the minimum, blank/invalid SKUs, nonnumeric quantities and wrong record lengths produce REJECT rows. Invalid identifiers are withheld from CSV output. Records are assessed independently; the program does not aggregate or update inventory.

Exit status is 0 for accepted input, 2 when any row is rejected, and 1 for usage or file errors. Input must be a text file with one record per line; trailing padding spaces are ignored. Reads and closes check file status.

The independent Python harness executes the compiled COBOL binary against the checked-in fixture, 24 numeric boundary cases, five reject cases, empty input and a missing file. All checks passed with GnuCOBOL 3.1.2.0 and Python 3.12 in an Ubuntu container. Ubuntu CI rebuilds and repeats the harness.

File handling and free-format syntax follow the [GnuCOBOL manual](https://gnucobol.sourceforge.io/doc/gnucobol.html).
