defmodule GruppieWeb.Team do
  use Ecto.Schema
  import Ecto.Changeset
  import GruppieWeb.Handler.TimeNow
  # alias GruppieWeb.Repo.TeamRepo
  import GruppieWeb.Repo.RepoHelper


  # @add_fields [ :name, :image, :category ]

  # @update_fields [ :name, :image, :category ]

  @class_team_fields [ :name, :image, :category, :subjectId, :ebookId ]

  # @subject_fields [ :name, :classSubjects ]

  # @ebooks_fields [ :className, :subjectBooks, :description]

  @primary_key{:id, :binary_id, autogenerate: true}
  schema "teams" do
    field :name, :string
    field :image, :string
    field :category, :string
    field :inserted_at, :string
    field :updated_at, :string
    field :classSubjects, {:array, :string}
    field :subjectId, :string
    field :className, :string
    field :subjectBooks, {:array, :map}
    field :ebookId, :string
    field :description, :string
    field :insertedAt, :string
    field :updatedAt, :string
  end




  def insert_team(objectId, loginUserId, groupObjectId, changeset) do
    teamDoc = %{
      "_id" => objectId,
      "adminId" => loginUserId,
      "groupId" => groupObjectId,
      "name" => changeset.name,
      "insertedAt" => changeset.insertedAt,
      "updatedAt" => changeset.updatedAt,
      "isActive" => true,
      ##"enableGps" => false,
      ##"enableAttendance" => false,
      "allowTeamPostAll" => true,
	    "allowTeamPostCommentAll" => true,
      "allowUserToAddOtherUser" => true
    }
    teamDoc =  if Map.has_key?(changeset, :image) do
      Map.merge(%{ "image" => changeset.image }, teamDoc)
    else
      teamDoc
    end
    teamDoc = if Map.has_key?(changeset, :category) do
      Map.merge(%{ "category" => changeset.category }, teamDoc)
    else
      teamDoc
    end
    teamDoc = if Map.has_key?(changeset, :boothTeamId) do
      Map.merge(%{ "boothTeamId" => changeset.boothTeamId }, teamDoc)
    else
      teamDoc
    end
    teamDoc = if Map.has_key?(changeset, :defaultTeam) do
      Map.merge(%{ "defaultTeam" => changeset.defaultTeam }, teamDoc)
    else
      teamDoc
    end
    teamDoc
  end


  def changeset_class(struct, params \\%{}) do
    struct
    |> cast(params, @class_team_fields)
    |> validate_required(:name, [message: "Team Name Must Not Be Empty"])
    |> set_time
  end



  def insertGroupTeamMembersForLoginUser(teamObjectId, loginUser) do
    %{
      "teamId" => teamObjectId,
      "userName" => loginUser["name"],
      "isTeamAdmin" => true,
      "allowedToAddUser" => true,
      "allowedToAddPost" => true,
      "allowedToAddComment" => true,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      "teamPostLastSeen" => bson_time(),
    }
  end


  def insert_class_team(objectId, userId, groupObjectId, changeset) do
    teamDoc = %{
      "_id" => objectId,
      "adminId" => userId,
      "groupId" => groupObjectId,
      "name" => changeset.name,
      "insertedAt" => changeset.insertedAt,
      "updatedAt" => changeset.updatedAt,
      "isActive" => true,
      "enableGps" => false,
      "enableAttendance" => true,
      "allowTeamPostAll" => false,
	    "allowTeamPostCommentAll" => false,
      "allowUserToAddOtherUser" => false,
      "class" => true,
    }
    teamDoc = if Map.has_key?(changeset, :image) do
      Map.merge(%{ "image" => changeset.image }, teamDoc)
    else
      teamDoc
    end
    teamDoc = if Map.has_key?(changeset, :category) do
      Map.merge(%{ "category" => changeset.category }, teamDoc)
    else
      teamDoc
    end
    teamDoc = if Map.has_key?(changeset, :subjectId) do
      Map.merge(%{ "subjectId" => decode_object_id(changeset.subjectId) }, teamDoc)
    else
      teamDoc
    end
    teamDoc = if Map.has_key?(changeset, :ebookId) do
      Map.merge(%{ "ebookId" => decode_object_id(changeset.ebookId) }, teamDoc)
    else
      teamDoc
    end
    teamDoc
  end



  defp set_time(struct) do
    struct
    |> put_change( :insertedAt, bson_time() )
    |> put_change( :updatedAt, bson_time() )
  end


end
