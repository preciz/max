defmodule Max do
  @enforce_keys [:array, :rows, :columns]
  defstruct [:array, :rows, :columns]

  @type t :: %Max{
          array: tuple,
          rows: pos_integer,
          columns: pos_integer
        }

  @type position :: {row :: non_neg_integer, col :: non_neg_integer}

  @spec new(pos_integer, pos_integer, list) :: t
  def new(rows, columns, options \\ []) do
    default = Keyword.get(options, :default, :undefined)

    array = :array.new(rows * columns, fixed: true, default: default)

    %Max{
      array: array,
      rows: rows,
      columns: columns
    }
  end

  @spec from_list(nonempty_list, pos_integer, pos_integer, list) :: t
  def from_list(list, rows, columns, options \\ []) do
    default = Keyword.get(options, :default, :undefined)

    array =
      :array.resize(
        rows * columns,
        :array.from_list(list, default)
      )
      |> :array.fix()

    %Max{
      array: array,
      rows: rows,
      columns: columns
    }
  end

  @spec from_list_of_lists(nonempty_list(nonempty_list), list) :: t
  def from_list_of_lists([h | _] = list, options \\ []) do
    default = Keyword.get(options, :default, :undefined)

    rows = length(list)
    columns = length(h)

    array =
      :array.resize(
        rows * columns,
        :array.from_list(List.flatten(list), default)
      )
      |> :array.fix()

    %Max{
      array: array,
      rows: rows,
      columns: columns
    }
  end

  @doc """
  Returns the default value for matrix.

  ## Examples

      iex> matrix = Max.from_list_of_lists([[1,2], [3,4]])
      iex> matrix |> Max.default()
      :undefined
      iex> matrix = Max.new(5, 5, default: "preciz")
      iex> matrix |> Max.default()
      "preciz"

  """
  @spec default(t) :: any
  def default(%Max{array: array}), do: :array.default(array)

  @doc """
  Returns the element count of matrix. (rows * columns)

  ## Examples

      iex> matrix = Max.new(5, 5)
      iex> Max.count(matrix)
      25

  """
  @spec count(t) :: pos_integer
  def count(%Max{rows: rows, columns: columns}) do
    rows * columns
  end

  @doc """
  Returns a position tuple for the given index.

  `:array` indices are 0 based.

  ## Examples

      iex> matrix = Max.new(5, 5)
      iex> matrix |> Max.position_to_index({0, 0})
      0
      iex> matrix |> Max.position_to_index({1, 0})
      5

  """
  @spec position_to_index(t, position) :: pos_integer
  def position_to_index(%Max{rows: rows, columns: columns}, {row, col})
      when row >= 0 and row < rows and col >= 0 and col < columns do
    row * columns + col
  end

  @doc """
  Returns array index corresponding to the position tuple.

  ## Examples

      iex> matrix = Max.new(10, 10)
      iex> matrix |> Max.position_to_index({1, 1})
      11
      iex> matrix |> Max.position_to_index({0, 4})
      4

  """
  @spec index_to_position(t, non_neg_integer) :: position
  def index_to_position(%Max{columns: columns}, index) do
    {div(index, columns), rem(index, columns)}
  end

  @spec get(t, position) :: any
  def get(%Max{array: array} = matrix, position) do
    index = position_to_index(matrix, position)

    :array.get(index, array)
  end

  @spec set(t, position, any) :: t
  def set(%Max{array: array} = matrix, position, value) do
    index = position_to_index(matrix, position)

    %Max{matrix | array: :array.set(index, value, array)}
  end

  @spec set_row(t, non_neg_integer, t) :: t
  def set_row(
        %Max{columns: columns} = matrix,
        row_index,
        %Max{columns: columns, rows: 1} = row_matrix
      ) do
    0..(columns - 1)
    |> Enum.reduce(matrix, fn col, acc ->
      set(
        acc,
        {row_index, col},
        get(row_matrix, {0, col})
      )
    end)
  end

  @spec set_column(t, non_neg_integer, t) :: t
  def set_column(
        %Max{rows: rows} = matrix,
        column_index,
        %Max{rows: rows, columns: 1} = column_matrix
      ) do
    0..(rows - 1)
    |> Enum.reduce(matrix, fn row, acc ->
      set(
        acc,
        {row, column_index},
        get(column_matrix, {row, 0})
      )
    end)
  end

  @spec to_list(t) :: list
  def to_list(%Max{array: array}) do
    :array.to_list(array)
  end

  @spec min(t) :: any
  def min(%Max{} = matrix) do
    {_index, value} = do_argmin(matrix)

    value
  end

  @spec max(t) :: any
  def max(%Max{} = matrix) do
    {_index, value} = do_argmax(matrix)

    value
  end

  @doc """
  ## Examples

      iex> matrix = Max.new(5, 5, default: 8)
      iex> matrix |> Max.argmin()
      {0, 0}
      iex> matrix = matrix |> Max.set({1, 1}, 7)
      iex> matrix |> Max.argmin()
      {1, 1}

  """
  @spec argmin(t) :: any
  def argmin(%Max{} = matrix) do
    {index, _value} = do_argmin(matrix)

    index_to_position(matrix, index)
  end

  @doc """
  ## Examples

      iex> matrix = Max.new(5, 5, default: 8)
      iex> matrix |> Max.argmax()
      {0, 0}
      iex> matrix = matrix |> Max.set({1, 1}, 10)
      iex> matrix |> Max.argmax()
      {1, 1}

  """
  @spec argmax(t) :: any
  def argmax(%Max{} = matrix) do
    {index, _value} = do_argmax(matrix)

    index_to_position(matrix, index)
  end

  @doc false
  def do_argmin(%Max{} = matrix) do
    sparse_foldl(
      matrix,
      fn index, value, {_acc_index, acc_val} = acc ->
        case min(value, acc_val) do
          ^acc_val ->
            acc

          _else ->
            {index, value}
        end
      end,
      {0, default(matrix)}
    )
  end

  @doc false
  def do_argmax(%Max{} = matrix) do
    sparse_foldl(
      matrix,
      fn index, value, {_acc_index, acc_val} = acc ->
        case max(value, acc_val) do
          ^acc_val ->
            acc

          _else ->
            {index, value}
        end
      end,
      {0, default(matrix)}
    )
  end

  @spec reshape(t, pos_integer, pos_integer) :: t
  def reshape(%Max{} = matrix, rows, columns) do
    %Max{matrix | rows: rows, columns: columns}
  end

  @spec map(t, fun) :: t
  def map(%Max{array: array} = matrix, fun) when is_function(fun, 2) do
    %Max{matrix | array: :array.map(fun, array)}
  end

  @spec sparse_map(t, fun) :: t
  def sparse_map(%Max{array: array} = matrix, fun) when is_function(fun, 2) do
    %Max{matrix | array: :array.sparse_map(fun, array)}
  end

  @spec foldl(t, function, any) :: any
  def foldl(%Max{array: array}, fun, acc) when is_function(fun, 3) do
    :array.foldl(fun, acc, array)
  end

  @spec foldr(t, function, any) :: any
  def foldr(%Max{array: array}, fun, acc) when is_function(fun, 3) do
    :array.foldr(fun, acc, array)
  end

  @spec sparse_foldl(t, function, any) :: any
  def sparse_foldl(%Max{array: array}, fun, acc) when is_function(fun, 3) do
    :array.sparse_foldl(fun, acc, array)
  end

  @spec sparse_foldr(t, function, any) :: any
  def sparse_foldr(%Max{array: array}, fun, acc) when is_function(fun, 3) do
    :array.sparse_foldr(fun, acc, array)
  end

  @spec reset(t, position) :: t
  def reset(%Max{array: array} = matrix, position) do
    index = position_to_index(matrix, position)

    %Max{matrix | array: :array.reset(index, array)}
  end

  @spec row(t, non_neg_integer) :: t
  def row(%Max{rows: rows, columns: columns} = matrix, row) when row in 0..(rows - 1) do
    for col <- 0..(columns - 1) do
      get(matrix, {row, col})
    end
    |> from_list(1, columns, default: default(matrix))
  end

  @spec column(t, non_neg_integer) :: t
  def column(%Max{rows: rows, columns: columns} = matrix, col) when col in 0..(columns - 1) do
    for row <- 0..(rows - 1) do
      get(matrix, {row, col})
    end
    |> from_list(rows, 1, default: default(matrix))
  end

  @spec row_to_list(t, non_neg_integer) :: list
  def row_to_list(%Max{rows: rows, columns: columns} = matrix, row) when row in 0..(rows - 1) do
    for col <- 0..(columns - 1) do
      get(matrix, {row, col})
    end
  end

  @spec column_to_list(t, non_neg_integer) :: list
  def column_to_list(%Max{rows: rows, columns: columns} = matrix, col)
      when col in 0..(columns - 1) do
    for row <- 0..(rows - 1) do
      get(matrix, {row, col})
    end
  end

  @spec to_list_of_lists(t) :: list
  def to_list_of_lists(%Max{rows: rows, columns: columns} = matrix) do
    for row <- 0..(rows - 1) do
      for col <- 0..(columns - 1) do
        get(matrix, {row, col})
      end
    end
  end

  @spec concat(nonempty_list(t), :rows | :columns, list) :: t | no_return
  def concat([%Max{rows: rows, columns: columns} | _] = list, concat_type, options \\ [])
      when length(list) > 0 do
    default = Keyword.get(options, :default, :undefined)

    can_concat? =
      case concat_type do
        :columns ->
          list |> Enum.all?(&(&1.rows == rows))

        :rows ->
          list |> Enum.all?(&(&1.columns == columns))
      end

    if not can_concat? do
      raise ArgumentError,
            "When concatenating by #{inspect(concat_type)} all matrices should " <>
              "have the same number of #{if(concat_type == :row, do: "columns", else: "rows")}"
    end

    size =
      list
      |> Enum.map(&count/1)
      |> Enum.sum()

    array = :array.new(size, default: default)

    {rows, columns} =
      case concat_type do
        :rows ->
          {round(size / columns), columns}

        :columns ->
          {rows, round(size / rows)}
      end

    matrix = %Max{array: array, rows: rows, columns: columns}

    do_concat(list, matrix, 0, 0, concat_type)
  end

  defp do_concat([], matrix, _, _, _), do: matrix

  defp do_concat([%Max{rows: rows} | tail], matrix, target_index, source_index, :rows)
       when source_index == rows do
    do_concat(tail, matrix, target_index, 0, :rows)
  end

  defp do_concat([%Max{columns: columns} | tail], matrix, target_index, source_index, :columns)
       when source_index == columns do
    do_concat(tail, matrix, target_index, 0, :columns)
  end

  defp do_concat([head | _] = list, matrix, target_index, source_index, concat_type) do
    matrix =
      case concat_type do
        :rows ->
          set_row(matrix, target_index, head |> row(source_index))

        :columns ->
          set_column(matrix, target_index, head |> column(source_index))
      end

    do_concat(list, matrix, target_index + 1, source_index + 1, concat_type)
  end

  @spec diagonal(t) :: t
  def diagonal(%Max{columns: columns} = matrix) do
    array = :array.new(columns, fixed: true, default: default(matrix))

    0..(columns - 1)
    |> Enum.reduce(
      %Max{array: array, rows: 1, columns: columns},
      fn col, acc ->
        set(acc, {0, col}, get(matrix, {col, col}))
      end
    )
  end

  @spec identity(list) :: t
  def identity(size, options \\ []) do
    default = Keyword.get(options, :default, :undefined)

    array = :array.new(size * size, fixed: true, default: default)

    0..(size - 1)
    |> Enum.reduce(
      %Max{array: array, rows: size, columns: size},
      fn index, acc ->
        position = {index, index}

        set(acc, position, 1)
      end
    )
  end

  @spec drop_column(t, non_neg_integer) :: t
  def drop_column(%Max{array: from_array, rows: rows, columns: columns} = matrix, column_index)
      when columns > 1 and column_index >= 0 and column_index < columns do
    to_array = :array.new(rows * (columns - 1), fixed: true, default: default(matrix))

    to_array = do_drop_column(from_array, to_array, 0, 0, count(matrix), column_index, columns)

    %Max{array: to_array, rows: rows, columns: columns - 1}
  end

  def do_drop_column(_, to_array, from_index, _, size, _, _) when from_index == size do
    to_array
  end

  def do_drop_column(from_array, to_array, from_index, to_index, size, column_index, columns) do
    case rem(from_index, columns) do
      ^column_index ->
        do_drop_column(from_array, to_array, from_index + 1, to_index, size, column_index, columns)
      _else ->
        value = :array.get(from_index, from_array)

        to_array = :array.set(to_index, value, to_array)

        do_drop_column(from_array, to_array, from_index + 1, to_index + 1, size, column_index, columns)
    end
  end
end