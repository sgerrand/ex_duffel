defmodule Duffel.Schema do
  @moduledoc """
  Opt-in typed views over Duffel API responses.

  Resource functions return raw string-keyed maps — that is the default and
  it does not change. When you want a struct with named fields instead, pass
  the map to the matching schema's `from_map/1`:

      {:ok, order} = Duffel.Orders.get(client, "ord_123")
      order = Duffel.Schema.Order.from_map(order)

      order.booking_reference
      #=> "RZPNX8"

  Nested resources that have their own schema are decoded too, so
  `order.slices` is a list of `Duffel.Schema.Slice` structs and each
  `slice.segments` is a list of `Duffel.Schema.Segment` structs.

  Fields without a dedicated schema (an offer's `owner` airline, a place, a
  payment requirement) are left as raw maps. Decoding is shallow and total:
  unknown keys are dropped, missing keys become `nil`, and missing lists
  become `[]`.

  Schemas cover the core booking flow: `Duffel.Schema.OfferRequest`,
  `Duffel.Schema.Offer`, `Duffel.Schema.Order`, `Duffel.Schema.Slice`,
  `Duffel.Schema.Segment`, `Duffel.Schema.Passenger` and
  `Duffel.Schema.Payment`.

  To decode a page of results, map over its data:

      {:ok, page} = Duffel.Orders.list(client)
      orders = Enum.map(page.data, &Duffel.Schema.Order.from_map/1)

  """

  @doc """
  Decodes a list of raw maps into structs of `module`.

  Returns `[]` when given `nil`, so a missing list field decodes to an empty
  list rather than `nil`.
  """
  @spec cast_list([map()] | nil, module()) :: [struct()]
  def cast_list(nil, _module), do: []
  def cast_list(list, module) when is_list(list), do: Enum.map(list, &module.from_map/1)
end
