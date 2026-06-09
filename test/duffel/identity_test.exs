defmodule Duffel.IdentityTest do
  use ExUnit.Case, async: true

  alias Duffel.Identity.{ComponentClientKeys, CustomerUserGroups, CustomerUsers}
  alias Duffel.Page

  defp client do
    Duffel.new(
      access_token: "duffel_test_abc",
      req_options: [plug: {Req.Test, __MODULE__}, retry: false]
    )
  end

  defp stub(fun), do: Req.Test.stub(__MODULE__, fun)

  describe "CustomerUsers" do
    test "create/3 posts a user" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/identity/customer/users"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"email" => "a@duffel.com"}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "icu_1"}})
      end)

      assert {:ok, %{"id" => "icu_1"}} =
               CustomerUsers.create(client(), %{email: "a@duffel.com"})
    end

    test "get/2 fetches a user" do
      stub(fn conn ->
        assert conn.request_path == "/identity/customer/users/icu_1"
        Req.Test.json(conn, %{"data" => %{"id" => "icu_1"}})
      end)

      assert {:ok, %{"id" => "icu_1"}} = CustomerUsers.get(client(), "icu_1")
    end

    test "list/1 defaults and stream/2" do
      stub(fn conn ->
        assert conn.request_path == "/identity/customer/users"
        Req.Test.json(conn, %{"data" => [%{"id" => "icu_1"}], "meta" => %{"after" => nil}})
      end)

      assert {:ok, %Page{data: [%{"id" => "icu_1"}]}} = CustomerUsers.list(client())
      assert client() |> CustomerUsers.stream() |> Enum.map(& &1["id"]) == ["icu_1"]
    end

    test "update/3 replaces a user with PUT" do
      stub(fn conn ->
        assert conn.method == "PUT"
        assert conn.request_path == "/identity/customer/users/icu_1"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"given_name" => "Amy"}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "icu_1", "given_name" => "Amy"}})
      end)

      assert {:ok, %{"given_name" => "Amy"}} =
               CustomerUsers.update(client(), "icu_1", %{given_name: "Amy"})
    end
  end

  describe "CustomerUserGroups" do
    test "create/3 posts a group" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/identity/customer/user_groups"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"name" => "Acme"}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"id" => "grp_1"}})
      end)

      assert {:ok, %{"id" => "grp_1"}} =
               CustomerUserGroups.create(client(), %{name: "Acme"})
    end

    test "get/2 fetches a group" do
      stub(fn conn ->
        assert conn.request_path == "/identity/customer/user_groups/grp_1"
        Req.Test.json(conn, %{"data" => %{"id" => "grp_1"}})
      end)

      assert {:ok, %{"id" => "grp_1"}} = CustomerUserGroups.get(client(), "grp_1")
    end

    test "list/1 returns an unpaginated list" do
      stub(fn conn ->
        assert conn.request_path == "/identity/customer/user_groups"
        Req.Test.json(conn, %{"data" => [%{"id" => "grp_1"}]})
      end)

      assert {:ok, [%{"id" => "grp_1"}]} = CustomerUserGroups.list(client())
    end

    test "update/3 patches a group" do
      stub(fn conn ->
        assert conn.method == "PATCH"
        assert conn.request_path == "/identity/customer/user_groups/grp_1"
        Req.Test.json(conn, %{"data" => %{"id" => "grp_1"}})
      end)

      assert {:ok, %{"id" => "grp_1"}} =
               CustomerUserGroups.update(client(), "grp_1", %{name: "New"})
    end

    test "delete/2 returns :ok" do
      stub(fn conn ->
        assert conn.method == "DELETE"
        assert conn.request_path == "/identity/customer/user_groups/grp_1"
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert :ok = CustomerUserGroups.delete(client(), "grp_1")
    end
  end

  describe "ComponentClientKeys" do
    test "create/2 posts scope IDs" do
      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/identity/component_client_keys"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{"order_id" => "ord_1"}} = Jason.decode!(body)

        Req.Test.json(conn, %{"data" => %{"component_client_key" => "ey.jwt"}})
      end)

      assert {:ok, %{"component_client_key" => "ey.jwt"}} =
               ComponentClientKeys.create(client(), %{order_id: "ord_1"})
    end

    test "create/1 defaults to an unscoped key" do
      stub(fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert %{"data" => %{}} = Jason.decode!(body)
        Req.Test.json(conn, %{"data" => %{"component_client_key" => "ey.jwt"}})
      end)

      assert {:ok, %{"component_client_key" => "ey.jwt"}} =
               ComponentClientKeys.create(client())
    end
  end
end
