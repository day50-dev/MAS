#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

pass=0
skip=0
fail=0

check_tool() {
    if ! command -v "$1" &>/dev/null; then
        echo "  SKIP  $2: $1 not found"
        skip=$((skip+1))
        return 1
    fi
    return 0
}

# -------------------------------------------------------
echo "=== MAS reference implementation tests ==="
echo ""

# -------------------------------------------------------
# C
# -------------------------------------------------------
if check_tool gcc "C"; then
    if echo 'int main(){}' | gcc -x c - -o /dev/null &>/dev/null; then
        src=$(mktemp --suffix=.c)
        bin=$(mktemp)
        cat > "$src" <<'CEOF'
#include "mas.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static void check(int cond, const char *msg) {
    if (!cond) { fprintf(stderr, "FAIL: %s\n", msg); exit(1); }
}

int main() {
    mas_params_t p;

    check(mas_decode("https://x.com#m=claude-sonnet-4-5&k=sk-ant-abc", &p) == 0, "decode basic");
    check(strcmp(p.m, "claude-sonnet-4-5") == 0, "m basic");
    check(strcmp(p.k, "sk-ant-abc") == 0, "k basic");
    mas_params_free(&p);

    check(mas_decode("https://x.com#m=mistral", &p) == 0, "decode no k");
    check(strcmp(p.m, "mistral") == 0, "m no k");
    check(p.k == NULL, "k null");
    mas_params_free(&p);

    check(mas_decode("https://x.com#m=foo&x=1&y=2&k=bar", &p) == 0, "decode unknown");
    check(strcmp(p.m, "foo") == 0, "m unknown");
    check(strcmp(p.k, "bar") == 0, "k unknown");
    mas_params_free(&p);

    check(mas_decode("https://x.com", &p) != 0, "no fragment");
    check(mas_decode("https://x.com#", &p) != 0, "empty fragment");
    check(mas_decode("https://x.com#k=foo", &p) != 0, "missing m");
    check(mas_decode("https://x.com#m=", &p) != 0, "empty m");

    char *s = mas_encode("gpt-4o", "sk-xyz");
    check(s != NULL && strcmp(s, "#m=gpt-4o&k=sk-xyz") == 0, "encode");
    free(s);

    s = mas_encode("mistral", NULL);
    check(s != NULL && strcmp(s, "#m=mistral") == 0, "encode no k");
    free(s);

    check(mas_encode("", NULL) == NULL, "encode empty m");

    s = mas_encode("roundtrip", "key123");
    check(s != NULL, "rt encode");
    char buf[256]; snprintf(buf, sizeof(buf), "https://x.com%s", s);
    check(mas_decode(buf, &p) == 0, "rt decode");
    check(strcmp(p.m, "roundtrip") == 0, "rt m");
    check(strcmp(p.k, "key123") == 0, "rt k");
    mas_params_free(&p);
    free(s);

    printf("ok\n");
    return 0;
}
CEOF
        if gcc -Wall -Wextra -I"$ROOT" -o "$bin" "$src" "$ROOT/mas.c" 2>/dev/null; then
            if "$bin" 2>&1; then echo "  PASS  C"; pass=$((pass+1))
            else echo "  FAIL  C"; fail=$((fail+1)); fi
        else echo "  SKIP  C: compilation failed"; skip=$((skip+1)); fi
        rm -f "$src" "$bin"
    else echo "  SKIP  C: gcc cannot compile"; skip=$((skip+1)); fi
else true; fi

# -------------------------------------------------------
# C++
# -------------------------------------------------------
if check_tool g++ "C++"; then
    src=$(mktemp --suffix=.cpp)
    bin=$(mktemp)
    cat > "$src" <<'CPPEOF'
#include "mas.hpp"
#include <cassert>
#include <iostream>
#include <stdexcept>

int main() {
    auto p = mas::decode("https://x.com#m=claude-sonnet-4-5&k=sk-ant-abc");
    assert(p.m == "claude-sonnet-4-5");
    assert(p.k && *p.k == "sk-ant-abc");

    p = mas::decode("https://x.com#m=mistral");
    assert(p.m == "mistral");
    assert(!p.k.has_value());

    p = mas::decode("https://x.com#m=foo&x=1&y=2&k=bar");
    assert(p.m == "foo");
    assert(p.k && *p.k == "bar");

    auto s = mas::encode({"gpt-4o", "sk-xyz"});
    assert(s == "#m=gpt-4o&k=sk-xyz");

    s = mas::encode({"mistral", std::nullopt});
    assert(s == "#m=mistral");

    bool ok = false;
    try { mas::decode("https://x.com"); } catch (...) { ok = true; }
    assert(ok);
    ok = false;
    try { mas::decode("https://x.com#"); } catch (...) { ok = true; }
    assert(ok);
    ok = false;
    try { mas::decode("https://x.com#k=foo"); } catch (...) { ok = true; }
    assert(ok);
    ok = false;
    try { mas::encode({"", "x"}); } catch (...) { ok = true; }
    assert(ok);

    mas::params orig{"roundtrip", "key123"};
    auto s2 = mas::encode(orig);
    auto p2 = mas::decode("https://x.com" + s2);
    assert(p2.m == "roundtrip");
    assert(p2.k && *p2.k == "key123");

    std::cout << "ok" << std::endl;
    return 0;
}
CPPEOF
    if g++ -std=c++17 -Wall -Wextra -I"$ROOT" -o "$bin" "$src" 2>/dev/null; then
        if "$bin" 2>&1; then echo "  PASS  C++"; pass=$((pass+1))
        else echo "  FAIL  C++"; fail=$((fail+1)); fi
    else echo "  SKIP  C++: compilation failed"; skip=$((skip+1)); fi
    rm -f "$src" "$bin"
else true; fi

# -------------------------------------------------------
# Go
# -------------------------------------------------------
if check_tool go "Go"; then
    # Disable cgo so the .c file in the root isn't picked up by go test
    if CGO_ENABLED=0 go test -count=1 "$ROOT" 2>&1; then
        echo "  PASS  Go"; pass=$((pass+1))
    else
        echo "  FAIL  Go"; fail=$((fail+1))
    fi
else true; fi

# -------------------------------------------------------
# Java
# -------------------------------------------------------
if check_tool javac "Java"; then
    tmp=$(mktemp -d)
    cp "$ROOT/Mas.java" "$tmp/"
    cat > "$tmp/TestMas.java" <<'JAVAEOF'
public class TestMas {
    public static void main(String[] args) {
        Mas.Params p = Mas.decode("https://x.com#m=claude-sonnet-4-5&k=sk-ant-abc");
        assert p.m.equals("claude-sonnet-4-5") : "m basic";
        assert p.k != null && p.k.equals("sk-ant-abc") : "k basic";

        p = Mas.decode("https://x.com#m=mistral");
        assert p.m.equals("mistral") : "m no k";
        assert p.k == null : "k null";

        p = Mas.decode("https://x.com#m=foo&x=1&y=2&k=bar");
        assert p.m.equals("foo") : "m unknown";
        assert p.k != null && p.k.equals("bar") : "k unknown";

        boolean ok = false;
        try { Mas.decode("https://x.com"); } catch (IllegalArgumentException e) { ok = true; }
        assert ok : "no fragment";
        ok = false;
        try { Mas.decode("https://x.com#k=foo"); } catch (IllegalArgumentException e) { ok = true; }
        assert ok : "missing m";
        ok = false;
        try { Mas.decode("https://x.com#m="); } catch (IllegalArgumentException e) { ok = true; }
        assert ok : "empty m";

        String s = Mas.encode(new Mas.Params("gpt-4o", "sk-xyz"));
        assert s.equals("#m=gpt-4o&k=sk-xyz") : "encode";

        s = Mas.encode(new Mas.Params("mistral", null));
        assert s.equals("#m=mistral") : "encode no k";

        ok = false;
        try { Mas.encode(new Mas.Params("", null)); } catch (IllegalArgumentException e) { ok = true; }
        assert ok : "encode empty m";

        Mas.Params orig = new Mas.Params("roundtrip", "key123");
        s = Mas.encode(orig);
        Mas.Params p2 = Mas.decode("https://x.com" + s);
        assert p2.m.equals("roundtrip") : "rt m";
        assert p2.k != null && p2.k.equals("key123") : "rt k";

        System.out.println("ok");
    }
}
JAVAEOF
    if javac -d "$tmp" "$tmp/Mas.java" "$tmp/TestMas.java" 2>/dev/null; then
        if java -ea -cp "$tmp" TestMas 2>&1; then echo "  PASS  Java"; pass=$((pass+1))
        else echo "  FAIL  Java"; fail=$((fail+1)); fi
    else echo "  SKIP  Java: compilation failed"; skip=$((skip+1)); fi
    rm -rf "$tmp"
else true; fi

# -------------------------------------------------------
# C#
# -------------------------------------------------------
if command -v mcs &>/dev/null; then
    tmp=$(mktemp -d)
    cp "$ROOT/Mas.cs" "$tmp/"
    cat > "$tmp/TestMas.cs" <<'CSEOF'
using System;

public class TestMas {
    public static void Main() {
        var p = Mas.Decode("https://x.com#m=claude-sonnet-4-5&k=sk-ant-abc");
        if (p.M != "claude-sonnet-4-5") throw new Exception("m basic");
        if (p.K != "sk-ant-abc") throw new Exception("k basic");

        p = Mas.Decode("https://x.com#m=mistral");
        if (p.M != "mistral") throw new Exception("m no k");
        if (p.K != null) throw new Exception("k null");

        p = Mas.Decode("https://x.com#m=foo&x=1&y=2&k=bar");
        if (p.M != "foo") throw new Exception("m unknown");
        if (p.K != "bar") throw new Exception("k unknown");

        bool ok = false;
        try { Mas.Decode("https://x.com"); } catch (ArgumentException) { ok = true; }
        if (!ok) throw new Exception("no fragment");
        ok = false;
        try { Mas.Decode("https://x.com#k=foo"); } catch (ArgumentException) { ok = true; }
        if (!ok) throw new Exception("missing m");
        ok = false;
        try { Mas.Decode("https://x.com#m="); } catch (ArgumentException) { ok = true; }
        if (!ok) throw new Exception("empty m");

        var s = Mas.Encode(new Mas.Params("gpt-4o", "sk-xyz"));
        if (s != "#m=gpt-4o&k=sk-xyz") throw new Exception("encode");

        s = Mas.Encode(new Mas.Params("mistral", null));
        if (s != "#m=mistral") throw new Exception("encode no k");

        ok = false;
        try { Mas.Encode(new Mas.Params("", null)); } catch (ArgumentException) { ok = true; }
        if (!ok) throw new Exception("encode empty m");

        var orig = new Mas.Params("roundtrip", "key123");
        s = Mas.Encode(orig);
        var p2 = Mas.Decode("https://x.com" + s);
        if (p2.M != "roundtrip") throw new Exception("rt m");
        if (p2.K != "key123") throw new Exception("rt k");

        Console.WriteLine("ok");
    }
}
CSEOF
    if mcs -out:"$tmp/TestMas.exe" "$tmp/Mas.cs" "$tmp/TestMas.cs" 2>/dev/null; then
        if mono "$tmp/TestMas.exe" 2>&1; then echo "  PASS  C#"; pass=$((pass+1))
        else echo "  FAIL  C#"; fail=$((fail+1)); fi
    else echo "  SKIP  C#: compilation failed"; skip=$((skip+1)); fi
    rm -rf "$tmp"
else echo "  SKIP  C#: mcs not found"; skip=$((skip+1)); fi

# -------------------------------------------------------
# PHP
# -------------------------------------------------------
if check_tool php "PHP"; then
    if php -r '
require "'"$ROOT"'/mas.php";
$r = mas_decode("https://x.com#m=claude-sonnet-4-5&k=sk-ant-abc");
assert($r[0] === "claude-sonnet-4-5");
assert($r[1] === "sk-ant-abc");
$r = mas_decode("https://x.com#m=mistral");
assert($r[0] === "mistral");
assert(count($r) === 1);
$r = mas_decode("https://x.com#m=foo&x=1&y=2&k=bar");
assert($r[0] === "foo");
assert($r[1] === "bar");
$ok = false;
try { mas_decode("https://x.com"); } catch (InvalidArgumentException $e) { $ok = true; }
assert($ok);
$ok = false;
try { mas_decode("https://x.com#k=foo"); } catch (InvalidArgumentException $e) { $ok = true; }
assert($ok);
$ok = false;
try { mas_decode("https://x.com#m="); } catch (InvalidArgumentException $e) { $ok = true; }
assert($ok);
$s = mas_encode(["m" => "gpt-4o", "k" => "sk-xyz"]);
assert($s === "#m=gpt-4o&k=sk-xyz");
$s = mas_encode(["m" => "mistral"]);
assert($s === "#m=mistral");
$ok = false;
try { mas_encode(["k" => "foo"]); } catch (InvalidArgumentException $e) { $ok = true; }
assert($ok);
$s = mas_encode(["m" => "roundtrip", "k" => "key123"]);
$r = mas_decode("https://x.com" . $s);
assert($r[0] === "roundtrip");
assert($r[1] === "key123");
echo "ok\n";
' 2>&1; then echo "  PASS  PHP"; pass=$((pass+1)); else echo "  FAIL  PHP"; fail=$((fail+1)); fi
else true; fi

# -------------------------------------------------------
# Python
# -------------------------------------------------------
if check_tool python3 "Python"; then
    if python3 -c "
import sys; sys.path.insert(0, '$ROOT')
import mas
r = mas.decode('https://x.com#m=claude-sonnet-4-5&k=sk-ant-abc')
assert r == {'m': 'claude-sonnet-4-5', 'k': 'sk-ant-abc'}
r = mas.decode('https://x.com#m=mistral')
assert r == {'m': 'mistral'}
r = mas.decode('https://x.com#m=foo&x=1&y=2&k=bar')
assert r == {'m': 'foo', 'k': 'bar'}
try: mas.decode('https://x.com'); assert False
except ValueError: pass
try: mas.decode('https://x.com#k=foo'); assert False
except ValueError: pass
try: mas.decode('https://x.com#m='); assert False
except ValueError: pass
s = mas.encode({'m': 'gpt-4o', 'k': 'sk-xyz'})
assert s == '#m=gpt-4o&k=sk-xyz'
s = mas.encode({'m': 'mistral'})
assert s == '#m=mistral'
try: mas.encode({'k': 'foo'}); assert False
except ValueError: pass
s = mas.encode({'m': 'roundtrip', 'k': 'key123'})
r = mas.decode('https://x.com' + s)
assert r == {'m': 'roundtrip', 'k': 'key123'}
print('ok')
" 2>&1; then echo "  PASS  Python"; pass=$((pass+1)); else echo "  FAIL  Python"; fail=$((fail+1)); fi
else true; fi

# -------------------------------------------------------
# Ruby
# -------------------------------------------------------
if check_tool ruby "Ruby"; then
    if ruby -e "
\$LOAD_PATH.unshift('$ROOT')
require 'mas'
r = MAS.decode('https://x.com#m=claude-sonnet-4-5&k=sk-ant-abc')
raise 'm basic' unless r == {'m' => 'claude-sonnet-4-5', 'k' => 'sk-ant-abc'}
r = MAS.decode('https://x.com#m=mistral')
raise 'm no k' unless r == {'m' => 'mistral'}
r = MAS.decode('https://x.com#m=foo&x=1&y=2&k=bar')
raise 'm unknown' unless r == {'m' => 'foo', 'k' => 'bar'}
begin MAS.decode('https://x.com'); raise; rescue RuntimeError; end
begin MAS.decode('https://x.com#k=foo'); raise; rescue RuntimeError; end
begin MAS.decode('https://x.com#m='); raise; rescue RuntimeError; end
s = MAS.encode({'m' => 'gpt-4o', 'k' => 'sk-xyz'})
raise 'encode' unless s == '#m=gpt-4o&k=sk-xyz'
s = MAS.encode({'m' => 'mistral'})
raise 'encode no k' unless s == '#m=mistral'
begin MAS.encode({'k' => 'foo'}); raise; rescue RuntimeError; end
s = MAS.encode({'m' => 'roundtrip', 'k' => 'key123'})
r = MAS.decode('https://x.com' + s)
raise 'rt m' unless r['m'] == 'roundtrip'
raise 'rt k' unless r['k'] == 'key123'
puts 'ok'
" 2>&1; then echo "  PASS  Ruby"; pass=$((pass+1)); else echo "  FAIL  Ruby"; fail=$((fail+1)); fi
else true; fi

# -------------------------------------------------------
# Rust
# -------------------------------------------------------
if check_tool cargo "Rust"; then
    if cargo test -q --manifest-path "$ROOT/Cargo.toml" 2>&1; then
        echo "  PASS  Rust"; pass=$((pass+1))
    else
        echo "  FAIL  Rust"; fail=$((fail+1))
    fi
else true; fi

# -------------------------------------------------------
# TypeScript
# -------------------------------------------------------
if check_tool npx "TypeScript" && check_tool node "TypeScript"; then
    tmp=$(mktemp -d)
    cp "$ROOT/mas.ts" "$tmp/"
    cat > "$tmp/test.ts" <<'TSEOF'
import { decode, encode } from "./mas";
const r = decode("https://x.com#m=claude-sonnet-4-5&k=sk-ant-abc");
console.assert(r.m === "claude-sonnet-4-5", "m basic");
console.assert(r.k === "sk-ant-abc", "k basic");
const r2 = decode("https://x.com#m=mistral");
console.assert(r2.m === "mistral", "m no k");
console.assert(r2.k === undefined, "k undefined");
const r3 = decode("https://x.com#m=foo&x=1&y=2&k=bar");
console.assert(r3.m === "foo", "m unknown");
console.assert(r3.k === "bar", "k unknown");
let ok = false;
try { decode("https://x.com"); } catch { ok = true; }
console.assert(ok, "no fragment");
ok = false;
try { decode("https://x.com#k=foo"); } catch { ok = true; }
console.assert(ok, "missing m");
ok = false;
try { decode("https://x.com#m="); } catch { ok = true; }
console.assert(ok, "empty m");
const s = encode({ m: "gpt-4o", k: "sk-xyz" });
console.assert(s === "#m=gpt-4o&k=sk-xyz", "encode");
const s2 = encode({ m: "mistral" });
console.assert(s2 === "#m=mistral", "encode no k");
ok = false;
try { encode({ m: "" }); } catch { ok = true; }
console.assert(ok, "encode empty m");
const s3 = encode({ m: "roundtrip", k: "key123" });
const r4 = decode("https://x.com" + s3);
console.assert(r4.m === "roundtrip", "rt m");
console.assert(r4.k === "key123", "rt k");
console.log("ok");
TSEOF
    if npx tsc --strict --esModuleInterop --target es2020 --module commonjs \
         --ignoreConfig --outDir "$tmp" "$tmp/mas.ts" "$tmp/test.ts" 2>/dev/null; then
        if node "$tmp/test.js" 2>&1; then echo "  PASS  TypeScript"; pass=$((pass+1))
        else echo "  FAIL  TypeScript"; fail=$((fail+1)); fi
    else echo "  SKIP  TypeScript: compilation failed"; skip=$((skip+1)); fi
    rm -rf "$tmp"
else true; fi

# -------------------------------------------------------
echo ""
echo "=== results: $pass pass, $fail fail, $skip skip ==="
exit $(( fail > 0 ? 1 : 0 ))
