defmodule CollectorWeb.Router do
  use CollectorWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CollectorWeb do
    pipe_through :browser

    get "/", LiveMetricController, :index
    get "/history", HistoryController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", CollectorWeb do
    pipe_through :api
    resources "/metrics", MetricController, only: [:create]
  end
end
