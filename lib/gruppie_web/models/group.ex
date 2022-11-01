defmodule GruppieWeb.Group do
  use Ecto.Schema
  import Ecto.Changeset
  import GruppieWeb.Handler.TimeNow

  # fields need to be filtered on create or update[@fields = module attributes]
  @fields [ :name, :avatar, :aboutGroup, :category, :subCategory, :type, :taluk, :district, :state, :country, :appName, :constituencyName, :categoryName ]

  #@zoom_host_fields [:hostName, :hostId]

  #@zoom_meeting_fields [:meetingId]

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "groups"  do
    field :name, :string
    field :aboutGroup, :string
    field :avatar, :string
    field :category, :string
    field :subCategory, :string
    field :type, :string
    field :inserted_at, :string
    field :updated_at, :string
    field :isActive, :boolean
    field :isAdminChangeAllowed, :boolean
    field :isPostShareAllowed, :boolean
    field :allowPostAll, :boolean
  #  field :hostName, :string
  #  field :hostId, :string
  #  field :meetingId, :string
    field :taluk, :string
    field :district, :string
    field :state, :string
    field :country, :string
    field :appName, :string
    field :constituencyName, :string
    field :categoryName, :string
  end


  def changeset_create(model, params \\%{}) do
    model
    |> cast(params, @fields)
    |> validate_required([:type], [message: "Must Not Be Empty"])
    |> validate_required([:name], [message: "Name Must Not Be Empty"])
    |> put_change(:isActive, true)
    |> put_change(:isAdminChangeAllowed, true)
    |> put_change(:isPostShareAllowed, false)
    |> put_change(:allowPostAll, false)
    |> put_change(:leaveRequest, false)
    |> check_visibility_public
    |> set_time
  end


  def check_visibility_public(struct) do
    visibility = get_field(struct, :type)
    if visibility == "public" do
      struct
      |> validate_required([:category], [message: "Must Not Be Empty"])
    else
      struct
    end
  end


  defp set_time(struct) do
    struct
    |> put_change( :insertedAt, bson_time() )
    |> put_change( :updatedAt, bson_time() )
  end

end
