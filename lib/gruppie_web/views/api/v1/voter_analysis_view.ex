defmodule GruppieWeb.Api.V1.VoterAnalysisView do
  use GruppieWeb, :view
  # alias GruppieWeb.Repo.TeamPostRepo
  # alias GruppieWeb.Repo.TeamPostCommentsRepo
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.FeederNotificationRepo


  def render("boothVoterList.json", %{getBoothVoterList: boothVoters}) do
    map = if boothVoters != [] do
      %{
        "votersUsersList" => boothVoters["voterDetails"]
      }
    else
      %{
        "votersUsersList" => []
      }
    end
    %{
      data: map
    }
  end


  def render("boothsPost.json", %{getBoothsPostList: postsList, groups: group, conn: conn, limit: pageLimit}) do
    list = if postsList != [] do
      login_user = Guardian.Plug.current_resource(conn)
      pageCount = Float.ceil(hd(postsList)["pageCount"] / pageLimit)
      %{
        final_list:  Enum.reduce(tl(postsList),[], fn post, acc ->
          canEdit = if post["userId"] == login_user["_id"] || group["adminId"] == login_user["_id"]  do
            true
          else
            false
          end
          # {:ok ,isLikedPostCount} = TeamPostRepo.findTeamPostIsLiked(login_user["_id"], group["_id"], post["teamId"], post["_id"])
          # isLiked = if isLikedPostCount == 0 do
          #     false
          #   else
          #     true
          #   end
          # #get total comments count for this post
          # {:ok, commentsCount} = TeamPostCommentsRepo.getTotalTeamPostCommentsCount(group["_id"], post["teamId"], post["_id"])
          postMap = %{
            "id" => encode_object_id(post["_id"]),
            "title" => post["title"],
            "text" => post["text"],
            "type" => post["type"],
            "createdById" => encode_object_id(post["userId"]),
            "createdBy" => post["name"],
            "phone" => post["phone"],
            "createdByImage" => post["image"],
            # "comments" => commentsCount,
            "canEdit" => canEdit,
            # "isLiked" => isLiked,
            "likes" => post["likes"],
            "createdAt" => post["insertedAt"],
            "updatedAt" => post["updatedAt"],
            "teamId" => encode_object_id(post["teamId"])
          }
          #get teamName
          teamName = FeederNotificationRepo.getTeamName(group["_id"], post["teamId"])
          postMap = postMap
          |> Map.put("teamId", encode_object_id(post["teamId"]))
          |> Map.put("teamName", teamName["name"])
          postMap = if !is_nil(post["body"]) do
           Map.put_new(postMap, "body", post["body"])
          else
            postMap
          end
          postMap = if !is_nil(post["fileName"]) do
            postMap
            |> Map.put_new("fileName", post["fileName"])
            |> Map.put_new("fileType", post["fileType"])
          else
            postMap
          end
          postMap = if !is_nil(post["video"]) do
            if post["fileType"] == "youtube" do
              watch = "https://www.youtube.com/watch?v="<>post["video"]<>""
              thumbnail = "https://img.youtube.com/vi/"<>post["video"]<>"/0.jpg"
              postMap
              |> Map.put_new("video", watch)
              |> Map.put_new("fileType", post["fileType"])
              |> Map.put_new("thumbnail", thumbnail)
            else
              postMap
            end
          else
            postMap
          end
          #if thumbnailImage for video and pdf is not nil then display
          postMap = if !is_nil(post["thumbnailImage"]) do
            postMap
            |> Map.put_new("thumbnailImage", post["thumbnailImage"])
          end
          acc ++ [ postMap ]
        end),
        totalPages: round(pageCount)
      }
    else
      %{
        final_list: [],
        totalPages: 0
      }
    end
    %{
      data: list.final_list,
      totalNumberOfPages: list.totalPages
    }
  end


  def render("workersList.json", %{getWorkersList: workersList, limit: pageLimit}) do
    list = if tl(workersList) != [] do
      for workerDetails <- tl(workersList) do
        %{
          "name" => workerDetails["name"],
          "phone" => workerDetails["phone"],
          "image" => workerDetails["image"],
          "userId" => encode_object_id(workerDetails["_id"])
        }
      end
    else
      []
    end
    pageCount = Float.ceil(hd(workersList)["pageCount"] / pageLimit)
    totalPages = round(pageCount)
    %{
      data: list,
      totalNumberOfPages: totalPages
    }
  end


  def render("usersList.json", %{getUsersList: getUsersBasedOnSearch}) do
    list = if getUsersBasedOnSearch != [] do
      for userDetails <- getUsersBasedOnSearch do
        %{
          "name" => userDetails["name"],
          "phone" => userDetails["phone"],
          "image" => userDetails["image"],
          "userId" => encode_object_id(userDetails["_id"])
        }
      end
    else
      []
    end
    %{
      data: list
    }
  end
end
