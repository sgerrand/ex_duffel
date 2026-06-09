defmodule Duffel.Identity.CustomerUserGroups do
  @moduledoc """
  Group customer users to scope what each of your users can see and manage.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/customer-user-groups).
  """

  alias Duffel.Client

  @path "/identity/customer/user_groups"

  @doc """
  Creates a customer user group.

  ## Examples

      Duffel.Identity.CustomerUserGroups.create(client, %{
        name: "Acme Corp",
        user_ids: ["icu_123"]
      })

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(client, params, opts \\ []) do
    with {:ok, %{"data" => data}} <- Client.post(client, @path, params, opts) do
      {:ok, data}
    end
  end

  @doc """
  Retrieves a single group by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(client, id) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.get(client, "#{@path}/#{id}") do
      {:ok, data}
    end
  end

  @doc """
  Lists customer user groups. Not paginated.
  """
  @spec list(Client.t()) :: {:ok, [map()]} | {:error, term()}
  def list(client) do
    with {:ok, %{"data" => data}} <- Client.get(client, @path) do
      {:ok, data}
    end
  end

  @doc """
  Updates a customer user group's name or members.
  """
  @spec update(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, term()}
  def update(client, id, params) when is_binary(id) do
    with {:ok, %{"data" => data}} <- Client.patch(client, "#{@path}/#{id}", params) do
      {:ok, data}
    end
  end

  @doc """
  Deletes a customer user group.
  """
  @spec delete(Client.t(), String.t()) :: :ok | {:error, term()}
  def delete(client, id) when is_binary(id) do
    with {:ok, _body} <- Client.delete(client, "#{@path}/#{id}") do
      :ok
    end
  end
end
