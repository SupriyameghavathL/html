defmodule GruppieWeb.Repo.MessageCommentsRepo do
  import GruppieWeb.Repo.RepoHelper

  @conn :mongo

  @message_col "messages"

  @comments_col "comments"

  @view_comments_col "VW_COMMENTS"


  def addCommentToMessage(changeset, loginUserId, groupObjectId, postObjectId) do
    insertCommentDoc = changeset
                        |> update_map_with_key_value(:createdBy, loginUserId)
                        |> update_map_with_key_value(:groupId, groupObjectId)
                        |> update_map_with_key_value(:postId, postObjectId)
                        |> update_map_with_key_value(:comment, true)
                        |> update_map_with_key_value(:type, "individualPostComment")
    Mongo.insert_one(@conn, @comments_col, insertCommentDoc)
  end


  def getMessageCommentApi(queryParams, _loginUserId, groupObjectId, postObjectId, limit) do
    filter = %{"groupId" => groupObjectId, "postId" => postObjectId, "comment" => true, "type" => "individualPostComment",}
    project = %{ "_id" => 1, "comment" => 1, "createdBy" => 1, "groupId" => 1, "insertedAt" => 1, "isActive" => 1,
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


  def addReplyForCommentApi(changeset, loginUserId, groupObjectId, postObjectId, commentObjectId) do
    insertCommentReplyDoc = changeset
                        |> update_map_with_key_value(:createdBy, loginUserId)
                        |> update_map_with_key_value(:groupId, groupObjectId)
                        |> update_map_with_key_value(:postId, postObjectId)
                        |> update_map_with_key_value(:commentId, commentObjectId)
                        |> update_map_with_key_value(:comment, false)
                        |> update_map_with_key_value(:type, "individualPostComment")
    Mongo.insert_one(@conn, @comments_col, insertCommentReplyDoc)
  end


  def getReplyForMessageComment(queryParams, _loginUserId, groupObjectId, postObjectId, commentObjectId, limit) do
    filter = %{"groupId" => groupObjectId, "postId" => postObjectId, "commentId" => commentObjectId, "comment" => false, "type" => "individualPostComment"}
    project = %{ "_id" => 1, "comment" => 1, "createdBy" => 1, "groupId" => 1, "insertedAt" => 1, "isActive" => 1,
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


  def getTotalCommentsCountForMessage(groupObjectId, postObjectId) do
    filter = %{ "groupId" => groupObjectId, "postId" => postObjectId, "type" => "individualPostComment" }
    project = %{"_id" => 1}
    Mongo.count(@conn, @comments_col, filter, [projection: project])
  end


  def getTotalParentCommentsCount(groupObjectId, postObjectId) do
    filter = %{ "groupId" => groupObjectId, "postId" => postObjectId, "type" => "individualPostComment", "comment" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @comments_col, filter, [projection: project])
  end



  def findCommentById(commentObjectId) do
    filter = %{"_id" => commentObjectId, "type" => "individualPostComment"}
    project = %{ "_id" => 1, "comment" => 1, "createdBy" => 1, "groupId" => 1, "insertedAt" => 1, "isActive" => 1,
                "likes" => 1, "postId" => 1, "replies" => 1, "text" => 1, "updatedAt" => 1, "name" => "$$CURRENT.userDetails.name",
                "phone" => "$$CURRENT.userDetails.phone", "image" => "$$CURRENT.userDetails.image"}
    pipeline = [%{ "$match" => filter }, %{ "$project" => project }]
    #cursor = Mongo.find(@conn, @post_comment_col, filter)
    hd(Enum.to_list(Mongo.aggregate(@conn, @view_comments_col, pipeline)))
  end


  #from comment view
  def getTotalCommentRepliesCount(groupObjectId, postObjectId, commentObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "postId" => postObjectId,
      "commentId" => commentObjectId,
      "comment" => false,
      "type" => "individualPostComment"
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @comments_col, filter, [projection: project])
  end



  def deleteIndividualPostComment123(groupObjectId, postObjectId, commentObjectId) do
    filter = %{ "groupId" => groupObjectId, "postId" => postObjectId, "_id" => commentObjectId }
    Mongo.delete_one(@conn, @comments_col, filter)

    #reduce comment count
    filterPost = %{ "_id" => postObjectId, "groupId" => groupObjectId }
    update = %{ "$inc" => %{ "comments" => -1 } }
    Mongo.update_one(@conn, @message_col, filterPost, update)
  end


  def deleteIndividualPostComment(groupObjectId, postObjectId, commentObjectId) do
    #check comment is parent comment
    comment = findCommentById(commentObjectId)
    if comment["comment"] == true do
      #find and remove replies comment of this comment
      #first remove replies comment
      filterReplies = %{ "commentId" => commentObjectId, "comment" => false, "groupId" => groupObjectId, "postId" => postObjectId, "type" => "individualPostComment" }
      Mongo.delete_many(@conn, @comments_col, filterReplies)
      #secondly remove main comment
      filter = %{ "_id" => commentObjectId, "groupId" => groupObjectId, "postId" => postObjectId, "type" => "individualPostComment" }
      Mongo.delete_one(@conn, @comments_col, filter)
    else
      #remove just comment
      filter = %{ "_id" => commentObjectId, "groupId" => groupObjectId, "postId" => postObjectId, "type" => "individualPostComment" }
      Mongo.delete_one(@conn, @comments_col, filter)
    end
  end



end
