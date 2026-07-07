# Model Address Standard (MAS)

Reference implementations of the [MAS specification](MAS.md). MAS is a minimal client-side convention for identifying AI models via URI fragment parameters.

## Libraries

| Language   | File                                                 | API                                    |
|------------|------------------------------------------------------|----------------------------------------|
| C          | [`mas.h`](mas.h) [`mas.c`](mas.c)                   | `mas_decode(uri, &p)` → `int`         |
| C++        | [`mas.hpp`](mas.hpp)                                 | `mas::decode(uri)` → `params`          |
| Go         | [`mas.go`](mas.go) [`mas_test.go`](mas_test.go)     | `mas.Decode(uri)` → `&Params`          |
| Java       | [`Mas.java`](Mas.java)                               | `Mas.decode(uri)` → `Params`           |
| C#         | [`Mas.cs`](Mas.cs)                                   | `Mas.Decode(uri)` → `Params`           |
| PHP        | [`mas.php`](mas.php)                                 | `mas_decode($uri)` → `[m, k?]`        |
| Python     | [`mas.py`](mas.py)                                   | `mas.decode(uri)` → `{m, k?}`         |
| Ruby       | [`mas.rb`](mas.rb)                                   | `MAS.decode(uri)` → `{m, k?}`         |
| Rust       | [`mas.rs`](mas.rs)                                   | `mas::decode(uri)` → `Params`          |
| TypeScript | [`mas.ts`](mas.ts)                                   | `decode(uri)` → `{m, k?}`             |

All libraries also provide `encode` — see each file for the exact signature.

## Standard

See [MAS.md](MAS.md) for the full specification.
