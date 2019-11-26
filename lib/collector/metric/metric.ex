defmodule Collector.Metrics.Metric do
  use Ecto.Schema
  import Ecto.Changeset

  schema "metrics" do
    field :name
    field :data, :map

    timestamps(inserted_at: :created_at)
  end

  def changeset(metric, attrs \\ %{}) do
    cast(metric, attrs, [:name, :data])
  end
end
