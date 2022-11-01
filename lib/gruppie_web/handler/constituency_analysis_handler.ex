defmodule  GruppieWeb.Handler.ConstituencyAnalysisHandler do
  alias GruppieWeb.Repo.ConstituencyAnalysisRepo
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Handler.TimeNow
  alias GruppieWeb.Repo.TeamRepo
  alias GruppieWeb.Repo.UserRepo



  def addZpTpToDb(groupObjectId, changeset, params) do
    #checking users exists in user_coll
    userDetails = ConstituencyAnalysisRepo.getUserId(changeset.phone)
    if !userDetails do
      newUser = %{
        phone: changeset.phone,
        name: changeset.zpIncharge,
        insertedAt: bson_time(),
        updatedAt: bson_time(),
      }
      user = UserRepo.addUserToUserDoc(newUser)
      groupTeamDoc = %{
        "groupId" => groupObjectId,
        "userId" => user["_id"],
        "isActive" => true,
        "insertedAt" =>  bson_time(),
        "updatedAt" =>  bson_time(),
        "teams" => [],
      }
      ConstituencyAnalysisRepo.insertGroupTeamDoc(groupTeamDoc)
      #add adminId to panchayat details
      addPanchayat(groupObjectId, changeset, user["_id"], params)
    else
      #check user exist in group_team_members
      groupTeamMembersCheck =  ConstituencyAnalysisRepo.groupTeamCheck(groupObjectId, userDetails["_id"])
      if !groupTeamMembersCheck do
        groupTeamDoc = %{
          "groupId" => groupObjectId,
          "userId" => userDetails["_id"],
          "isActive" => true,
          "insertedAt" =>  bson_time(),
          "updatedAt" =>  bson_time(),
          "teams" => [],
        }
        ConstituencyAnalysisRepo.insertGroupTeamDoc(groupTeamDoc)
        addPanchayat(groupObjectId, changeset, userDetails["_id"], params)
      else
        addPanchayat(groupObjectId, changeset, userDetails["_id"], params)
      end
    end
  end


  defp addPanchayat(groupObjectId, changeset, userObjectId, params) do
    changeset = cond do
      String.downcase(params["type"]) == "zp"  ->
        changeset
        |> Map.put(:groupId, groupObjectId)
        |> Map.put(:type, "zillaPanchayat")
        |> Map.put(:adminId, userObjectId)
        |> Map.delete(:zpIncharge)
        |> Map.delete(:phone)
      String.downcase(params["type"]) == "tp" && params["zpId"] ->
        changeset
        |> Map.put(:groupId, groupObjectId)
        |> Map.put(:type, "talukPanchayat")
        |> Map.put(:zillaPanchayatId,  decode_object_id( params["zpId"]))
        |> Map.put(:adminId, userObjectId)
        |> Map.delete(:zpIncharge)
        |> Map.delete(:phone)
      true ->
        changeset
        |> Map.put(:groupId, groupObjectId)
        |> Map.put(:type, "ward")
        |> Map.put(:adminId, userObjectId)
        |> Map.delete(:zpIncharge)
        |> Map.delete(:phone)
    end
    ConstituencyAnalysisRepo.addZpTpToDb(changeset)
  end


  def getZpTpToDb(groupObjectId, params) do
    cond do
      String.downcase(params["type"]) == "zp"  ->
        ConstituencyAnalysisRepo.getZpWardFromDb(groupObjectId, "zillaPanchayat", "ward")
      String.downcase(params["type"]) == "tp" && params["zpId"] ->
        #get tp from zp id
        zpObjectId = decode_object_id( params["zpId"])
        ConstituencyAnalysisRepo.getTpFromDbByZpId(groupObjectId, zpObjectId, "talukPanchayat")
      String.downcase(params["type"]) == "tp" ->
        #get all tp
        ConstituencyAnalysisRepo.getTpFromDb(groupObjectId, "talukPanchayat")
      true ->
        ConstituencyAnalysisRepo.getZpWardFromDb(groupObjectId, "ward", "")
    end
  end


  def editZpTpWard(groupObjectId, changeset, panchayatObjectId) do
    #get pachanyat details to check phone no changed or not
    getPanchayatDetails = ConstituencyAnalysisRepo.getPanchayatDetails(panchayatObjectId)
    #checking users exists in user_coll
    userDetails = ConstituencyAnalysisRepo.getUserId(changeset.phone)
    if userDetails do
      if userDetails["_id"] == getPanchayatDetails["adminId"] do
        if String.downcase(userDetails["name"]) == String.downcase(changeset.zpIncharge) do
          editFunction(groupObjectId, changeset, getPanchayatDetails["adminId"], panchayatObjectId)
        else
          ConstituencyAnalysisRepo.updateName(changeset.zpIncharge, getPanchayatDetails["adminId"])
          editFunction(groupObjectId, changeset, getPanchayatDetails["adminId"], panchayatObjectId)
        end
      else
        #check user exist in group_team_members
        groupTeamMembersCheck =  ConstituencyAnalysisRepo.groupTeamCheck(groupObjectId, userDetails["_id"])
        if !groupTeamMembersCheck do
          groupTeamDoc = %{
            "groupId" => groupObjectId,
            "userId" => userDetails["_id"],
            "isActive" => true,
            "insertedAt" =>  bson_time(),
            "updatedAt" =>  bson_time(),
            "teams" => [],
          }
          ConstituencyAnalysisRepo.insertGroupTeamDoc(groupTeamDoc)
          editFunction(groupObjectId, changeset, userDetails["_id"], panchayatObjectId)
        else
          editFunction(groupObjectId, changeset, userDetails["_id"], panchayatObjectId)
        end
      end
    else
      newUser = %{
        phone: changeset.phone,
        name: changeset.zpIncharge,
        insertedAt: bson_time(),
        updatedAt: bson_time(),
      }
      user = UserRepo.addUserToUserDoc(newUser)
      groupTeamDoc = %{
        "groupId" => groupObjectId,
        "userId" => user["_id"],
        "isActive" => true,
        "insertedAt" =>  bson_time(),
        "updatedAt" =>  bson_time(),
        "teams" => [],
      }
      ConstituencyAnalysisRepo.insertGroupTeamDoc(groupTeamDoc)
      editFunction(groupObjectId, changeset,  user["_id"], panchayatObjectId)
    end
  end



  def editFunction(groupObjectId, changeset, userObjectId, panchayatObjectId) do
    changeset = changeset
    |> Map.put(:updatedAt, bson_time())
    |> Map.put(:adminId, userObjectId)
    |> Map.delete(:zpIncharge)
    |> Map.delete(:phone)
    ConstituencyAnalysisRepo.editZpTpWard(groupObjectId, changeset, panchayatObjectId)
  end


  def deleteZpTpWard(groupObjectId, panchayatObjectId) do
    ConstituencyAnalysisRepo.deleteZpTpWard(groupObjectId, panchayatObjectId)
  end

  def getCommitteeMapAndTeam(groupObjectId, userObjectId) do
    ConstituencyAnalysisRepo.getCommitteeMapAndTeam(groupObjectId, userObjectId)
  end


  def getTeamDetails(groupObjectId, userObjectId) do
    ConstituencyAnalysisRepo.getTeamDetails(groupObjectId, userObjectId)
  end


  def pushToTeam(groupObjectId) do
    #getting team adminId and id team coll
    adminIdList = ConstituencyAnalysisRepo.getTeamIdAndBoothAdminId(groupObjectId)
    list = for adminId <- adminIdList do
      checkConditionList = ConstituencyAnalysisRepo.checkSubBoothExists(groupObjectId, adminId["adminId"], adminId["_id"])
      if checkConditionList != [] do
        for teamId <- checkConditionList do
          groupTeamExists = ConstituencyAnalysisRepo.checkGroupTeamExists(groupObjectId, adminId["adminId"], teamId["_id"])
          if !groupTeamExists do
            groupTeamMap = %{
              "allowedToAddComment" => true,
              "allowedToAddPost" => true,
              "allowedToAddUser" => true,
              "insertedAt" => bson_time(),
              "isTeamAdmin" => true,
              "teamId" =>  teamId["_id"],
              "updatedAt" => bson_time(),
            }
            ConstituencyAnalysisRepo.pushToGroupTeamRepo(groupTeamMap, groupObjectId, adminId["adminId"])
          else
            {:ok, "success"}
          end
        end
        |> Enum.reject(&is_nil/1)
      else
        teamChangeset = %{
          name: adminId["name"]<>" Team",
          category: "subBooth",
          insertedAt: bson_time(),
          updatedAt: bson_time(),
          boothTeamId: adminId["_id"]
        }
        user = %{
          "_id" => adminId["adminId"],
        }
        TeamRepo.createTeam(user, teamChangeset, groupObjectId)
      end
    end
    list
    |> Enum.reject(&is_nil/1)
    |>hd()
  end
end
