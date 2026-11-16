# Mutation patterns and the tests that catch them

The exact set of mutants changes between releases. `cargo mutants --list
--diff` shows what the installed version generates for the code at hand; the
tables here explain the kinds and how to respond.

## What is never mutated

- Functions and files under `#[cfg(test)]`, and functions with an attribute
  whose path ends in `test` (`#[test]`, `#[tokio::test]`, `#[sqlx::test]`).
- `unsafe` functions.
- Items marked `#[mutants::skip]`.
- Macro invocations, `macro_rules!` definitions, and macro expansions. Bodies
  of `#[proc_macro]` functions are mutated.
- Code produced by build scripts.

A crate that is mostly macros or generated code yields few mutants. Zero
missed mutants in such code says nothing about its tests.

`cfg` and `cfg_attr` conditions are not evaluated. Code for another platform
or feature is mutated anyway and can show as missed.

## Reading a mutant name

```text
src/lib.rs:485:5: replace copy_symlink -> Result<()> with Ok(Default::default())
└ location        └ what was changed                     └ what it became
```

Read it as a claim: "if `copy_symlink` did nothing and reported success, no
test would fail." The matching file under `mutants.out/diff/` shows the exact
edit.

## Kinds of mutant and the test that catches each

**Function body replaced by a value** (`replace f -> T with …`). The tests do
not depend on what `f` returns or does.

- `with ()`: nothing observes the side effect. Assert the effect: the file
  written, the state changed, the message sent, the counter moved.
- `with true` / `with false`: assert both outcomes, with one input for each.
- `with 0`, `1`, `-1`: assert an exact result for an input whose answer is
  none of those constants.
- `with String::new()` / `"xyzzy".into()`, `with vec![]`, `with None`,
  `with Default::default()`: assert the content, not only presence, length, or
  success.
- `with Ok(…)`: a test checks `is_ok()` or ignores the value. Assert what the
  `Ok` carries or the effect of the call.
- `with Err(…)` (only when error values are configured): only failure paths
  are tested. Add a success-path test.

**Binary operator replaced** (`replace == with !=`, `< with >`, `+ with -`).

- Comparison: test at the boundary and on each side of it. A test that uses
  only values far from the boundary cannot tell `<` from `<=`.
- Logical and/or: use cases where exactly one operand is true.
- Arithmetic: pick operands for which the two operators differ. Avoid 0, 1,
  and pairs such as `2 + 2` and `2 * 2`.
- Bitwise and shifts: use operands with distinct bit patterns and non-zero
  shift counts.
- Compound assignment (`+=`, `|=`): start from a non-zero accumulator.

**Unary operator deleted** (`delete !`, `delete -`). Test an input for each
polarity or sign.

**Match arm deleted** (`delete match arm …`; only when a wildcard arm exists).
Test an input that selects that arm and whose expected result differs from
the wildcard arm's.

**Match guard replaced** (`replace match guard … with true` or `false`). Test
one input for which the guard holds and one for which it does not, with
different expected results.

**Struct field deleted** (only in literals with a base such as
`..Default::default()`). Assert that the field has its intended, non-default
value.

## Return-value replacements

| Return type | Replacements |
| --- | --- |
| `()` | `()` |
| signed integers | `0`, `1`, `-1` |
| unsigned integers | `0`, `1` |
| floats | `0.0`, `1.0`, `-1.0` |
| `NonZero*` | `1`, and `-1` when the type may be signed |
| `bool` | `true`, `false` |
| `String` | `String::new()`, `"xyzzy".into()` |
| `&str` | `""`, `"xyzzy"` |
| `Option<T>` | `None`, `Some(…)` |
| `Result<T, E>` | `Ok(…)`, and `Err(…)` for each configured error value |
| `Vec<T>` | `vec![]`, `vec![…]` |
| `Box<T>`, `Rc<T>`, `Arc<T>` | the wrapper around each replacement of `T` |
| sets, deques, heaps, lists | empty and one-element collections |
| maps | empty, and one entry for each key and value replacement |
| `Cow<'_, T>` | borrowed and owned replacements |
| `[T; N]` | the array filled with each replacement of `T` |
| `&T`, `&mut T`, `&[T]`, `&mut [T]` | leaked boxes and vectors of the replacements |
| tuples | every combination of the element replacements |
| `impl Iterator` | empty and one-element iterators |
| `HttpResponse` | an empty OK response |
| anything else | `Default::default()` |

`…` means the inner type is mutated in turn: `Result<Option<String>>` yields
`Ok(None)`, `Ok(Some(String::new()))`, and so on. A replacement that does not
type-check is reported as unviable and needs no action.

## Operator replacements

```text
==  ->  !=                  !=  ->  ==
&&  ->  ||                  ||  ->  &&
<   ->  ==  >  <=           >   ->  ==  <  >=
<=  ->  >                   >=  ->  <
+   ->  -  *                -   ->  +  /
*   ->  +  /                /   ->  %  *
%   ->  /  +
<<  ->  >>                  >>  ->  <<
&   ->  |  ^                |   ->  &  ^               ^  ->  &  |
&=  ->  |=                  |=  ->  &=                 ^= ->  |=  &=
+= -= *= /= %= <<= >>=      as for the plain operator
```

This is the set in 27.1.0. The `<` to `<=` and `>` to `>=` replacements exist
from 25.1.0; they are the ones that only a test at the exact boundary catches.
Equality is not replaced by ordering comparisons, and `|=`/`&=` are not
replaced by `^=`, because those mutants were too often equivalent.

## Error values

The tool cannot guess how to build a crate's error type. Tell it, without the
`Err(…)` wrapper, and it will try each value where it type-checks:

```toml
# .cargo/mutants.toml
error_values = ["::anyhow::anyhow!(\"mutated\")", "crate::Error::Generic"]
```

The same is available as `--error EXPR`. This belongs in the config file,
because it is a property of the code, not of one run.

## Recognizing mutants that need no test

Decide these on evidence, mutant by mutant. When in doubt, write the test.

- **Equivalent.** The change cannot be observed: the original and the mutant
  compute the same thing for every reachable input, such as `x * 1` to
  `x / 1`, or a guard that an earlier check already makes true.
  First ask whether the code is redundant; removing it may be the better fix.
- **Numerical policy.** Real-number algebra is not a floating-point proof:
  rounding, overflow, NaN, signed zero, and boundary comparisons can distinguish
  apparently redundant expressions. Try exact equalities and adjacent
  representable inputs, and state the valid-input/caller invariants behind an
  equivalence argument. A finite corpus with no difference does not prove
  equivalence. If differences are accepted under an existing tolerance,
  classify the exclusion as numerical policy, state the tolerance and affected
  observable, and report measured evidence separately from the argument.
  Do not invent a tolerance just to remove a survivor; unresolved cases stay open.
- **Performance only.** Caches, capacity hints, fast paths with a slower
  correct fallback. Results do not change, so functional tests cannot fail.
  Make the effect observable (a hit counter, an allocation count) when it
  matters; otherwise skip with the reason.
- **Would hang.** A changed loop-termination condition can expose a real
  termination failure. Keep it as a timeout while investigating; reproduce
  under a bounded harness and distinguish it from an overly tight limit or
  test interference. Exclude only with an explicit policy reason, and keep
  the timeout evidence. Do not change production semantics just to finish a run.
- **Diagnostic output.** `Debug` implementations and log text, when the
  project does not treat them as a contract.
