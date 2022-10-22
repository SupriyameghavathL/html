defmodule GruppieWeb.Repo.GroupRepo do
  import GruppieWeb.Repo.RepoHelper

  @conn :mongo

  @group_coll "groups"



  def get(groupId) do
    groupObjectId = decode_object_id(groupId)
    filter = %{ "_id" => groupObjectId, "isActive" => true }
    projection =  %{ "updated_at" => 0 }
    #hd(Enum.to_list(Mongo.find(@conn, @group_coll, filter, [ projection: projection ])))
    Mongo.find(@conn, @group_coll, filter, [ projection: projection ])
    |> Enum.to_list
    |> hd
  end


  #remove authorizedToAdmin event from group_action_event col when user logout
  def removeAuthorizedToAdminEventForLoginUser(userObjectId) do
    filter = %{
      "userId" => userObjectId,
      "eventType" => 5  #authorizedToAdmin event
    }
    Mongo.delete_many(@conn, @group_action_events_col, filter)
  end

end
