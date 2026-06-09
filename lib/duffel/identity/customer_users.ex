defmodule Duffel.Identity.CustomerUsers do
  @moduledoc """
  Manage customer users — the travellers and bookers your own users
  represent within Duffel.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/customer-users).
  """

  alias Duffel.{Client, Page}

  @path "/identity/customer/users"

  @doc """
  Creates a customer user.

  ## Examples

      Duffel.Identity.CustomerUsers.create(client, %{
        email: "amelia@duffel.com",
        given_name: "Amelia",
        family_name: "Earhart",
        phone_number: "+442080160508"
      })

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, @path, params, opts) do
      {:ok, data}
    end
  end

  @doc """
  Retrieves a single customer user by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
  end

  @doc """
  Lists one page of customer users.

  ## Parameters

    * `:limit` / `:after` / `:before` - pagination (see `Duffel.Page`)

  """
  @spec list(Client.t(), keyword() | map()) :: {:ok, Page.t()} | {:error, term()}
  def list(client, params \\ []) do
    Client.list(client, @path, params)
  end

  @doc """
  Lazily streams all customer users across pages.

  Raises `Duffel.Error` if a page request fails.
  """
  @spec stream(Client.t(), keyword() | map()) :: Enumerable.t()
  def stream(client, params \\ []) do
    Client.stream(client, @path, params)
  end

  @doc """
  Updates a customer user. Replaces the user with the given attributes.
  """
  @spec update(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, term()}
  def update(client, id, params) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.put(client, "#{@path}/#{id}", params) do
      {:ok, data}
    end
  end
end
