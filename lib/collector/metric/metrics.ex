defmodule Collector.Metrics do
  import Ecto.Query

  def get!(id), do: Collector.Repo.get!(Collector.Metrics.Metric, id)

  def create(attrs),
    do:
      %Collector.Metrics.Metric{}
      |> Collector.Metrics.Metric.changeset(attrs)
      |> Collector.Repo.insert()

  @spec update(Collector.Metrics.Metric.t(), map()) ::
          {:ok, Collector.Metrics.Metric.t()} | {:error, Ecto.Changeset.t()}
  def update(metric, attrs) do
    metric
    |> Collector.Metrics.Metric.changeset(attrs)
    |> Collector.Repo.update()
  end

  @spec list() :: [Collector.Metrics.Metric.t()]
  def list() do
    from(
      m in Collector.Metrics.Metric,
      distinct: m.name,
      order_by: [desc: m.created_at]
    )
    |> Collector.Repo.all()
  end

  @spec history(map()) :: [Collector.Metrics.Metric.t()]
  def history(%{"name" => name} = params) do
    limit = params["limit"] || 100

    from(
      m in Collector.Metrics.Metric,
      limit: ^limit,
      order_by: m.inserted_at,
      where: m.name == ^name
    )
    |> Collector.Repo.all()
  end
end
