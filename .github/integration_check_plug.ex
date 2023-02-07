defmodule MyProjectWeb.IntegrationCheckPlug do
  @behaviour Plug

  alias MyProject.Repo

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    with :ok <- database_available?(),
         :ok <- connected_to_nodes?() do
      conn
      |> put_resp_header("content-type", "application/json")
      |> send_resp(200, Jason.encode!(%{}))
      |> halt()
    else
      {:error, error} ->
        conn
        |> put_resp_header("content-type", "application/json")
        |> send_resp(500, Jason.encode!(%{error: error}))
        |> halt()
    end
  end

  defp database_available? do
    try do
      Ecto.Adapters.SQL.query(Repo, "SELECT 1")
    rescue
      e in RuntimeError -> {:error, e.message}
    end
    |> case do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  defp connected_to_nodes? do
    case Node.list() do
      [] -> {:error, "not connected to any nodes"}
      _nodes -> :ok
    end
  end
end
