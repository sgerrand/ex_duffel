defmodule Duffel.SeatMapsTest do
  use Duffel.Case, async: true

  alias Duffel.SeatMaps

  test "lists seat maps for an offer" do
    Req.Test.stub(__MODULE__, fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/air/seat_maps"
      assert conn.query_params["offer_id"] == "off_1"

      Req.Test.json(conn, %{
        "data" => [%{"id" => "sea_1", "segment_id" => "seg_1", "cabins" => []}]
      })
    end)

    assert {:ok, [%{"id" => "sea_1"}]} = SeatMaps.list(client(), offer_id: "off_1")
  end
end
