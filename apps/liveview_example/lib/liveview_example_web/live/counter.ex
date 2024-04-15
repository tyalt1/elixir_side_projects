defmodule LiveviewExampleWeb.Counter do
  use LiveviewExampleWeb, :live_view

  @doc false
  @impl true
  @spec mount(any(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    {:ok, assign(socket, counter: 0)}
  end

  @doc false
  @impl true
  @spec render(Phoenix.LiveView.Socket.assigns()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="flex gap-2 items-center">
      <span><%= String.pad_leading(to_string(@counter), 3, "0") %></span>
      <.my_button click="inc" color={color_class(:green)}>+</.my_button>
      <.my_button click="dec" color={color_class(:red)}>-</.my_button>
      <.my_button click="reset">reset</.my_button>
    </div>
    """
  end

  @spec color_class(:red | :green | :blue) :: binary()
  defp color_class(:red), do: "bg-red-500 hover:bg-red-700"
  defp color_class(:green), do: "bg-green-500 hover:bg-green-700"
  defp color_class(:blue), do: "bg-blue-500 hover:bg-blue-700"

  attr :click, :string, required: true
  attr :debounce, :integer, default: 20
  attr :class, :string, default: "text-white font-bold py-2 px-4 rounded"
  attr :color, :string, default: "bg-blue-500 hover:bg-blue-700"

  slot :inner_block

  @doc """
  Custom button component

  - click: string for phoenix click event
  - debounce: number of milliseconds click events with debounce for
  - class: CSS class, default to "text-white font-bold py-2 px-4 rounded"
  - color: CSS color class, default to blue
  """
  @spec my_button(Phoenix.LiveView.Socket.assigns()) :: Phoenix.LiveView.Rendered.t()
  def my_button(assigns) do
    ~H"""
    <button class={@color <> " " <> @class} phx-click={@click} phx-debounce={@debounce}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp noreply(socket), do: {:noreply, socket}

  @doc false
  @impl true
  @spec handle_event(event :: binary(), map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("inc", _unsigned_params, socket) do
    socket
    |> update(:counter, fn x -> x + 1 end)
    |> noreply()
  end

  def handle_event("dec", _unsigned_params, socket) do
    socket
    |> update(:counter, fn
      x when x <= 0 -> 0
      x -> x - 1
    end)
    |> noreply()
  end

  def handle_event("reset", _unsigned_params, socket) do
    socket
    |> assign(counter: 0)
    |> noreply()
  end
end
