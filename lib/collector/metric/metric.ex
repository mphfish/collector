defmodule Collector.Metrics.Metric do
  @derive {Jason.Encoder, only: [:name, :source, :data, :created_at, :updated_at]}
  use Ecto.Schema
  import Ecto.Changeset

  schema "metrics" do
    field :name
    field :source
    field :unit
    field :value, :float

    timestamps(inserted_at: :created_at)
  end

  def changeset(metric, attrs \\ %{}) do
    cast(metric, attrs, [:name, :source, :unit, :value])
  end
end
