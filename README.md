# Ambavia

Incomplete implementation of [Desmos Graphing Calculator](https://www.desmos.com/calculator).

Currently there's an expression list you can type things into and see the results of.

## Subcrates at a glance
* [`parse`](/parse/src/): contains the infrastructure for parsing, name resolving and type checking Desmos expressions. See the [crate readme](/parse/README.md) for more information.
* [`eval`](/eval/src/): contains a simple stack-based bytecode VM for expression evaluation, as well as a compiler that transforms a [`TypedExpression`](/parse/src/type_checker.rs) program tree into a linear sequence of VM instructions.
* [`ui`](/ui/src/): binary crate that contains the UI implementation and its custom equation editor.


## Credits

- Fonts are from [KaTeX](https://github.com/KaTeX/KaTeX).
- Font atlas generated with [msdf-atlas-gen](https://github.com/Chlumsky/msdf-atlas-gen).
