defmodule GruppieWeb.Plugs.TeamUserAlreadyExistContactAuth do
  alias GruppieWeb.Repo.TeamRepo
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Plugs.PlugHelpers

  def init(_) do
    mongo_id_pattern = ~r/[a-f 0-9]{24}/
    mongo_id_pattern
  end

  def call(%Plug.Conn{ params: params } = conn, _pattern) do
    #IO.puts "#{params["user"]}"
    # loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(params["group_id"])
    teamObjectId = decode_object_id(params["team_id"])
    Enum.reduce(params["user"], [], fn k, _acc ->
      userList = String.split(k, ",")
      userCountryCode = Enum.at(userList, 1)
      userPhone = Enum.at(userList, 2)
      phoneNumber = e164_format(userPhone, userCountryCode)
      #check user already in team
      case TeamRepo.isTeamMemberByUserPhone(phoneNumber, groupObjectId, teamObjectId) do
        {:ok, count}->
          if(count >= 1) do
            IO.puts "User Already Exist In This Team"
            render404(conn)
          else
            conn
          end
        {:error, _mongo_error }->
          IO.inspect "mongo error in group auth"
          render500(conn)
      end
    end)



  end


end
