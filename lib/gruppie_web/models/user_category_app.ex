defmodule GruppieWeb.UserCategoryApp do


  def register_category(conn, changeset, userId, verify_otp) do
    #loginUser = Guardian.Plug.current_resource(conn)
    category = conn.query_params["category"]
    %{
      "userId" => userId,
      "phone" => changeset.phone,
      "category" => category,
      "otp_verify_individual" => verify_otp,
      "insertedAt" => changeset.insertedAt,
      "updatedAt" => changeset.updatedAt,
      "isActive" => true,
    }
  end


  def register_constituency_app(conn, changeset, userId, verify_otp) do
    #loginUser = Guardian.Plug.current_resource(conn)
    constituencyName = conn.query_params["constituencyName"]
    %{
      "userId" => userId,
      "phone" => changeset.phone,
      "constituencyName" => constituencyName,
      "otp_verify_individual" => verify_otp,
      "insertedAt" => changeset.insertedAt,
      "updatedAt" => changeset.updatedAt,
      "isActive" => true,
    }
  end
end
