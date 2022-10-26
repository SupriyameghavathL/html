defmodule GruppieWeb.Api.V1.SuggestionBoxView do
  use GruppieWeb, :view
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.SuggestionBoxRepo
  alias GruppieWeb.Repo.GroupPostCommentsRepo
  alias GruppieWeb.Repo.GroupPostRepo
  import GruppieWeb.Handler.TimeNow


  def render("get_suggestion_post.json", %{getSuggestionPost: suggestionPostList, group: group, login_user: login_user}) do
    final_list = Enum.reduce(suggestionPostList,[], fn post, acc ->
      canEdit = if group["adminId"] == login_user["_id"] || post["userId"] == login_user["_id"] do
        true
      else
        false
      end
      #check login user saved/favourited this post or not
      {:ok ,isSavedPostCount} = GroupPostRepo.findPostIsSaved(login_user["_id"], group["_id"], post["_id"])
      isFavourited = if isSavedPostCount == 0 do
        false
      else
        true
      end
      existsInStaffDatabase = SuggestionBoxRepo.getUserNameAndImageInStaffDatabase(group["_id"], post["userId"])
      userNameAndImage = if existsInStaffDatabase  do
        existsInStaffDatabase
      else
        SuggestionBoxRepo.getUserNameAndImageInStudentDatabase(group["_id"], post["userId"])
      end
        # get total comments count for this post
        {:ok, commentsCount} = GroupPostCommentsRepo.getTotalCommentsCountForGroupPost(group["_id"], post["_id"])
      postMap = %{
        "id" => encode_object_id(post["_id"]),
        "groupId" => encode_object_id(group["_id"]),
        "title" => post["title"],
        "text" => post["text"],
	      "type" => post["type"],
        "createdById" => encode_object_id(post["userId"]),
        "createdBy" => userNameAndImage["name"],
        "createdByImage" => userNameAndImage["image"],
        "phone" => post["phone"],
        "canEdit" => canEdit,
        "comments" => commentsCount,
        "isFavourited" => isFavourited,
        "createdAt" => post["insertedAt"],
        "updatedAt" => post["updatedAt"],
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
    canPost = SuggestionBoxRepo.checkCanPostTrue(group["_id"], login_user["_id"])
    {:ok, pageCount} = if login_user["_id"] == group["adminId"] || canPost["canPost"] == true do
      #to get all the post of that group from collection
      SuggestionBoxRepo.adminPageCount(group["_id"])
    else
      #to get only the post posted by the user
      SuggestionBoxRepo.getPostPostedByUserCount(group["_id"], login_user["_id"])
    end
    pageCount = Float.ceil(pageCount / 15)
    totalPages = round(pageCount)
    %{ data: final_list, totalNumberOfPages: totalPages}
  end


  def render("notes.json", %{getNotesPost: getNotesBasedOnId}) do
    final_list = if Map.has_key?(getNotesBasedOnId, "topics") do
      Enum.reduce(getNotesBasedOnId["topics"],[], fn post, acc ->
        #get createdBy image and name
        userDetail = SuggestionBoxRepo.getUserNameAndImageInStaffDatabase(getNotesBasedOnId["groupId"], decode_object_id(post["createdById"]))
        postMap = %{
          "id" => encode_object_id(getNotesBasedOnId["_id"]),
          "groupId" => encode_object_id(getNotesBasedOnId["groupId"]),
          "createdById" => post["createdById"],
          "createdBy" => userDetail["name"],
          "createdByImage" => userDetail["image"],
          "topicId" => post["topicId"],
          "createdAt" => post["insertedAt"],
          "updatedAt" => getNotesBasedOnId["updatedAt"],
          "text" => post["topicName"],
          "title" => getNotesBasedOnId["chapterName"],
          "teamId" => encode_object_id(getNotesBasedOnId["teamId"]),
          "canEdit" => false,
          "isLiked" => false,
          "comments" => 0,
          "likes" => 0
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
        postMap = if !is_nil(post["thumbnailImage"]) do
          postMap
          |> Map.put_new("thumbnailImage", post["thumbnailImage"])
        else
          postMap
        end
        postMap = if !is_nil(post["body"]) do
          Map.put_new(postMap, "body", post["body"])
        else
          postMap
        end
        acc ++ [ postMap ]
      end)
    else
      []
    end
    %{ data: hd(final_list)}
  end


  def render("homeWork.json", %{getHomeWorkPost: getHomeWorkPostBasedOnId}) do
    postMap = if getHomeWorkPostBasedOnId do
      #get createdBy image and name
      userDetail = SuggestionBoxRepo.getUserNameAndImageInStaffDatabase(getHomeWorkPostBasedOnId["groupId"], getHomeWorkPostBasedOnId["createdById"])
      postMap = %{
        "id" => encode_object_id(getHomeWorkPostBasedOnId["_id"]),
        "groupId" => encode_object_id(getHomeWorkPostBasedOnId["groupId"]),
        "subjectId" =>  encode_object_id(getHomeWorkPostBasedOnId["subjectId"]),
        "createdById" => encode_object_id(getHomeWorkPostBasedOnId["createdById"]),
        "createdBy" => userDetail["name"],
        "createdByImage" => userDetail["image"],
        "createdAt" => getHomeWorkPostBasedOnId["insertedAt"],
        "updatedAt" => getHomeWorkPostBasedOnId["updatedAt"],
        "title" => getHomeWorkPostBasedOnId["title"],
        "text" => getHomeWorkPostBasedOnId["text"],
        "teamId" => encode_object_id(getHomeWorkPostBasedOnId["teamId"]),
        "canEdit" => false,
        "isLiked" => false,
        "comments" => 0,
        "likes" => 0
      }
      postMap = if !is_nil(getHomeWorkPostBasedOnId["fileName"]) do
        postMap
        |> Map.put_new("fileName", getHomeWorkPostBasedOnId["fileName"])
        |> Map.put_new("fileType", getHomeWorkPostBasedOnId["fileType"])
      else
        postMap
      end
      if !is_nil(getHomeWorkPostBasedOnId["body"]) do
        Map.put_new(postMap, "body", getHomeWorkPostBasedOnId["body"])
      else
        postMap
      end
    else
      []
    end
    %{ data: postMap}
  end


  def render("suggestion_events.json", %{eventAt: eventAt}) do
    map = if eventAt != [] do
      %{
        "lastSuggestionPostEventAt" => hd(eventAt)["updatedAt"]
      }
    else
      %{
        "lastSuggestionPostEventAt" => bson_time()
      }
    end
    %{ data: [map] }
  end




end
