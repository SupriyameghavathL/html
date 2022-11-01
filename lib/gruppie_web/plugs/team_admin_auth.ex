defmodule GruppieWeb.Plugs.TeamAdminAuth do
  alias GruppieWeb.Repo.TeamRepo
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Plugs.PlugHelpers


  def init(_) do
    mongo_id_pattern = ~r/[a-f 0-9]{24}/
    mongo_id_pattern
  end

  def call(%Plug.Conn{ params: params } = conn, _pattern) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(params["group_id"])
    teamObjectId = decode_object_id(params["team_id"])
      #find this team is created by login user
      {:ok, isLoginUserTeam} = TeamRepo.isLoginUserTeam(groupObjectId, teamObjectId, loginUser["_id"])
      if isLoginUserTeam > 0 do
        conn
      else
        IO.puts "Not an Team Admin"
        render403(conn)
      end
  end



end
