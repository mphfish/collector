defmodule Collector.Query do
  defmacro between(value, lhs, rhs) do
    quote do
      fragment("? BETWEEN ? AND ?", unquote(value), unquote(lhs), unquote(rhs))
    end
  end
end
