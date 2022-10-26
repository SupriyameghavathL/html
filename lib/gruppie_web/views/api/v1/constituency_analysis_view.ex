defmodule GruppieWeb.Api.V1.ConstituencyAnalysisView  do
  use GruppieWeb, :view
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.ConstituencyAnalysisRepo
  alias GruppieWeb.Repo.UserRepo



  def render("panchayatList.json", %{getPanchayatList: getPanchayat, params: params}) do
    list = if getPanchayat != [] do
      cond do
        params["type"] == "tp"  && params["zpId"] ->
          for panchayat <- getPanchayat do
            %{
              "panchayatName" => panchayat["name"],
              "zillaPanchayatId" => encode_object_id(panchayat["zillaPanchayatId"]),
              "type" => panchayat["type"],
              "panchayatId" => encode_object_id(panchayat["_id"]),
            }
          end
        params["type"] == "tp" ->
          for panchayat <- getPanchayat do
            # get name of zp id
            name = ConstituencyAnalysisRepo.getZpName(panchayat["zillaPanchayatId"])
            %{
              "panchayatName" => panchayat["name"],
              "zillaPanchayatId" => encode_object_id(panchayat["zillaPanchayatId"]),
              "type" => panchayat["type"],
              "panchayatId" => encode_object_id(panchayat["_id"]),
              "zillaPanchayatName" => name["name"]
            }
          end
        params["type"] == "zp" ->
          wardZpList = Enum.reduce(getPanchayat, %{wards: [], zp: []}, fn k, acc ->
            map = %{
              "panchayatName" => k["name"],
              "panchayatId" => encode_object_id(k["_id"]),
              "type" => k["type"],
              "image" => k["image"],
            }
            #finding zp Incharge Name
            adminDetail = UserRepo.find_user_by_id(k["adminId"])
            map = map
            |> Map.put_new("phone", String.slice(adminDetail["phone"], 3..13))
            |> Map.put_new("zpIncharge", adminDetail["name"])
            |> Map.put_new("userId", encode_object_id(adminDetail["_id"]))
            |> Map.put_new("userImage", adminDetail["image"])
            if String.downcase(k["type"]) == "ward" do
              %{ wards: acc.wards ++ [map], zp: acc.zp}
            else
              %{ wards: acc.wards, zp: acc.zp ++ [map]}
            end
          end)
          wardZpList.zp ++ wardZpList.wards
        true ->
          for panchayat <- getPanchayat do
            %{
              "panchayatName" => panchayat["name"],
              "panchayatId" => encode_object_id(panchayat["_id"]),
              "type" => panchayat["type"],
            }
          end
      end
    else
      []
    end
    %{
      data: list
    }
  end
end
