defmodule CollectorWeb.MetricView do
  use CollectorWeb, :view

  def render("show.json", %{metric: metric}) do
    %{metric: render_one(metric, __MODULE__, "metric.json")}
  end

  def render("metric.json", %{metric: metric}) do
    metric
    |> Map.from_struct()
    |> Map.take([
      :name,
      :data,
      :created_at,
      :updated_at
    ])
  end
end
