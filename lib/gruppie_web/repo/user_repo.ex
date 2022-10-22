defmodule GruppieWeb.Repo.UserRepo do
  # alias GruppieWeb.User

  @conn :mongo

  @user_col "users"

  @user_category_app_col "user_category_apps"


  def find_user_by_phone(phone) do
    filter = %{
      "phone" => phone
    }
    projection =  %{
      "password_hash" => 0
    }
    Enum.to_list(Mongo.find(@conn, @user_col, filter, [ projection: projection, limit: 1]))
  end


  def check_user_exist_category_app(conn, user, _changeset) do
    category = conn.query_params["category"]
    # loginUser = Guardian.Plug.current_resource(conn)
    filter = %{ "userId" => user["_id"], "category" => category }
    cursor = Mongo.find(@conn, @user_category_app_col, filter)
    Enum.to_list(cursor)
  end


  def check_user_exist_constituency_app(conn, user, _changeset) do
    constituencyName = conn.query_params["constituencyName"]
    # loginUser = Guardian.Plug.current_resource(conn)
    filter = %{ "userId" => user["_id"], "constituencyName" => constituencyName }
    cursor = Mongo.find(@conn, @user_category_app_col, filter)
    Enum.to_list(cursor)
  end


end
