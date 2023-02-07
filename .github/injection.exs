defmodule Injector do
  def inject(file, needle, injection_content) do
    content = File.read!(file)

    content_lines = String.split(content, "\n")
    index = Enum.find_index(content_lines, & &1 =~ needle)

    {content_lines_before, content_lines_after} = Enum.split(content_lines, index + 1)

    content =
      [content_lines_before, [injection_content], content_lines_after]
      |> Enum.concat()
      |> Enum.join("\n")

    File.write!(file, content)
  end
end

case System.argv() do
  ["db_config"] ->
    Injector.inject(
      "config/runtime.exs",
      "import Config",
      """

      # AWS RDS rotation requires us to store db credentials in a specific format
      # in Secrets Manager so we will build the DSN here
      if credentials = System.get_env("DATABASE_CREDENTIALS") do
        %{
          "engine" => engine,
          "host" => host,
          "username" => username,
          "password" => password,
          "dbname" => dbname,
          "port" => port
        } = Jason.decode!(credentials)

        dsn = "\#{engine}://\#{URI.encode_www_form(username)}:\#{URI.encode_www_form(password)}@\#{host}:\#{port}/\#{dbname}"

        System.put_env("DATABASE_URL", dsn)
      end
      """)

  ["libcluster_config"] ->
    Injector.inject(
      "config/runtime.exs",
      "import Config",
      """
      case System.fetch_env("DNS_POLL_QUERY") do
        :error ->
          :ok

        {:ok, query} ->
          [node_basename, _host] = String.split(System.fetch_env!("RELEASE_NODE"), "@")

          config :libcluster,
            topologies: [
              dns: [
                strategy: Cluster.Strategy.DNSPoll,
                config: [
                  polling_interval: 1_000,
                  query: query,
                  node_basename: node_basename]]]
      end
      """
    )

  ["mix_dep_libcluster"] ->
    Injector.inject(
      "mix.exs",
      "{:postgrex,",
      "      {:libcluster, \"~> 3.2\"},")

  ["integration_check_plug"] ->
    Injector.inject(
      "lib/my_project_web/router.ex",
      "get \"/\", PageController, :index",
      "    get \"/integration-check\", IntegrationCheckPlug, []")
end
