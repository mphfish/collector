defmodule CollectorWeb.MetricDisplayView do
  use Phoenix.LiveView

  def mount(_session, socket) do
    socket = assign(socket, metrics: Collector.Metrics.list())
    if connected?(socket), do: schedule_next_update()
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <div class="metric-container">
      <%= for {source, metrics} <- Enum.map(@metrics, fn value -> value end) do %>
        <div class="source">
          <header>
            <%= source %>
          </header>
          <div class="metric-group">
            <%= for %{name: name, value: value} = metric <- metrics do %>
              <div class="metric-card <%= color_class(metric) %>">
                <header>
                  <%= name %>
                </header>
              <main>
              <%= value %><sup><%= unit(metric) %><sup>
              </main>
            </div>
          <% end %>
        </div>
      </div>
      <% end %>
    </div>
    """
  end

  def value_from_metric(%{data: %{"temp" => temp}}), do: temp
  def value_from_metric(%{data: %{"humidity" => humidity}}), do: humidity
  def value_from_metric(%{data: %{"pressure" => pressure}}), do: pressure

  def color_class(%{name: "temp", data: %{"temp" => temp}}) when temp > 74.0, do: "high"
  def color_class(%{name: "temp", data: %{"temp" => temp}}) when temp < 68.0, do: "low"

  def color_class(%{name: "temp", data: %{"humidity" => humidity}}) when humidity > 50.0,
    do: "high"

  def color_class(%{name: "humidity", data: %{"humidity" => humidity}}) when humidity < 40.0,
    do: "low"

  def color_class(_), do: "normal"

  def unit(%{name: "temp"}), do: "°F"
  def unit(%{name: "humidity"}), do: "%"
  def unit(%{name: "pressure"}), do: "Pa"

  def handle_info(:next_update, socket) do
    metrics = Collector.Metrics.list()

    socket = assign(socket, metrics: metrics)

    schedule_next_update()
    {:noreply, socket}
  end

  defp schedule_next_update() do
    Process.send_after(self(), :next_update, 10 * 1000)
  end
end
