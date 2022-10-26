defmodule Gruppie.Api.V1.ConstituencyCategoryView do
  use GruppieWeb, :view
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.ConstituencyCategoryRepo
  alias GruppieWeb.Repo.GroupPostCommentsRepo
  alias GruppieWeb.Repo.GroupPostRepo
  alias GruppieWeb.Repo.ConstituencyRepo



  def render("getConstituencyList.json", %{getConstituencyList: constituencyCategoryList}) do
    #IO.puts "#{constituencyCategoryList}"
    list = if !constituencyCategoryList do
      []
    else
      [
        %{
          categories: constituencyCategoryList["categories"]
        }
      ]
    end
    %{
      data: list
    }
  end


  def render("getConstituencyTypesList.json", %{getConstituencyTypesList: constituencyTypesList}) do
    list = if !constituencyTypesList do
      []
    else
      [
        %{
          categoryTypes: constituencyTypesList["categoryTypes"]
        }
      ]
    end
    %{
      data: list
    }
  end


  def render("usersListBasedOnFilter.json", %{ getUserListBasedOnFilter: getUserListBasedOnQueryFilter }) do
    # IO.puts "#{getUserListBasedOnQueryFilter}"
    count = hd(getUserListBasedOnQueryFilter)
    pageCount = Float.ceil(count["pageCount"] / 30)
    totalPages = round(pageCount)
    list = if getUserListBasedOnQueryFilter do
      Enum.reduce(getUserListBasedOnQueryFilter, [], fn k, acc ->
        map = if k["_id"] do
          %{
            "name" => k["name"],
            "phone" => k["phone"],
            "image" => k["image"],
            "userId" => encode_object_id(k["_id"]),
          }
        end
        acc ++ [map]
      end)
    else
      []
    end
    list = Enum.reject(list, &is_nil/1)
    %{
      data: list,
      totalNumberOfPages: totalPages
    }
  end


  def render("specialPostList123.json", %{getSpecialPostList: specialPostList}) do
    list = if specialPostList do
      Enum.reduce(specialPostList, [], fn k, acc ->
        map = %{
          "fileName" => k["fileName"],
          "fileType" => k["fileType"],
          "likes" => k["likes"],
          "text" => k["text"],
        }
        acc ++ [map]
      end)
    else
      []
    end
    %{
      data: list
    }
  end


  def render("specialPostList.json", %{getSpecialPostList: specialPostList, group: group, login_user: login_user, canPost: canPost}) do
    post = if group["adminId"] == login_user["_id"] || canPost do
      true
    else
      false
    end
    final_list = Enum.reduce(specialPostList,[], fn post, acc ->
      canEdit = if group["adminId"] == login_user["_id"] || post["userId"] == login_user["_id"] do
        true
      else
        false
      end
      # check login user liked this post or not
      {:ok ,isLikedPostCount} = GroupPostCommentsRepo.findPostIsLiked(login_user["_id"], group["_id"], post["_id"])
      isLiked = if isLikedPostCount == 0 do
        false
      else
        true
      end
      # check login user saved/favourited this post or not
      {:ok ,isSavedPostCount} = GroupPostRepo.findPostIsSaved(login_user["_id"], group["_id"], post["_id"])
      isFavourited = if isSavedPostCount == 0 do
        false
      else
        true
      end
      # get total comments count for this post
      {:ok, commentsCount} = GroupPostCommentsRepo.getTotalCommentsCountForGroupPost(group["_id"], post["_id"])
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
        "isFavourited" => isFavourited,
        "createdAt" => post["insertedAt"],
        "updatedAt" => post["updatedAt"]
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
      end

      #if thumbnailImage for video and pdf is not nil then display
      postMap = if !is_nil(post["thumbnailImage"]) do
        postMap
        |> Map.put_new("thumbnailImage", post["thumbnailImage"])
      else
        postMap
      end

      ########TEMPORARiLY REMOVED#### Please add this to production

      #if post type is "birthdayPost" then fetch that bdayUserId name and profile
      postMap = if post["type"] == "birthdayPost" do
        bdayUserDetail = GroupPostRepo.getBdayUserDetail(post["bdayUserId"])
        postMap
        |> Map.put_new("bdayUserId", encode_object_id(post["bdayUserId"]))
        |> Map.put_new("bdayUserName", bdayUserDetail["name"])
        |> Map.put_new("bdayUserImage", bdayUserDetail["image"])
      else
        postMap
      end

      acc ++ [ postMap ]
    end)
    limit = 15
    #get total number of pages
    {:ok, postCount} = ConstituencyCategoryRepo.getTotalSpecialPostCount(group["_id"], login_user, post)
    pageCount = Float.ceil(postCount / limit)
    totalPages = round(pageCount)

    %{ data: final_list, totalNumberOfPages: totalPages}
  end


  def render("constituency_special_post_events.json", %{getSpecialPostEvents: specialPostEvents}) do
   list = if specialPostEvents == [] do
      []
    else
      [ %{
        "specialPostEvent" => specialPostEvents["updatedAt"]
        }
      ]
    end
    %{
      data: list
    }
  end


  def render("getInstalledUsersAndVoters.json", %{getTotalUsersInstall: getVoterAndInstallList}) do
    %{ data: [getVoterAndInstallList ]}
  end


  def render("getAnalysisFields.json", %{getAnalysisFields: analysisFields}) do
    list = if analysisFields do
      analysisFields["voterAnalysisFields"]
    else
      []
    end
    %{ data: list}
  end


  def render("getVotersList.json", %{getAnalysisFields: votersList}) do
    list = if votersList !=[] do
      Enum.reduce(votersList, [], fn k, acc ->
        map = %{
          "userId" => encode_object_id(k["_id"]),
          "name" => k["name"],
          "image" => k["image"]
        }
        acc ++ [map]
      end)
    else
      []
    end
    %{data: list}
  end


  def render("filterBasedOnName.json", %{getNameBasedOnFilter: getUserOnSearchList}) do
    count = hd(getUserOnSearchList)
    getUserOnSearchList = tl(getUserOnSearchList)
    pageCount = Float.ceil(count["pageCount"] / 30)
    totalPages = round(pageCount)
    list = if getUserOnSearchList != [] do
      Enum.reduce(getUserOnSearchList, [], fn k, acc ->
          map = %{
            "name" => k["name"],
            "userId" => encode_object_id(k["_id"]),
          }
        acc ++ [map]
      end)
    else
      []
    end
    %{
      data: list,
      totalNumberOfPages: totalPages
    }
  end


  def render("filterBasedOnNameList.json", %{getNameBasedOnFilterList: userList, count: count}) do
    pageCount = Float.ceil(count / 30)
    totalPages = round(pageCount)
    list = if userList != [] do
      Enum.reduce(userList, [], fn k, acc ->
          map = %{
            "name" => k["name"],
            "userId" => encode_object_id(k["userId"]),
          }
        acc ++ [map]
      end)
    else
      []
    end
    %{
      data: list,
      totalNumberOfPages: totalPages
    }
  end


  def render("boothTeamList.json", %{getBoothTeamList: boothTeamList, group: group}) do
    list = Enum.reduce(boothTeamList, [], fn k, acc ->
      #1st get committee id that is default Committee of worker
      filterCommitteeTrue = if k["boothCommittees"] do
        #filter defaultCommittee=true to show that committeeId
        Enum.filter(k["boothCommittees"], fn(k) ->
          k["defaultCommittee"] == true
        end)
      else
        []
      end
      #check key Exists for worker
      if !Map.has_key?(k, "workersCount") do
        ConstituencyCategoryRepo.appendWorkerCount(k["_id"], group["_id"])
      end
      #check key Exists for user
      if !Map.has_key?(k, "usersCount") do
        ConstituencyCategoryRepo.appendUserCount(k["_id"], group["_id"])
      end
      #check downloaded users count
      if !Map.has_key?(k, "downloadedUserCount") do
        ConstituencyCategoryRepo.downloadedUserCount(k["_id"], group["_id"])
      end
      map = %{
          "boothId" => encode_object_id(k["_id"]),
          "teamId" => encode_object_id(k["_id"]),
          #"boothName" => k["name"],
          "name" => k["name"],
          #"boothImage" => k["image"],
          "image" => k["image"],
          "workersCount" => k["workersCount"],
          "usersCount" =>  k["usersCount"],
          "downloadedUserCount" => k["downloadedUserCount"],
          ##"adminName" => k["adminName"],
          ##"phone" => k["phone"],
          #"totalBoothMembersCount" => boothMembersCount,
          ##"members" => boothMembersCount,
          "phone" => k["phone"],
          "adminName" => k["adminName"],
          "userName" => k["adminName"],
          "userImage" => k["userImage"],
          "userId" => encode_object_id(k["userId"]),
          "allowTeamPostAll" => true,
          "allowTeamPostCommentAll" => true,
          "canAddUser" => true,
          "isTeamAdmin" => true,
          "category" => k["category"],
          "boothCommittee" => if length(filterCommitteeTrue) > 0 do
            hd(filterCommitteeTrue)
          else
            %{}
          end
      }
      #get admin name and phone number from user table
      # adminDetail = UserRepo.find_user_by_id(k["adminId"])
      # map = map
      #       |> Map.put_new("adminName", adminDetail["name"])
      #       |> Map.put_new("phone", adminDetail["phone"])
      #       |> Map.put_new("userName", adminDetail["name"])
      #       |> Map.put_new("userId", encode_object_id(adminDetail["_id"]))
      #       |> Map.put_new("userImage", adminDetail["image"])
      acc ++ [map]
    end)
    {:ok, pageCount} = ConstituencyCategoryRepo.getPageCountBooths(group["_id"])
    # pageCount = Float.ceil(pageCount / 50)
    pageCount = Float.ceil(pageCount / 15)
    totalPages = round(pageCount)
    %{data: list, totalNumberOfPages: totalPages}
  end


  def render("boothTeamMembersList.json", %{getBoothTeamUsersList: boothTeamUsersList,  groupObjectId: groupObjectId, team: team, loginUser: loginUser}) do
    list = Enum.reduce(boothTeamUsersList, [], fn k, acc ->
      #IO.puts "#{k}"
      if !Map.has_key?(k, "users") do
        ConstituencyCategoryRepo.getMembersCount(k["_id"], groupObjectId)
      end
      if !Map.has_key?(k, "downloadedUserCount") do
        ConstituencyCategoryRepo.getDownloadedMembersCount(k["_id"], groupObjectId)
      end
      map = %{
          "boothId" => encode_object_id(k["_id"]),
          "teamId" => encode_object_id(k["_id"]),
          "name" => k["name"],
          "image" => k["image"],
          "adminName" => k["adminName"],
          "phone" => k["phone"],
          "members" => k["membersCount"],
          "downloadedUserCount" => k["downloadedUserCount"],
          "allowTeamPostAll" => true,
          "allowTeamPostCommentAll" => true,
          "canAddUser" => true,
          "isTeamAdmin" => if loginUser["_id"] == team["adminId"] do
            true
          else
            false
          end,
          "category" => k["category"],
          "groupId" => encode_object_id(groupObjectId),
          "userName" => k["adminName"],
          "userId" => encode_object_id(k["userId"]),
          "userImage" => k["userImage"]
      }
      acc ++ [map]
    end)
    {:ok, pageCount} =  ConstituencyCategoryRepo.getPageCountMembers(groupObjectId, team["_id"])
    # pageCount = Float.ceil(pageCount / 50)
    pageCount = Float.ceil(pageCount / 15)
    totalPages = round(pageCount)
    %{
      data: list,
      totalNumberOfPages: totalPages
    }
  end


  def render("booth_team_members.json", %{ boothUsers: boothTeamUsersList, loginUserId: loginUserId, group: group, teamObjectId: teamObjectId, params: params }) do
    # IO.puts "#{group}"
    usersList = Enum.reduce(boothTeamUsersList, [], fn k, acc ->
      {:ok, getUserInUserCategoryApps} = ConstituencyCategoryRepo.getDownloadedUserIds(k["userId"])
      userDownloadedApp = if getUserInUserCategoryApps == 0 do
        #not downloaded
        false
      else
        true
      end
      #get this userId notification_token
      userNotificationPushToken = ConstituencyRepo.getUserNotificationPushToken(k["userId"])
      #IO.puts "#{userNotificationPushToken}"
      map = %{
        "userId" => encode_object_id(k["userId"]),
        "phone" => k["phone"],
        "image" => k["image"],
        "allowedToAddUser" => k["teams"]["allowedToAddUser"],
        "allowedToAddTeamPost" => k["teams"]["allowedToAddPost"],
        "allowedToAddTeamPostComment" => k["teams"]["allowedToAddComment"],
        ##"teamCount" => getTeamsCount,
        "name" => k["name"],
        "roleOnConstituency" => k["roleOnConstituency"],
        "dob" => k["dob"],
        "gender" => k["gender"],
        "bloodGroup" => k["bloodGroup"],
        "voterId" => k["voterId"],
        "aadharNumber" => k["userDetails"]["aadharNumber"],
        "address" => k["address"],
        "email" => k["email"],
        "religion" => k["religion"],
        "caste" => k["caste"],
        "subCaste" => k["subCaste"],
        "designation" => k["designation"],
        "qualification" => k["qualification"],
        "willVote" => k["willVote"],
        "nonResidentialVoter" => k["nonResidentialVoter"],
        "influencer" => k["influencer"],
        "typeOfInfluencer" => k["typeOfInfluencer"],
        "noOfVotes" => k["noOfVotes"],
        "userDownloadedApp" => userDownloadedApp,
        "pushTokens" => userNotificationPushToken,
        "isLoginUser" => if k["userId"] == loginUserId do
          true
        else
          false
        end
      }
      acc ++ [map]
    end)
    {:ok, totalPageCount} = if params["committeeId"] do
      ConstituencyCategoryRepo.pageCountCommittee(group["_id"], teamObjectId, params)
    else
      ConstituencyCategoryRepo.getTotalPageCount(group["_id"], teamObjectId)
    end
    usersList = usersList
    |> Enum.sort_by(& String.downcase(&1["name"]))
    # pageCount = Float.ceil(totalPageCount / 50)
    pageCount = Float.ceil(totalPageCount / 15)
    totalPages = round(pageCount)
    %{
      data: usersList,
      totalNumberOfPages: totalPages
    }
  end
end
