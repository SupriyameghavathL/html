defmodule GruppieWeb.Team do
  use Ecto.Schema
  import Ecto.Changeset
  import GruppieWeb.Handler.TimeNow
  alias GruppieWeb.Repo.TeamRepo
  import GruppieWeb.Repo.RepoHelper


  @add_fields [ :name, :image, :category ]

  @update_fields [ :name, :image, :category ]

  @class_team_fields [ :name, :image, :category, :subjectId, :ebookId ]

  @subject_fields [ :name, :classSubjects ]

  @ebooks_fields [ :className, :subjectBooks, :description]

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
    field :isActive, :boolean
  end




  def changeset(struct, params \\%{}) do
    struct
    |> cast(params, @add_fields)
    |> validate_required(:name, [message: "Team Name Must Not Be Empty"])
    |> set_time
  end

  def changeset_team_edit(struct, params \\%{}) do
    struct
    |> cast(params, @update_fields)
    |> validate_required(:name, [message: "Team Name Must Not Be Empty"])
    |> put_change(:updatedAt, bson_time())
  end


  def changeset_class(struct, params \\%{}) do
    struct
    |> cast(params, @class_team_fields)
    |> validate_required(:name, [message: "Team Name Must Not Be Empty"])
    |> set_time
  end

  defp set_time(struct) do
    struct
    |> put_change( :insertedAt, bson_time() )
    |> put_change( :updatedAt, bson_time() )
  end



  def changeset_ebook_register(struct, params) do
    struct
    |> cast(params, @ebooks_fields)
    |> validate_required(:className, [message: "Class Name Must Not Be Empty"])
    |> validate_required(:subjectBooks, [message: "Must Not Be Empty"])
    |> put_change(:isActive, true)
    |> set_time
  end



  def changeset_subject_add(struct, params) do
    struct
    |> cast(params, @subject_fields)
    |> validate_required(:name, [message: "Class Name Must Not Be Empty"])
    |> put_change(:isActive, true)
    |> set_time
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



  def insert_bus_team(objectId, userId, groupObjectId, changeset) do
    teamDoc = %{
      "_id" => objectId,
      "adminId" => userId,
      "groupId" => groupObjectId,
      "name" => changeset.name,
      "insertedAt" => changeset.insertedAt,
      "updatedAt" => changeset.updatedAt,
      "isActive" => true,
      "enableGps" => true,
      "enableAttendance" => false,
      "allowTeamPostAll" => false,
	    "allowTeamPostCommentAll" => false,
      "allowUserToAddOtherUser" => false,
      "bus" => true
    }
    if Map.has_key?(changeset, :image) do
      imageDoc = %{
        "image" => changeset.image
      }
      Map.merge(teamDoc, imageDoc)
    else
      teamDoc
    end
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



  def insertNewTeamForAddingUser(teamObjectId, userName) do
    #to check team is allowed to post or comment or adding users
    team = TeamRepo.get(encode_object_id(teamObjectId))
    %{
      "teamId" => teamObjectId,
      "userName" => userName,
      "isTeamAdmin" => false,
      "allowedToAddUser" => if team["allowUserToAddOtherUser"] == true do true else false end,
      "allowedToAddPost" => if team["allowTeamPostAll"] == true do true else false end,
      "allowedToAddComment" => if team["allowTeamPostCommentAll"] == true do true else false end,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      "teamPostLastSeen" => bson_time(),
    }
  end


  def insertNewTeamForAddingStaff(teamObjectId, userName) do
    #to check team is allowed to post or comment or adding users
    team = TeamRepo.get(encode_object_id(teamObjectId))
    %{
      "teamId" => teamObjectId,
      "userName" => userName,
      "isTeamAdmin" => false,
      "allowedToAddUser" => if team["allowUserToAddOtherUser"] == true do true else false end,
      "allowedToAddPost" => true,
      "allowedToAddComment" => true,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      "teamPostLastSeen" => bson_time(),
    }
  end



  def insertSubjectStaffToClass(teamObjectId) do
    #to check team is allowed to post or comment or adding users
    #team = TeamRepo.get(encode_object_id(teamObjectId))
    %{
      "teamId" => teamObjectId,
      ##"userName" => userName,
      "isTeamAdmin" => false,
      "allowedToAddUser" => false,
      "allowedToAddPost" => true,
      "allowedToAddComment" => true,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      "teamPostLastSeen" => bson_time(),
    }
  end


end
