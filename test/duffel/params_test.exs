defmodule Duffel.ParamsTest do
  use ExUnit.Case, async: true

  # The helpers are injected as private functions, so exercising them needs a
  # module that uses them, exactly as the params builders do.
  defmodule Builder do
    @moduledoc false
    use Duffel.Params

    def require!(opts, keys), do: require_params!(opts, keys)
    def put(map, opts, keys), do: put_params(map, opts, keys)
  end

  describe "require_params!/2" do
    test "passes when every required key is present" do
      assert Builder.require!([a: 1, b: 2], [:a, :b]) == :ok
    end

    test "passes when a required key is present but nil" do
      assert Builder.require!([a: nil], [:a]) == :ok
    end

    test "raises listing every missing key" do
      assert_raise ArgumentError, "missing required options: [:b, :c]", fn ->
        Builder.require!([a: 1], [:a, :b, :c])
      end
    end
  end

  describe "put_params/3" do
    test "copies the given keys onto the map" do
      assert Builder.put(%{a: 1}, [b: 2, c: 3], [:b, :c]) == %{a: 1, b: 2, c: 3}
    end

    test "skips a key the caller left out" do
      assert Builder.put(%{}, [b: 2], [:b, :c]) == %{b: 2}
    end

    test "skips a key the caller passed as nil" do
      assert Builder.put(%{}, [b: nil], [:b]) == %{}
    end

    test "keeps a false value" do
      assert Builder.put(%{}, [b: false], [:b]) == %{b: false}
    end

    test "ignores options that are not in the key list" do
      assert Builder.put(%{}, [b: 2, other: 3], [:b]) == %{b: 2}
    end
  end
end
