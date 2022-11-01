defmodule GruppieWeb.Api.V1.FriendView do
  use GruppieWeb, :view
  alias GruppieWeb.Repo.FriendRepo
  alias GruppieWeb.Repo.NotificationRepo
  alias GruppieWeb.Repo.ConstituencyRepo
  import GruppieWeb.Repo.RepoHelper


  def render("myPeopleList.json", %{ myPeople: getPeople, groupObjectId: groupObjectId }) do
    list = Enum.reduce(getPeople, [], fn k, acc ->
      #get members count
      members = FriendRepo.getMyPeopleCount(k["_id"], groupObjectId)
      map = %{
        "userId" => encode_object_id(k["_id"]),
        "name" => k["name"],
        "phone" => k["phone"],
        "image" => k["image"],
        "membersCount" => members
      }
      acc ++ [map]
    end)
    %{ data: list }
  end


  def render("notifications.json", %{ notifications: notifications, loginUserId: loginUserId, groupObjectId: groupObjectId, limit: limit }) do
    list = Enum.reduce(notifications, [], fn k, acc ->
      map = %{
        "notificationId" => encode_object_id(k["_id"]),
        "groupId" => encode_object_id(k["groupId"]),
        "message" => k["message"],
        "insertedAt" => k["insertedAt"],
        "type" => k["type"],
        "createdById" => encode_object_id(k["createdById"]),
        #"createdByName" => k["userDetails"]["name"],
        #"createdByPhone" => k["userDetails"]["phone"],
        #"createdByImage" => k["userDetails"]["image"],
      }
      #get user details from user repo
      userDetail = ConstituencyRepo.getUserDetailFromUserCol(k["createdById"])
      map = map
      |> Map.put("createdByName", userDetail["name"])
      |> Map.put("createdByPhone", userDetail["phone"])
      |> Map.put("createdByImage", userDetail["image"])
      if k["type"] == "groupPost" do
        map
        |>Map.put_new("postId", encode_object_id(k["postId"]))
        |>Map.put_new("showComment", false)
      end
      if k["type"] == "groupPostComment" do
        map
        |>Map.put_new("postId", encode_object_id(k["postId"]))
        |>Map.put_new("showComment", true)
      end
      if k["type"] == "gallery" do
        map
        |>Map.put_new("albumId", encode_object_id(k["albumId"]))
        |>Map.put_new("showComment", false)
      end
      if k["type"] == "teamPost" do
        map
        |>Map.put_new("teamId", encode_object_id(k["teamId"]))
        |>Map.put_new("postId", encode_object_id(k["postId"]))
        |>Map.put_new("showComment", false)
      end
      if k["type"] == "teamPostComment" do
        map
        |>Map.put_new("teamId", encode_object_id(k["teamId"]))
        |>Map.put_new("postId", encode_object_id(k["postId"]))
        |>Map.put_new("showComment", true)
      end
      if k["type"] == "individualPost" do
        map
        |>Map.put_new("userId", encode_object_id(k["createdById"]))
        |>Map.put_new("postId", encode_object_id(k["postId"]))
        |>Map.put_new("showComment", false)
      end
      if k["type"] == "individualPostComment" do
        map
        |>Map.put_new("userId", encode_object_id(k["createdById"]))
        |>Map.put_new("postId", encode_object_id(k["postId"]))
        |>Map.put_new("showComment", true)
      end
      if k["type"] == "notesVideosPost" || k["type"] == "homeWorkPost" do
        map = if !is_nil(k["teamId"]) do
          Map.put(map, "teamId", encode_object_id(k["teamId"]))
        else
          map
        end
        map = if !is_nil(k["subjectId"]) do
          Map.put(map, "subjectId", encode_object_id(k["subjectId"]))
        else
          map
        end
        map = if !is_nil(k["postId"]) do
          Map.put(map, "postId", encode_object_id(k["postId"]))
        else
          map
        end
        map = if !is_nil(k["teamId"]) do
          Map.put(map, "teamId", encode_object_id(k["teamId"]))
        else
          map
        end
        map = if !is_nil(k["topicId"]) do
          Map.put(map, "topicId", k["topicId"])
        else
          map
        end
        map
        |>Map.put_new("showComment", false)
      end
      map = if !is_nil(k["month"]) do
        Map.put(map, "month", k["month"])
      else
        map
      end
      acc ++ [map]
    end)
    #get total number of pages
    {:ok, notificationsCount} = NotificationRepo.getTotalNotificationsCount(loginUserId, groupObjectId)
    notificationsCount = Float.ceil(notificationsCount / limit)
    totalPages = round(notificationsCount)

    %{ data: list, totalNumberOfPages: totalPages }
  end



end
