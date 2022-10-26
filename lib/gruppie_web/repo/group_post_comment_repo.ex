defmodule GruppieWeb.Repo.GroupPostCommentsRepo do

  @conn :mongo

  @comments_col "comments"

  @group_post_like_col "group_post_likes"


  def findPostIsLiked(loginUserId, groupObjectId, postObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => loginUserId, "postId" => postObjectId }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_post_like_col, filter, [projection: project])
  end


  #get comment count for post
  def getTotalCommentsCountForGroupPost(groupObjectId, postObjectId) do
    filter = %{ "groupId" => groupObjectId, "postId" => postObjectId, "type" => "groupPostComment" }
    project = %{"_id" => 1}
    Mongo.count(@conn, @comments_col, filter, [projection: project])
  end

end
