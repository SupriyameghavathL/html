# defmodule GruppieWeb.Plugs.TeamPostAuth do
#   import GruppieWeb.Plugs.PlugHelpers
#   alias GruppieWeb.Repo.TeamPostRepo


#   @doc """
#   initialize any argument need to pass in call
#   """
#   def init(_) do
#     mongo_id_pattern = ~r/[a-f 0-9]{24}/
#     mongo_id_pattern
#   end


#   @doc """
#   carries out the connection transformation
#   """
#   def call(%Plug.Conn{ params: params } = conn, pattern) do
#     group_id = params["group_id"]
#     team_id = params["team_id"]
#     post_id = params["post_id"]
#     cond do
#       group_id =~ pattern && team_id =~ pattern && post_id =~ pattern ->
#         case TeamPostRepo.findPostBelongsToGroup(group_id, team_id, post_id) do
#           {:ok, teamPostFoundCount}->
#             if teamPostFoundCount == 1 do
#                conn
#             else
#               IO.puts "Post not belongs to team"
#               render404(conn)
#             end
#           {:error, _mongo_error }->
#             IO.inspect "mongo error in team auth"
#             render500(conn)
#         end
#      true->
#         IO.inspect "not found in team auth"
#         render404(conn)
#     end

#   end

# end
