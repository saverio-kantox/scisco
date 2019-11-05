# Scisco

Easy query builder for Ecto.

Pronounciation: ʃːisko (Shisko), which is a synonym of "quaero".

This package implements a simplified behavior for querying Ecto schemas, based
on a common browser <-> API <-> database set of functions.

A module implementing it will have two public functions: `list/1` and `get_page_count/1`,
both accepting a map with the same keys: `:page`, `:filter` and `:sort`.

The semantics of the parameters are strongly inspired by [JSON:API](https://jsonapi.org/format/#fetching-sorting).

See `Scisco.Query` for more information.

## Installation

The package can be installed
by adding `scisco` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:scisco, "~> 0.1.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/scisco](https://hexdocs.pm/scisco).
