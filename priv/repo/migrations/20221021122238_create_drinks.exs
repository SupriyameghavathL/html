defmodule Gruppie.Repo.Migrations.CreateDrinks do
  use Ecto.Migration

  def change do
    create table(:drinks) do
      add :name, :string
      add :temperature, :string

      timestamps()
    end
  end
end
