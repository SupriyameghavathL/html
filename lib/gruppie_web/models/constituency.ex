defmodule GruppieWeb.Constituency do
  use Ecto.Schema
  import Ecto.Changeset
  import GruppieWeb.Handler.TimeNow
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.TeamRepo


  @web_youtube_link_regEx  ~r/\s*[a-zA-Z\/\/:\.]*youtube.com\/watch\?v=([a-zA-Z0-9\-_]+)([a-zA-Z0-9\/\*\-\_\?\&\;\%\=\.]*)/i

  @android_youtube_link_regEx ~r/\s*[a-zA-Z\/\/:\.]*youtu.be\/([a-zA-Z0-9\-_]+)([a-zA-Z0-9\/\*\-\_\?\&\;\%\=\.]*)/i

  @booth_team_fields [ :name, :image, :category, :boothNumber, :boothAddress, :aboutBooth, :boothCommittees, :zpId ]

  @update_Member_information_fields [ :image, :name, :roleOnConstituency, :address, :dob, :gender, :bloodGroup, :voterId, :aadharNumber, :salary, :education,
                                      :profession, :religion, :caste, :subCaste ]

  @issue_register_fields [ :issue, :jurisdiction, :dueDays ]

  @department_party_user_add_fields [ :departmentUser, :partyUser ]

  @add_issue_tickets_fields [:text, :fileName, :video, :fileType, :thumbnailImage, :location]

  @add_coordinator_to_booth [:name, :image, :roleOnConstituency, :countryCode, :phone, :address, :dob, :gender, :bloodGroup, :voterId, :aadharNumber, :salary]

  @add_comment_issue_ticket_fields [:text]

  @add_booth_committees_fields [:committeeName]

  @add_voters_master_list_fields [:name, :countryCode, :phone, :image, :husbandName, :fatherName, :voterId, :serialNumber, :address, :dob, :age, :gender,
                                  :aadharNumber, :bloodGroup, :email]

  @primary_key{:id, :binary_id, autogenerate: true}

  schema "counstituency" do
    field :image, :string
    field :name, :string
    field :roleOnConstituency, :string
    field :address, :string
    field :dob, :string
    field :gender, :string
    field :bloodGroup, :string
    field :voterId, :string
    field :aadharNumber, :string

    #update user profiles in constituency
    field :education, :string
    field :profession, :string
    field :religion, :string
    field :caste, :string
    field :subCaste, :string

    ##Add coordinator to booth
    field :countryCode, :string
    field :phone, :string
    field :salary, :string

    ##add_voters_master_list_fields
    field :husbandName, :string
    field :fatherName, :string
    field :serialNumber, :string
    field :age, :string
    field :email, :string

    ##Add booth fields
    field :category, :string
    field :boothNumber, :string
    field :boothAddress, :string
    field :aboutBooth, :string
    field :boothCommittees, {:array, :map}
    field :zpId, :string

    ##Add committee fields
    field :committeeName, :string

    ##Issues register fields
    field :issue, :string
    field :jurisdiction, :string
    field :dueDays, :integer

    ##department/party user register to constitiuency issue fields
    field :departmentUser, :map
    field :partyUser, :map

    ##add/raise issue tickets
    field :text, :string
    field :fileName, {:array, :string}  #["image1.png", "image2.png"] || ["video1.mp4", "video2mp4"]
    field :fileType, :string #image/pdf/audio/video
    field :thumbnailImage, {:array, :string}  #["video1Image.png", "video2Image.png"] if mp4 video is uploading
    field :video, :string #youtube link
    field :location, :map #{latitude: , longitude: , address: , landmark: , pincode: }

    ##add banner post
    field :bannerFile, {:array, :string}
    field :bannerFileType, :string
    field :isActive, :boolean
    field :insertedAt, :string
    field :updatedAt, :string
  end


  def changeset_add_banner(struct, params \\%{}) do
    struct
    |> cast(params, [:bannerFile, :bannerFileType])
    |> validate_required(:bannerFile, [message: "Must Not Be Empty"])
    |> validate_required(:bannerFileType, [message: "Must Not Be Empty"])
    |> put_change( :bannerUpdatedAt, bson_time() )
  end



  def changeset_add_voters_master_list(model, params \\%{}) do
    model
    |> cast(params, @add_voters_master_list_fields)
    |> validate_required(:voterId, [message: "Must Not Be Empty"])
    |> validate_required(:name, [message: "Name Must Not Be Empty"])
    |> set_time
    |> check_phone_exist
  end

  defp check_phone_exist(struct) do
    if Map.has_key?(struct.changes, :phone) do
      struct
      |> validate_required(:phone, [message: "Phone Number Must Not Be Empty"])
      |> validate_required(:countryCode, [message: "Country Code Must Not Be Empty"])
      |> valid_phone_number
    else
      struct
    end
  end


  #user add to team changeset
  def changeset_add_booth_members(struct, params \\%{}) do
    struct
    |> cast(params, [:name, :countryCode, :phone, :roleOnConstituency])
    |> validate_required(:phone, [message: "Phone Number Must Not Be Empty"])
    |> validate_required(:countryCode, [message: "Country Code Must Not Be Empty"])
    |> validate_required(:name, [message: "Name Must Not Be Empty"])
    |> valid_phone_number
    |> set_time
  end


  def changeset_add_booth_committees(model, params \\%{}) do
    model
    |> cast(params, @add_booth_committees_fields)
    |> validate_required(:committeeName, [message: "Name Must Not Be Empty"])
    |> put_change(:committeeId, encode_object_id(new_object_id()))
  end


  def changeset_comment_issue_ticket(model, params \\%{}) do
    model
    |> cast(params, @add_comment_issue_ticket_fields)
    |> validate_required(:text, [message: "Text Must Not Be Empty"])
  end


  def changeset_booth_add(model, params \\%{}) do
    model
    |> cast(params, @booth_team_fields)
    |> validate_required(:name, [message: "Team Name Must Not Be Empty"])
    |> put_change(:allowTeamPostAll, true)
    |> put_change(:allowTeamPostCommentAll, true)
    |> put_change(:allowUserToAddOtherUser, true)
    |> set_time
  end


  def changeset_update_booth_member(model, params \\%{}) do
    model
    |> cast(params, @update_Member_information_fields)
    |> validate_required([:name], [message: "Name Must Not Be Empty"])
  end


  def changeset_add_booth_coordinator(model, params \\%{}) do
    model
    |> cast(params, @add_coordinator_to_booth)
    |> validate_required([:name], [message: "Name Must Not Be Empty"])
    |> validate_required(:phone, [message: "Phone Number Must Not Be Empty"])
    |> validate_required(:countryCode, [message: "countryCode Must Not Be Empty"])
    |> valid_phone_number
    |> put_change(:roleOnConstituency, "coordinator")
  end


  def changeset_issues_register(model, params \\%{}) do
    model
    |> cast(params, @issue_register_fields)
    |> validate_required([:jurisdiction], [message: "Jurisdiction Must Not Be Empty"])
    |> validate_required([:issue], [message: "Issue Must Not Be Empty"])
    |> put_change(:isActive, true)
    |> set_time
  end


  def changeset_department_party_user_add(model, params \\%{}) do
    model
    |> cast(params, @department_party_user_add_fields)
    #|> validate_required([:departmentUser], [message: "department user Must Not Be Empty"])
    #|> validate_required([:partyUser], [message: "Party user Must Not Be Empty"])
    |> validate_key_exists()
  end

  defp validate_key_exists(changeset) do
    if Map.has_key?(changeset.changes, :departmentUser) do
      if Map.has_key?(changeset.changes, :partyUser) do
        #department user
        departmentUserMap = changeset.changes.departmentUser
        if !Map.has_key?(departmentUserMap, "name") do
          add_error(changeset, :name, "Department User Name Is Missing")
        else
          if !Map.has_key?(departmentUserMap, "phone") do
            add_error(changeset, :phone, "Department User phone number Is Missing")
          else
            #party user
            partyUserMap = changeset.changes.partyUser
            if !Map.has_key?(partyUserMap, "name") do
              add_error(changeset, :name, "Party User Name Is Missing")
            else
              if !Map.has_key?(partyUserMap, "phone") do
                add_error(changeset, :phone, "party User phone number Is Missing")
              else
                changeset
              end
            end
          end
        end
      else
        add_error(changeset, :partyUser, "Party User Is Missing")
      end
    else
      add_error(changeset, :departmentUser, "Department User Is Missing")
    end
  end



  def changeset_add_issue_ticket(model, params \\%{}) do
    model
    |> cast(params, @add_issue_tickets_fields)
    |> put_change(:isActive, true)
    |> put_change(:partyTaskForceStatus, "notApproved")
    |> set_time
    |> check_valid_post
    |> check_valid_youtube_link
    |> check_file_type
  end



  defp set_time(struct) do
    struct
    |> put_change( :insertedAt, bson_time() )
    |> put_change( :updatedAt, bson_time() )
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


  defp check_file_type(struct) do
    fileName = get_field(struct, :fileName)
    video = get_field(struct, :video)
    fileType = get_field(struct, :fileType)
    if !is_nil(fileName) || !is_nil(video) do
      if !is_nil(fileType) do
        struct
      else
        add_error(struct, :fileType, "File Type Mandatory")
      end
    else
      struct
    end
  end


  defp check_valid_youtube_link(struct) do
    if struct.valid? do
      video = get_field(struct, :video)
      fileType = get_field(struct, :fileType)
      if fileType != "youtube" do
        struct
      else
        if Regex.match?(@web_youtube_link_regEx, video) do
          id = getWebId(video)
          put_change(struct, :video, id)
        else
          if Regex.match?(@android_youtube_link_regEx, video) do
            id = getAndroidId(video)
            put_change(struct, :video, id)
          else
            add_error(struct, :video, "Not Valid YouTube Link")
          end
        end
      end
    else
      struct
    end
  end

  defp getWebId(url) do
    list = Regex.split(~r{v=}, url)
    id = Enum.at(list, 1)
    id
  end

  defp getAndroidId(url) do
    list = Regex.split(~r{youtu.be/}, url)
    id = Enum.at(list, 1)
    id
  end


  defp check_valid_post(struct) do
    if struct.valid? do
      title = get_field(struct, :title)
      text = get_field(struct, :text)
      fileName = get_field(struct, :fileName)
      video = get_field(struct, :video)
      # fileType = get_field(struct, :fileType)
      if is_nil(fileName) do
        if is_nil(video) do
          if is_nil(text) do
            if is_nil(title) do
              add_error(struct, :title, "Add The Post You Want To Add")
            else
              struct
            end
          else
            struct
          end
        else
          struct
        end
      else
        struct
      end
    else
      struct
    end
  end



  def insertGroupTeamMemberForBoothMembers(userObjectId, group, teamObjectId, changeset) do
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
         "committeeIds" => [changeset.committeeId]
        }],
    }
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



  def insertNewTeamForAddingUser(teamObjectId, changeset) do
    #to check team is allowed to post or comment or adding users
    team = TeamRepo.get(encode_object_id(teamObjectId))
    map = %{
      "teamId" => teamObjectId,
      "isTeamAdmin" => false,
      "allowedToAddUser" => if team["allowUserToAddOtherUser"] == true do true else false end,
      "allowedToAddPost" => if team["allowTeamPostAll"] == true do true else false end,
      "allowedToAddComment" => if team["allowTeamPostCommentAll"] == true do true else false end,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
    }
    map = if Map.has_key?(changeset, :committeeId) do
      Map.put(map, "committeeIds", [changeset.committeeId])
    else
      map
    end
    map
  end



  def insertGroupMemberWhileJoining(userObjectId, groupObjectId) do
    %{
      "userId" => userObjectId,
      "groupId" => groupObjectId,
      "isAdmin" => false,
      "canPost" => false,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      "isActive" => true,
      "teams" => [],
      #"groupPostLastSeen" => bson_time(),
      #"messageInboxLastSeen" => bson_time(),
      #"notificationLastSeen" => bson_time()
    }
  end


  def insert_booth_team12345(teamObjectId, userId, groupObjectId, changeset) do
    teamDoc = %{
      "_id" => teamObjectId,
      "adminId" => userId,
      "groupId" => groupObjectId,
      "name" => changeset.name,
      "boothName" => changeset.name,
      #"boothNumber" => changeset.boothNumber,
      "insertedAt" => changeset.insertedAt,
      "updatedAt" => changeset.updatedAt,
      "isActive" => true,
      #"allowTeamPostAll" => false,
	    #"allowTeamPostCommentAll" => false,
      #"allowUserToAddOtherUser" => false,
      "booth" => true,
      "category" => "booth"
    }
    teamDoc = if Map.has_key?(changeset, :image) do
      Map.merge(%{ "image" => changeset.image }, teamDoc)
    else
      teamDoc
    end
    #if Map.has_key?(changeset, :category) do
    #  teamDoc = Map.merge(%{ "category" => changeset.category }, teamDoc)
    #end
    teamDoc = if Map.has_key?(changeset, :boothNumber) do
      Map.merge(%{ "boothNumber" => changeset.boothNumber }, teamDoc)
    else
      teamDoc
    end
    teamDoc
  end


  def insertGroupTeamMembersForAdmin(teamObjectId, _loginUser) do
    %{
      "teamId" => teamObjectId,
      #"userName" => loginUser["name"],
      "isTeamAdmin" => true,
      "allowedToAddUser" => true,
      "allowedToAddPost" => true,
      "allowedToAddComment" => true,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      #"teamPostLastSeen" => bson_time(),
    }
  end

  #if MLA adds booth to other president then add MLA as booth authorized user
  def insertGroupTeamMembersForAdminUser(teamObjectId, _loginUser) do
    %{
      "teamId" => teamObjectId,
      #"userName" => loginUser["name"],
      "isTeamAdmin" => false,
      "allowedToAddUser" => true,
      "allowedToAddPost" => true,
      "allowedToAddComment" => true,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      #"teamPostLastSeen" => bson_time(),
    }
  end

  def insertGroupTeamMembersForUser(teamObjectId, _loginUser) do
    %{
      "teamId" => teamObjectId,
      #"userName" => loginUser["name"],
      "isTeamAdmin" => false,
      "allowedToAddUser" => false,
      "allowedToAddPost" => true,
      "allowedToAddComment" => true,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      #"teamPostLastSeen" => bson_time(),
    }
  end



  def insertGroupTeamMemberForTaskForce(userObjectId, groupObjectId, teamObjectId) do
    %{
      "userId" => userObjectId,
      "groupId" => groupObjectId,
      "isAdmin" => false,
      "canPost" => false,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      "isActive" => true,
      "teams" => [%{
         "teamId" => teamObjectId,
         "isTeamAdmin" => false,
         "allowedToAddUser" => false,
         "allowedToAddPost" => true,
         "allowedToAddComment" => true,
         "insertedAt" => bson_time(),
         "updatedAt" => bson_time()
        }]
    }
  end

end
