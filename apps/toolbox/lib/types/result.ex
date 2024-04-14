defmodule Toolbox.Types.Result do
  @moduledoc """

  ```
  iex> use Toolbox.Types

  iex> parseInt = fn x ->
    try do
      Integer.parse(x) |> elem(0) |> Result.ok()
    rescue
      _ -> Result.error("Failed to parse " <> x <> " to int")
    end
    end
  iex> "3" |> then(parseInt)
  %Types.Result.Ok{a: 3}
  iex> "3" |> then(parseInt) |> Result.to_tuple
  {:ok, 3}
  iex> "foo" |> then(parseInt)
  %Types.Result.Error{a: "Failed to parse foo to int"}
  iex> "foo" |> then(parseInt) |> Result.to_tuple
  {:error, "Failed to parse foo to int"}

  # Functor
  iex> "3" |> then(parseInt) |> map(fn x -> x+1 end)
  %Types.Result.Ok{a: 4}

  # Monad
  iex> import Integer, only: [is_even: 1]
  iex> half = fn
    x when is_even(x) -> x |> div(2) |> Option.new()
    _ -> Option.new()
    end
  iex> Result.ok(3) |> bind(half)
  %Toolbox.Types.Option.None{}
  iex> Result.ok(4) |> bind(half)
  %Toolbox.Types.Option.Some{a: 2}
  ```
  """

  use Toolbox.Types

  defmodule Ok do
    defstruct [:a]
    alias __MODULE__

    @type t(a) :: %__MODULE__{a: a}

    @spec new(any()) :: %Ok{a: any()}
    def new(a), do: %Ok{a: a}

    defimpl Functor, for: __MODULE__ do
      def map(%Ok{a: a}, fun) do
        a
        |> then(fun)
        |> Ok.new()
      end
    end

    defimpl Monad, for: __MODULE__ do
      def bind(%Ok{a: a}, fun), do: then(a, fun)
    end
  end

  defmodule Error do
    defstruct [:a]

    @type t(a) :: %__MODULE__{a: a}

    def new(a), do: %Error{a: a}

    defimpl Functor, for: __MODULE__ do
      def map(e = %Error{}, _), do: e
    end

    defimpl Monad, for: __MODULE__ do
      def bind(error, _), do: error
    end
  end

  @type t :: Ok.t() | Error.t()

  # ctor
  @spec ok(any()) :: t()
  def ok(a), do: Ok.new(a)

  @spec error(any()) :: t()
  def error(a), do: Error.new(a)

  # boolean checks
  @spec ok?(any()) :: boolean()
  def ok?(%Ok{}), do: true
  def ok?(_), do: false

  @spec error?(any()) :: boolean()
  def error?(%Error{}), do: true
  def error?(_), do: false

  # converts
  @spec unwrap(t()) :: any()
  def unwrap(%Ok{a: a}), do: a
  def unwrap(%Error{}), do: nil

  @spec unwrap(t(), any()) :: any()
  def unwrap(%Ok{a: a}, _), do: a
  def unwrap(%Error{}, default), do: default

  @spec to_tuple(t()) :: {:ok, any()} | {:error, any()}
  def to_tuple(%Ok{a: a}), do: {:ok, a}
  def to_tuple(%Error{a: a}), do: {:error, a}

  @spec from_tuple({:ok, any()} | {:error, any()}) :: t()
  def from_tuple({:ok, a}), do: Ok.new(a)
  def from_tuple({:error, a}), do: Error.new(a)

  @spec to_option(t()) :: Option.t()
  def to_option(%Ok{a: a}), do: Option.new(a)
  def to_option(%Error{}), do: Option.new()
end
