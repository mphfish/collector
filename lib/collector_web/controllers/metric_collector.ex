defmodule CollectorWeb.MetricController do
  use CollectorWeb, :controller

  action_fallback(CollectorWeb.FallbackController)

  def create(conn, params) do
    with {:ok, %Collector.Metrics.Metric{} = metric} <- Collector.Metrics.create(params) do
      conn
      |> put_status(:created)
      |> render("show.json", metric: metric)
    end
  end
end
