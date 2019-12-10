defmodule Collector.Repo.Migrations.Initial do
  use Ecto.Migration

  def change do
    create table(:metrics) do
      add :name, :string
      add :unit, :string
      add :value, :float
      add :source, :string

      timestamps(inserted_at: :created_at)
    end

    create_if_not_exists(index(:metrics, [:name]))
    create_if_not_exists(index(:metrics, [:source]))
    create_if_not_exists(index(:metrics, [:value]))
  end
end
