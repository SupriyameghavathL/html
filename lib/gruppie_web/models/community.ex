defmodule GruppieWeb.Community do
  use Ecto.Schema
  import Ecto.Changeset
  import GruppieWeb.Handler.TimeNow
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.TeamRepo


  @primary_key{:id, :binary_id, autogenerate: true}

  schema "community" do
    field :name, :string
    field :countryCode, :string
    field :phone, :string
    field :image, :string
    field :branchName, :string
    field :relation, :string
    field :insertedAt, :string
    field :updatedAt, :string
    field :isActive, :boolean
  end


  #user add to community team changeset
  def changeset_add_user_community(struct, params \\%{}) do
    struct
    |> cast(params, [:name, :countryCode, :phone, :relation])
    |> validate_required(:phone, [message: "Phone Number Must Not Be Empty"])
    |> validate_required(:countryCode, [message: "Country Code Must Not Be Empty"])
    |> validate_required(:name, [message: "Name Must Not Be Empty"])
    |> valid_phone_number
    |> set_time
  end


  #check phone is valid or not
  defp valid_phone_number(struct) do
    if struct.valid? do
      countryCode = get_field(struct, :countryCode) #get_field used to get values from struct
      phone = get_field(struct, :phone)
      case ExPhoneNumber.parse(phone, countryCode) do
        {:ok, phone_number} ->
          e164_number = ExPhoneNumber.format(phone_number, :e164)
          struct
          |> delete_change(:countryCode)
          |> put_change(:phone, e164_number)
        {:error, _}->
          add_error(struct, :phone, "Invalid CountryCode/Phone Given")
      end
    else
      struct
    end
  end


  defp set_time(struct) do
    struct
    |> put_change( :insertedAt, bson_time() )
    |> put_change( :updatedAt, bson_time() )
  end



  def insertGroupTeamMemberForSubBoothMembers(userObjectId, group, teamObjectId) do
    #to check team is allowed to post or comment or adding users
    team = TeamRepo.get(encode_object_id(teamObjectId))
    %{
      "userId" => userObjectId,
      "groupId" => group["_id"],
      "isAdmin" => false,
      "canPost" => false,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      "isActive" => true,
      "teams" => [%{
         "teamId" => teamObjectId,
         "isTeamAdmin" => false,
         "allowedToAddUser" => if team["allowUserToAddOtherUser"] == true do true else false end,
         "allowedToAddPost" => if team["allowTeamPostAll"] == true do true else false end,
         "allowedToAddComment" => if team["allowTeamPostCommentAll"] == true do true else false end,
         "insertedAt" => bson_time(),
         "updatedAt" => bson_time(),
        }],
    }
  end


  def insertNewTeamForAddingUser(teamObjectId, _changeset) do
    #to check team is allowed to post or comment or adding users
    team = TeamRepo.get(encode_object_id(teamObjectId))
    %{
      "teamId" => teamObjectId,
      "isTeamAdmin" => false,
      "allowedToAddUser" => if team["allowUserToAddOtherUser"] == true do true else false end,
      "allowedToAddPost" => if team["allowTeamPostAll"] == true do true else false end,
      "allowedToAddComment" => if team["allowTeamPostCommentAll"] == true do true else false end,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
    }
  end


  def branchEditDetails(struct, params \\%{}) do
    struct
    |> cast(params, [:branchName, :image, :name])
    |> set_time
  end
end
