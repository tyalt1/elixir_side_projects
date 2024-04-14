defmodule Toolbox do
  @moduledoc """
  Documentation for `Toolbox`.
  """

  defmacro __using__(_opts) do
    quote do
      alias Toolbox.Batch
      alias Toolbox.Memo
      use Toolbox.Types
    end
  end
end
