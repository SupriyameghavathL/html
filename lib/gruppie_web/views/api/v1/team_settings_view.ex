defmodule GruppieWeb.Api.V1.TeamSettingsView do
  use GruppieWeb, :view
  import GruppieWeb.Repo.RepoHelper

  def render("archiveTeam.json", %{ archiveTeam: getArchiveTeam }) do
    list = Enum.reduce(getArchiveTeam, [], fn k, acc ->
      map =  %{
         groupId: encode_object_id(k["groupId"]),
         teamId: encode_object_id(k["_id"]),
         teamName: k["name"],
         teamImage: k["image"],
         teamType: "created",
         allowTeamPostCommentAll: k["allowTeamPostCommentAll"]
       }
       acc ++ [ map ]
    end)

    %{ data: list }
  end

end
