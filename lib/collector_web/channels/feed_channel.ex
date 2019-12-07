defmodule CollectorWeb.FeedChannel do
  use Phoenix.Channel

  def join("feed:" <> source, _message, socket) do
    Collector.Metrics.subscribe(source)
    metrics = Collector.Metrics.list(%{"source" => source})

    {:ok, metrics, assign(socket, :feed, source)}
  end

  def handle_info({_module, :created, data}, socket) do
    broadcast(socket, "metric_added", data)
    {:noreply, socket}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end
end
