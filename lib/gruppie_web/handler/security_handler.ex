defmodule GruppieWeb.Handler.SecurityHandler do
  alias GruppieWeb.Repo.SecurityRepo

  def findUserExistByPhoneNumber(changeset) do
   SecurityRepo.findUserExistByPhoneNumber(changeset.phone)
  end
end
