defmodule GruppieWeb.Plugs.GroupPostAddAuth do
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Plugs.PlugHelpers
  alias GruppieWeb.Repo.GroupPostRepo

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
    login_user = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(params["group_id"])

    cond do
      params["group_id"] =~ pattern ->
        case GroupPostRepo.checkLoginUserCanPostInGroup(groupObjectId, login_user["_id"]) do
          {:ok, canPostCount}->
            if canPostCount > 0 do
              conn
            else
              IO.puts "user cannot add post"
              render404(conn)
            end
          {:error, _mongo_error }->
            IO.inspect "mongo error in group post add auth"
            render500(conn)
        end
      true->
        IO.inspect "not found in team auth"
        render404(conn)
    end
  end

end
