defmodule Duffel.PageTest do
  use ExUnit.Case, async: true

  doctest Duffel.Page

  alias Duffel.Page

  describe "has_more?/1" do
    test "is true only while a page carries an after cursor" do
      assert Page.has_more?(%Page{after_cursor: "cur_2"})
      refute Page.has_more?(%Page{after_cursor: nil})
    end
  end

  describe "next_params/2" do
    test "merges the cursor into the params, keeping the filters" do
      page = %Page{after_cursor: "cur_2"}

      assert Page.next_params(page, sort: "total_amount", limit: 50) == %{
               "sort" => "total_amount",
               "limit" => 50,
               "after" => "cur_2"
             }
    end

    test "replaces a cursor already in the params" do
      assert Page.next_params(%Page{after_cursor: "cur_2"}, %{"after" => "cur_1"}) == %{
               "after" => "cur_2"
             }
    end

    test "defaults to no params" do
      assert Page.next_params(%Page{after_cursor: "cur_2"}) == %{"after" => "cur_2"}
    end

    test "is nil on the last page" do
      assert Page.next_params(%Page{after_cursor: nil}, limit: 50) == nil
    end
  end
end
