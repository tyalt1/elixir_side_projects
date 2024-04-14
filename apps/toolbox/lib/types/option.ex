defmodule Toolbox.Types.Option do
  @moduledoc """

  ```
  iex> use Toolbox.Types

  # Functor
  iex> Option.new(5) |> map(fn x -> x+1 end)
  %Types.Option.Some{val: 6}

  # Monad
  iex> import Integer, only: [is_even: 1]
  iex> half = fn
    x when is_even(x) -> x |> div(2) |> Option.new()
    _ -> Option.new()
    end
  iex> Option.new(20) |> bind(half)
  %Types.Option.Some{val: 10}
  iex> Option.new(20) |> bind(half) |> bind(half)
  %Types.Option.Some{val: 5}
  iex> Option.new(20) |> bind(half) |> bind(half) |> bind(half)
  %Types.Option.None{}
  ```
  """

  use Toolbox.Types

  defmodule Some do
    defstruct [:a]

    @type t(a) :: %__MODULE__{a: a}

    def new(a), do: %__MODULE__{a: a}

    defimpl Functor, for: __MODULE__ do
      def map(%Some{a: a}, fun) do
        a
        |> then(fun)
        |> Some.new()
      end
    end

    defimpl Monad, for: __MODULE__ do
      def bind(%Some{a: a}, fun), do: then(a, fun)
    end
  end

  defmodule None do
    defstruct []

    @type t :: %__MODULE__{}

    def new(), do: %__MODULE__{}

    defimpl Functor, for: __MODULE__ do
      def map(n, _), do: n
    end

    defimpl Monad, for: __MODULE__ do
      def bind(n, _), do: n
    end
  end

  @type t :: None.t() | Some.t()

  # ctor
  @spec new() :: t()
  def new(), do: None.new()

  @spec new(any()) :: t()
  def new(val), do: Some.new(val)

  # boolean
  @spec is_none?(t()) :: boolean()
  def is_none?(%None{}), do: true
  def is_none?(_), do: false

  @spec is_some?(t()) :: boolean()
  def is_some?(%Some{}), do: true
  def is_some?(_), do: false

  # coverts
  @spec unwrap(t()) :: any()
  def unwrap(%None{}), do: nil
  def unwrap(%Some{a: a}), do: a

  @spec unwrap(t(), any()) :: any()
  def unwrap(%None{}, default), do: default
  def unwrap(%Some{a: a}, _), do: a

  @spec to_result(t()) :: Result.t()
  def to_result(%None{}), do: Result.error(nil)
  def to_result(%Some{a: a}), do: Result.ok(a)
end
