defmodule GruppieWeb.Plugs.AdminAuth do
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Plugs.PlugHelpers
  alias GruppieWeb.Repo.AdminRepo

  def init(_) do
    mongo_id_pattern = ~r/[a-f 0-9]{24}/
    mongo_id_pattern
  end

  def call(%Plug.Conn{ params: params } = conn, pattern) do
    group_id = params["group_id"]
    group_object_id = decode_object_id(group_id)
    login_user = Guardian.Plug.current_resource(conn)

    cond do
      group_id =~ pattern ->
        case AdminRepo.findGroupAdmin(login_user["_id"], group_object_id) do
          {:ok, count}->
            if count > 0 do
              conn
            else
              IO.puts "Not an Admin"
              render403(conn)
            end
          {:error, _mongo_error }->
            IO.inspect "mongo error in group auth"
            render500(conn)
        end
    true->
      IO.inspect "not found in admin auth"
      render404(conn)
    end
  end

end
