# Model Address Standard (MAS)

Reference implementations of the [MAS specification](MAS.md). MAS is a minimal client-side convention for identifying AI models via URI fragment parameters.

## Libraries

| Language   | File                                   | API                              |
|------------|----------------------------------------|----------------------------------|
| Python     | [`mas.py`](mas.py)                     | `mas.decode(uri)` → `{m, k?}`   |
| Ruby       | [`mas.rb`](mas.rb)                     | `MAS.decode(uri)` → `{m, k?}`   |
| TypeScript | [`mas.ts`](mas.ts)                     | `decode(uri)` → `{m, k?}`       |
| Go         | [`mas.go`](mas.go) [`mas_test.go`](mas_test.go) | `mas.Decode(uri)` → `&Params`   |
| Rust       | [`mas.rs`](mas.rs)                     | `mas::decode(uri)` → `Params`   |

All libraries also provide `encode({m, k?})` → `#m=...&k=...`.

## Standard

See [MAS.md](MAS.md) for the full specification.
