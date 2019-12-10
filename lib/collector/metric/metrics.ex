defmodule Collector.Metrics do
  import Ecto.Query

  @topic inspect(__MODULE__)

  def subscribe(source) do
    Phoenix.PubSub.subscribe(Collector.PubSub, @topic <> "#{source}")
  end

  def get!(id), do: Collector.Repo.get!(Collector.Metrics.Metric, id)

  @spec create(:invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}) ::
          {:error, any} | {:ok, Collector.Metrics.Metric.t()}
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
      {key,
       %{
         ticks: Enum.map(values, &transform_metric/1),
         history: history(%{"source" => source, "name" => key})
       }}
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
  def history(%{"source" => source, "name" => name} = params) do
    base_query =
      from(
        m in Collector.Metrics.Metric,
        where: m.name == ^name and m.source == ^source,
        select: %{
          avg: avg(m.value),
          min: min(m.value),
          max: max(m.value)
        }
      )

    %{
      all_time:
        base_query
        |> time(%{})
        |> Collector.Repo.one(),
      last_24:
        base_query
        |> time(%{"timeframe" => "24h"})
        |> Collector.Repo.one()
    }
  end

  import Collector.Query

  defp time(query, %{"timeframe" => "24h"}) do
    now = DateTime.utc_now()

    twenty_four_hours_ago = Timex.shift(now, hours: -24)
    where(query, [m], between(m.created_at, ^twenty_four_hours_ago, ^now))
  end

  defp time(query, _), do: query

  defp notify_subscribers({:ok, %Collector.Metrics.Metric{source: source} = metric}, event) do
    Phoenix.PubSub.broadcast(
      Collector.PubSub,
      @topic <> "#{source}",
      {__MODULE__, event, transform_metric(metric)}
    )

    {:ok, metric}
  end

  defp notify_subscribers({:error, reason}, _event), do: {:error, reason}

  defp transform_metric(value) do
    value
    |> Map.from_struct()
    |> Map.take([:created_at, :name, :unit, :value, :source])
  end
end
