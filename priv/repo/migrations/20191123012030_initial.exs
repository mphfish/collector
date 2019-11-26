defmodule Collector.Repo.Migrations.Initial do
  use Ecto.Migration

  def change do
    create table :metrics do
      add :name, :string
      add :data, :map

      timestamps(inserted_at: :created_at)
    end

  end
end
