defmodule GruppieWeb.Handler.AdminHandler do
  alias GruppieWeb.Repo.AdminRepo
  alias GruppieWeb.Repo.UserRepo
  alias GruppieWeb.Repo.GroupMembershipRepo
  alias GruppieWeb.Repo.GroupRepo
  import GruppieWeb.Repo.RepoHelper


  def updateStudentStaffPhoneNumber(changesetPhone, user_id) do
    userObjectId = decode_object_id(user_id)
    AdminRepo.updateStudentStaffPhoneNumber(userObjectId, changesetPhone)
  end


  def addTeacherToUserTableIfNotExist(changeset, group) do
    #check user exist in user doc by phone
    checkUserExist = UserRepo.find_user_by_phone(changeset.phone)
    if length(checkUserExist) > 0 do
      #check user already in group but not in this team
      {:ok, count} = GroupRepo.checkUserAlreadyInGroup(hd(checkUserExist)["_id"], group["_id"])
      if count < 1 do
        #insert to group_team_members
        GroupMembershipRepo.joinUserToGroup(hd(checkUserExist)["_id"], group["_id"])
        hd(checkUserExist)
      else
        hd(checkUserExist)
      end
    else
      #add user to uer doc
      userRegisterToUserDoc = UserRepo.addUserToUserDoc(changeset)
      #add user to  group_team_members doc / userRegisterToUserDoc = user (inserted user details)
      GroupMembershipRepo.joinUserToGroup(userRegisterToUserDoc["_id"], group["_id"])
      userRegisterToUserDoc
    end
  end


  def getClasses(groupObjectId) do
    #get class teams of this group
    AdminRepo.getClassesForAdmin(groupObjectId)
  end


  def getClassStudents(group, team_id) do
    teamObjectId = decode_object_id(team_id)
    studentsList = AdminRepo.getClassStudents(group["_id"], teamObjectId)
    studentsList
    |> Enum.sort_by(& String.downcase(&1["name"]))
  end

end
