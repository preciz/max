defmodule Max do
  @moduledoc """
  A matrix library in pure Elixir based on `:array`.

  [Erlang array documentation](http://erlang.org/doc/man/array.html)

  ## Examples

      iex> matrix = Max.new(5, 5, default: 2) # 5x5 matrix with default value 2
      iex> Max.get(matrix, {0, 0})
      2
      iex> matrix = Max.set(matrix, {0, 0}, 8)
      iex> Max.get(matrix, {0, 0})
      8

  ## Enumberable protocol

  `Max` implements the Enumerable protocol, so all Enum functions can be used:

      iex> matrix = Max.new(10, 10, default: 8)
      iex> Enum.max(matrix)
      8
      iex> Enum.member?(matrix, 7)
      false

  """

  @compile {:inline, get: 2, set: 3, index_to_position: 2, position_to_index: 2, size: 1}

  @enforce_keys [:array, :rows, :columns]
  defstruct [:array, :rows, :columns]

  @type t :: %Max{
          array: tuple,
          rows: pos_integer,
          columns: pos_integer
        }

  @type position :: {row :: non_neg_integer, col :: non_neg_integer}

  @doc """
  Returns a new `%Max{}` struct with the given `rows` and `columns` size.

  ## Options
    * `:default` - (term) the default value of the matrix. Defaults to `0`.

  ## Examples

       Max.new(10, 5) # 10 x 5 matrix
       Max.new(10, 5, default: 70) # 70 as a default value
  """
  @spec new(pos_integer, pos_integer, list) :: t
  def new(rows, columns, options \\ []) do
    default = Keyword.get(options, :default, 0)

    array = :array.new(rows * columns, fixed: true, default: default)

    %Max{
      array: array,
      rows: rows,
      columns: columns
    }
  end

  @doc """
  Converts a flat list to a new `%Max{}` struct with the given `rows` & `columns` size.

  ## Options
    * `:default` - (term) the default value of the matrix. Defaults to `0`.

  ## Examples

       iex> matrix = Max.from_list([1,2,3,4,5,6], 2, 3)
       iex> matrix |> Max.to_list_of_lists
       [[1,2,3], [4, 5, 6]]

  """
  @spec from_list(nonempty_list, pos_integer, pos_integer, list) :: t
  def from_list(list, rows, columns, options \\ []) do
    default = Keyword.get(options, :default, 0)

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

  @doc """
  Converts a list of lists matrix to a new `%Max{}` struct.

  ## Options
    * `:default` - (term) the default value of the matrix. Defaults to `0`.

  ## Examples

       iex> matrix = %Max{rows: 2, columns: 3} = Max.from_list_of_lists([[1,2,3], [4, 5, 6]])
       iex> matrix |> Max.to_list_of_lists
       [[1,2,3], [4, 5, 6]]

  """
  @spec from_list_of_lists(nonempty_list(nonempty_list), list) :: t
  def from_list_of_lists([h | _] = list, options \\ []) do
    default = Keyword.get(options, :default, 0)

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
      0
      iex> matrix = Max.new(5, 5, default: "preciz")
      iex> matrix |> Max.default()
      "preciz"

  """
  @spec default(t) :: any
  def default(%Max{array: array}), do: :array.default(array)

  @doc """
  Returns the size of matrix. (rows * columns)

  ## Examples

      iex> matrix = Max.new(5, 5)
      iex> Max.size(matrix)
      25

  """
  @spec size(t) :: pos_integer
  def size(%Max{rows: rows, columns: columns}) do
    rows * columns
  end

  @doc """
  Returns the sparse size of the `:array`.

  Erlang array docs:
  "Gets the number of entries in the array up until the last non-default-valued entry. That is, returns I+1 if I is the last non-default-valued entry in the array, or zero if no such entry exists."

  ## Examples

      iex> matrix = Max.new(5, 5)
      iex> Max.sparse_size(matrix)
      0

  """
  @spec sparse_size(t) :: pos_integer
  def sparse_size(%Max{array: array}) do
    :array.sparse_size(array)
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

  @doc """
  Returns value at `position` from the given `matrix`.

  ## Examples

      iex> matrix = Max.identity(5)
      iex> matrix |> Max.get({1, 1})
      1

  """
  @spec get(t, position) :: any
  def get(%Max{array: array} = matrix, position) do
    index = position_to_index(matrix, position)

    :array.get(index, array)
  end

  @doc """
  Sets `value` at `position` in `matrix`.

  Returns `%Max{}` struct.

  ## Examples

      iex> matrix = Max.new(10, 10)
      iex> matrix = matrix |> Max.set({1, 3}, 5)
      iex> matrix |> Max.get({1, 3})
      5

  """
  @spec set(t, position, any) :: t
  def set(%Max{array: array} = matrix, position, value) do
    index = position_to_index(matrix, position)

    %Max{matrix | array: :array.set(index, value, array)}
  end

  @doc """
  Set row of a matrix at `row_index` to the values from the given 1-row matrix.

  ## Examples

      iex> matrix = Max.new(5, 5, default: 1)
      iex> row_matrix = Max.new(1, 5, default: 3)
      iex> Max.set_row(matrix, 2, row_matrix) |> Max.to_list_of_lists()
      [
        [1, 1, 1, 1, 1],
        [1, 1, 1, 1, 1],
        [3, 3, 3, 3, 3],
        [1, 1, 1, 1, 1],
        [1, 1, 1, 1, 1],
      ]

  """
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

  @doc """
  Set column of a matrix at `column_index` to the values from the given 1-column matrix.

  ## Examples

      iex> matrix = Max.new(5, 5, default: 1)
      iex> column_matrix = Max.new(5, 1, default: 3)
      iex> Max.set_column(matrix, 2, column_matrix) |> Max.to_list_of_lists
      [
        [1, 1, 3, 1, 1],
        [1, 1, 3, 1, 1],
        [1, 1, 3, 1, 1],
        [1, 1, 3, 1, 1],
        [1, 1, 3, 1, 1],
      ]

  """
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

  @doc """
  Converts matrix to a flat list.

  ## Examples

      iex> matrix = Max.new(3, 3) |> Max.map(fn index, _val -> index end)
      iex> Max.to_list(matrix)
      [0, 1, 2, 3, 4, 5, 6, 7, 8]

  """
  @spec to_list(t) :: list
  def to_list(%Max{array: array}) do
    :array.to_list(array)
  end

  @doc """
  Returns smallest value in matrix using `Kernel.min/2`.

  ## Examples

      iex> matrix = Max.new(10, 10, default: 7)
      iex> matrix |> Max.min()
      7

  """
  @spec min(t) :: any
  def min(%Max{} = matrix) do
    {_index, value} = do_argmin(matrix)

    value
  end

  @doc """
  Returns largest value in matrix using `Kernel.max/2`.

  ## Examples

      iex> matrix = Max.new(10, 10) |> Max.map(fn index, _ -> index end)
      iex> matrix |> Max.max()
      99

  """
  @spec max(t) :: any
  def max(%Max{} = matrix) do
    {_index, value} = do_argmax(matrix)

    value
  end

  @doc """
  Returns position tuple of smallest value.

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
  Returns position tuple of largest value.

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
    if sparse_size(matrix) < size(matrix) do
      sparse_foldl(
        matrix,
        fn index, value, {_acc_index, acc_val} = acc ->
          case min(value, acc_val) do
            ^acc_val -> acc
            _else -> {index, value}
          end
        end,
        {0, default(matrix)}
      )
    else
      foldl(
        matrix,
        fn
          index, value, {_acc_index, acc_val} = acc ->
            case min(value, acc_val) do
              ^acc_val -> acc
              _else -> {index, value}
            end
          index, value, nil ->
            {index, value}
        end,
        nil
      )
    end
  end

  @doc false
  def do_argmax(%Max{} = matrix) do
    if sparse_size(matrix) < size(matrix) do
      sparse_foldl(
        matrix,
        fn index, value, {_acc_index, acc_val} = acc ->
          case max(value, acc_val) do
            ^acc_val -> acc
            _else -> {index, value}
          end
        end,
        {0, default(matrix)}
      )
    else
      foldl(
        matrix,
        fn
          index, value, {_acc_index, acc_val} = acc ->
            case max(value, acc_val) do
              ^acc_val -> acc
              _else -> {index, value}
            end
          index, value, nil ->
            {index, value}
        end,
        nil
      )
    end
  end

  @doc """
  Checks for membership of given `term`.
  Returns `true` if member, `false` otherwise.

  ## Examples

      iex> matrix = Max.new(5, 5) |> Max.map(fn i, _ -> i end)
      iex> matrix |> Max.member?(6)
      true
      iex> matrix |> Max.member?(100)
      false

  """
  @spec member?(t, any) :: boolean
  def member?(%Max{array: array} = matrix, term) do
    if :array.sparse_size(array) < size(matrix) && default(matrix) == term do
      true
    else
      try do
        sparse_foldl(
          matrix,
          fn
            _, ^term, _ -> throw(:found)
            _, _, _ -> false
          end,
          false
        )
      catch
        :throw, :found ->
          true
      end
    end
  end

  @doc """
  Returns position of the first occurence of the given `value`
  or `nil ` if nothing was found.

  ## Examples

      iex> Max.new(5, 5) |> Max.find(0)
      {0, 0}
      iex> matrix = Max.new(5, 5) |> Max.map(fn i, _v -> i end)
      iex> matrix |> Max.find(16)
      {3, 1}
      iex> matrix |> Max.find(42)
      nil

  """
  @spec find(t, any) :: position | nil
  def find(%Max{} = matrix, term) do
    try do
      default_is_term? = default(matrix) == term

      throw_found = fn
        index, ^term, _ -> throw({:found, index})
        _, _, _ -> nil
      end

      case default_is_term? do
        true -> foldl(matrix, throw_found, nil)
        false -> sparse_foldl(matrix, throw_found, nil)
      end
    catch
      :throw, {:found, index} ->
        index_to_position(matrix, index)
    end
  end

  @doc """
  Reshapes `matrix` to the given `rows` & `columns`.

  ## Examples

      iex> matrix = Max.identity(4)
      iex> matrix |> Max.to_list_of_lists()
      [
          [1, 0, 0, 0],
          [0, 1, 0, 0],
          [0, 0, 1, 0],
          [0, 0, 0, 1]
      ]
      iex> matrix |> Max.reshape(2, 8) |> Max.to_list_of_lists()
      [
          [1, 0, 0, 0, 0, 1, 0, 0],
          [0, 0, 1, 0, 0, 0, 0, 1]
      ]

  """
  @spec reshape(t, pos_integer, pos_integer) :: t
  def reshape(%Max{} = matrix, rows, columns) do
    %Max{matrix | rows: rows, columns: columns}
  end

  @doc """
  Maps each element to the result of the a given `fun`.

  The given `fun` receives the index as first and
  value as the second argument.
  To convert index to position use `index_to_position/2`.

  ## Examples

      iex> matrix = Max.new(10, 10, default: 2)
      iex> matrix = Max.map(matrix, fn _index, value -> value + 2 end)
      iex> matrix |> Max.get({0, 0})
      4

  """
  @spec map(t, fun) :: t
  def map(%Max{array: array} = matrix, fun) when is_function(fun, 2) do
    %Max{matrix | array: :array.map(fun, array)}
  end

  @doc """
  Same as `map/2` except it skips default valued elements.

  ## Examples

      iex> matrix = Max.new(10, 10, default: 2)
      iex> matrix = Max.sparse_map(matrix, fn _index, value -> value + 2 end)
      iex> matrix |> Max.get({0, 0}) # value stays at 2 because it was at default
      2

  """
  @spec sparse_map(t, fun) :: t
  def sparse_map(%Max{array: array} = matrix, fun) when is_function(fun, 2) do
    %Max{matrix | array: :array.sparse_map(fun, array)}
  end

  @doc """
  Folds the elements using the specified function and initial accumulator value. The elements are visited in order from the lowest index to the highest.

  ## Examples

      iex> matrix = Max.new(5, 5, default: 1)
      iex> matrix |> Max.foldl(fn _index, value, acc -> value + acc end, 0)
      25

  """
  @spec foldl(t, function, any) :: any
  def foldl(%Max{array: array}, fun, acc) when is_function(fun, 3) do
    :array.foldl(fun, acc, array)
  end

  @doc """
  Folds the elements right-to-left using the specified function and initial accumulator value. The elements are visited in order from the highest index to the lowest.

  ## Examples

      iex> matrix = Max.new(5, 5, default: 1)
      iex> matrix |> Max.foldr(fn _index, value, acc -> value + acc end, 0)
      25

  """
  @spec foldr(t, function, any) :: any
  def foldr(%Max{array: array}, fun, acc) when is_function(fun, 3) do
    :array.foldr(fun, acc, array)
  end

  @doc """
  Folds the elements using the specified function and initial accumulator value, skipping default-valued entries. The elements are visited in order from the lowest index to the highest.

  ## Examples

      iex> matrix = Max.new(5, 5, default: 1)
      iex> matrix |> Max.sparse_foldl(fn _index, value, acc -> value + acc end, 0)
      0

  """
  @spec sparse_foldl(t, function, any) :: any
  def sparse_foldl(%Max{array: array}, fun, acc) when is_function(fun, 3) do
    :array.sparse_foldl(fun, acc, array)
  end

  @doc """
  Folds the array elements right-to-left using the specified function and initial accumulator value, skipping default-valued entries. The elements are visited in order from the highest index to the lowest.

  ## Examples

      iex> matrix = Max.new(5, 5, default: 1)
      iex> matrix |> Max.sparse_foldr(fn _index, value, acc -> value + acc end, 0)
      0

  """
  @spec sparse_foldr(t, function, any) :: any
  def sparse_foldr(%Max{array: array}, fun, acc) when is_function(fun, 3) do
    :array.sparse_foldr(fun, acc, array)
  end

  @doc """
  Resets element at position to the default value.

  ## Examples

      iex> matrix = Max.new(5, 5, default: 1) |> Max.map(fn _,_ -> 7 end)
      iex> matrix |> Max.get({0, 0})
      7
      iex> matrix |> Max.reset({0, 0}) |> Max.get({0, 0})
      1

  """
  @spec reset(t, position) :: t
  def reset(%Max{array: array} = matrix, position) do
    index = position_to_index(matrix, position)

    %Max{matrix | array: :array.reset(index, array)}
  end

  @doc """
  Reduces matrix to only one row at given `row` index.

  ## Examples

      iex> matrix = Max.new(5, 5, default: 3)
      iex> matrix |> Max.row(4) |> Max.to_list_of_lists
      [[3, 3, 3, 3, 3]]

  """
  @spec row(t, non_neg_integer) :: t
  def row(%Max{rows: rows, columns: columns} = matrix, row) when row in 0..(rows - 1) do
    for col <- 0..(columns - 1) do
      get(matrix, {row, col})
    end
    |> from_list(1, columns, default: default(matrix))
  end

  @doc """
  Reduces matrix to only one column at given `col` index.

  ## Examples

      iex> matrix = Max.new(5, 5, default: 3)
      iex> matrix |> Max.column(4) |> Max.to_list_of_lists
      [[3], [3], [3], [3], [3]]

  """
  @spec column(t, non_neg_integer) :: t
  def column(%Max{rows: rows, columns: columns} = matrix, col) when col in 0..(columns - 1) do
    for row <- 0..(rows - 1) do
      get(matrix, {row, col})
    end
    |> from_list(rows, 1, default: default(matrix))
  end

  @doc """
  Converts row at given row index of matrix to list.

  ## Examples

      iex> matrix = Max.identity(5)
      iex> matrix |> Max.row_to_list(2)
      [0, 0, 1, 0, 0]

  """
  @spec row_to_list(t, non_neg_integer) :: list
  def row_to_list(%Max{rows: rows, columns: columns} = matrix, row) when row in 0..(rows - 1) do
    for col <- 0..(columns - 1) do
      get(matrix, {row, col})
    end
  end

  @doc """
  Converts column at given column index of matrix to list.

  ## Examples

      iex> matrix = Max.identity(5)
      iex> matrix |> Max.column_to_list(0)
      [1, 0, 0, 0, 0]

  """
  @spec column_to_list(t, non_neg_integer) :: list
  def column_to_list(%Max{rows: rows, columns: columns} = matrix, col)
      when col in 0..(columns - 1) do
    for row <- 0..(rows - 1) do
      get(matrix, {row, col})
    end
  end

  @doc """
  Converts matrix to list of lists.

  ## Examples

      iex> matrix = Max.new(5, 5) |> Max.map(fn i, _v -> i + 1 end)
      iex> Max.to_list_of_lists(matrix)
      [
        [1, 2, 3, 4, 5],
        [6, 7, 8, 9, 10],
        [11, 12, 13, 14, 15],
        [16, 17, 18, 19, 20],
        [21, 22, 23, 24, 25],
      ]

  """
  @spec to_list_of_lists(t) :: list
  def to_list_of_lists(%Max{rows: rows, columns: columns} = matrix) do
    for row <- 0..(rows - 1) do
      for col <- 0..(columns - 1) do
        get(matrix, {row, col})
      end
    end
  end

  @doc """
  Concatenates a list of matrices.

  Returns a new `%Max{}` struct with a new array containing all values
  of matrices from `list`.

  ## Options
    * `:default` - (term) the default value of the matrix. Defaults to `0`.

  ## Examples

      iex> matrix = Max.new(3, 3) |> Max.map(fn i, _v -> i end)
      iex> matrix |> Max.to_list_of_lists()
      [
          [0, 1, 2],
          [3, 4, 5],
          [6, 7, 8]
      ]
      iex> Max.concat([matrix, matrix], :rows) |> Max.to_list_of_lists()
      [
          [0, 1, 2],
          [3, 4, 5],
          [6, 7, 8],
          [0, 1, 2],
          [3, 4, 5],
          [6, 7, 8]
      ]
      iex> Max.concat([matrix, matrix], :columns) |> Max.to_list_of_lists()
      [
          [0, 1, 2, 0, 1, 2],
          [3, 4, 5, 3, 4, 5],
          [6, 7, 8, 6, 7, 8]
      ]

  """
  @spec concat(nonempty_list(t), :rows | :columns, list) :: t | no_return
  def concat([%Max{rows: rows, columns: columns} | _] = list, concat_type, options \\ [])
      when length(list) > 0 do
    default = Keyword.get(options, :default, 0)

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
      |> Enum.map(&size/1)
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

  @doc """
  Returns diagonal of matrix.

  ## Examples

      iex> matrix = Max.identity(3)
      iex> matrix |> Max.to_list_of_lists()
      [
        [1, 0, 0],
        [0, 1, 0],
        [0, 0, 1]
      ]
      iex> matrix |> Max.diagonal() |> Max.to_list_of_lists()
      [[1, 1, 1]]

  """
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

  @doc """
  Create identity square matrix of given `size`.

  ## Options
    * `:default` - (term) the default value of the matrix. Defaults to `0`.

  ## Examples

      iex> Max.identity(5) |> Matrax.to_list_of_lists()
      [
          [1, 0, 0, 0, 0],
          [0, 1, 0, 0, 0],
          [0, 0, 1, 0, 0],
          [0, 0, 0, 1, 0],
          [0, 0, 0, 0, 1]
      ]

  """
  @spec identity(list) :: t
  def identity(size, options \\ []) do
    default = Keyword.get(options, :default, 0)

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

  @spec drop_row(t, non_neg_integer) :: t
  def drop_row(%Max{array: from_array, rows: rows, columns: columns} = matrix, row_index)
      when rows > 1 and row_index >= 0 and row_index < rows do
    to_array = :array.new((rows - 1) * columns, fixed: true, default: default(matrix))

    to_array =
      do_drop_row(
        from_array,
        to_array,
        0,
        0,
        size(matrix),
        row_index * columns,
        (row_index + 1) * columns
      )

    %Max{array: to_array, rows: rows - 1, columns: columns}
  end

  defp do_drop_row(_, to_array, from_index, _, size, _, _) when from_index == size do
    to_array
  end

  defp do_drop_row(from_array, to_array, from_index, to_index, size, skip_from, skip_to) do
    case from_index >= skip_from && from_index < skip_to do
      true ->
        do_drop_row(from_array, to_array, from_index + 1, to_index, size, skip_from, skip_to)

      false ->
        value = :array.get(from_index, from_array)

        to_array = :array.set(to_index, value, to_array)

        do_drop_row(from_array, to_array, from_index + 1, to_index + 1, size, skip_from, skip_to)
    end
  end

  @spec drop_column(t, non_neg_integer) :: t
  def drop_column(%Max{array: from_array, rows: rows, columns: columns} = matrix, column_index)
      when columns > 1 and column_index >= 0 and column_index < columns do
    to_array = :array.new(rows * (columns - 1), fixed: true, default: default(matrix))

    to_array = do_drop_column(from_array, to_array, 0, 0, size(matrix), column_index, columns)

    %Max{array: to_array, rows: rows, columns: columns - 1}
  end

  defp do_drop_column(_, to_array, from_index, _, size, _, _) when from_index == size do
    to_array
  end

  defp do_drop_column(from_array, to_array, from_index, to_index, size, column_index, columns) do
    case rem(from_index, columns) do
      ^column_index ->
        do_drop_column(
          from_array,
          to_array,
          from_index + 1,
          to_index,
          size,
          column_index,
          columns
        )

      _else ->
        value = :array.get(from_index, from_array)

        to_array = :array.set(to_index, value, to_array)

        do_drop_column(
          from_array,
          to_array,
          from_index + 1,
          to_index + 1,
          size,
          column_index,
          columns
        )
    end
  end

  @spec transpose(t) :: t
  def transpose(%Max{rows: rows, columns: columns} = matrix) do
    t_matrix = %Max{
      array: :array.new(rows * columns, fixed: true, default: default(matrix)),
      rows: columns,
      columns: rows
    }

    sparse_foldl(
      matrix,
      fn index, value, t_matrix ->
        {row, col} = index_to_position(matrix, index)

        t_matrix |> set({col, row}, value)
      end,
      t_matrix
    )
  end

  @spec sum(t) :: number
  def sum(%Max{} = matrix) do
    {n, acc_val} =
      sparse_foldl(
        matrix,
        fn _, val, {n, acc_val} ->
          {n + 1, acc_val + val}
        end,
        {0, 0}
      )

    case size(matrix) - n do
      0 ->
        acc_val

      default_values_skipped ->
        default_values_skipped * default(matrix) + acc_val
    end
  end

  @spec trace(t) :: number
  def trace(%Max{} = matrix) do
    matrix
    |> diagonal()
    |> sum()
  end

  @spec flip_lr(t) :: t
  def flip_lr(%Max{columns: columns} = matrix) do
    new_matrix = %Max{
      matrix
      | array: :array.new(size(matrix), fixed: true, default: default(matrix))
    }

    sparse_foldl(
      matrix,
      fn index, val, acc ->
        {row, col} = index_to_position(matrix, index)

        new_col = columns - 1 - col

        acc |> set({row, new_col}, val)
      end,
      new_matrix
    )
  end

  @spec flip_ud(t) :: t
  def flip_ud(%Max{rows: rows} = matrix) do
    new_matrix = %Max{
      matrix
      | array: :array.new(size(matrix), fixed: true, default: default(matrix))
    }

    sparse_foldl(
      matrix,
      fn index, val, acc ->
        {row, col} = index_to_position(matrix, index)

        new_row = rows - 1 - row

        acc |> set({new_row, col}, val)
      end,
      new_matrix
    )
  end

  @spec add(t, t) :: t
  def add(%Max{rows: rows, columns: columns} = left, %Max{
        array: array_right,
        rows: rows,
        columns: columns
      }) do
    map(
      left,
      fn i, v ->
        v + :array.get(i, array_right)
      end
    )
  end

  @spec multiply(t, t) :: t
  def multiply(
        %Max{rows: rows, columns: columns} = left,
        %Max{array: array_right, rows: rows, columns: columns}
      ) do
    map(
      left,
      fn i, v ->
        v * :array.get(i, array_right)
      end
    )
  end

  @spec dot(t, t) :: t
  def dot(
        %Max{rows: left_rows, columns: left_columns} = left,
        %Max{rows: right_rows, columns: right_columns} = right
      )
      when left_columns == right_rows do
    array = :array.new(left_rows * right_columns, fixed: true)

    matrix = %Max{
      array: array,
      rows: left_rows,
      columns: right_columns
    }

    left_cache =
      for row_i <- 0..(left_rows - 1), into: %{} do
        {row_i, left |> row(row_i) |> transpose}
      end

    right_cache =
      for col_i <- 0..(right_columns - 1), into: %{} do
        {col_i, right |> column(col_i)}
      end

    map(
      matrix,
      fn index, _ ->
        {row, col} = index_to_position(matrix, index)

        multiply(
          Map.get(left_cache, row),
          Map.get(right_cache, col)
        )
        |> sum()
      end
    )
  end

  defimpl Enumerable do
    @moduledoc false

    alias Max

    def count(%Max{} = matrix) do
      {:ok, Max.size(matrix)}
    end

    def member?(%Max{} = matrix, term) do
      {:ok, Max.member?(matrix, term)}
    end

    def slice(%Max{array: array} = matrix) do
      {
        :ok,
        Max.size(matrix),
        fn start, length ->
          do_slice(array, start, length)
        end
      }
    end

    defp do_slice(_, _, 0), do: []

    defp do_slice(array, index, length) do
      [:array.get(index, array) | do_slice(array, index + 1, length - 1)]
    end

    def reduce(%Max{array: array} = matrix, acc, fun) do
      do_reduce({array, 0, Max.size(matrix)}, acc, fun)
    end

    defp do_reduce(_, {:halt, acc}, _fun), do: {:halted, acc}
    defp do_reduce(tuple, {:suspend, acc}, fun), do: {:suspended, acc, &do_reduce(tuple, &1, fun)}
    defp do_reduce({_, same, same}, {:cont, acc}, _fun), do: {:done, acc}

    defp do_reduce({array, index, count}, {:cont, acc}, fun) do
      do_reduce(
        {array, index + 1, count},
        fun.(:array.get(index, array), acc),
        fun
      )
    end
  end
end
