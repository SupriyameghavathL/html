defmodule GruppieWeb.Calendar do
  use Ecto.Schema
  import Ecto.Changeset
  import GruppieWeb.Handler.TimeNow


  @events_fields [ :title, :startDate, :endDate, :startTime, :endTime, :location, :reminder, :venue, :landmark ]

  schema "calendar" do
    field :title, :string
    field :startDate, :string
    field :endDate, :string
    field :startTime, :string
    field :endTime, :string
    field :location, :map
    field :reminder, :string
    field :venue, :string
    field :landmark, :string
    field :insertedAt, :string
    field :updatedAt, :string
    field :isActive, :boolean
  end


  def calendarEventAdd(struct, params \\%{}) do
    struct
    |> cast(params, @events_fields)
    |> validate_required(:title, [message: "Title Must Not Be Empty"])
    |> set_time
  end


  defp set_time(struct) do
    struct
    |> put_change( :insertedAt, bson_time() )
    |> put_change( :updatedAt, bson_time() )
    |> put_change( :isActive, true )
  end
end
