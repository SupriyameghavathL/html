defmodule GruppieWeb.Plugs.GroupAuth do
  alias GruppieWeb.Repo.GroupMembershipRepo
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
    group_id = params["group_id"]
    user_id = params["user_id"]
    cond do
      group_id =~ pattern && user_id =~ pattern ->
        case GroupMembershipRepo.findUserBelongsToGroup(user_id, group_id) do
          {:ok, count}->
            if count == 1 do
              conn
            else
              IO.puts "user not belongs to group"
              render404(conn)
            end
          {:error, _mongo_error }->
            IO.inspect "mongo error in group auth"
            render500(conn)
        end
      true->
        IO.inspect "not found in group auth"
        render404(conn)
    end

  end

end
