defmodule GruppieWeb.Repo.SecurityRepo do
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.UserCategoryApp

  @conn :mongo

  @user_col "users"

  @user_individual_col "user_individual_apps"

  @user_category_app_col "user_category_apps"

  @view_group_team_members_col "VW_GROUP_TEAM_MEMBERS"


  def findUserExistByPhoneNumber(phone) do
    filter = %{ "phone" => phone }
    project = %{"_id" => 1}
    Mongo.count(@conn, @user_col, filter, [projection: project])
  end



  def find_user_exists_individual_app(changeset, appId) do
    filter = %{ "phone" => changeset.phone, "appId" => decode_object_id(appId) }
    project = %{"_id" => 1}
    Mongo.count(@conn, @user_individual_col, filter, [projection: project])
  end



  def findUserRegisteredToCategoryApp(conn, changeset) do
    filter = %{ "phone" =>  changeset.phone, "category" => conn.query_params["category"] }
    project = %{"_id" => 1}
    Mongo.count(@conn, @user_category_app_col, filter, [projection: project])
  end

  def findUserRegisteredToConstituencyApp(conn, changeset) do
    filter = %{ "phone" =>  changeset.phone, "constituencyName" => conn.query_params["constituencyName"] }
    project = %{"_id" => 1}
    Mongo.count(@conn, @user_category_app_col, filter, [projection: project])
  end


  def getCategoryGroupsCountForUser(userObjectId, category) do
    filter = %{
      "userId" => userObjectId,
      "groupDetails.category" => category,
      "groupDetails.isActive" => true,
      "isActive" => true
    }
    projection = %{ "_id" => 0, "groupId" => 1, "groupDetails.category" => 1 }
    pipeline = [%{ "$match" => filter }, %{ "$project" => projection }]
    Enum.to_list(Mongo.aggregate(@conn, @view_group_team_members_col, pipeline))
  end


  def register(changeset) do
    generatedPassword = hash_password()
    hashed_password = generatedPassword.password #accessing field from map
    otp = generatedPassword.otp
    changeset = Map.put_new(changeset, :password_hash, hashed_password) #hash_password[private function]
    case Mongo.insert_one(@conn, @user_col, changeset) do
      {:ok, _ok} ->
        {:ok, otp}
      {:mongo_error, _err} ->
        {:mongo_error, "Something went wrong"}
    end
  end



  def register_user_category_app(conn, changeset, user) do
    generatedPassword = hash_password()
    # hashed_password = generatedPassword.password
    otp = generatedPassword.otp
    user_doc = UserCategoryApp.register_category(conn, changeset, user["_id"], otp)
    case Mongo.insert_one(@conn, @user_category_app_col, user_doc) do
      {:ok, _ok}->
        {:ok, otp}
      {:mongo_error, _err}->
        {:mongo_error, "Something went wrong"}
    end
  end



  def register_user_constituency_app(conn, changeset, user) do
    generatedPassword = hash_password()
    # hashed_password = generatedPassword.password
    otp = generatedPassword.otp
    user_doc = UserCategoryApp.register_constituency_app(conn, changeset, user["_id"], otp)
    case Mongo.insert_one(@conn, @user_category_app_col, user_doc) do
      {:ok, _ok}->
        {:ok, otp}
      {:mongo_error, _err}->
        {:mongo_error, "Something went wrong"}
    end
  end


  def upate_user_profile_while_register(updadteChangesetDoc, user) do
    filter = %{
      "_id" => user["_id"]
    }
    update = %{"$set" => updadteChangesetDoc}
    Mongo.update_one(@conn, @user_col, filter, update)
  end


  def verifyOtpCategoryApp(changeset, category) do
    filter = %{
      "phone" => changeset.phone,
      "category" => category,
      "otp_verify_individual" => changeset.otp
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @user_category_app_col, filter, [projection: project])
  end


  def verifyOtpConstituencyApp(changeset, constituencyName) do
    filter = %{
      "phone" => changeset.phone,
      "constituencyName" => constituencyName,
      "otp_verify_individual" => changeset.otp
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @user_category_app_col, filter, [projection: project])
  end
end
