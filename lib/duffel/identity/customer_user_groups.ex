defmodule Duffel.Identity.CustomerUserGroups do
  @moduledoc """
  Group customer users to scope what each of your users can see and manage.

  See the [Duffel documentation](https://duffel.com/docs/api/v2/customer-user-groups).
  """

  alias Duffel.{Client, Error}

  @path "/identity/customer/user_groups"

  @doc """
  Creates a customer user group.

  ## Examples

      Duffel.Identity.CustomerUserGroups.create(client, %{
        name: "Acme Corp",
        user_ids: ["icu_123"]
      })

  """
  @spec create(Client.t(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def create(client, params, opts \\ []) do
    client |> Client.post(@path, params, opts) |> Client.unwrap()
  end

  @doc """
  Retrieves a single group by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id) when is_binary(id) do
    client |> Client.get("#{@path}/#{id}") |> Client.unwrap()
  end

  @doc """
  Lists customer user groups. Not paginated.
  """
  @spec list(Client.t()) :: {:ok, [map()]} | {:error, Error.t()}
  def list(client) do
    client |> Client.get(@path) |> Client.unwrap()
  end

  @doc """
  Updates a customer user group's name or members.
  """
  @spec update(Client.t(), String.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def update(client, id, params) when is_binary(id) do
    client |> Client.patch("#{@path}/#{id}", params) |> Client.unwrap()
  end

  @doc """
  Deletes a customer user group.
  """
  @spec delete(Client.t(), String.t()) :: :ok | {:error, Error.t()}
  def delete(client, id) when is_binary(id) do
    with {:ok, _body} <- Client.delete(client, "#{@path}/#{id}") do
      :ok
    end
  end
end
