defmodule Duffel.Page do
  @moduledoc """
  One page of results from a Duffel list endpoint.

  The Duffel API uses [cursor pagination](https://duffel.com/docs/api/overview/pagination):
  pass `:after_cursor` as the `after` parameter to fetch the next page.
  `after_cursor` is `nil` on the final page.

  To iterate over all pages lazily, use the `stream/2` function on the
  resource module instead, e.g. `Duffel.OfferRequests.stream/2`.
  """

  defstruct data: [], after_cursor: nil, before_cursor: nil, limit: nil

  @type t :: %__MODULE__{
          data: [map()],
          after_cursor: String.t() | nil,
          before_cursor: String.t() | nil,
          limit: pos_integer() | nil
        }

  @doc false
  @spec from_body(map()) :: t()
  def from_body(body) when is_map(body) do
    meta = body["meta"] || %{}

    %__MODULE__{
      data: body["data"] || [],
      after_cursor: meta["after"],
      before_cursor: meta["before"],
      limit: meta["limit"]
    }
  end
end
