defmodule Collector.Metrics do
  import Ecto.Query

  @topic inspect(__MODULE__)

  def subscribe(source) do
    Phoenix.PubSub.subscribe(Collector.PubSub, @topic <> "#{source}")
  end

  def get!(id), do: Collector.Repo.get!(Collector.Metrics.Metric, id)

  def create(attrs) do
    %Collector.Metrics.Metric{}
    |> Collector.Metrics.Metric.changeset(attrs)
    |> Collector.Repo.insert()
    |> notify_subscribers(:created)
  end

  @spec update(Collector.Metrics.Metric.t(), map()) ::
          {:ok, Collector.Metrics.Metric.t()} | {:error, Ecto.Changeset.t()}
  def update(metric, attrs) do
    metric
    |> Collector.Metrics.Metric.changeset(attrs)
    |> Collector.Repo.update()
  end

  @spec list(map()) :: [Collector.Metrics.Metric.t()]

  def list(params \\ %{})

  def list(%{"source" => source} = params) do
    limit = params["limit"] || 20
    offset = params["offset"] || 0
    IO.puts("some shit")

    from(
      m in Collector.Metrics.Metric,
      where: m.source == ^source,
      limit: ^limit,
      order_by: [desc: m.created_at]
    )
    |> Collector.Repo.all()
    |> Enum.reverse()
    |> Enum.group_by(& &1.name)
    |> Enum.into(%{}, fn {key, values} ->
      {key, Enum.map(values, &transform_metric/1)}
    end)
  end

  def list(_) do
    from(
      m in Collector.Metrics.Metric,
      distinct: m.name,
      order_by: [desc: m.created_at]
    )
    |> Collector.Repo.all()
    |> Enum.group_by(& &1.source)
  end

  @spec history(map()) :: [Collector.Metrics.Metric.t()]
  def history(%{name: name} = params) do
    from(
      m in Collector.Metrics.Metric,
      limit: ^10,
      order_by: [desc: m.created_at],
      where: m.name == ^name
    )
    |> Collector.Repo.all()
    |> Enum.reverse()
  end

  defp notify_subscribers({:ok, %Collector.Metrics.Metric{source: source} = metric}, event) do
    Phoenix.PubSub.broadcast(
      Collector.PubSub,
      @topic <> "#{source}",
      {__MODULE__, event, transform_metric(metric)}
    )

    {:ok, metric}
  end

  defp notify_subscribers({:error, reason}, _event), do: {:error, reason}

  defp transform_metric(%{name: name, data: data} = value) do
    data = data |> Map.values() |> hd

    value
    |> Map.from_struct()
    |> Map.take([:created_at, :name])
    |> Map.put(name, data)
    |> Map.drop([:data])
  end
end
