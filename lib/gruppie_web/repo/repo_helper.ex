defmodule GruppieWeb.Repo.RepoHelper do

  def new_object_id do
    object_id = Mongo.object_id
    object_id
  end

  def update_map_with_key_value(map, k, v) do
    Map.put_new(map, k, v)
  end


  def decode_object_id id do
    BSON.ObjectId.decode!(id)
  end

  def encode_object_id id do
    BSON.ObjectId.encode!(id)
  end


  def hash_password do
    otp = Enum.random(111111..999999) #Enum Modules random method used to generate random number between given value, uses erlang :rand module
    string_otp = Integer.to_string(otp) #converts integer to string bcoz comeonin rise exception if not string[Wrong type. The password and salt need to be strings]
    %{
      otp: string_otp,
      password: Bcrypt.hash_pwd_salt(string_otp)
    }
  end

  def mongo_update_result(result) do
    case result.modified_count do
      1 ->
        {:ok, 1}
      0 ->
        {:error, 0}
      _->
        {:mongo_error, "something went wrong"}
    end
  end


  def e164_format(phone, countryCode) do
    case ExPhoneNumber.parse(phone, countryCode) do
      {:ok, phone_number} ->
        ExPhoneNumber.format(phone_number, :e164)
    end
  end
end
