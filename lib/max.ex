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
  def get(%Max{array: array} = max, position) do
    index = position_to_index(max, position)

    :array.get(index, array)
  end

  @spec set(t, position, any) :: t
  def set(%Max{array: array} = max, position, value) do
    index = position_to_index(max, position)

    %Max{max | array: :array.set(index, value, array)}
  end

  @spec to_list(t) :: list
  def to_list(%Max{array: array}) do
    :array.to_list(array)
  end

  @spec min(t) :: any
  def min(%Max{} = max) do
    sparse_foldl(
      max,
      fn _, value, acc -> min(value, acc) end,
      default(max)
    )
  end

  @spec max(t) :: any
  def max(%Max{} = max) do
    sparse_foldl(
      max,
      fn _, value, acc -> max(value, acc) end,
      default(max)
    )
  end

  @spec reshape(t, pos_integer, pos_integer) :: t
  def reshape(%Max{} = max, rows, columns) do
    %Max{max | rows: rows, columns: columns}
  end

  @spec map(t, fun) :: t
  def map(%Max{array: array} = max, fun) when is_function(fun, 2) do
    %Max{max | array: :array.map(fun, array)}
  end

  @spec sparse_foldl(t, function, any) :: any
  def sparse_foldl(%Max{array: array}, fun, acc) when is_function(fun, 3) do
    :array.sparse_foldl(fun, acc, array)
  end

  @spec reset(t, position) :: t
  def reset(%Max{array: array} = max, position) do
    index = position_to_index(max, position)

    %Max{max | array: :array.reset(index, array)}
  end

  @spec row_to_list(t, non_neg_integer) :: list
  def row_to_list(%Max{rows: rows, columns: columns} = max, row) when row in 0..(rows - 1) do
    for col <- 0..(columns - 1) do
      get(max, {row, col})
    end
  end

  @spec column_to_list(t, non_neg_integer) :: list
  def column_to_list(%Max{rows: rows, columns: columns} = max, col)
      when col in 0..(columns - 1) do
    for row <- 0..(rows - 1) do
      get(max, {row, col})
    end
  end

  @spec to_list_of_lists(t) :: list
  def to_list_of_lists(%Max{rows: rows, columns: columns} = max) do
    for row <- 0..(rows - 1) do
      for col <- 0..(columns - 1) do
        get(max, {row, col})
      end
    end
  end
end
