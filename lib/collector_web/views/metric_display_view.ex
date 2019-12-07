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
    <%= for %{name: name, data: data, history: history} = metric <- metrics do %>
    <div class="metric-card <%= color_class(metric) %>">
    <header>
    <%= name %>
    </header>
    <main>
    <script>

    const labels<%= name %> = [
      <%= reduce_labels(history) %>
    ].map(Date)

    const data<%= name %> = {
      labels: labels<%= name %>,
      datasets: [
        {
          values: [
            <%= reduce_values(history) %>
          ]
        }
      ]
    }
    </script>
    <div id="<%= name %>chart"></div>
    <script>
    new frappe.Chart("#<%= name %>chart", {
      data: data<%= name %>,
      type: "line",
      height: 140,
      colors: ["red"]
    })
    </script>
    <%= for value <- Map.values(data) do %>
    <%= value %><sup><%= unit(metric) %><sup>
    <% end %>
    </main>
    </div>
    <% end %>
    </div>
    </div>
    <% end %>
    </div>
    """
  end

  def reduce_labels(history) do
    Enum.reduce(
      history,
      "",
      fn
        %{created_at: created_at}, "" ->
          "#{created_at |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()}"

        %{created_at: created_at}, acc ->
          acc <> "," <> "#{created_at |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()}"
      end
    )
  end

  def reduce_values(history) do
    Enum.reduce(
      history,
      "",
      fn
        metric, "" ->
          "#{value_from_metric(metric)}"

        metric, acc ->
          acc <> "," <> "#{value_from_metric(metric)}"
      end
    )
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
