defmodule GruppieWeb.SchoolCollege do
  use Ecto.Schema
  import Ecto.Changeset
  import GruppieWeb.Handler.TimeNow


  @register_fields [ :name, :board, :academicStartYear, :academicEndYear, :classTypeId,  :schoolType, :university, :medium, :subCategory, :classSection, :appName, :logo, :address, :location]

  @add_fields [ :name, :image, :subCategory ]


  schema "school_register" do
    #add courses to school/college #addCoursesForSchool controller
    field :name, :string
    field :board, :string
    field :academicEndYear, :string
    field :academicStartYear, :string
    field :classTypeId, {:array, :string}
    field :schoolType, :string
    field :university, :string
    field :medium, :string
    field :subCategory, :string
    field :classSection, {:array, :map}
    field :image, :string
    field :appName, :string
    field :logo, :string
    field :address, :string
    field :location, {:array, :map}
    field :insertedAt, :string
    field :updatedAt, :string
  end


  def school_college_register(model, params \\%{}) do
    model
    |> cast(params, @register_fields)
    |> validate_required(:name, [message: "Must Not Be Empty"])
    |> validate_required(:board, [message: "Must Not Be Empty"])
    |> validate_required(:academicStartYear, [message: "Must Not Be Empty"])
    |> validate_required(:academicEndYear, [message: "Must Not Be Empty"])
    |> validate_required(:subCategory, [message: "Field Required"])
    |> put_change(:isActive, true)
    |> set_time
    |> validateBoard(params)
  end


  # def new_class_insert(model, params \\%{}) do
  #   model
  #   |> cast(params, @new_class_insert)
  # end


  def changeset(struct, params \\%{}) do
    struct
    |> cast(params, @add_fields)
    |> validate_required(:name, [message: "Team Name Must Not Be Empty"])
    |> set_time
  end


  def insert_team(objectId, loginUserId, groupObjectId, changeset) do
    teamDoc = %{
      "_id" => objectId,
      "adminId" => loginUserId,
      "groupId" => groupObjectId,
      "class" => true,
      "name" => changeset.name,
      "insertedAt" => changeset.insertedAt,
      "updatedAt" => changeset.updatedAt,
      "isActive" => true,
      "allowTeamPostAll" => false,
	    "allowTeamPostCommentAll" => false,
      "allowUserToAddOtherUser" => false,
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
    teamDoc
  end


  defp validateBoard(model, params)  do
    if params["board"] == "state" do
      model
      |> cast(params, @register_fields)
      |> validate_required(:university, [message: "Must Not Be Empty"])
      |> validate_required(:medium, [message: "Must Not Be Empty"])
    else
      model
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



  defp set_time(struct) do
    struct
    |> put_change( :insertedAt, bson_time() )
    |> put_change( :updatedAt, bson_time() )
  end
end
