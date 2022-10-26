defmodule GruppieWeb.Api.V1.FeederNotificationView do
  use GruppieWeb, :view
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.FeederNotificationRepo
  alias GruppieWeb.Repo.GroupPostCommentsRepo
  alias GruppieWeb.Repo.GroupPostRepo
  alias GruppieWeb.Repo.ConstituencyCategoryRepo
  alias GruppieWeb.Repo.SuggestionBoxRepo



  def render("postListAll.json", %{getAllPostList: allPostList, group: group, loginUser: loginUser}) do
    pageNo = hd(allPostList)
    allPostList = tl(allPostList)
    final_list = Enum.reduce(allPostList,[], fn post, acc ->
      canEdit = if group["adminId"] == loginUser["_id"] || post["userId"] == loginUser["_id"] do
        true
      else
        false
      end

      # if post["type"] == "teamPost" do
      #   {:ok ,isLikedPostCount} = TeamPostRepo.findTeamPostIsLiked(loginUser["_id"], group["_id"], post["teamId"], post["_id"])
      #   if isLikedPostCount == 0 do
      #     isLiked = false
      #   else
      #     isLiked = true
      #   end
      #   #get total comments count for this post
      #   {:ok, commentsCount} = TeamPostCommentsRepo.getTotalTeamPostCommentsCount(group["_id"], post["teamId"], post["_id"])
      # end

      isLiked = if post["type"] == "specialPost" || post["type"] == "groupPost" || post["type"] == "teamPost" do
        # check login user liked this post or not
        {:ok ,isLikedPostCount} = GroupPostCommentsRepo.findPostIsLiked(loginUser["_id"], group["_id"], post["_id"])
        if isLikedPostCount == 0 do
          false
        else
          true
        end
      end
      # get total comments count for this post
      {:ok, commentsCount} = GroupPostCommentsRepo.getTotalCommentsCountForGroupPost(group["_id"], post["_id"])
      # check login user saved/favorite this post or not
      {:ok ,isSavedPostCount} = GroupPostRepo.findPostIsSaved(loginUser["_id"], group["_id"], post["_id"])
      isFavorite =if isSavedPostCount == 0 do
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
        "uniquePostId" => post["uniquePostId"]
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
      #to get team name if team id present
      postMap = if Map.has_key?(post, "teamId") do
        team = FeederNotificationRepo.getTeamDetails(post["teamId"])
        if team["category"] == "booth" do
          teamName = FeederNotificationRepo.getTeamName(group["_id"], post["teamId"])
          postMap
          |> Map.put("teamId", encode_object_id(post["teamId"]))
          |> Map.put("teamName", teamName["name"])
        else
          if team["category"] == "subBooth" do
            teamName = FeederNotificationRepo.getTeamName(group["_id"], post["teamId"])
            postMap
            |> Map.put("teamId", encode_object_id(post["teamId"]))
            |> Map.put("teamName", teamName["name"])
            |> Map.put("boothTeamId", encode_object_id(team["boothTeamId"]))
          else
            teamName = FeederNotificationRepo.getTeamName(group["_id"], post["teamId"])
            postMap
            |> Map.put("teamId", encode_object_id(post["teamId"]))
            |> Map.put("teamName", teamName["name"])
          end
        end
      else
        postMap
      end
      acc ++ [ postMap ]
    end)
    final_list =  Enum.uniq_by(final_list, & &1["uniquePostId"])
    pageCount = Float.ceil(pageNo["pageCount"] / 15)
    totalPages = round(pageCount)
    %{
      data: final_list,
      totalNumberOfPages: totalPages
    }
  end


  def render("allPostSchool.json", %{getAllPostList: allPostSchool,  group: group, loginUser: loginUser, params: params}) do
    pageNo = hd(allPostSchool)
    allPostSchool = tl(allPostSchool)
    final_list = cond do
    params["type"] == "noticeBoard" ->
      Enum.reduce(allPostSchool, [], fn post, acc ->
        canEdit = if group["adminId"] == loginUser["_id"] || post["userId"] == loginUser["_id"] do
          true
        else
          false
        end
        isLiked = if post["type"] == "suggestionPost" || post["type"] == "groupPost" ||  post["type"] == "teamPost" do
          # check login user liked this post or not
          {:ok ,isLikedPostCount} = GroupPostCommentsRepo.findPostIsLiked(loginUser["_id"], group["_id"], post["_id"])
          if isLikedPostCount == 0 do
            false
          else
            true
          end
        end
        # get total comments count for this post
        {:ok, commentsCount} = GroupPostCommentsRepo.getTotalCommentsCountForGroupPost(group["_id"], post["_id"])

        # if post["type"] == "teamPost" do
        #   {:ok ,isLikedPostCount} = TeamPostRepo.findTeamPostIsLiked(loginUser["_id"], group["_id"], post["teamId"], post["_id"])
        #   if isLikedPostCount == 0 do
        #     isLiked = false
        #   else
        #     isLiked = true
        #   end
        #   #get total comments count for this post
        #   {:ok, commentsCount} = TeamPostCommentsRepo.getTotalTeamPostCommentsCount(group["_id"], post["teamId"], post["_id"])
        # end

        # check login user saved/favorite this post or not
        {:ok ,isSavedPostCount} = GroupPostRepo.findPostIsSaved(loginUser["_id"], group["_id"], post["_id"])
        isFavourited = if isSavedPostCount == 0 do
          false
        else
          true
        end

        if post["type"] == "feePost" do
          Map.put(post, "userId", group["adminId"])
        end
        # get name and image from staff table
        existsInStaffDatabase = SuggestionBoxRepo.getUserNameAndImageInStaffDatabase(group["_id"], post["userId"])
        userNameAndImage = if existsInStaffDatabase  do
          existsInStaffDatabase
        else
          # get name and image from student table
          existsInStudentDatabase = SuggestionBoxRepo.getUserNameAndImageInStudentDatabase(group["_id"], post["userId"])
          if existsInStudentDatabase do
            existsInStudentDatabase
          else
            # if user not found on both staff and student register get name and image from user collection
            SuggestionBoxRepo.getUserNameAndImageFromUserCol(post["userId"])
          end
        end
        postMap = %{
          "id" => encode_object_id(post["_id"]),
          "groupId" => encode_object_id(group["_id"]),
          "title" => post["title"],
          "text" => post["text"],
          "type" => post["type"],
          "createdBy" => userNameAndImage["name"],
          "createdByImage" => userNameAndImage["image"],
          "comments" => commentsCount,
          "likes" => post["likes"],
          "canEdit" => canEdit,
          "isLiked" => isLiked,
          "isFavourited" => isFavourited,
          "createdAt" => post["insertedAt"],
          "updatedAt" => post["updatedAt"],
          "createdById" => encode_object_id(post["userId"]),
          "uniquePostId" => post["uniquePostId"]
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
        #to get team name if team id present
        postMap = if Map.has_key?(post, "teamId") do
          teamName = FeederNotificationRepo.getTeamName(group["_id"], post["teamId"])
          postMap
          |> Map.put("teamId", encode_object_id(post["teamId"]))
          |> Map.put("teamName", teamName["name"])
        else
          postMap
        end
        acc ++ [ postMap ]
      end)
    params["type"] == "homeWork" ->
      Enum.reduce(allPostSchool, [], fn post, acc ->
        canEdit = if group["adminId"] == loginUser["_id"] || post["createdById"] == loginUser["_id"] do
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
        # check login user saved/favourited this post or not
        {:ok ,isSavedPostCount} = GroupPostRepo.findPostIsSaved(loginUser["_id"], group["_id"], post["_id"])
        isFavourited = if isSavedPostCount == 0 do
          false
        else
          true
        end
        # get total comments count for this post
        {:ok, commentsCount} = GroupPostCommentsRepo.getTotalCommentsCountForGroupPost(group["_id"], post["_id"])
        # get name and image from userTable
        existsInStaffDatabase = SuggestionBoxRepo.getUserNameAndImageInStaffDatabase(group["_id"], post["createdById"])
        userNameAndImage = if existsInStaffDatabase  do
          existsInStaffDatabase
        else
          # get name and image from student table
          existsInStudentDatabase = SuggestionBoxRepo.getUserNameAndImageInStudentDatabase(group["_id"], post["createdById"])
          if existsInStudentDatabase do
            existsInStudentDatabase
          else
            # if user not found on both staff and student register get name and image from user collection
            SuggestionBoxRepo.getUserNameAndImageFromUserCol(post["createdById"])
          end
        end
        #get subjectname from subjectId
        getSubjectName = FeederNotificationRepo.getSubjectName(group["_id"], post["subjectId"])
        subjectName = if getSubjectName do
          getSubjectName["subjectName"]
        else
          ""
        end
        postMap = %{
          "id" => encode_object_id(post["_id"]),
          "groupId" => encode_object_id(group["_id"]),
          "subjectId" => encode_object_id(post["_id"]),
          "subjectName" => subjectName,
          "title" => post["title"],
          "text" => post["text"],
          "createdBy" => userNameAndImage["name"],
          "createdByImage" => userNameAndImage["image"],
          "comments" => commentsCount,
          "likes" => post["likes"],
          "canEdit" => canEdit,
          "isLiked" => isLiked,
          "isFavourited" => isFavourited,
          "createdAt" => post["insertedAt"],
          "updatedAt" => post["updatedAt"],
          "createdById" => encode_object_id(post["createdById"])
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
        #to get team name if team id present
        postMap = if Map.has_key?(post, "teamId") do
          teamName = FeederNotificationRepo.getTeamName(group["_id"], post["teamId"])
          postMap
          |> Map.put("teamId", encode_object_id(post["teamId"]))
          |> Map.put("teamName", teamName["name"])
        else
          postMap
        end
        acc ++ [ postMap ]
      end)
    params["type"] == "notesVideos" ->
      Enum.reduce(allPostSchool, [], fn post, acc ->
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
        # check login user saved/favourited this post or not
        {:ok ,isSavedPostCount} = GroupPostRepo.findPostIsSaved(loginUser["_id"], group["_id"], post["_id"])
        isFavourited = if isSavedPostCount == 0 do
          false
        else
          true
        end
        # get total comments count for this post
        {:ok, commentsCount} = GroupPostCommentsRepo.getTotalCommentsCountForGroupPost(group["_id"], post["_id"])
        # get name and image from userTable
        existsInStaffDatabase = SuggestionBoxRepo.getUserNameAndImageInStaffDatabase(group["_id"], post["userId"])
        userNameAndImage = if existsInStaffDatabase  do
          existsInStaffDatabase
        else
          # get name and image from student table
          existsInStudentDatabase = SuggestionBoxRepo.getUserNameAndImageInStudentDatabase(group["_id"], post["userId"])
          if existsInStudentDatabase do
            existsInStudentDatabase
          else
            # if user not found on both staff and student register get name and image from user collection
            SuggestionBoxRepo.getUserNameAndImageFromUserCol(post["userId"])
          end
        end
        #get subjectname from subjectId
        getSubjectName = FeederNotificationRepo.getSubjectName(group["_id"], post["subjectId"])
        subjectName = if getSubjectName do
          getSubjectName["subjectName"]
        else
          ""
        end
        postMap = %{
          "id" => encode_object_id(post["_id"]),
          "groupId" => encode_object_id(group["_id"]),
          "subjectId" => encode_object_id(post["_id"]),
          "subjectName" => subjectName,
          "title" => post["chapterName"],
          "text" => post["topics"]["topicName"],
          "createdBy" => userNameAndImage["name"],
          "createdByImage" => userNameAndImage["image"],
          "comments" => commentsCount,
          "likes" => post["likes"],
          "canEdit" => canEdit,
          "isLiked" => isLiked,
          "isFavourited" => isFavourited,
          "createdAt" => post["insertedAt"],
          "updatedAt" => post["updatedAt"],
          "createdById" => encode_object_id(post["userId"])
        }
        postMap = if !is_nil(post["topics"]["fileName"]) do
          postMap
          |> Map.put_new("fileName", post["topics"]["fileName"])
          |> Map.put_new("fileType", post["topics"]["fileType"])
        else
          postMap
        end
        postMap = if !is_nil(post["topics"]["video"]) do
          if post["topics"]["fileType"] == "youtube" do
            watch = "https://www.youtube.com/watch?v="<>post["topics"]["video"]<>""
            thumbnail = "https://img.youtube.com/vi/"<>post["topics"]["video"]<>"/0.jpg"
            postMap
            |> Map.put_new("video", watch)
            |> Map.put_new("fileType", post["topics"]["fileType"])
            |> Map.put_new("thumbnail", thumbnail)
          else
            postMap
          end
        else
          postMap
        end
        #if thumbnailImage for video and pdf is not nil then display
        postMap = if !is_nil(post["topics"]["thumbnailImage"]) do
          postMap
          |> Map.put_new("thumbnailImage", post["topics"]["thumbnailImage"])
        else
          postMap
        end
        #to get team name if team id present
        postMap = if Map.has_key?(post, "teamId") do
          teamName = FeederNotificationRepo.getTeamName(group["_id"], post["teamId"])
          postMap
          |> Map.put("teamId", encode_object_id(post["teamId"]))
          |> Map.put("teamName", teamName["name"])
        else
          postMap
        end
        acc ++ [ postMap ]
      end)
    true ->
      Enum.reduce(allPostSchool, [], fn post, acc ->
        canEdit = if group["adminId"] == loginUser["_id"] || post["userId"] == loginUser["_id"] do
          true
        else
          false
        end

        isLiked = if post["type"] == "suggestionPost" || post["type"] == "groupPost" ||  post["type"] == "teamPost" do
          # check login user liked this post or not
          {:ok ,isLikedPostCount} = GroupPostCommentsRepo.findPostIsLiked(loginUser["_id"], group["_id"], post["_id"])
          if isLikedPostCount == 0 do
            false
          else
            true
          end
        end
         # get total comments count for this post
         {:ok, commentsCount} = GroupPostCommentsRepo.getTotalCommentsCountForGroupPost(group["_id"], post["_id"])

        # if post["type"] == "teamPost" do
        #   {:ok ,isLikedPostCount} = TeamPostRepo.findTeamPostIsLiked(loginUser["_id"], group["_id"], post["teamId"], post["_id"])
        #   if isLikedPostCount == 0 do
        #     isLiked = false
        #   else
        #     isLiked = true
        #   end
        #   #get total comments count for this post
        #   {:ok, commentsCount} = TeamPostCommentsRepo.getTotalTeamPostCommentsCount(group["_id"], post["teamId"], post["_id"])
        # end

        # check login user saved/favorite this post or not
        {:ok ,isSavedPostCount} = GroupPostRepo.findPostIsSaved(loginUser["_id"], group["_id"], post["_id"])
        isFavourited = if isSavedPostCount == 0 do
          false
        else
          true
        end

        if post["type"] == "feePost" do
          Map.put(post, "userId", group["adminId"])
        end
        # get name and image from staff table
        existsInStaffDatabase = SuggestionBoxRepo.getUserNameAndImageInStaffDatabase(group["_id"], post["userId"])
        userNameAndImage = if existsInStaffDatabase  do
          existsInStaffDatabase
        else
          # get name and image from student table
          existsInStudentDatabase = SuggestionBoxRepo.getUserNameAndImageInStudentDatabase(group["_id"], post["userId"])
          if existsInStudentDatabase do
            existsInStudentDatabase
          else
            # if user not found on both staff and student register get name and image from user collection
            SuggestionBoxRepo.getUserNameAndImageFromUserCol(post["userId"])
          end
        end
        postMap = %{
          "id" => encode_object_id(post["_id"]),
          "groupId" => encode_object_id(group["_id"]),
          "title" => post["title"],
          "text" => post["text"],
          "type" => post["type"],
          "createdBy" => userNameAndImage["name"],
          "createdByImage" => userNameAndImage["image"],
          "comments" => commentsCount,
          "likes" => post["likes"],
          "canEdit" => canEdit,
          "isLiked" => isLiked,
          "isFavourited" => isFavourited,
          "createdAt" => post["insertedAt"],
          "updatedAt" => post["updatedAt"],
          "createdById" => encode_object_id(post["userId"]),
          "uniquePostId" => post["uniquePostId"]
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
        #to get team name if team id present
        postMap = if Map.has_key?(post, "teamId") do
          teamName = FeederNotificationRepo.getTeamName(group["_id"], post["teamId"])
          postMap
          |> Map.put("teamId", encode_object_id(post["teamId"]))
          |> Map.put("teamName", teamName["name"])
        else
          postMap
        end
        acc ++ [ postMap ]
      end)
   end
   final_list = Enum.uniq_by(final_list, & &1["uniquePostId"])
    pageCount = Float.ceil(pageNo["pageCount"] / 15)
    totalPages = round(pageCount)
    %{
      data: final_list,
      totalNumberOfPages: totalPages
    }
  end

  #events
  def render("postListAllEvents.json", %{getAllPostListEvents: allPostListEvents}) do
    list = if allPostListEvents != [] do
     [%{
      "updatedAt" => hd(allPostListEvents)["updatedAt"]
     }]
    else
      []
    end
    %{
      data: list
    }
  end


  def render("reportList.json", %{getReportList: reportList}) do
    list = if reportList do
      [%{
        "reports" => reportList["reports"]
      }]
    else
      []
    end
    %{
      data: list
    }
  end


  def render("canPostTeamList.json", %{teamsList: allTeamsList, group: group, params: params}) do
    # pageNo = hd(allTeamsList)["pageCount"]
    list = if allTeamsList != [] do
      for teamMap <- allTeamsList do
        %{
          "id" => encode_object_id(teamMap["_id"]),
          "image" => teamMap["image"],
          "name" => teamMap["name"],
          "type" => "teamPost"
        }
      end
    else
      []
    end
    datalist = if params["page"] == "1" do
      list = Enum.uniq_by(list, & &1["id"])
      if group["category"] == "school" do
        [%{
          "id" => encode_object_id(group["_id"]),
          "name" => "Notice Board",
          "image" => group["image"],
          "type" => "groupPost"
        }] ++ list
      else
        [%{
          "id" => encode_object_id(group["_id"]),
          "name" => "Announcement",
          "image" => group["image"],
          "type" => "groupPost"
        }] ++ list
      end
    else
     Enum.uniq_by(list, & &1["id"])
    end
    # pageCount = Float.ceil(pageNo / 15)
    # totalPages = round(pageCount)
    %{
      totalNumberOfPages: 1,
      data: datalist
    }
  end


  def render("teamListUser.json", %{teamsList: allTeamListUser}) do
    # pageNo = hd(allTeamListUser)["pageCount"]
    list = if allTeamListUser != [] do
      for teamMap <- allTeamListUser do
        %{
          "id" => encode_object_id(teamMap["_id"]),
          "image" => teamMap["image"],
          "name" => teamMap["name"],
          "type" => "teamPost"
        }
      end
    else
      []
    end
    # pageCount = Float.ceil(pageNo / 15)
    # totalPages = round(pageCount)
    %{
      totalNumberOfPages: 1,
      data: list,
    }
  end


  def render("languageList.json", %{getLanguageList: getLanguageList}) do
    list = if getLanguageList !=[]  do
      for language <- getLanguageList do
        %{
          "id" => encode_object_id(language["_id"]),
          "subjectName" => language["subjectName"],
          "subjectPriority" => language["subjectPriority"]
        }
      end
    else
      []
    end
    %{
      data: list
    }
  end


  def render("gruppieLanguage.json", %{getLanguageMap: languageMap}) do
    list = if languageMap do
      %{
        "languages" => languageMap["languages"]
      }
    else
      []
    end
    %{
      data: [list]
    }
  end
end
