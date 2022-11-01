defmodule GruppieWeb.Api.V1.ProfileView do
  use GruppieWeb, :view
  import GruppieWeb.Repo.RepoHelper
  # alias Gruppie.Repo.UserRepo

  def render("show.json", %{ user: user }) do
    userStringId = encode_object_id(user["_id"])
    #final_map = Map.put(user, "_id", encoded_object_id)
    #final_map = Map.put(user, "userId", encoded_object_id)
    #final_map1 = Map.put(final_map, "image", user["image"])
    user = user
    |> Map.put("_id", userStringId)
    |> Map.put("userId", userStringId)
    |> Map.delete("user_secret_otp")
    |> Map.delete("password_hash")
    #%{ date: final_map1 }
    %{ data: user }
  end


  def render("casteReligion.json", %{ religion: religion }) do
    map = %{religion: religion}
    %{ data: [map] }
  end


  def render("mainCaste.json", %{ caste: caste }) do
    mainCasteList = Enum.reduce(caste, [], fn k, acc ->
      map = %{
        "casteName" => k["casteName"],
        "categoryName" => k["categoryName"],
        "casteId" => fetch_id_from_object(k["_id"]),
        "religion" => k["religion"]
      }
      acc ++ [map]
    end)
    %{ data: mainCasteList }
  end



  def render("mainCasteForReligion.json", %{ caste: caste }) do
    mainCasteList = Enum.reduce(caste, [], fn k, acc ->
      map = %{
        "casteName" => k["casteName"],
        "categoryName" => k["categoryName"],
        "casteId" => fetch_id_from_object(k["_id"]),
        "religion" => k["religion"]
      }
      acc ++ [map]
    end)
    %{ data: mainCasteList }
  end


  def render("subCaste.json", %{ caste: caste }) do
    mainCasteList = Enum.reduce(caste, [], fn k, acc ->
      map = %{
        "subCasteName" => k["subCasteName"],
        "subCasteId" => k["subCasteId"]
      }
      acc ++ [map]
    end)
    %{ data: mainCasteList }
  end


  def render("profession.json", %{ professionList: professionList }) do
    list = [%{
      profession: professionList["professionList"]
    }]
    %{ data: list }
  end


  def render("education.json", %{ educationList: educationList }) do
    list = [%{
      education: educationList["educationList"]
    }]
    %{ data: list }
  end


  def render("constituency.json", %{ constituencyList: constituencyList }) do
    list = [%{
      constituency: constituencyList["constituencyList"]
    }]
    %{ data: list }
  end

  def fetch_id_from_object(bson_obj) do
    bson_id = BSON.ObjectId.encode!( bson_obj );
    bson_id
  end

  def render("statesList.json", %{getStatesList: statesList}) do
    list = if statesList do
      stateSort = Enum.sort(statesList["states"])
      %{
        "states" => stateSort
      }
    else
      []
    end
    %{
      data: list
    }
  end


  def render("districtsList.json", %{getDistrictsList: districtsList}) do
    list = if districtsList["districtsList"] != [] do
      districtSort = Enum.sort(hd(districtsList["districtsList"])["districts"])
      %{
        "districts" => districtSort
      }
    else
      []
    end
    %{
      data: list
    }
  end

  def render("taluksList.json", %{getTaluksList: taluksList}) do
    list = if taluksList["taluksList"] != [] do
      talukSort = Enum.sort(hd(taluksList["taluksList"])["taluks"])
      %{
        "taluks" => talukSort
      }
    else
      []
    end
    %{
      data: list
    }
  end


  def render("reminderList.json", %{getreminderList: reminderList}) do
    list = if reminderList do
      %{
        "reminderList" => reminderList["reminderList"]
      }
    else
      []
    end
    %{
      data: list
    }
  end


  def render("relativesList.json", %{getrelativesList: relativesList}) do
    list = if relativesList do
      relativesSort = Enum.sort(relativesList["relativesList"])
      %{
        "relativesList" => relativesSort ++ ["Other relative"]
      }
    else
      []
    end
    %{
      data: list
    }
  end


  #post report reasons
  def render("post_report_reasons.json", %{ postReportReasons: postReportReasons }) do
    list = Enum.reduce(postReportReasons, [], fn k, acc ->
      map = %{
        reason: k["reason"],
        type: k["type"]
      }

      acc ++ [map]
    end)

    %{ data: list }
  end
end
