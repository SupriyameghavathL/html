defmodule GruppieWeb.Repo.GroupSettingsRepo do

  @conn :mongo

  @group_col "groups"


  def changeAdminAllow(groupObjectId, status) do
    filter = %{ "_id" => groupObjectId }
    update = %{ "$set" => %{ "isAdminChangeAllowed" => status } }
    Mongo.update_one(@conn, @group_col, filter, update)
  end


  def postShareAllow(groupObjectId, status) do
    filter = %{ "_id" => groupObjectId }
    update = %{ "$set" => %{ "isPostShareAllowed" => status } }
    Mongo.update_one(@conn, @group_col, filter, update)
  end


  def allowPostAll(groupObjectId, status) do
    filter = %{ "_id" => groupObjectId }
    update = %{ "$set" => %{ "allowPostAll" => status } }
    Mongo.update_one(@conn, @group_col, filter, update)
  end


end
