defmodule GruppieWeb.ConstituencyCategory do
  use Ecto.Schema
  import Ecto.Changeset
  import GruppieWeb.Handler.TimeNow

  @web_youtube_link_regEx  ~r/\s*[a-zA-Z\/\/:\.]*youtube.com\/watch\?v=([a-zA-Z0-9\-_]+)([a-zA-Z0-9\/\*\-\_\?\&\;\%\=\.]*)/i

  @android_youtube_link_regEx ~r/\s*[a-zA-Z\/\/:\.]*youtu.be\/([a-zA-Z0-9\-_]+)([a-zA-Z0-9\/\*\-\_\?\&\;\%\=\.]*)/i


  @fields [ :title, :text, :fileName, :video, :fileType, :thumbnail, :thumbnailImage, :category, :categorySelection,
            :categoryType , :teamIds]


  schema "specialPost" do
    field :title, :string
    field :text, :string
    field :fileName, {:array, :string}
    field :thumbnailImage, {:array, :string}
    field :video, :string
    field :fileType, :string #image/pdf/audio/video
    field :thumbnail, :string
    field :category, :string
    field :categorySelection, :string
    field :categoryType, :string
    field :teamIds, {:array, :string}
    field :isActive, :boolean
    field :insertedAt, :string
    field :updatedAt, :string
  end

  def specialPost(struct, params) do
    struct
    |> cast(params, @fields)
    #|> validate_required(:text, [message: "Title Must Not Be Empty"])
    |> put_change(:isActive, true)
    |> put_change(:likes, 0)
    |> put_change(:likedUsers, [])
    |> set_time
    |> check_valid_post
    |> check_valid_youtube_link
    |> check_file_type
  end


  defp check_valid_post(struct) do
    if struct.valid? do
      title = get_field(struct, :title)
      text = get_field(struct, :text)
      fileName = get_field(struct, :fileName)
      video = get_field(struct, :video)
      # fileType = get_field(struct, :fileType)
      if is_nil(fileName) do
        if is_nil(video) do
          if is_nil(text) do
            if is_nil(title) do
              add_error(struct, :title, "Add The Post You Want To Add")
            else
              struct
            end
          else
            struct
          end
        else
          struct
        end
      else
        struct
      end
    else
      struct
    end
  end


  def check_valid_youtube_link(struct) do
    if struct.valid? do
      video = get_field(struct, :video)
      fileType = get_field(struct, :fileType)
      if fileType != "youtube" do
        struct
      else
        if Regex.match?(@web_youtube_link_regEx, video) do
          id = getWebId(video)
          put_change(struct, :video, id)
        else
          if Regex.match?(@android_youtube_link_regEx, video) do
            id = getAndroidId(video)
            put_change(struct, :video, id)
          else
            add_error(struct, :video, "Not Valid YouTube Link")
          end
        end
      end
    else
      struct
    end
  end


  defp getWebId(url) do
    list = Regex.split(~r{v=}, url)
    id = Enum.at(list, 1)
    id
  end

  defp getAndroidId(url) do
    list = Regex.split(~r{youtu.be/}, url)
    id = Enum.at(list, 1)
    id
  end


  defp check_file_type(struct) do
    fileName = get_field(struct, :fileName)
    video = get_field(struct, :video)
    fileType = get_field(struct, :fileType)
    if !is_nil(fileName) || !is_nil(video) do
      if !is_nil(fileType) do
        struct
      else
        add_error(struct, :fileType, "File Type Mandatory")
      end
    else
      struct
    end
  end


  defp set_time(struct) do
    struct
    |> put_change( :insertedAt, bson_time() )
    |> put_change( :updatedAt, bson_time() )
  end
end
