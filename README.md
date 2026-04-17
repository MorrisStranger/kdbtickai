# kdbtickai

This repository contains:

- `feedhandler.q` — a feed handler that publishes random `trade` and `quote` rows to a tickerplant.
- `tick.q` — the official KxSystems `tick.q` tickerplant script.
- `tick-custom.q` — a backup of the original local `tick.q` before replacing it with the official version.

## Usage

### Start the tickerplant

The tickerplant must be running before the feed handler connects.

```bash
q tick.q schema localhost:5010
```

This loads the schema file at `tick/schema.q`, which defines the `trade` and `quote` tables.

### Start the feed handler

```bash
q feedhandler.q localhost:5010
```

This will publish random batches of trades and quotes to the tickerplant every 500ms.

## Notes

- `tick.q` in this repo is the official KxSystems tickerplant implementation.
- `tick-custom.q` is the preserved local copy of the previous tickerplant file.
- `feedhandler.q` publishes 1–4 rows per tick for both `trade` and `quote`.

## Example workflow

```bash
cd /path/to/kdbtickai
q tick.q schema.q localhost:5010
q feedhandler.q localhost:5010
```

If you want to use a different host or port, change the argument passed to `feedhandler.q` accordingly.
