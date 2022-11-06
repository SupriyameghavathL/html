defmodule GruppieWeb.Repo.TeamPostCommentsRepo do
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Handler.TimeNow
  # alias GruppieWeb.GroupPostComments

  @conn :mongo

  @comments_col "comments"

  @post_col "posts"

  @view_comments_col "VW_COMMENTS"

  @view_team_post_liked_users_col "VW_TEAM_POST_LIKED_USERS"

  def addCommentApi(changeset, loginUserId, groupObjectId, teamObjectId, postObjectId) do
    insertCommentDoc = changeset
                        |> update_map_with_key_value(:createdBy, loginUserId)
                        |> update_map_with_key_value(:groupId, groupObjectId)
                        |> update_map_with_key_value(:teamId, teamObjectId)
                        |> update_map_with_key_value(:postId, postObjectId)
                        |> update_map_with_key_value(:comment, true)
                        |> update_map_with_key_value(:type, "teamPostComment")
    Mongo.insert_one(@conn, @comments_col, insertCommentDoc)
  end


  def getCommentApi(queryParams, _loginUserId, groupObjectId, teamObjectId, postObjectId, limit) do
    filter = %{"groupId" => groupObjectId, "teamId" => teamObjectId, "postId" => postObjectId, "comment" => true, "type" => "teamPostComment"}
    project = %{ "_id" => 1, "comment" => 1, "createdBy" => 1, "groupId" => 1, "teamId" => 1, "insertedAt" => 1, "isActive" => 1,
                "likes" => 1, "postId" => 1, "text" => 1, "updatedAt" => 1, "name" => "$$CURRENT.userDetails.name",
                "phone" => "$$CURRENT.userDetails.phone", "image" => "$$CURRENT.userDetails.image"}
    if !is_nil(queryParams["page"]) do
      pageNo = String.to_integer(queryParams["page"])
      skip = (pageNo - 1) * limit
      pipeline = [ %{"$match" => filter}, %{"$project" => project}, %{"$skip" => skip}, %{"$limit" => limit} ]
      Mongo.aggregate(@conn, @view_comments_col, pipeline)
    else
      pipeline = [ %{"$match" => filter}, %{"$project" => project} ]
      Mongo.aggregate(@conn, @view_comments_col, pipeline)
    end
  end


  def getLoginUserCommentApi(queryParams, loginUserId, groupObjectId, teamObjectId, postObjectId, limit) do
    filter = %{"groupId" => groupObjectId, "teamId" => teamObjectId, "postId" => postObjectId, "createdBy" => loginUserId, "comment" => true, "type" => "teamPostComment"}
    project = %{ "_id" => 1, "comment" => 1, "createdBy" => 1, "groupId" => 1, "teamId" => 1, "insertedAt" => 1, "isActive" => 1,
                "likes" => 1, "postId" => 1, "text" => 1, "updatedAt" => 1, "name" => "$$CURRENT.userDetails.name",
                "phone" => "$$CURRENT.userDetails.phone", "image" => "$$CURRENT.userDetails.image"}
    if !is_nil(queryParams["page"]) do
      pageNo = String.to_integer(queryParams["page"])
      skip = (pageNo - 1) * limit
      pipeline = [ %{"$match" => filter}, %{"$project" => project}, %{"$skip" => skip}, %{"$limit" => limit} ]
      Mongo.aggregate(@conn, @view_comments_col, pipeline)
    else
      pipeline = [ %{"$match" => filter}, %{"$project" => project} ]
      Mongo.aggregate(@conn, @view_comments_col, pipeline)
    end
  end



  def addCommentReplyApi(changeset, loginUserId, groupObjectId, teamObjectId, postObjectId, commentObjectId) do
    insertCommentReplyDoc = changeset
                        |> update_map_with_key_value(:createdBy, loginUserId)
                        |> update_map_with_key_value(:groupId, groupObjectId)
                        |> update_map_with_key_value(:teamId, teamObjectId)
                        |> update_map_with_key_value(:postId, postObjectId)
                        |> update_map_with_key_value(:commentId, commentObjectId)
                        |> update_map_with_key_value(:comment, false)
                        |> update_map_with_key_value(:type, "teamPostComment")
    Mongo.insert_one(@conn, @comments_col, insertCommentReplyDoc)
  end



  def getCommentRepliesApi(queryParams, _loginUserId, groupObjectId, teamObjectId, postObjectId, commentObjectId, limit) do
    filter = %{"groupId" => groupObjectId, "teamId" => teamObjectId, "postId" => postObjectId, "commentId" => commentObjectId, "comment" => false, "type" => "teamPostComment"}
    project = %{ "_id" => 1, "comment" => 1, "createdBy" => 1, "groupId" => 1, "teamId" => teamObjectId, "insertedAt" => 1, "isActive" => 1,
                "likes" => 1, "postId" => 1, "commentId" => 1, "text" => 1, "updatedAt" => 1, "name" => "$$CURRENT.userDetails.name",
                "phone" => "$$CURRENT.userDetails.phone", "image" => "$$CURRENT.userDetails.image"}
    if !is_nil(queryParams["page"]) do
      pageNo = String.to_integer(queryParams["page"])
      skip = (pageNo - 1) * limit
      pipeline = [ %{"$match" => filter}, %{"$project" => project}, %{"$skip" => skip}, %{"$limit" => limit} ]
      Mongo.aggregate(@conn, @view_comments_col, pipeline)
    else
      pipeline = [ %{"$match" => filter}, %{"$project" => project} ]
      Mongo.aggregate(@conn, @view_comments_col, pipeline)
    end
  end


  def getTotalTeamPostCommentsCount(groupObjectId, teamObjectId, postObjectId) do
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "postId" => postObjectId, "type" => "teamPostComment" }
    project = %{"_id" => 1}
    Mongo.count(@conn, @comments_col, filter, [projection: project])
  end



  def getTotalTeamPostParentCommentsCount(groupObjectId, teamObjectId, postObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "postId" => postObjectId,
      "comment" => true,
      "type" => "teamPostComment"
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @comments_col, filter, [projection: project])
  end


  #from comment view
  def getTotalTeamPostCommentRepliesCount(groupObjectId, teamObjectId, postObjectId, commentObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "postId" => postObjectId,
      "commentId" => commentObjectId,
      "comment" => false,
      "type" => "teamPostComment"
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @comments_col, filter, [projection: project])
  end


  def deleteTeamPostComment(groupObjectId, teamObjectId, postObjectId, commentObjectId) do
    #check comment is parent comment
    comment = findTeamPostCommentById(commentObjectId)
    if comment["comment"] == true do
      #find and remove replies comment of this comment
      #first remove replies comment
      filterReplies = %{ "commentId" => commentObjectId, "comment" => false, "groupId" => groupObjectId, "teamId" => teamObjectId, "postId" => postObjectId, "type" => "teamPostComment" }
      Mongo.delete_many(@conn, @comments_col, filterReplies)
      #secondly remove main comment
      filter = %{ "_id" => commentObjectId, "groupId" => groupObjectId, "teamId" => teamObjectId, "postId" => postObjectId, "type" => "teamPostComment" }
      Mongo.delete_one(@conn, @comments_col, filter)
    else
      #remove just comment
      filter = %{ "_id" => commentObjectId, "groupId" => groupObjectId, "teamId" => teamObjectId, "postId" => postObjectId, "type" => "teamPostComment" }
      Mongo.delete_one(@conn, @comments_col, filter)
    end
  end


  def findTeamPostCommentById(commentObjectId) do
    filter = %{"_id" => commentObjectId, "type" => "teamPostComment"}
    project = %{ "_id" => 1, "comment" => 1, "createdBy" => 1, "groupId" => 1, "teamId" => 1, "insertedAt" => 1, "isActive" => 1,
                "likes" => 1, "postId" => 1, "replies" => 1, "text" => 1, "updatedAt" => 1, "name" => "$$CURRENT.userDetails.name",
                "phone" => "$$CURRENT.userDetails.phone", "image" => "$$CURRENT.userDetails.image"}
    pipeline = [%{ "$match" => filter }, %{ "$project" => project }]
    #cursor = Mongo.find(@conn, @post_comment_col, filter)
    hd(Enum.to_list(Mongo.aggregate(@conn, @view_comments_col, pipeline)))
  end


  def findTeamPostIsLiked(loginUserId, groupObjectId, teamObjectId, postObjectId) do
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "_id" => postObjectId, "type" => "teamPost", "likedUsers.userId" => loginUserId }
    project = %{"_id" => 1}
    Mongo.count(@conn, @post_col, filter, [projection: project])
  end


  def teamPostLike(loginUserId, groupObjectId, teamObjectId, postObjectId) do
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "_id" => postObjectId, "type" => "teamPost" }
    update = %{ "$push" => %{ "likedUsers" => %{ "userId" => loginUserId, "insertedAt" => bson_time() } } }
    Mongo.update_one(@conn, @post_col, filter, update)
    #increament likes count
    updateLikeCount = %{ "$inc" => %{ "likes" =>  1 } }
    Mongo.update_one(@conn, @post_col, filter, updateLikeCount)
  end


  def teamPostUnLike(loginUserId, groupObjectId, teamObjectId, postObjectId) do
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "_id" => postObjectId, "type" => "teamPost" }
    update = %{ "$pull" => %{ "likedUsers" => %{ "userId" => loginUserId } } }
    Mongo.update_one(@conn, @post_col, filter, update)
    #increament likes count
    updateLikeCount = %{ "$inc" => %{ "likes" =>  -1 } }
    Mongo.update_one(@conn, @post_col, filter, updateLikeCount)
  end


  def getTeamPostLikedUsers(groupObjectId, teamObjectId, postObjectId) do
    filter = %{ "_id" => postObjectId, "groupId" => groupObjectId, "teamId" => teamObjectId, "type" => "teamPost" }
    project = %{ "userId" => "$$CURRENT.likedUserDetails._id", "name" => "$$CURRENT.likedUserDetails.name",
                "phone" => "$$CURRENT.likedUserDetails.phone", "image" => "$$CURRENT.likedUserDetails.image", "_id" => 0, "likedUsers.insertedAt" => 1 }
    pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{"likedUsers.insertedAt" => -1}}]
    Mongo.aggregate(@conn, @view_team_post_liked_users_col, pipeline)
  end


end
