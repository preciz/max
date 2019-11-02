# Max

A matrix library in pure Elixir based on `:array`.

```elixir
iex> matrix = Max.new(5, 5, default: 2) # 5x5 matrix with default value 2
iex> matrix = Max.set(matrix, {0, 0}, 8) # set position {0, 0} to 8
iex> Max.get(matrix, {0, 0})
8
iex> Max.to_list_of_lists(matrix)
[
  [8, 2, 2, 2, 2],
  [2, 2, 2, 2, 2],
  [2, 2, 2, 2, 2],
  [2, 2, 2, 2, 2],
  [2, 2, 2, 2, 2]
]
```

Documentation can be found at [https://hexdocs.pm/max](https://hexdocs.pm/max).

## Installation

Add `max` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:max, "~> 0.1.0"}
  ]
end
```

## License

Max is [MIT licensed](LICENSE).
