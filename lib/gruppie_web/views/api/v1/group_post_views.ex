defmodule GruppieWeb.Api.V1.GroupPostView do
  use GruppieWeb, :view
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.GroupPostRepo
  alias GruppieWeb.Repo.GroupPostCommentsRepo
  alias GruppieWeb.Repo.AdminRepo


  def render("posts.json", %{ posts: posts, group: group, conn: conn, limit: limit }) do
    login_user = Guardian.Plug.current_resource(conn)
    final_list = Enum.reduce(posts,[], fn post, acc ->
      canEdit = if group["adminId"] == login_user["_id"] || post["userId"] == login_user["_id"] do
        true
      else
         false
      end
      #check login user liked this post or not
      {:ok ,isLikedPostCount} = GroupPostCommentsRepo.findPostIsLiked(login_user["_id"], group["_id"], post["_id"])
      isLiked = if isLikedPostCount == 0 do
        false
      else
        true
      end
      #check login user saved/favourited this post or not
      {:ok ,isSavedPostCount} = GroupPostRepo.findPostIsSaved(login_user["_id"], group["_id"], post["_id"])
      isFavourited = if isSavedPostCount == 0 do
        false
      else
        true
      end
      #get total comments count for this post
      {:ok, commentsCount} = GroupPostCommentsRepo.getTotalCommentsCountForGroupPost(group["_id"], post["_id"])

      postMap = %{
        "id" => encode_object_id(post["_id"]),
        "groupId" => encode_object_id(post["groupId"]),
        "title" => post["title"],
        "text" => post["text"],
	      "type" => post["type"],
        "createdById" => encode_object_id(post["userId"]),
        "createdBy" => post["name"],
        "phone" => post["phone"],
        "createdByImage" => post["image"],
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
    #get total number of pages
    {:ok, postCount} = GroupPostRepo.getTotalPostCount(group["_id"])
    pageCount = Float.ceil(postCount / limit)
    totalPages = round(pageCount)

    %{ data: final_list, totalNumberOfPages: totalPages}
  end



  #get gallery allbum + file list
  def render("gallery.json", %{ gallery: gallery, limit: limit, conn: conn, group: group }) do
    login_user = Guardian.Plug.current_resource(conn)
    resultList = Enum.reduce(gallery, [], fn k, acc ->
      canEdit = if group["adminId"] == login_user["_id"] || k["userId"] == login_user["_id"] do
        true
      else
        false
      end
      map = %{
        "albumId" => encode_object_id(k["_id"]),
        "groupId" => encode_object_id(k["groupId"]),
        "albumName" => k["albumName"],
        "createdAt" => k["insertedAt"],
        "updatedAt" => k["updatedAt"],
        "canEdit" => canEdit,
      }
      map = if !is_nil(k["fileName"]) do
        map
        |> Map.put_new("fileName", k["fileName"])
        |> Map.put_new("fileType", k["fileType"])
      else
        map
      end

      map = if !is_nil(k["video"]) do
        if k["fileType"] == "youtube" do
          watch = "https://www.youtube.com/watch?v="<>k["video"]<>""
          thumbnail = "https://img.youtube.com/vi/"<>k["video"]<>"/0.jpg"
          map
          |> Map.put_new("video", watch)
          |> Map.put_new("fileType", k["fileType"])
          |> Map.put_new("thumbnail", thumbnail)
        else
          map
        end
      else
        map
      end
      #if thumbnailImage for video and pdf is not nil then display
      map = if !is_nil(k["thumbnailImage"]) do
        map
        |> Map.put_new("thumbnailImage", k["thumbnailImage"])
      else
        map
      end
      acc ++ [ map ]
    end)
    #get total number of pages
    {:ok, postCount} = GroupPostRepo.getTotalAlbumCount(group["_id"])
    pageCount = Float.ceil(postCount / limit)
    totalPages = round(pageCount)

    %{ data: resultList, totalNumberOfPages: totalPages}
  end


   #get vendors
   def render("vendor.json", %{ vendors: vendors, conn: conn, group: group }) do
    login_user = Guardian.Plug.current_resource(conn)
    resultList = Enum.reduce(vendors, [], fn k, acc ->
      canEdit = if group["adminId"] == login_user["_id"] || k["user_id"] == login_user["_id"] do
        true
      else
        false
      end
      map = %{
        "vendorId" => encode_object_id(k["_id"]),
        "groupId" => encode_object_id(k["groupId"]),
        "vendor" => k["vendor"],
        "description" => k["description"],
        "createdAt" => k["inserted_at"],
        "updatedAt" => k["updated_at"],
        "canEdit" => canEdit,
      }
      map = if !is_nil(k["fileName"]) do
        map
        |> Map.put_new("fileName", k["fileName"])
        |> Map.put_new("fileType", k["fileType"])
      else
        map
      end
      #if thumbnailImage for video and pdf is not nil then display
      map = if !is_nil(k["thumbnailImage"]) do
        map
        |> Map.put_new("thumbnailImage", k["thumbnailImage"])
      else
        map
      end
      acc ++ [ map ]
    end)
    %{ data: resultList }
  end


  #get coc
  def render("coc.json", %{ coc: coc, conn: conn, group: group }) do
    login_user = Guardian.Plug.current_resource(conn)
    resultList = Enum.reduce(coc, [], fn k, acc ->
      canEdit = if group["adminId"] == login_user["_id"] || k["user_id"] == login_user["_id"] do
        true
      else
        false
      end
      map = %{
        "cocId" => encode_object_id(k["_id"]),
        "groupId" => encode_object_id(k["groupId"]),
        "title" => k["title"],
        "description" => k["description"],
        "createdAt" => k["insertedAt"],
        "updatedAt" => k["updatedAt"],
        "canEdit" => canEdit,
      }
      if !is_nil(k["fileName"]) do
        map
        |> Map.put_new("fileName", k["fileName"])
        |> Map.put_new("fileType", k["fileType"])
      else
        map
      end
      #if thumbnailImage for video and pdf is not nil then display
      if !is_nil(k["thumbnailImage"]) do
        map
        |> Map.put_new("thumbnailImage", k["thumbnailImage"])
      else
        map
      end
      acc ++ [ map ]
    end)
    %{ data: resultList }
  end


  def render("staff.json", %{ staff: staff, group: group }) do
    # IO.puts "#{staff}"
    list = Enum.reduce(staff, [], fn k, acc ->
      # IO.puts "#{k["userId"]}"
      #get this student phone number from users_col
      getStaffPhoneNumber = AdminRepo.getUserPhoneDetailFromUsersCol(k["userId"])
      # IO.puts "#{getStaffPhoneNumber}"
      { :ok, isAccountant } = AdminRepo.getIsAccountant(k["groupId"], k["userId"])
      { :ok, isExaminer} =  AdminRepo.getIsExaminer(k["groupId"], k["userId"])
      accountant = if isAccountant == 1 || k["userId"] == group["adminId"] do
        true
      else
        false
      end
      examiner = if isExaminer == 1 || k["userId"] == group["adminId"] do
        true
      else
        false
      end
      staffPhoneNumber = getStaffPhoneNumber["phone"]
      |> String.slice(3..-1)
      map = %{
        #staffId: encode_object_id(k["_id"]),
        staffId: encode_object_id(k["userId"]),
        staffRegId: k["staffId"],
        userId: encode_object_id(k["userId"]),
        name: k["name"],
        phone: staffPhoneNumber,
        image: k["image"],
        designation: k["designation"],
        fatherName: k["fatherName"],
        motherName: k["motherName"],
        emergencyContactNumber: k["emergencyContactNumber"],
        email: k["email"],
        gender: k["gender"],
        address: k["address"],
        religion: k["religion"],
        caste: k["caste"],
        bloodGroup: k["bloodGroup"],
        qualification: k["qualification"],
        doj: k["doj"],
        isAllowedToPost: false,  #authorized user,
        uanNumber: k["uanNumber"],
        bankAccountNumber: k["bankAccountNumber"],
        bankIfscCode: k["bankIfscCode"],
        panNumber: k["panNumber"],
        staffType: k["staffType"],
        classTypeId: k["classTypeId"],
        disability: k["disability"],
        category: k["category"],
        dob: k["dob"],
        aadharNumber: k["aadharNumber"],
        bankName: k["bankName"],
        groupId: encode_object_id(k["groupId"]),
        accountant: accountant,
        examiner: examiner,
      }
      #check user allowed to post in this group or not
      {:ok, checkUserAllowedToPost} = AdminRepo.checkUserAllowedToPost(k["userId"], k["groupId"])
      map = if checkUserAllowedToPost > 0 do
        Map.put(map, :isAllowedToPost, true)
      else
        map
      end

      acc ++ [map]
    end)
    %{ data: list }
  end


  def render("class.json", %{ classes: classes, groupObjectId: groupObjectId }) do
    #IO.puts "#{Enum.to_list(classes)}"
    list = Enum.reduce(classes, [], fn k, acc ->
      #get total students in team
      {:ok, membersCount} = AdminRepo.getTotalStudentsCountInStudentRegister(k["_id"], groupObjectId)
      map = %{
        "teamId" => encode_object_id(k["_id"]),
        "name" => k["name"],
        "gruppieClassName" => k["gruppieClassName"],
        "image" => k["image"],
        "teacherName" => k["adminName"],
        "phone" => k["phone"],
        "members" => membersCount,
        "category" => k["category"],
      }

      map = if k["gruppieClassName"] do
        appendIdToClasses(map)
      else
        Map.put(map, "sortBy", "Z")
      end

      map = if k["subjectId"] do
        map
        |> Map.put_new("subjectId", true)
      else
        map
        |> Map.put_new("subjectId", false)
      end

      map = if k["ebookId"] do
        map
        |> Map.put_new("ebookId", true)
      else
        map
        |> Map.put_new("ebookId", false)
      end

      map = if k["zoomKey"] && k["zoomSecret"] do
        map
        |> Map.put_new("jitsiToken", true)
      else
        map
        |> Map.put_new("jitsiToken", false)
      end
      acc ++ [map]
    end)
    # IO.puts "#{list}"
    list = list
    |> Enum.sort_by(& String.downcase(&1["sortBy"]))
    #########temporary
    #list = [%{"name" => "Staffs"}] ++ list

    %{ data: list }
  end


  defp appendIdToClasses(map) do
    cond do
      map["gruppieClassName"] == "Pre-Nursery" ->
        Map.put(map, "sortBy", "A")
      map["gruppieClassName"] == "Nursery" ->
        Map.put(map, "sortBy", "B")
      map["gruppieClassName"] == "LKG" ->
        Map.put(map, "sortBy", "C")
      map["gruppieClassName"] == "UKG" ->
        Map.put(map, "sortBy", "D")
      map["gruppieClassName"] in ["Class 1" , "Grade 1"] ->
        Map.put(map, "sortBy", "E")
      map["gruppieClassName"] in ["Class 2" ,"Grade 2"] ->
        Map.put(map, "sortBy", "F")
      map["gruppieClassName"] in ["Class 3", "Grade 3"] ->
        Map.put(map, "sortBy", "G")
      map["gruppieClassName"] in ["Class 4", "Grade 4"] ->
        Map.put(map,"sortBy", "H")
      map["gruppieClassName"] in ["Class 5", "Grade 5"] ->
        Map.put(map, "sortBy", "I")
      map["gruppieClassName"] in ["Class 6", "Grade 6"] ->
        Map.put_new(map, "sortBy", "J")
      map["gruppieClassName"] in ["Class 7", "Grade 7"] ->
        Map.put(map, "sortBy", "K")
      map["gruppieClassName"] in ["Class 8", "Grade 8"] ->
        Map.put(map, "sortBy", "L")
      map["gruppieClassName"] in ["Class 9", "Grade 9"] ->
        Map.put(map, "sortBy", "M")
      map["gruppieClassName"] in ["Class 10","Grade 10"] ->
        Map.put(map, "sortBy", "N")
      true ->
        Map.put(map, "sortBy", "Z")
    end
  end


  def render("studentsList.json", %{ students: students, groupObjectId: groupObjectId, teamId: teamId }) do
    list = Enum.reduce(students, [], fn k, acc ->
      #get this student phone number from users_col
      getStudentPhoneNumber = AdminRepo.getUserPhoneDetailFromUsersCol(k["userId"])
      studentPhoneNumber = getStudentPhoneNumber["phone"]
      |> String.slice(3..-1)
      #check student downloaded and logged in from user_category_apps
      {:ok, getStudentInUserCategoryApps} = AdminRepo.getStudentInUserCategoryApps(k["userId"], "school")
      userDownloadedApp = if getStudentInUserCategoryApps == 0 do
        #not downloaded
        false
      else
        true
      end
      map = %{
        studentDbId: encode_object_id(k["_id"]),
        userId: encode_object_id(k["userId"]),
        name: k["name"],
        image: k["image"],
        phone: studentPhoneNumber,
        gender: k["gender"],
        admissionNumber: k["admissionNumber"],
        studentRegId: k["studentRegId"],
        rollNumber: k["rollNumber"],
        dob: k["dob"],
        doj: k["doj"],
        fatherName: k["fatherName"],
        motherName: k["motherName"],
        fatherNumber: k["fatherNumber"],
        motherNumber: k["motherNumber"],
        address: k["address"],
        class: k["class"],
        section: k["section"],
        email: k["email"],
        aadharNumber: k["aadharNumber"],
        bloodGroup: k["bloodGroup"],
        religion: k["religion"],
        caste: k["caste"],
        subCaste: k["subCaste"],
        groupId: encode_object_id(groupObjectId),
        teamId: teamId,
        gruppieRollNumber: k["gruppieRollNumber"],
        fatherEducation: k["fatherEducation"],
        motherEducation: k["motherEducation"],
        satsNo: k["satsNo"],
        disability: k["disability"],
        nationality: k["nationality"],
        motherOccupation: k["motherOccupation"],
        fatherOccupation: k["fatherOccupation"],
        category: k["category"],
        userDownloadedApp: userDownloadedApp,
        familyIncome: k["familyIncome"],
      }
      acc ++ [map]
    end)
    %{ data: list }
  end




end
