defmodule CollectorWeb.LiveMetricController do
  use CollectorWeb, :controller

  alias Phoenix.LiveView

  def index(conn, _) do
    LiveView.Controller.live_render(conn, CollectorWeb.MetricDisplayView, session: %{})
  end
end
