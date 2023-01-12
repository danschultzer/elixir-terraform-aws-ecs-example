# Elixir Terraform AWS ECS Example

There are some resources on terraform and/or ECS setup with Elixir, but all were missing some pieces I needed. Either they were outdated, or incomplete for my use case. So I've created this repo to show how you can set up a complete production-ready ECS setup with terraform.

## Features

- Github Actions builds and pushes to ECR
- ECS with rolling deployment
- ECS with blue-green deployment using CodeDeploy
- Github Actions triggers deployment
- Monolithic support with multiple ports
- Secrets in Secrets Manager
- CloudWatch for logging
- RDS postgres instance
- Elixir clustering

This includes the necessary network and permissions configuration.

## Caveat for CodeDeploy and multiple ports

One caveat to know is that AWS doesn't support multiple target groups for CodeDeploy controller. So for blue-green deployment to work with multiple ports on the instance it's necessary to set up separate ECS services for each port.

If you are not going to use blue-green deployment then you can just add a second `load_balance` on the `aws_ecs_service`.

## Prerequisites

It's expected that you already have an Elixir app dockerized with an `entrypoint.sh` bash script. See [`my_project/README.md`](my_project/README.md) for details.

The dockerfile is expected to exist in `.release/Dockerfile`. Adjust the dockerfile path in [my_project/.github/workflows/cd.yml](.github/worksflows/cd.yml) if it's in a different location.

## Go by commits

To make it easier to understand what each part does you should follow the commit history. It'll go step-by-step for each feature.

## Github Actions variables

Github Actions will need all the variables from the terraform output set for the CD workflow to work.

## Elixir code changes

### Database URL

The terraform build is set up to use Secrets Manager for the database. Furthermore password rotation is supported, however that means we can't store the connection string as is. Instead we need to build it (or if you prefer you can also just pass in the host/username/password directly):

```elixir
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

    dsn = "#{engine}://#{URI.encode_www_form(username)}:#{URI.encode_www_form(password)}@#{host}:#{port}/#{dbname}"

    System.put_env("DATABASE_URL", dsn)
  end
```

### Elixir cluster

Private DNS is used for cluster discovery. You should setup libcluster with the following `config/runtime.ex` configuration:

```elixir
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
```
