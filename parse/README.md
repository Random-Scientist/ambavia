## Parsing

### LaTeX
Desmos expressions are internally represented in the [LaTeX](https://www.latex-project.org/) markup language.
Rich mathematical typesetting information is conveyed by calls to various macros,
which affect how their parameters are typeset.
For example, `\frac{a}{b}` typesets as a horizontal fraction bar with `a` on the top and `b` on the bottom.

The first step in parsing an expression is to parse its textual markup representation into a sequence of [`Node`](/parse/src/latex_tree.rs)s.
`Node` is a simple token tree-style data structure where leaf nodes are either `char` or a primitive LaTeX operation, and the branches correspond to various LaTeX typesetting commands.

The entry point for latex parsing is [`latex_parser::parse_latex`](/parse/src/latex_parser.rs).

### Flattening
Next, the `Nodes` are flattened into a sequence of [`Token`](/parse/src/latex_tree_flattener.rs)s that is much more convenient to parse. Delimited groups of brackets and pipes are converted from raw `Char` nodes into enum variants, as are various fundamental LaTeX symbols like those for integrals, sums/products, comparisons... etc. Equivalent ASCII math representation of some LaTeX symbols are also normalized into their corresponding `Token` variant at this stage.

The entry point for flattening is [`latex_tree_parser::flatten`](/parse/src/latex_tree_flattener.rs).

### AST Parsing
This is a fairly typical Pratt recursive parser which parses the flattened `Token` stream into an [`ExpressionListEntry`](/parse/src/ast.rs). [`ast::Expression`](/parse/src/ast.rs) is an untyped AST data structure with raw identifiers (i.e. the scoping rules for overlapping identifiers have not been applied).

The entry point for AST parsing is [`ast_parser::parse_expression_list_entry`](/parse/src/ast_parser.rs).

### Name Resolution

Desmos' variable name resolution and scoping rules are rather labrynthine due to the many possible interactions between wackscopes, dynamic rebinding via `with` and `for` as well as function parameter binding. The name resolution process consumes a list of every `ExpressionListEntry` in the graph state and returns a list of [`Assignment`](/parse/src/name_resolver.rs)s, that provide the values of all of the globals in the graphstate. [`name_resolver::Expression`](/parse/src/name_resolver.rs) is effectively an `ast::Expression` with all its function calls inlined and identifier names erased such that each usize `Identifier` node is bound by an `Assignment` exactly once.

The entry point for name resolution is [`name_resolver::resolve_names`](/parse/src/name_resolver.rs).

### Type Checking

Compared to name resolution, type checking is fairly simple. Each global `name_resolver::Assignment`
//TODO


