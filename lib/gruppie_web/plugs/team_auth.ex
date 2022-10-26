defmodule GruppieWeb.Plugs.TeamAuth do
  alias GruppieWeb.Repo.TeamRepo
  alias GruppieWeb.Repo.GroupRepo
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Plugs.PlugHelpers

  @doc """
  initialize any argument need to pass in call
  """
  def init(_) do
    mongo_id_pattern = ~r/[a-f 0-9]{24}/
    mongo_id_pattern
  end

  @doc """
  carries out the connection transformation
  """
  def call(%Plug.Conn{ params: params } = conn, pattern) do
    groupObjectId = decode_object_id(params["group_id"])
    teamObjectId = decode_object_id(params["team_id"])
    login_user = Guardian.Plug.current_resource(conn)
    group = GroupRepo.get(params["group_id"])
    cond do
      params["group_id"] =~ pattern && params["team_id"] =~ pattern ->
        case TeamRepo.isTeamMemberByUserId(login_user["_id"], groupObjectId, teamObjectId) do
          {:ok, count}->
            if count > 0 || group["adminId"] == login_user["_id"] do
              conn
            else
              IO.puts "user not belongs to team"
              render404(conn)
            end
          {:error, _mongo_error }->
            IO.inspect "mongo error in group auth"
            render500(conn)
        end
      true->
        IO.inspect "not found in team auth"
        render404(conn)
    end
  end

end
