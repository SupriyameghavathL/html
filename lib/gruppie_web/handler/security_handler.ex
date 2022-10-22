defmodule GruppieWeb.Handler.SecurityHandler do
  alias GruppieWeb.Repo.SecurityRepo
  alias GruppieWeb.Repo.UserRepo

  def findUserExistByPhoneNumber(changeset) do
   SecurityRepo.findUserExistByPhoneNumber(changeset.phone)
  end

  def register(changeset) do
    SecurityRepo.register(changeset)
  end


  def registerCategoryApp(conn, changeset) do
    #check user already in user table or not
    checkUserExistInUserModel = UserRepo.find_user_by_phone(changeset.phone)
    if length(checkUserExistInUserModel) > 0 do
      #check user in  user school app table
      checkUserExistInSchoolAppModel = UserRepo.check_user_exist_category_app(conn, hd(checkUserExistInUserModel), changeset)
      if length(checkUserExistInSchoolAppModel) > 0 do
        {:user_already_error, "user already registered"}
      else
        registerUserToCategoryApp(conn, changeset, hd(checkUserExistInUserModel))
      end
    else
      {:new_user, "register"}
    end
  end


  defp registerUserToCategoryApp(conn, changeset, user) do
    SecurityRepo.register_user_category_app(conn, changeset, user)
  end


  def registerUserToConstituencyApp(conn, changeset) do
    #check user already in user table or not
    checkUserExistInUserModel = UserRepo.find_user_by_phone(changeset.phone)
    if length(checkUserExistInUserModel) > 0 do
      #check user in  constituency app
      checkUserExistInConstituencyApp = UserRepo.check_user_exist_constituency_app(conn, hd(checkUserExistInUserModel), changeset)
      if length(checkUserExistInConstituencyApp) > 0 do
        {:user_already_error, "user already registered"}
      else
        #register user to constituency app
        user = hd(checkUserExistInUserModel)
        SecurityRepo.register_user_constituency_app(conn, changeset, user)
        # set user_col with :caste, :subcaste, :category, :designation, :education, :image
        changeset = changeset
        |> Map.delete(:phone)
        SecurityRepo.upate_user_profile_while_register(changeset, user)
      end
    else
      {:new_user, "register"}
    end
  end

end
