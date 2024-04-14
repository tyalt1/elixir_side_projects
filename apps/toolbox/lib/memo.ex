defmodule Toolbox.Memo do
  @moduledoc """

  ```
  iex> expensive_fun = fn _ -> :timer.sleep(5000); 2 end
  iex> m = Memo.new(expensive_fun)
  iex> {time, {result, m = %Memo{}}} = :timer.tc(fn -> Memo.call(m, 1) end)
  {5000799, {2, %Memo{}}}
  iex> {time, {result, m = %Memo{}}} = :timer.tc(fn -> Memo.call(m, 1) end)
  {25, {2, %Memo{}}}
  iex> {time, m = %Memo{}} = :timer.tc(fn -> Memo.cast(m, 1) end)
  {8, %Memo{}}
  ```
  """

  alias __MODULE__

  defstruct cache: %{}, callback: nil

  @type t :: %__MODULE__{
          cache: map(),
          callback: function()
        }

  @spec new(function()) :: t()
  def new(callback) when is_function(callback, 1) do
    %Toolbox.Memo{callback: callback}
  end

  @doc """

    iex> m = Memo.new(fn _ -> :timer.sleep(5000); 2 end)
    iex> {result, m} = Memo.call(m, 1) # slow
    iex> {result, m} = Memo.call(m, 1) # much faster
  """
  @spec call(t(), any()) :: {t(), any()}
  def call(m = %{cache: cache, callback: callback}, input) do
    case Map.get(cache, input, :error) do
      :error ->
        output = apply(callback, [input])
        {output, %Memo{m | cache: Map.put(cache, input, output)}}

      output ->
        {output, m}
    end
  end

  @doc """
    Like call, but discards result of function. Used to seed values, pipes, etc.

    iex> m = Memo.new(fn _ -> :timer.sleep(5000); 2 end)
    iex> m = Memo.cast(m, 1)
    iex> m = Memo.cast(m, 1)
  """
  @spec cast(t(), any()) :: t()
  def cast(m, input) do
    call(m, input) |> elem(1)
  end
end

defmodule Toolbox.MemoServer do
  use GenServer
  alias Toolbox.Memo

  @spec start_link(function(), GenServer.options()) :: GenServer.on_start()
  def start_link(f, opts \\ []) do
    GenServer.start_link(__MODULE__, f, opts)
  end

  @spec call(GenServer.server(), any(), timeout()) :: term()
  def call(server, item, timeout \\ :infinity) do
    GenServer.call(server, {:call, item}, timeout)
  end

  @spec cast(GenServer.server(), any()) :: :ok
  def cast(server, item) do
    GenServer.cast(server, {:call, item})
  end

  @impl true
  def init(f) do
    {:ok, Memo.new(f)}
  end

  @impl true
  def handle_call({:call, input}, _from, state) do
    {result, state} = Memo.call(state, input)
    {:reply, result, state}
  end

  @impl true
  def handle_cast({:call, input}, state) do
    {_, state} = Memo.call(state, input)
    {:noreply, state}
  end
end
