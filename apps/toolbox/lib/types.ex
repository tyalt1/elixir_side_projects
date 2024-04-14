defmodule Toolbox.Types do
  defmacro __using__(_opts) do
    quote do
      # protocols
      alias Toolbox.Types.Functor
      alias Toolbox.Types.Monad

      # types
      alias Toolbox.Types.Option
      alias Toolbox.Types.Result
    end
  end

  defprotocol Functor do
    def map(fa, fun)
  end

  defprotocol Monad do
    def bind(ma, fun)
  end
end
