defmodule Duffel.Case do
  @moduledoc false

  # The case every test that makes a request uses. It builds a client wired
  # to `Req.Test`, so no test reaches the network, and names the stub after
  # the test module, so stubs stay isolated while tests run async.

  use ExUnit.CaseTemplate

  using do
    quote do
      @doc false
      def client(opts \\ []) do
        [
          access_token: "duffel_test_abc",
          req_options: [plug: {Req.Test, __MODULE__}, retry: false]
        ]
        |> Keyword.merge(opts)
        |> Duffel.new()
      end

      @doc false
      def stub(fun), do: Req.Test.stub(__MODULE__, fun)
    end
  end
end
