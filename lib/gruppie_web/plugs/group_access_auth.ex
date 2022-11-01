defmodule GruppieWeb.Plugs.GroupAccessAuth do
  alias GruppieWeb.Repo.GroupMembershipRepo
  alias GruppieWeb.Plugs.PlugHelpers


  @mongo_id_pattern ~r/^[a-f0-9]{24}$/

  def init(format_map) do
    format_map
  end

  def call(%Plug.Conn{params: params} = conn, format_map) do
    group_id = format_map["group_id"]
    user_id = format_map["user_id"]
    cond do
      group_id == "group_id" && user_id == "login_user_id"->
        group_id = Map.get(params, "group_id")
        if Regex.match?(@mongo_id_pattern, group_id) do
          login_user = Guardian.Plug.current_resource(conn)
          user_id = login_user["_id"]
          decoded_group_id = BSON.ObjectId.decode!(group_id)
          handle_auth(conn, decoded_group_id, user_id)
        else
          PlugHelpers.render404(conn)
        end
      group_id == "id" && user_id == "login_user_id"->
        group_id = Map.get(params, "id")
        if Regex.match?(@mongo_id_pattern, group_id) do
          login_user = Guardian.Plug.current_resource(conn)
          user_id = login_user["_id"]
          decoded_group_id = BSON.ObjectId.decode!(group_id)
          handle_auth(conn, decoded_group_id, user_id)
        else
          PlugHelpers.render404(conn)
        end
      true->
        IO.inspect "something not good in group access auth plug"
        PlugHelpers.render500(conn)
    end
  end

  defp handle_auth(conn, group_id, user_id) do
    case GroupMembershipRepo.findUserBelongsToGroup(user_id, group_id) do
      {:ok, count}->
        if count > 0 do
          conn
        else
          PlugHelpers.render404(conn)
        end
      {:error, mongo_error}->
        IO.inspect "#{mongo_error}"
        PlugHelpers.render500(conn)
    end
  end
end
