defmodule GruppieWeb.Api.V1.CommunityView do
  use GruppieWeb, :view
  alias GruppieWeb.Repo.GroupPostCommentsRepo
  alias GruppieWeb.Repo.ConstituencyCategoryRepo
  alias GruppieWeb.Repo.GroupPostRepo
  import GruppieWeb.Repo.RepoHelper



  def render("branchPost.json", %{getBranchPostList: getBranchPostList, group: group, loginUser: loginUser})  do
    pageNo = hd(getBranchPostList)
    getBranchPostList = tl(getBranchPostList)
    final_list =  if getBranchPostList != [] do
      Enum.reduce(getBranchPostList,[], fn post, acc ->
        canEdit = if group["adminId"] == loginUser["_id"] || post["userId"] == loginUser["_id"] do
          true
        else
          false
        end
        # check login user liked this post or not
        {:ok ,isLikedPostCount} = GroupPostCommentsRepo.findPostIsLiked(loginUser["_id"], group["_id"], post["_id"])
        isLiked = if isLikedPostCount == 0 do
          false
        else
          true
        end
        # get total comments count for this post
        {:ok, commentsCount} = GroupPostCommentsRepo.getTotalCommentsCountForGroupPost(group["_id"], post["_id"])
        # check login user saved/favorite this post or not
        {:ok ,isSavedPostCount} = GroupPostRepo.findPostIsSaved(loginUser["_id"], group["_id"], post["_id"])
        isFavorite = if isSavedPostCount == 0 do
          false
        else
          true
        end
        # get name and image from userTable
        userNameAndImage = ConstituencyCategoryRepo.getUserNameAndImage(post["userId"])
        postMap = %{
          "id" => encode_object_id(post["_id"]),
          "groupId" => encode_object_id(group["_id"]),
          "title" => post["title"],
          "text" => post["text"],
          "type" => post["type"],
          "createdById" => encode_object_id(post["userId"]),
          "createdBy" => userNameAndImage["name"],
          "phone" => userNameAndImage["phone"],
          "createdByImage" => userNameAndImage["image"],
          "comments" => commentsCount,
          "likes" => post["likes"],
          "canEdit" => canEdit,
          "isLiked" => isLiked,
          "isFavourited" => isFavorite,
          "createdAt" => post["insertedAt"],
          "updatedAt" => post["updatedAt"],
          "uniquePostId" => post["uniquePostId"],
          "branchId" => encode_object_id(post["branchId"])
        }
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
        else
          postMap
        end
        acc ++ [ postMap ]
      end)
    else
      []
    end
    final_list = Enum.uniq_by(final_list, & &1["uniquePostId"])
    pageCount = Float.ceil(pageNo["pageCount"] / 15)
    totalPages = round(pageCount)
    %{
      data: final_list,
      totalNumberOfPages: totalPages
    }
  end

  def render("adminList.json", %{getAdminList: adminList}) do
    list = if adminList != [] do
      for userId <- adminList do
        %{
          "userId" => encode_object_id(userId["_id"]),
          "name" => userId["name"],
          "phone" => String.slice(userId["phone"],3..13),
          "image" => userId["image"]
        }
      end
    else
      []
    end
    %{
      data: list
    }
  end


  def render("searchList.json", %{getSearchList: searchList}) do
    count = hd(searchList)
    pageCount = Float.ceil(count["pageCount"] / 25)
    list = if tl(searchList) != [] do
      for userDetails <- tl(searchList) do
        %{
          "userId" => encode_object_id(userDetails["_id"]),
          "name" => userDetails["name"],
          "phone" => String.slice(userDetails["phone"],3..13),
          "image" => userDetails["image"]
        }
      end
    else
      []
    end
    totalPages = round(pageCount)
    %{
      data: list,
      totalNumberOfPages: totalPages
    }
  end
end
