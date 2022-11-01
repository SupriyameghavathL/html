defmodule GruppieWeb.Handler.TeamPostHandler do
  alias GruppieWeb.Repo.TeamPostRepo
  import GruppieWeb.Repo.RepoHelper


  def add(changeset, conn, group_id, teamObjectId) do
    login_user = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    TeamPostRepo.add(changeset, login_user["_id"], groupObjectId, teamObjectId)
  end

end
