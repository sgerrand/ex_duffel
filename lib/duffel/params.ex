defmodule Duffel.Params do
  @moduledoc false

  # The helpers every params builder needs (`Duffel.Orders.CreateParams`,
  # `Duffel.OfferRequests.SearchParams`, `Duffel.Stays.SearchParams`,
  # `Duffel.Cars.SearchParams`): each assembles a request body from a
  # keyword list, drops the options the caller left out, and raises on a
  # missing required one.
  #
  # They are injected as private functions rather than called across
  # modules, so sharing them adds nothing to the library's public API.

  @doc false
  defmacro __using__(_opts) do
    quote do
      # Raises unless every key in `keys` is present in `opts`.
      defp require_params!(opts, keys) do
        case Enum.reject(keys, &Keyword.has_key?(opts, &1)) do
          [] -> :ok
          missing -> raise ArgumentError, "missing required options: #{inspect(missing)}"
        end
      end

      # Copies `keys` from `opts` into `map`, skipping the absent ones.
      defp put_params(map, opts, keys) do
        Enum.reduce(keys, map, fn key, acc ->
          case Keyword.get(opts, key) do
            nil -> acc
            value -> Map.put(acc, key, value)
          end
        end)
      end
    end
  end
end
