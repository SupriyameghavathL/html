defmodule GruppieWeb.Plugs.TeamUserAlreadyExistAuth do
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Plugs.PlugHelpers
  alias GruppieWeb.Repo.TeamRepo


  def init(_) do
    mongo_id_pattern = ~r/[a-f 0-9]{24}/
    mongo_id_pattern
  end

  def call(%Plug.Conn{ params: params } = conn, _pattern) do
    # loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(params["group_id"])
    teamObjectId = decode_object_id(params["team_id"])
    phoneNumber = e164_format(params["phone"], params["countryCode"])
    #check user already in team
    case TeamRepo.isTeamMemberByUserPhone(phoneNumber, groupObjectId, teamObjectId) do
      {:ok, count}->
        if(count == 1) do
          IO.puts "User Already Exist In This Team"
          render404(conn)
        else
          conn
        end
      {:error, _mongo_error }->
        IO.inspect "mongo error in group auth"
        render500(conn)
    end
  end


end
