defmodule GruppieWeb.Repo.SuggestionBoxRepo do

  @conn :mongo

  @group_team_member_col "group_team_members"

  @student_database_col "student_database"

  @post_col "posts"

  @staff_database_col "staff_database"

  @subject_post_coll "subject_posts"

  @home_work_post_coll "school_assignment"

  @users_col "users"



  def postSuggestionByParents(changeset, groupObjectId, userObjectId) do
    changeset = changeset
    |> Map.put(:groupId, groupObjectId)
    |> Map.put(:userId, userObjectId)
    |> Map.put(:type, "suggestionPost")
    Mongo.insert_one(@conn, @post_col, changeset)
  end


  def checkCanPostTrue(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true,
    }
    project = %{
      "canPost" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @group_team_member_col, filter, [projection: project])
  end


  def getAllSuggestionPost(groupObjectId, params) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => "suggestionPost",
      "isActive" => true,
    }
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 15
      Mongo.find(@conn, @post_col, filter, [sort: %{"_id" => -1}, skip: skip, limit: 15])
      |>Enum.to_list()
    else
      Mongo.find(@conn, @post_col, filter, [sort: %{"_id" => -1}])
      |>Enum.to_list()
    end
  end

  def getSuggestionBoxPostForAdmin(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => "suggestionPost",
      "isActive" => true,
    }
    project = %{"_id" => 0, "updatedAt" => 1}
    Mongo.find(@conn, @post_col, filter, [projection: project, sort: %{"updatedAt" => -1}, limit: 1])
    |> Enum.to_list
  end


  def getSuggestionBoxPostForUser(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "type" => "suggestionPost",
      "isActive" => true,
    }
    project = %{"_id" => 0, "updatedAt" => 1}
    Mongo.find(@conn, @post_col, filter, [projection: project, sort: %{"updatedAt" => -1}, limit: 1])
    |> Enum.to_list
  end


  def adminPageCount(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => "suggestionPost",
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @post_col, filter, [projection: project])
  end


  def getPostPostedByUser(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "type" => "suggestionPost",
      "isActive" => true,
    }
    Mongo.find(@conn, @post_col, filter, [sort: %{"_id" => -1}])
    |> Enum.to_list()
  end


  def getPostPostedByUserCount(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "type" => "suggestionPost",
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @post_col, filter, [projection: project])
  end


  def getUserNameAndImageInStaffDatabase(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true,
    }
    project = %{
      "name" => 1,
      "image" => 1,
    }
    Mongo.find_one(@conn, @staff_database_col, filter, [projection: project])
  end


  def getUserNameAndImageInStudentDatabase(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true,
    }
    project = %{
      "name" => 1,
      "image" => 1,
    }
    Mongo.find_one(@conn, @student_database_col, filter, [projection: project])
  end


  def getUserNameAndImageFromUserCol(userObjectId) do
    filter = %{
      "_id" => userObjectId
    }
    project = %{
      "name" => 1,
      "image" => 1,
    }
    Mongo.find_one(@conn, @users_col, filter, [projection: project])
  end


  def getNotesFeedTopic(groupObjectId, teamObjectId, topicId)  do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "topics.topicId" => topicId,
      "isActive" => true,
    }
    project = %{
      "topics.$" => 1,
      "groupId" => 1,
      "teamId" => 1,
      "updatedAt" => 1,
      "chapterName" => 1,
    }
    Mongo.find_one(@conn, @subject_post_coll, filter, [projection: project])
  end


  def getNotesFeed(groupObjectId, teamObjectId, postObjectId) do
    filter = %{
      "_id" => postObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "topics" => 1,
      "groupId" => 1,
      "teamId" => 1,
      "updatedAt" => 1,
      "chapterName" => 1,
    }
    Mongo.find_one(@conn, @subject_post_coll, filter, [projection: project])
  end


  def getHomeWorksFeed(groupObjectId, teamObjectId, postObjectId) do
    filter = %{
      "_id" => postObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true,
    }
    Mongo.find_one(@conn, @home_work_post_coll, filter)
  end

end
