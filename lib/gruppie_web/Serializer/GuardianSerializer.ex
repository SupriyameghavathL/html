defmodule GruppieWeb.Serializer.GuardianSerializer do
  use Guardian, otp_app: :gruppie
  alias GruppieWeb.Repo.UserRepo
  require Logger


 def subject_for_token(resource, _claims) do
  bson_id  = resource["_id"]
  login_user_id = BSON.ObjectId.encode!(bson_id)
  password = if Map.has_key?(resource, "password_hash") do
    resource["password_hash"]
  else
    resource["password"]
  end
    map = %{"id" => login_user_id, "password" => password}
    {:ok,map}
 end


 def resource_from_claims(claims) do
  map = claims["sub"]
  #login_user_id = map["id"]
  resource = UserRepo.find_by_id(map["id"], map["password"])
  resource
 end

end
