defmodule GruppieWeb.Repo.SecurityRepo do

  @conn :mongo

  @user_col "users"


  def findUserExistByPhoneNumber(phone) do
    filter = %{ "phone" => phone }
    project = %{"_id" => 1}
    Mongo.count(@conn, @user_col, filter, [projection: project])
  end


end
