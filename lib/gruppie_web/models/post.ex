defmodule GruppieWeb.Post do
  use Ecto.Schema
  import Ecto.Changeset
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Handler.TimeNow


  @web_youtube_link_regEx  ~r/\s*[a-zA-Z\/\/:\.]*youtube.com\/watch\?v=([a-zA-Z0-9\-_]+)([a-zA-Z0-9\/\*\-\_\?\&\;\%\=\.]*)/i

  @android_youtube_link_regEx ~r/\s*[a-zA-Z\/\/:\.]*youtu.be\/([a-zA-Z0-9\-_]+)([a-zA-Z0-9\/\*\-\_\?\&\;\%\=\.]*)/i

  @fields [ :title, :text, :fileName, :video, :fileType, :thumbnail, :thumbnailImage, :uniquePostId, :postType]
  @gallery_fields [ :albumName, :fileName, :video, :fileType, :thumbnail, :thumbnailImage ]
  @album_fields [ :fileName, :video, :fileType, :thumbnail, :thumbnailImage ]
  # @time_table_fields [ :title, :fileName, :fileType, :thumbnailImage ]
  # @subject_staff_add_fields [:subjectName, :staffId, :subjectPriority, :isLanguage]
  # @year_time_table_fields [ :day, :period, :startTime, :endTime ]
  @vendor_fields [:vendor, :description, :fileName, :fileType, :thumbnailImage]
  @coc_fields [:title, :description, :fileName, :fileType, :thumbnailImage] #Fields for COC, e-books add
  # @calendar_fields [:text, :type]
  # @assignment_fields [ :title, :text, :fileName, :fileType, :thumbnailImage, :lastSubmissionDate, :lastSubmissionTime ]   #only image or PDF on attachment
  # @subject_posts_fields [:chapterName, :topicName, :fileName, :video, :fileType, :thumbnail, :thumbnailImage, :topicId]
  # @assignment_comment_fields [ :text, :fileName, :fileType ]
  # @testexam_fields [ :title, :text, :testDate, :testStartTime, :testEndTime, :lastSubmissionTime, :fileName, :fileType, :thumbnailImage, :proctoring]   #only image attachment

  schema "posts" do
    field :title, :string
    field :text, :string
    field :fileName, {:array, :string}
    field :thumbnailImage, {:array, :string}
    field :video, :string
    field :fileType, :string #image/pdf/audio/video
    field :thumbnail, :string
    field :inserted_at, :utc_datetime
    field :updated_at, :utc_datetime
    field :is_active, :boolean
    field :likes, :integer
    field :albumName, :string
    field :vendor, :string
    field :description, :string
    field :type, :string #calendar add
    field :lastSubmissionDate, :string #assignment add
    field :lastSubmissionTime, :string #assignment/testExam add
    field :testStartTime, :string #testexam add
    field :testEndTime, :string #testExam add
    field :testDate, :string #testExam add
    field :proctoring, :boolean #testExam add
    field :day, :string #year timetable add
    field :period, :string #year timetable add
    field :startTime, :string #year timetable add(09:15 AM)
    field :endTime, :string #year timetable add(10:15 AM)
    field :subjectName, :string #add subject and staff to class
    field :staffId, {:array, :string} #add subject and staff to class
    field :chapterName, :string #add subject vice posts(notes/videos)
    field :topicName, :string #add subject vice posts(notes/videos)
    field :topicId, :string #notes/ videos
    field :subjectPriority, :integer #subject/staff/update
    field :isLanguage, :boolean #subject/staff/update
    field :uniquePostId, :string
    field :postType, :string
    field :isActive, :boolean
    field :insertedAt, :string
    field :updatedAt, :string
  end



  def changeset(struct, params) do
    struct
    |> cast(params, @fields)
    #|> validate_required(:text, [message: "Title Must Not Be Empty"])
    |> put_change(:isActive, true)
    |> put_change(:likes, 0)
    |> set_time
    |> put_change(:uniquePostId, encode_object_id(new_object_id()))
    |> check_valid_post
    |> check_valid_youtube_link
    |> check_file_type
  end



  def changeset_gallery(struct, params) do
    struct
    |> cast(params, @gallery_fields)
    |> validate_required(:albumName, [message: "Album Name Must Not Be Empty"])
    |> put_change(:isActive, true)
    |> set_time
    |> check_valid_post_to_gallery
    |> check_valid_youtube_link
    |> check_file_type
  end


  def changeset_album_add(struct, params) do
    struct
    |> cast(params, @album_fields)
    |> check_valid_post_to_gallery
    |> check_valid_youtube_link
    |> check_file_type
  end


  def changeset_vendor(struct, params) do
    struct
    |> cast(params, @vendor_fields)
    |> validate_required(:vendor, [message: "Must Not Be Empty"])
    |> put_change(:isActive, true)
    |> set_time
    |> check_file_type
  end


  def changeset_coc(struct, params) do
    struct
    |> cast(params, @coc_fields)
    |> validate_required(:title, [message: "Must Not Be Empty"])
    |> put_change(:isActive, true)
    |> set_time
    |> check_file_type
  end




  defp check_valid_post_to_gallery(struct) do
    if struct.valid? do
      fileName = get_field(struct, :fileName)
      video = get_field(struct, :video)
      # fileType = get_field(struct, :fileType)
      if is_nil(fileName) do
        if is_nil(video) do
          add_error(struct, :fileName, "Add The File You Want To Add")
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


  defp set_time(struct) do
    struct
    |> put_change( :insertedAt, bson_time() )
    |> put_change( :updatedAt, bson_time() )
  end



end
