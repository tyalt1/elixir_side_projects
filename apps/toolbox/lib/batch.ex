defmodule Toolbox.Batch do
  @moduledoc """

  ```
  iex> batch = Batch.new(3, &IO.inspect/1)
  iex> Batch.is_empty?(batch)
  true
  iex> batch = Batch.add(batch, 1)
  iex> Batch.is_empty?(batch)
  false
  iex> batch = Batch.add(batch, 2) |> Batch.add(3)
  [1, 2, 3]
  iex> Batch.is_empty?(batch)
  ```
  """

  alias __MODULE__

  defstruct batch: [], size: 10, callback: nil

  # @type Batch :: %{}
  @type t :: %__MODULE__{
          batch: list(),
          size: integer(),
          callback: function()
        }

  def new(size \\ 10, f) when is_function(f, 1) do
    %Batch{size: size, callback: f}
  end

  @spec add(t(), any()) :: t()
  def add(b = %Batch{batch: batch}, item) do
    new_batch = %Batch{b | batch: [item | batch]}

    if is_full?(new_batch) do
      flush(new_batch)
    else
      new_batch
    end
  end

  @spec flush(Batch.t()) :: Batch.t()
  def flush(b = %Batch{batch: batch, callback: callback}) do
    if is_empty?(b) do
      b
    else
      apply(callback, [Enum.reverse(batch)])
      %Batch{b | batch: []}
    end
  end

  @spec is_empty?(Batch.t()) :: boolean()
  def is_empty?(%Batch{batch: batch}) do
    Enum.empty?(batch)
  end

  @spec is_full?(Batch.t()) :: boolean()
  def is_full?(%Batch{batch: batch, size: size}) do
    length(batch) >= size
  end
end

defmodule Toolbox.BatchServer do
  use GenServer
  alias Toolbox.Batch

  defp reply(x), do: {:reply, x, x}
  defp noreply(x), do: {:noreply, x}

  @spec start_link(non_neg_integer(), function(), GenServer.options()) :: GenServer.on_start()
  def start_link(size \\ 10, f, opts \\ []) when is_function(f, 1) do
    GenServer.start_link(__MODULE__, Batch.new(size, f), opts)
  end

  @spec is_full?(GenServer.server()) :: boolean()
  def is_full?(server), do: GenServer.call(server, :is_full?, :infinity)
  @spec is_empty?(GenServer.server()) :: boolean()
  def is_empty?(server), do: GenServer.call(server, :is_empty?, :infinity)

  @spec add(GenServer.server(), any()) :: :ok
  def add(server, item), do: GenServer.cast(server, {:add, item})

  @doc false
  @impl true
  def init(batch) do
    {:ok, batch}
  end

  @doc false
  @impl true
  def handle_call(:is_full?, _from, batch) do
    batch
    |> Batch.is_full?()
    |> reply()
  end

  def handle_call(:is_empty?, _from, batch) do
    batch
    |> Batch.is_empty?()
    |> reply()
  end

  @doc false
  @impl true
  def handle_cast({:add, item}, batch) do
    batch
    |> Batch.add(item)
    |> noreply()
  end
end
