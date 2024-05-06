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
      <span class="font-bold"><%= pad_number(@counter) %></span>
      <.my_button click="inc" color={color_css(:green)}>+</.my_button>
      <.my_button click="dec" color={color_css(:red)}>-</.my_button>
      <.my_button click="reset" color={color_css(:blue)}>reset</.my_button>
    </div>
    """
  end

  # add leading zeros
  # iex> pad_number(3) => "003"
  # iex> pad_number(13) =>"013"
  # iex> pad_number(1300) =>"1300"
  # iex> pad_number(1300, 5) =>"01300"
  defp pad_number(n, digit_len \\ 3) do
    n
    |> to_string()
    |> String.pad_leading(digit_len, "0")
  end

  @spec color_css(atom()) :: binary()
  defp color_css(:red), do: "bg-red-500 hover:bg-red-700"
  defp color_css(:green), do: "bg-green-500 hover:bg-green-700"
  defp color_css(:blue), do: "bg-blue-500 hover:bg-blue-700"

  attr :click, :string, required: true
  attr :debounce, :integer, default: 20
  attr :class, :string, default: "text-white font-bold py-2 px-4 rounded"
  attr :color, :string, examples: ["bg-blue-500 hover:bg-blue-700"]

  slot :inner_block

  @spec my_button(Phoenix.LiveView.Socket.assigns()) :: Phoenix.LiveView.Rendered.t()
  defp my_button(assigns) do
    ~H"""
    <button class={"#{@color} #{@class}"} phx-click={@click} phx-debounce={@debounce}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp noreply(socket), do: {:noreply, socket}

  @doc false
  @impl true
  @spec handle_event(binary(), map(), Phoenix.LiveView.Socket.t()) ::
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
