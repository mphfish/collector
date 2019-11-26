defmodule Collector.Repo.Migrations.AddSource do
  use Ecto.Migration

  def change do
    alter table :metrics do
      add :source, :string
    end
  end
end
