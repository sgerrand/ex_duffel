defmodule DuffelTest do
  use ExUnit.Case, async: true
  doctest Duffel

  describe "new/1" do
    test "builds a client with defaults" do
      client = Duffel.new(access_token: "duffel_test_abc")

      assert %Duffel.Client{} = client
      assert client.access_token == "duffel_test_abc"
      assert client.base_url == "https://api.duffel.com"
      assert client.api_version == "v2"
      assert client.req_options == []
    end

    test "accepts overrides" do
      client =
        Duffel.new(
          access_token: "duffel_test_abc",
          base_url: "https://example.test",
          api_version: "v1",
          req_options: [retry: false]
        )

      assert client.base_url == "https://example.test"
      assert client.api_version == "v1"
      assert client.req_options == [retry: false]
    end

    test "raises without an access token" do
      assert_raise ArgumentError, ~r/missing :access_token/, fn ->
        Duffel.new([])
      end
    end
  end

  describe "new/0" do
    test "reads from the application environment" do
      Application.put_env(:duffel, :access_token, "duffel_test_env")
      on_exit(fn -> Application.delete_env(:duffel, :access_token) end)

      assert %Duffel.Client{access_token: "duffel_test_env"} = Duffel.new()
    end
  end
end
