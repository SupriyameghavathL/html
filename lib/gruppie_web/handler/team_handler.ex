defmodule GruppieWeb.Handler.TeamHandler do
  alias GruppieWeb.Repo.UserRepo
  alias GruppieWeb.Repo.TeamRepo



  def getSchoolStaff(groupObjectId) do
    staffs = UserRepo.getSchoolStaff(groupObjectId)
    staffs
    |> Enum.sort_by(& String.downcase(&1["name"]))
  end


  def getMyClassTeams(userObjectId, groupObjectId) do
    #loginUser = Guardian.Plug.current_resource(conn)
    TeamRepo.findClassTeamForLoginUser(userObjectId, groupObjectId)
  end
end
