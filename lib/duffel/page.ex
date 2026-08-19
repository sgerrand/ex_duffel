defmodule Duffel.Page do
  @moduledoc """
  One page of results from a Duffel list endpoint.

  The Duffel API uses [cursor pagination](https://duffel.com/docs/api/overview/pagination):
  pass `:after_cursor` as the `after` parameter to fetch the next page.
  `after_cursor` is `nil` on the final page.

  To iterate over all pages lazily, use the `stream/2` function on the
  resource module instead, e.g. `Duffel.OfferRequests.stream/2`. To walk
  the pages yourself — to checkpoint between them, say — `has_more?/1` and
  `next_params/2` do the cursor bookkeeping:

      def each_page(client, params) do
        {:ok, page} = Duffel.Orders.list(client, params)
        handle(page.data)

        case Duffel.Page.next_params(page, params) do
          nil -> :done
          next -> each_page(client, next)
        end
      end

  """

  defstruct data: [], after_cursor: nil, before_cursor: nil, limit: nil

  @type t :: %__MODULE__{
          data: [map()],
          after_cursor: String.t() | nil,
          before_cursor: String.t() | nil,
          limit: pos_integer() | nil
        }

  @doc """
  Says whether another page follows this one.

  ## Examples

      iex> Duffel.Page.has_more?(%Duffel.Page{after_cursor: "cur_2"})
      true

      iex> Duffel.Page.has_more?(%Duffel.Page{after_cursor: nil})
      false

  """
  @spec has_more?(t()) :: boolean()
  def has_more?(%__MODULE__{after_cursor: nil}), do: false
  def has_more?(%__MODULE__{}), do: true

  @doc """
  Builds the parameters that fetch the page after this one.

  Pass the parameters you used for this page and the `after` cursor is
  merged in, keeping your filters. Returns `nil` on the last page, so a
  `case` can drive the loop:

      case Duffel.Page.next_params(page, sort: "total_amount") do
        nil -> :done
        params -> Duffel.Offers.list(client, params)
      end

  ## Examples

      iex> Duffel.Page.next_params(%Duffel.Page{after_cursor: "cur_2"}, limit: 50)
      %{"limit" => 50, "after" => "cur_2"}

      iex> Duffel.Page.next_params(%Duffel.Page{after_cursor: nil}, limit: 50)
      nil

  """
  @spec next_params(t(), keyword() | map()) :: map() | nil
  def next_params(page, params \\ [])

  def next_params(%__MODULE__{after_cursor: nil}, _params), do: nil

  def next_params(%__MODULE__{after_cursor: cursor}, params) do
    params
    |> Map.new(fn {key, value} -> {to_string(key), value} end)
    |> Map.put("after", cursor)
  end

  @doc false
  @spec from_body(map()) :: t()
  def from_body(body) when is_map(body) do
    meta = body["meta"] || %{}

    %__MODULE__{
      data: body["data"],
      after_cursor: meta["after"],
      before_cursor: meta["before"],
      limit: meta["limit"]
    }
  end
end
