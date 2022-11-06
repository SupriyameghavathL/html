defmodule GruppieWeb.Api.V1.TeamView do
  use GruppieWeb, :view
  alias GruppieWeb.Repo.TeamRepo
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Repo.AdminRepo
  alias GruppieWeb.Repo.UserRepo
  import GruppieWeb.Repo.RepoHelper



  #to list all teams of group for the user
  # TEAM INDEX for FULL Version
  defp getGruppieHomePage(teams, loginUser, group) do
    groupStringId = encode_object_id(group["_id"])
    teams_map = Enum.reduce(teams, [], fn k, acc ->
      {:ok, teamMembersCount} = TeamRepo.getCreatedTeamMembersCount(group["_id"], k["teamId"])   ##Instead, get team members count of all teams fot this group and concatenate inside for loop
      #IO.puts "#{encode_object_id(k["teamId"])}"
      map =  %{
        groupId: groupStringId,
        #teamId: encode_object_id(k["_id"]),
        teamId: encode_object_id(k["teamId"]),
        name: k["name"],
        image: k["image"],
        category: k["category"],
        members: teamMembersCount,
        isTeamAdmin: k["isTeamAdmin"],
        allowTeamPostAll: k["allowedToAddPost"],
        allowTeamPostCommentAll: k["allowedToAddComment"],
        canAddUser: k["isTeamAdmin"]
      }
      #if category school then provide enable gps and enable attendance
      map = if group["category"] == "school" do
        map
        |> Map.put_new("enableGps", k["enableGps"])
        |> Map.put_new("enableAttendance", k["enableAttendance"])
        #check it is class team or not
        if k["class"] do
          map
          |> Map.put_new("isClass", k["class"])
        else
          map
          |> Map.put_new("isClass", false)
        end
      else
        map
      end
      acc ++ [ map ]
    end)
    # group_map = %{
    #   groupId: groupStringId,
    #   name: group["name"],
    #   image: group["avatar"],
    # }
    ################################ FOR KREIS Admin Group & FOR PURE SCHOOL CATEGORY ########################################
    data = if group["category"] == "school" do
      if group["_id"] == decode_object_id("61e00faa7f92c73b7674c054") do
        getIconsForKreisAdminGroup(groupStringId, group, teams_map)
      else
        #check login user can post in group or not
        checkCanPost = GroupRepo.checkUserCanPostInGroup(group["_id"], loginUser["_id"]) #instead, Check login user can post in group outside the loop
        #find is group admin or authorized user
        {details, role, count} = if group["adminId"] == loginUser["_id"] || checkCanPost["canPost"] == true do
          # role = "admin"
          {%{}, "admin", 1}
        else
          #find loginUser have class to take attendance
          #findClass = TeamRepo.findClassTeamForLoginUser(loginUser["_id"], group["_id"])
          findClass = TeamRepo.findClassTeamForLoginUserAsTeacher(loginUser["_id"], group["_id"]) #instead, Firstle check student or staff and get class team for login user outside the loop
          #IO.puts "#{hd(findClass)["teams"]["teamId"]}"
          if length(findClass) > 0 do
            #class found for the login user so, show list of classes
            if length(findClass) == 1 do
              {
                %{
                  "teamId" => encode_object_id(hd(findClass)["teams"]["teamId"]),
                  "teamImage" => hd(findClass)["image"],
                  "teamName" => hd(findClass)["name"],
                  "category" => hd(findClass)["category"]
                },
                "teacher",
                length(findClass)
              }
            else
              {%{}, "teacher", length(findClass)}
              #provide another api to list class teams to take an attendance
            end
          else
            #parent (find kids class for parents)
            findStudent = TeamRepo.getMyKidsClassForSchool(loginUser["_id"], group["_id"])
            #IO.puts "#{findStudent}"
            if length(findStudent) == 1 do
              #directly redirect to this student report
              {
                %{
                  "userId" => encode_object_id(loginUser["_id"]),
                  "teamId" => encode_object_id(hd(findStudent)["teamDetails"]["_id"]),
                  "studentName" => hd(findStudent)["teamDetails"]["name"]
                },
                "parent",
                length(findStudent)
              }
            else
              #redirect to another api to select student
              {%{}, "parent", length(findStudent)}
            end
          end
        end
        group_map_school = %{groupId: groupStringId, name: "Notice Board",
                            image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_52998",}
        ####****members: groupUserCount, postUnseenCount: groupPostUnseenCount}
        icons_map = if group["appName"] == "KREIS" do
          #get dashboard for KREIS school (Eliminate attendance and fees icon and add teachers dairy and hostel stock icons)
          getDashboardIconsForKreisSchoolApp(groupStringId, group, details, role, count)
        else
          getDashboardIconsForSchoolApp(groupStringId, group, details, role, count)
        end
        icons_map ++ [group_map_school] ++  teams_map
      end
    else
      ################################ FOR CONSTITUENCY CATEGORY #####################################
      if group["category"] == "constituency" do
        #replace group name to "Announcement like noticeboard in school"
        group_map_constituency = %{groupId: groupStringId, name: "Announcement",
                            image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/Announcement.jpeg"}
        #static icons (Productivity)
        icons_map = [
          %{ id: 9, groupId: groupStringId, name: "Live Meetings", type: "Video Class", category: group["category"],
              image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/rsz_zoom_live.png"
            },
          %{ id: 1, groupId: groupStringId, name: "Gallery", type: "Gallery",
              image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_56252.jpeg",
              ####****postUnseenCount: galleryUnseenCount
            },
          %{ id: 2, groupId: groupStringId, name: "Calendar", type: "Calendar",
              image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_03_02935.jpeg"
            },
            %{ id: 15, groupId: groupStringId, name: "Issues", type: "Issues",
              image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/Tickets.jpeg", #role: role
            },
            %{ id: 16, groupId: groupStringId, name: "My Family", type: "My Family",
              image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/MyFamily.jpeg"
            },
        ]
        icons_map ++ [group_map_constituency] ++  teams_map
      else
        []
      end
    end
    %{ data: data }
  end

  #for school apps
  defp getDashboardIconsForSchoolApp(groupStringId, group, details, role, count) do
    [
        %{ id: 9, groupId: groupStringId, name: "Live Class", type: "Video Class", category: group["category"],
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/rsz_zoom_live.png"
        },
        %{ id: 11, groupId: groupStringId, name: "Notes & Videos", type: "Recorded Class",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/recorded.png",
          details: details, count: count, role: role
        },
        %{ id: 13, groupId: groupStringId, name: "Home Work", type: "Home Work",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/HomeWork.jpg",
          details: details, count: count, role: role
        },
        %{ id: 14, groupId: groupStringId, name: "Test/Exam", type: "Test",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/exam.png",
          details: details, count: count, role: role
        },
        %{ id: 1, groupId: groupStringId, name: "Gallery", type: "Gallery",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_56252.jpeg",
          ####****postUnseenCount: galleryUnseenCount
        },
        %{ id: 2, groupId: groupStringId, name: "Calendar", type: "Calendar",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_03_02935.jpeg"
        },
        %{ id: 3, groupId: groupStringId, name: "Time Table", type: "Time Table",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_56228",
          details: details, count: count, role: role, #postUnseenCount: timeTableUnseenCount
        },
        %{ id: 4, groupId: groupStringId, name: "Messages", type: "Chat", role: role,
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_03_01281",
          ####****postUnseenCount: messageUnseenCount
        },
        %{ id: 10, groupId: groupStringId, name: "Library", type: "E-Books",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_55794",
          details: details, count: count, role: role
        },
        %{ id: 12, groupId: groupStringId, name: "Fee Payment", type: "Fees",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/fee.png",
          details: details, count: count, role: role
        },
        %{ id: 5, groupId: groupStringId, name: "Vendor Connect", type: "Vendor Connect",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_51351", role: role
        },
        %{ id: 6, groupId: groupStringId, name: "Rules", type: "Code Of Conduct",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_57735" , role: role
        },
        %{ id: 7, groupId: groupStringId, name: "Attendance", type: "Attendance",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_50536",
          details: details, count: count, role: role
        },
        %{ id: 8, groupId: groupStringId, name: "Marks Card", type: "Marks Card",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_58528",
          details: details, count: count, role: role
        },
    ]
  end


  defp getDashboardIconsForKreisSchoolApp(groupStringId, group, details, role, count) do
    icons_map = [
        %{ id: 9, groupId: groupStringId, name: "Live Class", type: "Video Class", category: group["category"],
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/rsz_zoom_live.png"
        },
        %{ id: 11, groupId: groupStringId, name: "Notes & Videos", type: "Recorded Class",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/recorded.png",
          details: details, count: count, role: role
        },
        %{ id: 13, groupId: groupStringId, name: "Home Work", type: "Home Work",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/HomeWork.jpg",
          details: details, count: count, role: role
        },
        %{ id: 14, groupId: groupStringId, name: "Test/Exam", type: "Test",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/exam.png",
          details: details, count: count, role: role
        },
        %{ id: 1, groupId: groupStringId, name: "Gallery", type: "Gallery",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_56252.jpeg",
          ####****postUnseenCount: galleryUnseenCount
        },
        %{ id: 2, groupId: groupStringId, name: "Calendar", type: "Calendar",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_03_02935.jpeg"
        },
        %{ id: 3, groupId: groupStringId, name: "Time Table", type: "Time Table",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_56228",
          details: details, count: count, role: role, #postUnseenCount: timeTableUnseenCount
        },
        %{ id: 4, groupId: groupStringId, name: "Messages", type: "Chat", role: role,
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_03_01281",
          ####****postUnseenCount: messageUnseenCount
        },
        %{ id: 10, groupId: groupStringId, name: "Library", type: "E-Books",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_55794",
          details: details, count: count, role: role
        },
        ##%{ id: 12, groupId: groupStringId, name: "Fee Payment", type: "Fees",
        ##  image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/fee.png",
        ##  details: details, count: count, role: role
        ##},
        %{ id: 5, groupId: groupStringId, name: "Vendor Connect", type: "Vendor Connect",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_51351", role: role
        },
        %{ id: 6, groupId: groupStringId, name: "Rules", type: "Code Of Conduct",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_57735" , role: role
        },
        ##%{ id: 7, groupId: groupStringId, name: "Attendance", type: "Attendance",
        ##  image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_50536",
        ##  details: details, count: count, role: role
        ##},
        %{ id: 8, groupId: groupStringId, name: "Marks Card", type: "Marks Card",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_58528",
          details: details, count: count, role: role
        },
    ]
    icons_map = if role == "admin" || role == "teacher" do
      teacherDairyMap = [%{ id: 17, groupId: groupStringId, name: "Teacher's Diary", type: "Teacher's Dairy",
         image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/school-diary-icon-modified.png",
         details: details, count: count, role: role
       }]
       icons_map ++ teacherDairyMap
    else
      icons_map
    end
    icons_map = if role == "admin" do
      hostelStockMap = [%{ id: 18, groupId: groupStringId, name: "Hostel Stock", type: "Hostel Stock",
         image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/hospital-icon-modified.png",
         details: details, count: count, role: role
       }]
       icons_map ++ hostelStockMap
    else
      icons_map
    end
    icons_map
  end



  defp getIconsForKreisAdminGroup(groupStringId, _group, teams_map) do
    group_map_school = %{groupId: groupStringId, name: "Notice Board",
                        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_52998",}
    ####****members: groupUserCount, postUnseenCount: groupPostUnseenCount}
    icons_map = [
        %{ id: 1, groupId: groupStringId, name: "Gallery", type: "Gallery",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_56252.jpeg",
          ####****postUnseenCount: galleryUnseenCount
        },
        %{ id: 2, groupId: groupStringId, name: "Calendar", type: "Calendar",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_03_02935.jpeg"
        },
        %{ id: 4, groupId: groupStringId, name: "Messages", type: "Chat", #role: role,
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_03_01281",
          ####****postUnseenCount: messageUnseenCount
        },
    ]
    icons_map ++ [group_map_school] ++  teams_map
    #IO.puts "#{map}"
    #%{ data: final_list }
  end




  #to list all teams of group for the user
  # with FIREBASE integration
  def render("video_conference_teams.json", %{ teams: teams, loginUser: loginUser, group: group }) do
    groupStringId = encode_object_id(group["_id"])
    teams_map = Enum.reduce(teams, [], fn k, acc ->
      map =  %{
        groupId: groupStringId,
        teamId: encode_object_id(k["teams"]["teamId"]),
        name: k["teamDetails"]["name"],
        ####phone: k["teamDetails"]["phone"],
        ####image: k["teamDetails"]["image"],
        #category: k["teamDetails"]["category"],
        canPost: k["teams"]["allowedToAddPost"],
        #canAddComment: k["teams"]["allowedToAddComment"],
        #jitsiToken: k["teamDetails"]["jitsiToken"],
        jitsiToken: k["teamDetails"]["zoomMeetingId"],  # remove colon (:) from string
        ####alreadyOnJitsiLive: k["teamDetails"]["alreadyOnJitsiLive"],
        zoomKey: k["teamDetails"]["zoomKey"],
        zoomSecret: k["teamDetails"]["zoomSecret"],
        zoomMeetingPassword: k["teamDetails"]["zoomMeetingPassword"],
        #meetingIdOnLive: encode_object_id(k["teamDetails"]["meetingIdOnLive"])
      }
      ####if !is_nil(k["teamDetails"]["meetingIdOnLive"]) do
      ####  map = Map.put_new(map, "meetingIdOnLive", encode_object_id(k["teamDetails"]["meetingIdOnLive"]))
      ####end
      #if canPost=true(teacher) then provide zoom mail and password
      map = if k["teams"]["allowedToAddPost"] == true do
        map
        |> Map.put_new("zoomMail", k["teamDetails"]["zoomMail"])
        |> Map.put_new("zoomPassword", k["teamDetails"]["zoomPassword"])
      end
      #check alreadyJitsiOnLive : true
      ####if k["teamDetails"]["alreadyOnJitsiLive"] == true do
      ####  #check meeting createdBy login user
      ####  if k["teamDetails"]["jitsiMeetCreatedBy"] == loginUser["_id"] do
      ####    meetingCreated = true
      ####  else
      ####    meetingCreated = false
      ####  end
        #get created by user name
        ####userName = UserRepo.find_user_by_id(k["teamDetails"]["jitsiMeetCreatedBy"])
        ####map = map
        ####|> Map.put_new("meetingCreatedBy", meetingCreated)
        ####|> Map.put_new("meetingCreatedByName", userName["name"])
      ####end
      #check login user id is in student_database
      {:ok, checkLoginUserIsStudent} = TeamRepo.checkLoginUserIsStudent(group["_id"], k["teams"]["teamId"], loginUser["_id"]) #Instead, check and get zoomName for login user outside the loop
      map = if checkLoginUserIsStudent > 0 do
        #get name from student_database
        getStudentsName = TeamRepo.getStudentName(loginUser["_id"], group["_id"], k["teams"]["teamId"]) # instead, get zoomName for loginUser outside the loop
        getNameinList = Enum.reduce(getStudentsName, [], fn k, acc ->
          acc ++ [k["name"]]
        end)
        map
        |> Map.put_new("zoomName", getNameinList)
      else
        #get user profile name
        map
        |> Map.put_new("zoomName", [loginUser["name"]])
        |> Map.put_new("meetingCreatedByName", loginUser["name"])
      end

       acc ++ [ map ]
    end)

    %{ data: teams_map }
  end




  def render("myTeams.json", %{ myTeam: myTeams, groupId: groupObjectId }) do
    result = Enum.reduce(myTeams, [], fn k, acc ->
      {:ok, teamMembersCount} = TeamRepo.getCreatedTeamMembersCount(groupObjectId, k["_id"])
      map = %{
        "teamId" => encode_object_id(k["_id"]),
        "name" => k["name"],
        "image" => k["image"],
        "members" => teamMembersCount,
        "allowedToAddTeamPost" => true,
        "allowedToAddTeamPostComment" => true,
      }

      acc ++ [map]
    end)
    %{ data: result }
  end



  def render("myClassTeams.json", %{ myClassTeam: myClassTeam, groupObjectId: groupObjectId }) do
    result = Enum.reduce(myClassTeam, [], fn k, acc ->
      {:ok, teamStudentsCount} = AdminRepo.getTotalStudentsCountInStudentRegister(k["teams"]["teamId"], groupObjectId)
      map = %{
        "teamId" => encode_object_id(k["teams"]["teamId"]),
        "name" => k["teamDetails"]["name"],
        "image" => k["teamDetails"]["image"],
        "studentCount" => teamStudentsCount,
        #"enableAttendance" => k["enableAttendance"],
        "category" => k["teamDetails"]["category"]
      }

      acc ++ [map]
    end)
    #########temporary
    # result = [%{"name" => "Staffs"}] ++ result
    %{ data: result }
  end


  def render("myKids.json", %{ myKids: myKids, groupObjectId: groupObjectId }) do
    result = Enum.reduce(myKids, [], fn k, acc ->
      map = %{
        "userId" => encode_object_id(k["userId"]),
        "teamId" => encode_object_id(k["teamId"]),
        "groupId" => encode_object_id(groupObjectId),
        "name" => k["name"],
        "image" => k["image"],
        "rollNumber" => k["rollNumber"],
        #"className" => k["teamDetails"]["name"]
        "className" => k["name"],
      }

      acc ++ [map]
    end)
    #########temporary
    ##result = [%{"name" => "Staffs"}] ++ result
    %{ data: result }
  end


  def render("myKidsClass.json", %{ myKidsClass: myKidsClass }) do
    result = Enum.reduce(myKidsClass, [], fn k, acc ->
      map = %{
        "userId" => encode_object_id(k["userId"]),
        "teamId" => encode_object_id(k["teamDetails"]["_id"]),
        "groupId" => encode_object_id(k["groupId"]),
        #"name" => k["studentDbDetails"]["name"]<>" ("<>k["teamDetails"]["name"]<>")",
        "name" => k["teamDetails"]["name"],
        "image" => k["teamDetails"]["image"],
        #"className" => k["teamDetails"]["name"],
      }

      acc ++ [map]
    end)
    #########temporary
    ##result = [%{"name" => "Staffs"}] ++ result
    %{ data: result }
  end


  #to list all teams of group for the user
  # TEAM INDEX for school - FULL Version
  def render("group_home.json", %{ teams: teams, loginUser: loginUser, group: group }) do
    cond do
      group["category"] == "school" ->
        # # render(conn, "group_school_home.json", [teams: teams, loginUser: loginUser, group: group])
        getSchoolHomePage(teams, loginUser, group)
      group["category"] == "constituency" ->
        # render(conn, "group_constituency_home.json", [teams: teams, loginUser: loginUser, group: group])
        getConstituencyHomePage(teams, loginUser, group)
      group["category"] == "community" ->
        # render(conn, "group_community_home.json", [teams: teams, loginUser: loginUser, group: group])
        getCommunityHomePage(teams, loginUser, group)
      true ->
        # render(conn, "team_index_new.json", [teams: teams, loginUser: loginUser, group: group])
        getGruppieHomePage(teams, loginUser, group)
    end
  end




  #to list all teams of group for the user
  # TEAM INDEX for school - FULL Version
  def getSchoolHomePage(teams, loginUser, group) do
    #find role of loginUser
    roleCountDetails = findRoleForSchoolApp(group, loginUser)
    accountantDetails = checkAccountant(group, loginUser)
    examinerDetails = checkIsExaminer(group, loginUser)
    role = roleCountDetails.role
    count = roleCountDetails.count
    details = roleCountDetails.details
    accountant = accountantDetails.accountant
    examiner = examinerDetails.examiner
    # 0. Get all registers for only super admin
    registersMap = if role == "admin" do
      # register icons map
      [getIconsForSchoolRegisters(group, role, count, details)]
    else
      []
    end
    cond do
      group["appName"] == "KREIS" ->
        #get dashboard or home page for KREIS app
        # 1. Get Daily activities feature map
        dailyActivitiesMap = getIconsForDailyActivitiesForKreis(group, role, count, details)
        # 2. Get communication feature map
        communicationMap = getIconsForCommunicationForKreis(group, teams, role, count, loginUser["_id"])
        # 3. Other activities feature map
        otherActivityMap = getIconsForOtherActivitiesForKreis(group, role, count, details, accountant, examiner)
        # 4. admission features
        # admissionMap = getIconsForAdmissionActivities(group, role, count, details)
        # %{ data: [dailyActivitiesMap] ++ [communicationMap] ++ [otherActivityMap] ++ [admissionMap]}
        %{ data: registersMap ++ [dailyActivitiesMap] ++ [communicationMap] ++ [otherActivityMap]}
        ##### %{ data: [dailyActivitiesMap] ++ [communicationMap] ++ [otherActivityMap]}
      group["category"] == "school" && group["subCategory"] == "sports" ->
        #get dashboard activities for sports academy
        # 1. get academies activity
        academicActivityMap = getIconsForAcademyActivities(group, teams, role, count, loginUser["_id"])
        # 2. Get productivity items
        productivityActivityMap = getIconsForAcademyProductivityActivities(group, role, count, details, accountant)
        %{ data: [academicActivityMap] ++ [productivityActivityMap]}
      true ->
        #get all other schools home page
        # 1. Get Daily activities feature map
        dailyActivitiesMap = getIconsForDailyActivities(group, role, count, details)
        # 2. Get communication feature map
        communicationMap = getIconsForCommunication(group, teams, role, count, loginUser["_id"])
        # 3. Other activities feature map
        otherActivityMap = getIconsForOtherActivities(group, role, count, details, accountant, examiner)
        # 4. Social media features map
        socialMediaActivityMap = getIconsForSocialMediaActivities(group, role, count, details)
        # 5. admission features
        # admissionMap = getIconsForAdmissionActivities(group, role, count, details)
        # %{ data: [dailyActivitiesMap] ++ [communicationMap] ++ [otherActivityMap] ++ [admissionMap]}
        %{ data: registersMap ++ [dailyActivitiesMap] ++ [communicationMap] ++ [otherActivityMap] ++ [socialMediaActivityMap]}
        ##### %{ data: [dailyActivitiesMap] ++ [communicationMap] ++ [otherActivityMap]}
    end
  end

  defp getIconsForSocialMediaActivities(group, role, _count, _details) do
    groupStringId = encode_object_id(group["_id"])
    icons_map = [
      # %{ id: 31, groupId: groupStringId, name: "School Website", type: "School Website",
      #   #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Live%20Classes.png"
      #   image: group["image"],
      #   kanName: "ಶಾಲೆಯ ವೆಬ್‌ಸೈಟ್", link: group["schoolWebsite"], role: role
      # },
      %{ id: 32, groupId: groupStringId, name: "Facebook", type: "Facebook",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Live%20Classes.png"
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Facebook.jpeg",
        kanName: "ಫೇಸ್ಬುಕ್", link: group["facebookId"], role: role
      },
      %{ id: 34, groupId: groupStringId, name: "Twitter", type: "Twitter",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Live%20Classes.png"
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Twitter-Emblem.png",
        kanName: "ಟ್ವಿಟರ್", link: group["twitterId"], role: role
      },
      %{ id: 37, groupId: groupStringId, name: "Youtube", type: "Youtube",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Live%20Classes.png"
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/youtube.png",
        kanName: "ಯೌಟ್ಯೂಬ್", link: group["youtubeId"], role: role
      },
    ]
    icons_map = if group["category"] == "school" do
      websiteMap = [%{ id: 31, groupId: groupStringId, name: "School Website", type: "School Website",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Live%20Classes.png"
        image: group["image"],
        kanName: "ಶಾಲೆಯ ವೆಬ್‌ಸೈಟ್", link: group["schoolWebsite"], role: role
      },
      %{ id: 33, groupId: groupStringId, name: "Instagram", type: "Instagram",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Live%20Classes.png"
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Instagram.jpeg",
        kanName: "ಇನ್ಸ್ಟಾಗ್ರಾಮ್", link: group["instagramId"], role: role
      }]
      websiteMap ++ icons_map
    else
      websiteMap = [%{ id: 31, groupId: groupStringId, name: "Website", type: "School Website",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Live%20Classes.png"
        image: group["image"],
        kanName: "ವೆಬ್‌ಸೈಟ್", link: group["schoolWebsite"], role: role
      }]
      websiteMap ++ icons_map
    end
    #daily activity feature icons
    %{
      activity: "Social Media",
      featureIcons: icons_map,
      kanActivity: "ಸಾಮಾಜಿಕ ಮಾಧ್ಯಮ"
    }
  end

  defp getIconsForSchoolRegisters(group, _role, _count, _details) do
    groupStringId = encode_object_id(group["_id"])
    icons_map = [
      %{ id: 22, groupId: groupStringId, name: "Staff Register", type: "Staff Register",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Live%20Classes.png"
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/staffReg.jpeg",
        kanName: "ಸ್ಟಾಫ್ ರಿಜಿಸ್ಟರ್"
      },
      %{ id: 23, groupId: groupStringId, name: "Subject Register", type: "Subject Register",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Live%20Classes.png"
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/depositphotos_48843831-stock-photo-text-file-sign-icon-add%20%281%29.png",
        kanName: "ಸಬ್ಜೆಕ್ಟ್ ರಿಜಿಸ್ಟರ್"
      },
      %{ id: 24, groupId: groupStringId, name: "Student Register", type: "Student Register",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Live%20Classes.png"
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/studentRegister.png",
        kanName: "ಸ್ಟೂಡೆಂಟ್ ರಿಜಿಸ್ಟರ್"
      },
      # %{ id: 36, groupId: groupStringId, name: "Reports", type: "Reports",
      #   #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Live%20Classes.png"
      #   image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/studentRegister.png",
      #   kanName: "ಸ್ಟೂಡೆಂಟ್ ರಿಜಿಸ್ಟರ್"
      # },
      # %{ id: 26, groupId: groupStringId, name: "Bus Register", type: "Bus Register",
      #   #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Live%20Classes.png"
      #   image: "",
      #   kanName: "ಬಸ್ ರಿಜಿಸ್ಟರ್"
      # }
      %{ id: 26, groupId: groupStringId, name: "Reports", type: "Reports",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Live%20Classes.png"
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/dashboard%20%20%282%29.png",
        kanName: "ವರದಿಗಳು"
      },
      %{ id: 25, groupId: groupStringId, name: "Staff Attendance", type: "Staff Attendance",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Live%20Classes.png"
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/StaffAttendance.png",
        kanName: "ಸ್ಟಾಫ್ ಅಟೆಂಡೆನ್ಸ್"
      },
    ]
    #daily activity feature icons
    %{
      activity: "Dashboard, Register & Reports",
      featureIcons: icons_map,
      kanActivity: "ಡ್ಯಾಶ್‌ಬೋರ್ಡ್ & ನೋಂದಣಿ"
    }
  end

  # defp getIconsForAdmissionActivities(group, role, count, details) do
  #   groupStringId = encode_object_id(group["_id"])
  #   icons_map = [
  #     %{ id: 20, groupId: groupStringId, name: "Course", type: "Course", category: group["category"],
  #       #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Live%20Classes.png"
  #       image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/Courses.png",
  #       details: details, count: count, role: role,
  #       kanName: "ಕೋರ್ಸ್"
  #     }
  #   ]
  #   #Admission feature icons
  #   admissionActivitiesMap = %{
  #     activity: "Admission",
  #     featureIcons: icons_map,
  #     kanActivity: "ಅಡ್ಮಿಶನ್"
  #   }
  # end

  #private function to get list of other activities icons
  defp getIconsForDailyActivities(group, role, count, details) do
    groupStringId = encode_object_id(group["_id"])
    icons_map = [
      %{ id: 7, groupId: groupStringId, name: "Attendance", type: "Attendance",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Student%20Attendance.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_50536",
        details: details, count: count, role: role,
        kanName: "ಅಟೆಂಡೆನ್ಸ್"
      },
      %{ id: 11, groupId: groupStringId, name: "Notes & Videos", type: "Recorded Class",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Notes%20and%20videos.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/recorded.png",
        details: details, count: count, role: role,
        kanName: "ನೋಟ್ಸ್ ಮತ್ತು ವೀಡಿಯೋಸ್"
      },
      %{ id: 13, groupId: groupStringId, name: "Home Work", type: "Home Work",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Home%20works.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/HomeWork.jpg",
        details: details, count: count, role: role,
        kanName: "ಹೋಂ ವರ್ಕ್"
      },
      %{ id: 3, groupId: groupStringId, name: "Time Table", type: "Time Table",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Time%20Table.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_56228",
        details: details, count: count, role: role, #postUnseenCount: timeTableUnseenCount
        kanName: "ಟೈಮ್ ಟೇಬಲ್"
      },
      %{ id: 9, groupId: groupStringId, name: "Live Class", type: "Video Class", category: group["category"],
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Live%20Classes.png"
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/rsz_zoom_live.png",
        kanName: "ಲೈವ್ ತರಗತಿ"
      },
      %{ id: 21, groupId: groupStringId, name: "Syllabus Tracker", type: "Syllabus Tracker",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/1%20school.png" , role: role
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/SyllabusTracker.png",
        details: details, count: count, role: role,
        kanName: "ಪಠ್ಯಕ್ರಮ ಟ್ರ್ಯಾಕರ್"
      },
      # %{ id: 28, groupId: groupStringId, name: "Quiz", type: "MCQ's",
      #   #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/1%20school.png" , role: role
      #   image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/QUIZ_New.png",
      #   details: details, count: count, role: role,
      #   kanName: "MCQ's"
      # },
    ]
    #daily activity feature icons
    %{
      activity: "Daily Activities",
      featureIcons: icons_map,
      kanActivity: "ದೈನಂದಿನ ಚಟುವಟಿಕೆಗಳು"
    }
  end

  #private function to get list of other activities icons
  defp getIconsForDailyActivitiesForKreis(group, role, count, details) do
    groupStringId = encode_object_id(group["_id"])
    icons_map = [
      %{ id: 7, groupId: groupStringId, name: "Attendance", type: "Attendance",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Student%20Attendance.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_50536",
        details: details, count: count, role: role,
        kanName: "ಅಟೆಂಡೆನ್ಸ್"
      },
      %{ id: 11, groupId: groupStringId, name: "Notes & Videos", type: "Recorded Class",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Notes%20and%20videos.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/recorded.png",
        details: details, count: count, role: role,
        kanName: "ನೋಟ್ಸ್ ಮತ್ತು ವೀಡಿಯೋಸ್"
      },
      # %{ id: 13, groupId: groupStringId, name: "Home Work", type: "Home Work",
      #   #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Home%20works.png",
      #   image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/HomeWork.jpg",
      #   details: details, count: count, role: role,
      #   kanName: "ಹೋಂ ವರ್ಕ್"
      # },
      %{ id: 3, groupId: groupStringId, name: "Time Table", type: "Time Table",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Time%20Table.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_56228",
        details: details, count: count, role: role, #postUnseenCount: timeTableUnseenCount
        kanName: "ಟೈಮ್ ಟೇಬಲ್"
      },
      # %{ id: 9, groupId: groupStringId, name: "Live Class", type: "Video Class", category: group["category"],
      #   #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Live%20Classes.png"
      #   image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/rsz_zoom_live.png",
      #   kanName: "ಲೈವ್ ತರಗತಿ"
      # },
      %{ id: 21, groupId: groupStringId, name: "Syllabus Tracker", type: "Syllabus Tracker",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/1%20school.png" , role: role
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/SyllabusTracker.png",
        details: details, count: count, role: role,
        kanName: "ಪಠ್ಯಕ್ರಮ ಟ್ರ್ಯಾಕರ್"
      },
    ]
    #daily activity feature icons
    %{
      activity: "Daily Activities",
      featureIcons: icons_map,
      kanActivity: "ದೈನಂದಿನ ಚಟುವಟಿಕೆಗಳು"
    }
  end

  #private function to get list of daily activities icons
  defp getIconsForOtherActivities(group, role, count, details, accountant, examiner) do
    groupStringId = encode_object_id(group["_id"])
    icons_map = [
      %{ id: 14, groupId: groupStringId, name: "Test/Exam", type: "Test",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/8%20Test%20Exam.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/exam.png",
        details: details, count: count, role: role, examiner: examiner,
        kanName: "ಪರೀಕ್ಷೆ"
      },
      %{ id: 8, groupId: groupStringId, name: "Marks Card", type: "Marks Card",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Progress%20report.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_58528",
        details: details, count: count, role: role, examiner: examiner,
        kanName: "ಮಾರ್ಕ್ಸ್ ಕಾರ್ಡ್"
      },
      %{ id: 1, groupId: groupStringId, name: "Gallery", type: "Gallery",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/15%20Gallery.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_56252.jpeg",
        kanName: "ಗ್ಯಾಲರಿ",
        ####****postUnseenCount: galleryUnseenCount
      },
      %{ id: 2, groupId: groupStringId, name: "Calendar", type: "Calendar",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/14%20Calender.png"
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_03_02935.jpeg",
        kanName: "ಕ್ಯಾಲೆಂಡರ್"
      },
      %{ id: 10, groupId: groupStringId, name: "Library", type: "E-Books",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Library.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_55794",
        details: details, count: count, role: role,
        kanName: "ಗ್ರಂಥಾಲಯ"
      },
      %{ id: 12, groupId: groupStringId, name: "Fee Payment", type: "Fees",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/3%20Fee%20management.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/fee.png",
        details: details, count: count, role: role, accountant: accountant,  parentAllowedToPayFee: false, #parentAllowedToPayFee: group["parentAllowedToPayFee"],
        kanName: "ಶುಲ್ಕ ಪಾವತಿ"
      },
      %{ id: 5, groupId: groupStringId, name: "Vendor Connect", type: "Vendor Connect",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/16%20Vendor%20Contact.png", role: role
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_51351", role: role,
        kanName: "ಮಾರಾಟಗಾರರ ಸಂಪರ್ಕ"
      },
      %{ id: 35, groupId: groupStringId, name: "Suggestion Box", type: "Suggestion Box",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/1%20school.png" , role: role
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/Suggestion%20Box.png" , role: role,
        kanName: "ಸಲಹೆ ಪೆಟ್ಟಿಗೆ"
      },
      %{ id: 6, groupId: groupStringId, name: "About Us", type: "Code Of Conduct",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/1%20school.png" , role: role
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_57735" , role: role,
        kanName: "ನಮ್ಮ ಬಗ್ಗೆ"
      },
    ]
    #daily activity feature icons
    %{
      activity: "Other Activities",
      featureIcons: icons_map,
      kanActivity: "ಇತರೆ ಚಟುವಟಿಕೆಗಳು"
    }
  end

  #private function to get list of daily activities icons
  defp getIconsForOtherActivitiesForKreis(group, role, count, details, _accountant, examiner) do
    groupStringId = encode_object_id(group["_id"])
    icons_map = [
      %{ id: 14, groupId: groupStringId, name: "Test/Exam", type: "Test",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/8%20Test%20Exam.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/exam.png",
        details: details, count: count, role: role,
        kanName: "ಪರೀಕ್ಷೆ"
      },
      %{ id: 8, groupId: groupStringId, name: "Marks Card", type: "Marks Card",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Progress%20report.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_58528",
        details: details, count: count, role: role, examiner: examiner,
        kanName: "ಮಾರ್ಕ್ಸ್ ಕಾರ್ಡ್"
      },
      %{ id: 1, groupId: groupStringId, name: "Gallery", type: "Gallery",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/15%20Gallery.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_56252.jpeg",
        kanName: "ಗ್ಯಾಲರಿ",
        ####****postUnseenCount: galleryUnseenCount
      },
      %{ id: 2, groupId: groupStringId, name: "Calendar", type: "Calendar",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/14%20Calender.png"
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_03_02935.jpeg",
        kanName: "ಕ್ಯಾಲೆಂಡರ್"
      },
      %{ id: 10, groupId: groupStringId, name: "E-Books", type: "E-Books",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Library.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_55794",
        details: details, count: count, role: role,
        kanName: "ಗ್ರಂಥಾಲಯ"
      },
      # %{ id: 12, groupId: groupStringId, name: "Fee Payment", type: "Fees",
      #   #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/3%20Fee%20management.png",
      #   image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/fee.png",
      #   details: details, count: count, role: role, accountant: accountant,
      #   kanName: "ಶುಲ್ಕ ಪಾವತಿ"
      # },
      # %{ id: 5, groupId: groupStringId, name: "Vendor Connect", type: "Vendor Connect",
      #   #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/16%20Vendor%20Contact.png", role: role
      #   image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_51351", role: role,
      #   kanName: "ಮಾರಾಟಗಾರರ ಸಂಪರ್ಕ"
      # },
      # %{ id: 6, groupId: groupStringId, name: "About Us", type: "Code Of Conduct",
      #   #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/1%20school.png" , role: role
      #   image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_57735" , role: role,
      #   kanName: "ನಮ್ಮ ಬಗ್ಗೆ"
      # },
    ]
    #daily activity feature icons
    %{
      activity: "Other Activities",
      featureIcons: icons_map,
      kanActivity: "ಇತರೆ ಚಟುವಟಿಕೆಗಳು"
    }
  end


  defp getIconsForCommunication(group, teams, role, count, loginUserId) do
    teams_map_list = Enum.reduce(teams, [], fn k, acc ->
      ##{:ok, teamMembersCount} = TeamRepo.getCreatedTeamMembersCount(group["_id"], k["teamId"])   ##Instead, get team members count of all teams fot this group and concatenate inside for loop
      map =  %{
        "groupId" => encode_object_id(group["_id"]),
        "teamId" => encode_object_id(k["teamId"]),
        "name" =>  k["name"],
        "phone" => k["phone"],
        "image" => k["image"],
        "category" => k["category"],
        #"members" => teamMembersCount,
        "members" => 0,
        "isTeamAdmin" => k["isTeamAdmin"],
        "allowTeamPostAll" => k["allowedToAddPost"],
        "allowTeamPostCommentAll" => k["allowedToAddComment"],
        "canAddUser" => k["isTeamAdmin"]
      }
      #check login user is admin or authorized user
      # if role == "admin" do
      #   map = map
      #   |> Map.put("allowTeamPostAll", true)
      #   |> Map.put("allowTeamPostCommentAll", true)
      # end
      #if category school then provide enable gps and enable attendance
      map = map
      |> Map.put_new("enableGps", k["enableGps"])
      |> Map.put_new("enableAttendance", k["enableAttendance"])
      #check it is class team or not
      map = if k["class"] do
        map
        |> Map.put_new("isClass", k["class"])
      else
        map
        |> Map.put_new("isClass", false)
      end
      acc ++ [ map ]
    end)
    #get all class teams for admin
    allClassTeams = if role == "admin" do
      #get all class teams for admin
      getAllClassTeamsForAdmin(group["_id"], loginUserId)
    else
      []
    end
    #make unique teamIds
    homeTeamsList = teams_map_list ++ allClassTeams
    |> Enum.uniq_by(& &1["teamId"])
    |> Enum.sort_by(& String.downcase(&1["name"]))
    #group map (Notice board)
    group_map_list = [
      %{ groupId: encode_object_id(group["_id"]), name: "Notice Board", type: "Broadcast",
         #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Notice%20Board.png"
         image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_52998",
         kanName: "ನೋಟೀಸ್ ಬೋರ್ಡ್"
        }
    ]
    #individual message icon map
    message_map_list = [
       %{ id: 4, groupId: encode_object_id(group["_id"]), name: "Messages", type: "Chat", role: role, count: count,
          #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Communication%20and%20Messages.png",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_03_01281",
          kanName: "ಸಂದೇಶಗಳು"
        }
    ]
    # final list
    communicationMap = group_map_list ++ homeTeamsList ++ message_map_list
    #communication feature icons
    %{
      activity: "Communication",
      featureIcons: communicationMap,
      kanActivity: "ಸಂವಹನ"
    }
  end

  defp getIconsForAcademyActivities(group, teams, role, count, loginUserId) do
    teams_map_list = Enum.reduce(teams, [], fn k, acc ->
      ##{:ok, teamMembersCount} = TeamRepo.getCreatedTeamMembersCount(group["_id"], k["teamId"])   ##Instead, get team members count of all teams fot this group and concatenate inside for loop
      map =  %{
        "groupId" => encode_object_id(group["_id"]),
        "teamId" => encode_object_id(k["teamId"]),
        "name" =>  k["name"],
        "phone" => k["phone"],
        "image" => k["image"],
        "category" => k["category"],
        #"members" => teamMembersCount,
        "members" => 0,
        "isTeamAdmin" => k["isTeamAdmin"],
        "allowTeamPostAll" => k["allowedToAddPost"],
        "allowTeamPostCommentAll" => k["allowedToAddComment"],
        "canAddUser" => k["isTeamAdmin"]
      }
      #if category school then provide enable gps and enable attendance
      map = map
      |> Map.put_new("enableGps", k["enableGps"])
      |> Map.put_new("enableAttendance", k["enableAttendance"])
      #check it is class team or not
      map = if k["class"] do
        map
        |> Map.put_new("isClass", k["class"])
      else
        map
        |> Map.put_new("isClass", false)
      end
      acc ++ [ map ]
    end)
    #get all class teams for admin
    allClassTeams = if role == "admin" do
      #get all class teams for admin
      getAllClassTeamsForAdmin(group["_id"], loginUserId)
    else
      []
    end
    #make unique teamIds
    homeTeamsList = teams_map_list ++ allClassTeams
    |> Enum.uniq_by(& &1["teamId"])
    |> Enum.sort_by(& String.downcase(&1["name"]))
    #group map (Notice board)
    group_map_list = [
      %{ groupId: encode_object_id(group["_id"]), name: "Announcement", type: "Broadcast",
         #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Notice%20Board.png"
         image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/announcement.png",
         kanName: "ಅನೌನ್ಸ್ಮೆಂಟ್"
        }
    ]
    #individual message icon map
    message_map_list = [
       %{ id: 4, groupId: encode_object_id(group["_id"]), name: "Messages", type: "Chat", role: role, count: count,
          #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Communication%20and%20Messages.png",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_03_01281",
          kanName: "ಸಂದೇಶಗಳು"
        }
    ]
    # final list
    communicationMap = group_map_list ++ homeTeamsList ++ message_map_list
    #communication feature icons
    %{
      activity: "Academies",
      featureIcons: communicationMap,
      kanActivity: "ಅಕಾಡೆಮಿಗಳು"
    }
  end

  defp getIconsForAcademyProductivityActivities(group, role, count, details, accountant) do
    groupStringId = encode_object_id(group["_id"])
    icons_map = [
      %{ id: 7, groupId: groupStringId, name: "Attendance", type: "Attendance",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Student%20Attendance.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_50536",
        details: details, count: count, role: role,
        kanName: "ಅಟೆಂಡೆನ್ಸ್"
      },
      %{ id: 12, groupId: groupStringId, name: "Fees", type: "Fees",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/3%20Fee%20management.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Fee.png",
        details: details, count: count, role: role, accountant: accountant,
        kanName: "ಶುಲ್ಕ ಪಾವತಿ"
      },
      %{ id: 1, groupId: groupStringId, name: "Gallery", type: "Gallery",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/15%20Gallery.png",
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_56252.jpeg",
        kanName: "ಗ್ಯಾಲರಿ",
        ####****postUnseenCount: galleryUnseenCount
      },
      %{ id: 2, groupId: groupStringId, name: "Calendar", type: "Calendar",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/14%20Calender.png"
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_03_02935.jpeg",
        kanName: "ಕ್ಯಾಲೆಂಡರ್"
      },
      %{ id: 5, groupId: groupStringId, name: "Vendor Connect", type: "Vendor Connect",
        #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/16%20Vendor%20Contact.png", role: role
        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_51351", role: role,
        kanName: "ಮಾರಾಟಗಾರರ ಸಂಪರ್ಕ"
      },
      # %{ id: 6, groupId: groupStringId, name: "About Us", type: "Code Of Conduct",
      #   #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/1%20school.png" , role: role
      #   image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_57735" , role: role,
      #   kanName: "ನಮ್ಮ ಬಗ್ಗೆ"
      # },
    ]
    #daily activity feature icons
    %{
      activity: "Productivity",
      featureIcons: icons_map,
      kanActivity: "ಪ್ರೊಡಕ್ಟಿವಿಟಿ"
    }
  end

  defp getIconsForCommunicationForKreis(group, teams, role, count, loginUserId) do
    teams_map_list = Enum.reduce(teams, [], fn k, acc ->
      ##{:ok, teamMembersCount} = TeamRepo.getCreatedTeamMembersCount(group["_id"], k["teamId"])   ##Instead, get team members count of all teams fot this group and concatenate inside for loop
      map =  %{
        "groupId" => encode_object_id(group["_id"]),
        "teamId" => encode_object_id(k["teamId"]),
        "name" =>  k["name"],
        "phone" => k["phone"],
        "image" => k["image"],
        "category" => k["category"],
        #"members" => teamMembersCount,
        "members" => 0,
        "isTeamAdmin" => k["isTeamAdmin"],
        "allowTeamPostAll" => k["allowedToAddPost"],
        "allowTeamPostCommentAll" => k["allowedToAddComment"],
        "canAddUser" => k["isTeamAdmin"]
      }
      #if category school then provide enable gps and enable attendance
      map = map
      |> Map.put_new("enableGps", k["enableGps"])
      |> Map.put_new("enableAttendance", k["enableAttendance"])
      #check it is class team or not
      map = if k["class"] do
        map
        |> Map.put_new("isClass", k["class"])
      else
        map
        |> Map.put_new("isClass", false)
      end
      acc ++ [ map ]
    end)
    #get all class teams for admin
    allClassTeams = if role == "admin" do
      #get all class teams for admin
      getAllClassTeamsForAdmin(group["_id"], loginUserId)
    else
      []
    end
    #make unique teamIds
    homeTeamsList = teams_map_list ++ allClassTeams
    |> Enum.uniq_by(& &1["teamId"])
    |> Enum.sort_by(& String.downcase(&1["name"]))
    #group map (Notice board)
    group_map_list = [
      %{ groupId: encode_object_id(group["_id"]), name: "Notice Board", type: "Broadcast",
         #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Notice%20Board.png"
         image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_52998",
         kanName: "ನೋಟೀಸ್ ಬೋರ್ಡ್"
        }
    ]
    #individual message icon map
    message_map_list = [
       %{ id: 4, groupId: encode_object_id(group["_id"]), name: "Messages", type: "Chat", role: role, count: count,
          #image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/Communication%20and%20Messages.png",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_03_01281",
          kanName: "ಸಂದೇಶಗಳು"
        }
    ]
    # final list
    communicationMap = group_map_list ++ homeTeamsList ++ message_map_list
    #communication feature icons
    %{
      activity: "Communication",
      featureIcons: communicationMap,
      kanActivity: "ಸಂವಹನ"
    }
  end

  defp getAllClassTeamsForAdmin(groupObjectId, loginUserId) do
    allClassTeams = TeamRepo.get_all_class_team_list(groupObjectId)
    list = Enum.reduce(allClassTeams, [], fn k, acc ->
      map = %{
        "groupId" => encode_object_id(groupObjectId),
        "teamId" => encode_object_id(k["_id"]),
        "name" =>  k["name"],
        "phone" => k["phone"],
        "image" => k["image"],
        "category" => k["category"],
        "members" => 0,
        "isTeamAdmin" => if loginUserId == k["adminId"] do
          true
        else
          false
        end,
        "allowTeamPostAll" => true,
        "allowTeamPostCommentAll" => true,
        "canAddUser" => if loginUserId == k["adminId"] do
          true
        else
          false
        end
      }
      acc ++ [map]
    end)
    list
  end


  defp checkAccountant(group, loginUser) do
    {:ok, checkAccountant} = GroupRepo.checkIsAccountant(group["_id"], loginUser["_id"]) # checking login userId is Accountant or not
    # checkingAccountant as role
    accountant = if checkAccountant == 1 || loginUser["_id"] == group["adminId"] do
      true
    else
      false
    end
    %{ accountant: accountant}
  end


  defp checkIsExaminer(group, loginUser)  do
    {:ok, checkIsExaminer} = GroupRepo.checkIsExaminer(group["_id"], loginUser["_id"]) # checking login userId is Accountant or not
    examiner = if checkIsExaminer == 1 || loginUser["_id"] == group["adminId"] do
      true
    else
      false
    end
    %{ examiner: examiner}
  end


  #private function to get role = teacher/admin/parent
  defp findRoleForSchoolApp(group, loginUser) do
    #check login user can post in group or not
    checkCanPost = GroupRepo.checkUserCanPostInGroup(group["_id"], loginUser["_id"]) #instead, Check login user can post in group outside the loop
    #find is group admin or authorized user
    {role, count, details} = if group["adminId"] == loginUser["_id"] || checkCanPost["canPost"] == true do
      {"admin", 2, %{}}
    else
      #find loginUser have class to take attendance
      findClass = TeamRepo.findClassTeamForLoginUserAsTeacher(loginUser["_id"], group["_id"])
      #IO.puts "#{hd(findClass)["teams"]["teamId"]}"
      if length(findClass) > 0 do
        #class found for the login user so, show list of classes
        if length(findClass) == 1 do
          {
            "teacher",
            length(findClass),
            %{
              "teamId" => encode_object_id(hd(findClass)["teams"]["teamId"]),
              "teamImage" => hd(findClass)["image"],
              "teamName" => hd(findClass)["name"],
              "category" => hd(findClass)["category"]
            }
          }
        else
          #provide another api to list class teams to take an attendance
          {
            "teacher",
            length(findClass),
            %{}
          }
        end
      else
        #parent (find kids class for parents)
        findStudent = TeamRepo.getMyKidsClassForSchool(loginUser["_id"], group["_id"])
        #IO.puts "#{findStudent}"
        if length(findStudent) == 1 do
          #directly redirect to this student report
          {
            "parent",
            length(findStudent),
            %{
              "userId" => encode_object_id(loginUser["_id"]),
              "teamId" => encode_object_id(hd(findStudent)["teamDetails"]["_id"]),
              "studentName" => hd(findStudent)["teamDetails"]["name"]
            }
          }
        else
          #redirect to another api to select student
          {
            "parent",
            length(findStudent),
            %{}
          }
        end
      end
    end
    %{role: role, count: count, details: details}
  end


  #to list all teams of group for the user in constituency app
  # TEAM INDEX for constituency - FULL Version
  defp getConstituencyHomePage(teams, loginUser, group) do
    #0. Election icons
    # electionMap = getIconsForElectionFeatures(group["_id"])
    #1. communication icons
    constituencyCommunicationMap = getIconsForConstituencyCommunicationFeatures(group, teams, loginUser)
    #2. Productivity icons
    constituencyProductivityMap = getIconsForConstituencyProductivityFeatures(group["_id"])
    # 4. Social media features map
    socialMediaActivityMap = getIconsForSocialMediaActivities(group, _role=nil, _count=nil, _details=nil)
    # %{ data:  [electionMap] ++ [constituencyCommunicationMap] ++ [constituencyProductivityMap] }
    %{ data:  [constituencyCommunicationMap] ++ [constituencyProductivityMap] ++ [socialMediaActivityMap] }
  end

  # defp getIconsForElectionFeatures(groupObjectId) do
  #   groupStringId = encode_object_id(groupObjectId)
  #   icons_map = [
  #     %{ id: 19, groupId: groupStringId, name: "Master List", type: "Master List",
  #        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/masterVotersList.png",
  #        kanName: "ಮಾಸ್ಟರ್ ಪಟ್ಟಿ"
  #      },
  #   ]
  #   data = icons_map
  #   #feature icons
  #   featuresMap = %{
  #     activity: "Election",
  #     featureIcons: data,
  #     kanActivity: "ಚುನಾವಣೆ"
  #   }
  # end

  defp getIconsForConstituencyProductivityFeatures(groupObjectId) do
    groupStringId = encode_object_id(groupObjectId)
    icons_map = [
      %{ id: 2, groupId: groupStringId, name: "Calendar", type: "Calendar",
         image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_03_02935.jpeg",
         kanName: "ಕ್ಯಾಲೆಂಡರ್"
       },
      #  %{ id: 15, groupId: groupStringId, name: "Issues", type: "Issues",
      #    image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/Tickets.jpeg",
      #    kanName: "ಸಮಸ್ಯೆಗಳು"
      #  },
      #  %{ id: 19, groupId: groupStringId, name: "Master List", type: "Master List",
      #    image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/masterVotersList.png",
      #    kanName: "ಮಾಸ್ಟರ್ ಪಟ್ಟಿ"
      #  },
      %{ id: 29, groupId: groupStringId, name: "My Teams", type: "My Teams",
         image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/my_teams.jpg",
         kanName: "ನನ್ನ ತಂಡಗಳು"
       },

      #  %{ id: 30, groupId: groupStringId, name: "Voter Analysis", type: "Voter Analysis",
      #     image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_03_02935.jpeg",
      #     kanName: "ಕ್ಯಾಲೆಂಡರ್"
      #   },
    ]
    data = icons_map
    #feature icons
    %{
      activity: "Productivity",
      featureIcons: data,
      kanActivity: "ಪ್ರೊಡಕ್ಟಿವಿಟಿ"
    }
  end

  defp getIconsForConstituencyCommunicationFeatures(group, teams, loginUser) do
    groupStringId = encode_object_id(group["_id"])
    # teams_map_list = Enum.reduce(teams, [], fn k, acc ->
    #   {:ok, teamMembersCount} = TeamRepo.getCreatedTeamMembersCount(group["_id"], k["teams"]["teamId"])   ##Instead, get team members count of all teams fot this group and concatenate inside for loop
    #   map =  %{
    #     groupId: encode_object_id(group["_id"]),
    #     teamId: encode_object_id(k["teams"]["teamId"]),
    #     name: k["teamDetails"]["name"],
    #     phone: k["teamDetails"]["phone"],
    #     image: k["teamDetails"]["image"],
    #     category: k["teamDetails"]["category"],
    #     subCategory: k["teamDetails"]["subCategory"],
    #     members: teamMembersCount,
    #     isTeamAdmin: k["teams"]["isTeamAdmin"],
    #     allowTeamPostAll: k["teams"]["allowedToAddPost"],
    #     allowTeamPostCommentAll: k["teams"]["allowedToAddComment"],
    #     canAddUser: k["teams"]["isTeamAdmin"]
    #   }
    #   #get admin name and phpne number from user table
    #   adminDetail = UserRepo.find_user_by_id(k["teamDetails"]["adminId"])
    #   map = map
    #   |> Map.put_new("adminName", adminDetail["name"])
    #   |> Map.put_new("phone", adminDetail["phone"])
    #   |> Map.put_new("userName", adminDetail["name"])
    #   |> Map.put_new("userId", encode_object_id(adminDetail["_id"]))
    #   |> Map.put_new("userImage", adminDetail["image"])
    #   acc ++ [ map ]
    # end)
    teams_map_list = Enum.reduce(teams, [], fn k, acc ->
      # {:ok, teamMembersCount} = TeamRepo.getCreatedTeamMembersCount(group["_id"], k["teamId"])   ##Instead, get team members count of all teams fot this group and concatenate inside for loop
      map =  %{
        "groupId" => encode_object_id(group["_id"]),
        "teamId" => encode_object_id(k["teamId"]),
        "name" =>  k["name"],
        "phone" => k["phone"],
        "image" => if k["image"] do
          k["image"]
        else
          ##"aHR0cHM6Ly9ncnVwcGllbWVkaWEuc2dwMS5jZG4uZGlnaXRhbG9jZWFuc3BhY2VzLmNvbS9HcnVwcGllX0ljb25zLzMwJTIwVGVhY2hlciUyME1lZXRpbmcucG5n"
        end,
        "category" => k["category"],
        "subCategory" => k["subCategory"],
        # "members" => teamMembersCount,
        "members" => 0,
        "isTeamAdmin" => k["isTeamAdmin"],
        "allowTeamPostAll" => k["allowedToAddPost"],
        "allowTeamPostCommentAll" => k["allowedToAddComment"],
        "canAddUser" => k["isTeamAdmin"]
      }
      map = if k["category"] == "public" && group["adminId"] == loginUser["_id"] do
        map
        |> Map.put("allowedToAddComment", true)
        |> Map.put("isTeamAdmin", true)
        |> Map.put("canAddUser", true)
        |> Map.put("allowTeamPostAll", true)
      else
        map
      end
      map = if Map.has_key?(k, "adminId") do
        #get admin name and phpne number from user table
        adminDetail = UserRepo.find_user_by_id(k["adminId"])
        map
        |> Map.put_new("adminName", adminDetail["name"])
        |> Map.put("phone", adminDetail["phone"])
        |> Map.put_new("userName", adminDetail["name"])
        |> Map.put_new("userId", encode_object_id(adminDetail["_id"]))
        |> Map.put_new("userImage", adminDetail["image"])
      else
        map
      end

    # end)
      # #if category school then provide enable gps and enable attendance
      # map = map
      # |> Map.put_new("enableGps", k["enableGps"])
      # |> Map.put_new("enableAttendance", k["enableAttendance"])
      # #check it is class team or not
      # if k["class"] do
      #   map = map
      #     |> Map.put_new("isClass", k["class"])
      # else
      #   map = map
      #     |> Map.put_new("isClass", false)
      # end
      acc ++ [ map ]
    end)
    #replace group name to "Announcement like noticeboard in school"
    group_map_constituency = [
       %{ groupId: groupStringId, name: "Announcement", type: "Broadcast",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/Announcement.jpeg",
          kanName: "ಘೋಷಣೆ"
        }
    ]
    #static icons (Productivity)
    icons_map = [
      %{ id: 1, groupId: groupStringId, name: "Gallery", type: "Gallery",
         image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_56252.jpeg",
         kanName: "ಗ್ಯಾಲರಿ"
         ####****postUnseenCount: galleryUnseenCount
       },
       %{ id: 27, groupId: groupStringId, name: "Special Messages", type: "Special Messages",
         image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/SpecialMessage.png",
         kanName: "ವಿಶೇಷ ಸಂದೇಶಗಳು"
         ####****postUnseenCount: galleryUnseenCount
       },
      %{ id: 9, groupId: groupStringId, name: "Live Meetings", type: "Video Class", category: group["category"],
         image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/rsz_zoom_live.png",
         kanName: "ನೇರ ಸಭೆಗಳು"
       }
    ]
    data = group_map_constituency ++ icons_map ++  teams_map_list
    #feature icons
    %{
      activity: "Communication",
      featureIcons: data,
      kanActivity: "ಸಂದೇಶ"
    }
  end



  ###################### COMMUNITY MAP Home page ##################################
  #to list all teams of group for the user in community app
  # TEAM INDEX for community - FULL Version
  defp getCommunityHomePage(teams, _loginUser, group) do
    #1. communication icons
    communityCommunicationMap = getIconsForCommunityCommunicationFeatures(group, teams)
    #2. Show branches for SAMADHAN app
    # branchesMap = if group["appName"] == "SAMADHAN" do
    #   getIconsForBranchesOfSamadhan(group, teams)
    # else
    #   []
    # end
    # 4. Social media features map
    socialMediaActivityMap = getIconsForSocialMediaActivities(group, _role=nil, _count=nil, _details=nil)
    #get branches if Existed
    branches = getBranches(group["_id"])
    if group["appName"] == "SAMADHANA" do
      #data render json
      %{ data:  [communityCommunicationMap] ++ [branches] ++ [socialMediaActivityMap] }
    else
      #data render json
      %{ data:  [communityCommunicationMap] ++ [socialMediaActivityMap] }
    end
  end

  # defp getIconsForBranchesOfSamadhan(group, teams) do
  #   icons_map = [
  #     %{ id: , groupId: groupStringId, name: "Gallery", type: "Gallery",
  #        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_56252.jpeg",
  #        kanName: "ಗ್ಯಾಲರಿ"
  #        ####****postUnseenCount: galleryUnseenCount
  #      },
  #     #  %{ id: 27, groupId: groupStringId, name: "Special Messages", type: "Special Messages",
  #     #    image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/SpecialMessage.png",
  #     #    kanName: "ವಿಶೇಷ ಸಂದೇಶಗಳು"
  #     #    ####****postUnseenCount: galleryUnseenCount
  #     #  },
  #     %{ id: 9, groupId: groupStringId, name: "Live Meetings", type: "Video Class", category: group["category"],
  #        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/rsz_zoom_live.png",
  #        kanName: "ನೇರ ಸಭೆಗಳು"
  #      },
  #      %{ id: 2, groupId: groupStringId, name: "Calendar", type: "Calendar",
  #        image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_03_02935.jpeg",
  #        kanName: "ಕ್ಯಾಲೆಂಡರ್"
  #      },
  #   ]
  #   data = group_map_constituency ++ icons_map ++  teams_map_list
  #   #feature icons
  #   featuresMap = %{
  #     activity: "Dashboard",
  #     featureIcons: data,
  #     kanActivity: "ಡ್ಯಾಶ್ಬೋರ್ಡ್"
  #   }
  # end

  defp getIconsForCommunityCommunicationFeatures(group, teams) do
    groupStringId = encode_object_id(group["_id"])
    teams_map_list = Enum.reduce(teams, [], fn k, acc ->
      # {:ok, teamMembersCount} = TeamRepo.getCreatedTeamMembersCount(group["_id"], k["teamId"])   ##Instead, get team members count of all teams fot this group and concatenate inside for loop
      map =  %{
        "groupId" => encode_object_id(group["_id"]),
        "teamId" => encode_object_id(k["teamId"]),
        "name" =>  k["name"],
        "phone" => k["phone"],
        "image" => if k["image"] do
          k["image"]
        else
          nil
          ##"aHR0cHM6Ly9ncnVwcGllbWVkaWEuc2dwMS5jZG4uZGlnaXRhbG9jZWFuc3BhY2VzLmNvbS9HcnVwcGllX0ljb25zLzMwJTIwVGVhY2hlciUyME1lZXRpbmcucG5n"
        end,
        "category" => k["category"],
        "subCategory" => k["subCategory"],
        #"members" => teamMembersCount,
        "members" => 0,
        "isTeamAdmin" => k["isTeamAdmin"],
        "allowTeamPostAll" => k["allowedToAddPost"],
        "allowTeamPostCommentAll" => k["allowedToAddComment"],
        "canAddUser" => k["isTeamAdmin"]
      }
      #get admin name and phpne number from user table
      map = if Map.has_key?(k, "adminId") do
        adminDetail = UserRepo.find_user_by_id(k["adminId"])
        map
        |> Map.put_new("adminName", adminDetail["name"])
        |> Map.put_new("phone", adminDetail["phone"])
        |> Map.put_new("userName", adminDetail["name"])
        |> Map.put_new("userId", encode_object_id(adminDetail["_id"]))
        |> Map.put_new("userImage", adminDetail["image"])
      else
        map
      end
      #list merge
      acc ++ [ map ]
    end)
    #replace group name to "Announcement like noticeboard in school"
    group_map_constituency = [
       %{ groupId: groupStringId, name: "Announcement", type: "Broadcast",
          image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/Announcement.jpeg",
          kanName: "ಘೋಷಣೆ"
        }
    ]
    #static icons (Productivity)
    icons_map = [
      %{ id: 1, groupId: groupStringId, name: "Gallery", type: "Gallery",
         image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_02_56252.jpeg",
         kanName: "ಗ್ಯಾಲರಿ"
         ####****postUnseenCount: galleryUnseenCount
       },
      #  %{ id: 27, groupId: groupStringId, name: "Special Messages", type: "Special Messages",
      #    image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Gruppie_Icons/SpecialMessage.png",
      #    kanName: "ವಿಶೇಷ ಸಂದೇಶಗಳು"
      #    ####****postUnseenCount: galleryUnseenCount
      #  },
      %{ id: 9, groupId: groupStringId, name: "Live Meetings", type: "Video Class", category: group["category"],
         image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/rsz_zoom_live.png",
         kanName: "ನೇರ ಸಭೆಗಳು"
       },
       %{ id: 2, groupId: groupStringId, name: "Calendar", type: "Calendar",
         image: "https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/images/gruppie_14_09_2020_02_03_02935.jpeg",
         kanName: "ಕ್ಯಾಲೆಂಡರ್"
       },
    ]
    data = group_map_constituency ++ icons_map ++  teams_map_list
    #feature icons
    %{
      activity: "Dashboard",
      featureIcons: data,
      kanActivity: "ಡ್ಯಾಶ್ಬೋರ್ಡ್"
    }
  end


  defp getBranches(groupObjectId) do
    #getting Community branches if existed
    branchList = TeamRepo.getBranches(groupObjectId)
    branchNameArray = if branchList != [] do
      for branchDetails <- branchList do
        %{
          "name" => branchDetails["branchName"],
          "branchId" => encode_object_id(branchDetails["_id"]),
          "image" => branchDetails["image"],
          "type" => "Branch"
        }
      end
    else
      []
    end
    data = branchNameArray
    %{
      activity: "Kendras",
      featureIcons: data,
      kanActivity: "ಕೇಂದ್ರಗಳು"
    }
  end
end
