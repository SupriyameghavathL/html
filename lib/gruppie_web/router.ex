defmodule GruppieWeb.Router do
  use GruppieWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {GruppieWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug GruppieWeb.Handler.GuardianAuthHandler
  end

  scope "/", GruppieWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", GruppieWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GruppieWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end


  #gruppie application api starts
  ################################################################################################################################################################################
  scope "/api", GruppieWeb.Api, as: :api do
    pipe_through :api
    scope "/v1", V1, as: :v1 do
      post "/user/exist", SecurityController, :userExist #verified
      post "/user/exist/category/app", SecurityController, :userExistCategoryApp #verified
      post "/register", SecurityController, :register #verified
      post "/register/category/app", SecurityController, :registerIndividualCategory #verified
      post "/verify/otp/category/app", SecurityController, :verifyOtpCategoryApp #verified
      put "/create/password/category/app", SecurityController, :createPasswordCategoryApp #verified
      post "/login", SecurityController, :login #verified
      post "/login/category/app", SecurityController, :login_category_app #verified
      put "/forgot/password", SecurityController, :forgot_password #verified
      put "/forgot/password/category/app", SecurityController, :forgot_password_category_app #verified
      #get list of religion for caste in karnataka
      get "/caste/religions", ProfileController, :constituencyReligionGet #verified
      #get all castes list of karnataka / india
      get "/caste/get", ProfileController, :constituencyCasteGet #verified
      #add profession
      post "/profession/add", ProfileController, :addProfession #verified
      #get list of professions
      get "/profession/get", ProfileController, :getProfession #verified
      #add education to db
      post "/education/add", ProfileController, :addEducation #verified
      #get education from db
      get "/education/get", ProfileController, :getEducation #verified
      #to add influencer list
      post "/influencer/add", ProfileController, :addInfluencerList #verified
      #get influencer list
      get "/influencer/get", ProfileController, :getInfluencerList #verified
      #add constituency to db
      post "/constituency/add", ProfileController, :addConstituency #verified
      #get constituency from db
      get "/constituency/get", ProfileController, :getConstituency #verified
      #post birthdayPost
      post "/birthday/post/add", ProfileController, :addBirthdayPost #verified
      #post add state
      post "/gruppie/states/add",  ProfileController, :addStates #verified
      #get states
      get "/gruppie/states/get", ProfileController, :getStates #verified
      #add districts
      post "/gruppie/districts/add", ProfileController, :addDistricts #verified
      #get districts
      get "/gruppie/districts/get", ProfileController, :getDistricts #verified
      #taluk add
      post "/gruppie/taluks/add", ProfileController, :addTaluks #verified
      #get taluk
      get "/gruppie/taluks/get", ProfileController, :getTaluks #verified
      #add reminder
      post "/gruppie/reminder/add", ProfileController, :addReminder #verified
      #get reminderList
      get "/gruppie/reminder/get", ProfileController, :getReminder #verified
      #post relatives
      post "/gruppie/relatives/add", ProfileController, :addRelatives #verified
      #get relatives List
      get "/gruppie/relatives/get", ProfileController, :getRelatives #verified
      get "/post/report/reasons", ProfileController, :getPostReportReasons #verified
    end

    scope "/v1", V1, as: :v1 do
      pipe_through :api_auth
      #login user profile show
      get "/profile/show", ProfileController, :show #verified
      #login user profile edit
      put "/profile/edit", ProfileController, :edit #verified
      #change mobile number
      put "/number/change", ProfileController, :changeMobileNumber #verified
      #remove user profile pic
      put "/profile/pic/remove", ProfileController, :removeUserProfilePic #verified
      #password change
      put "/password/change", SecurityController, :change_password #verified
      put "/password/change/individual", SecurityController, :change_password_individual #verified
      put "/password/change/category/app", SecurityController, :change_password_category_app #verified
      #group create, get groups
      resources "/groups", GroupController , except: [ :edit, :new, :update ] #group create verified, get groups verified
      #get groups category list.    // for constituency app
      get "/constituency/groups/category", GroupController, :getConstituencyGroupsCategory #verified
      #get groups events for login user for school group
      get "/groups/:id/events", GroupController, :getEventsListForGroupSchool #verified
      #get groups events for login user for constituency group
      get "/groups/:id/events/constituency", GroupController, :getEventsListForGroupConstituency #verified
      #get all booths events for admin/MLA
      get "/groups/:id/events/all/booths", GroupController, :getEventListForConstituencyAllBooths #verified
      #get last team post updated time for teams
      get "/groups/:id/team/:team_id/events/team/post", GroupController, :getEventForTeamPost #verified
      #get last team user updated at time and if booth category team get last committee updated at time
      get "/groups/:id/team/:team_id/events/team", GroupController, :getEventForTeam #verified
      #get events for subBooth teams
      get "/groups/:id/team/:team_id/events/subbooth", GroupController, :getEventListForConstituencySubBoothTeams #verified
      #get events for my booth teams (For booth president if more than 1 booth)
      get "/groups/:id/events/my/booths", GroupController, :getEventListForConstituencyMyBoothTeams #verified
      #get events for my sub-booth teams (For booth worker/page pramukh if more than 1 booth)
      get "/groups/:id/events/my/subbooths", GroupController, :getEventListForConstituencyMySubBoothTeams #verified
      #get groups action for login user
      get "/groups/:id/live/class/events", GroupController, :getLiveClassActionEventList #verified
      #get groups action for login user
      get "/groups/:id/live/testexam/events", GroupController, :getLiveTestExamActionEventList #verified
      #get list of taluks where MLA belongs to school group
      get "/taluks", GroupController, :getListOfTaluks #verified
      #get my people list
      get "/groups/:group_id/my/people", FriendController, :getMyPeople #verified
      #get nested level people list
      get "/groups/:group_id/user/:user_id/people", FriendController, :getNestedPeople #verified
      #get notifications for login user
      get "/groups/:group_id/notifications/get", FriendController, :getNotifications #verified
      #get all posts for the group
      get "/groups/:group_id/posts/get", GroupPostController, :index #verified
      #create/add post in group
      post "/groups/:group_id/posts/add", GroupPostController, :create #verified
      #add items to gallery from only admin and authorized users
      post "/groups/:group_id/gallery/add", GroupPostController, :galleryAdd #verified
      #add image to album in gallery
      put "/groups/:group_id/album/:album_id/add", GroupPostController, :galleryAlbumAdd #verified
      #remove image from album in gallery
      put "/groups/:group_id/album/:album_id/remove", GroupPostController, :removeAlbumImage #verified
      #add vendors only admin and authorized users
      post "/groups/:group_id/vendors/add", GroupPostController, :vendorsAdd #verified
      #add code of conduct only admin and authorized users
      post "/groups/:group_id/coc/add", GroupPostController, :cocAdd #verified
      #get gallery
      get "/groups/:group_id/gallery/get", GroupPostController, :getGallery #verified
      #get vendors
      get "/groups/:group_id/vendors/get", GroupPostController, :getVendors #verified
      #get coc
      get "/groups/:group_id/coc/get", GroupPostController, :getCoc #verified
      #delete group post
      put "/groups/:group_id/posts/:post_id/delete", GroupPostController, :deletePost #verified
      #delete album from gallery
      put "/groups/:group_id/album/:album_id/delete", GroupPostController, :deleteAlbum #verified
      #delete vendor
      put "/groups/:group_id/vendor/:vendor_id/delete", GroupPostController, :deleteVendor #verified
      #delete coc
      put "/groups/:group_id/coc/:coc_id/delete", GroupPostController, :deleteCoc #verified
      #add class to school category group
      post "/groups/:group_id/class/add", GroupPostController, :addClassToSchool #verified
      #get classes from student register
      get "/groups/:group_id/class/get", GroupPostController, :getClasses #verified
      #get school staff list (school category)
      get "/groups/:group_id/staff/get", GroupPostController, :getSchoolStaff #verified
      #get class students list
      get "/groups/:group_id/team/:team_id/students/get", GroupPostController, :getStudents #verified




      ################################################ School-College-Register API ###########################################################
      #post add board class to the db
      post "/add/board/class/to/db", SchoolCollegeRegisterController, :addBoardClassToDb #verified
      #post add board to the db
      post "/add/board/to/db", SchoolCollegeRegisterController, :addBoardToDb #verified
      #post /create/group/team
      post "/user/:user_id/new/register", SchoolCollegeRegisterController, :createGroupTeams #verified
      #get boardClassList from db
      get "/get/board/class/list/school", SchoolCollegeRegisterController, :getSchoolClassList #verified
      #get created class list
      get "/groups/:group_id/get/created/class/list", SchoolCollegeRegisterController, :getCreatedClassList #verified
      #post create class
      post "/groups/:group_id/add/classes", SchoolCollegeRegisterController, :addClassToSchool #verified
      #get board list
      get "/get/board/db", SchoolCollegeRegisterController, :getboards #verified
      #add university to db
      post "/add/university/to/db", SchoolCollegeRegisterController, :addUniversity #verified
      #get University Boards
      get "/get/university/from/db", SchoolCollegeRegisterController, :getUniversity #verified
      #post add medium to db
      post "/add/medium/to/db", SchoolCollegeRegisterController, :addMedium #verified
      #get medium from db
      get "/get/medium/from/db",SchoolCollegeRegisterController, :getMedium #verified
      #post add type of campus
      post "/add/type/of/campus", SchoolCollegeRegisterController, :addTypeOfCampus #verified
      #get type of campus
      get "/get/type/of/campus", SchoolCollegeRegisterController, :getTypeOfCampus #verified
      #put delete the class created
      put "/groups/:group_id/delete/class", SchoolCollegeRegisterController, :deleteClassCreated #verified
      # post "/groups/:group_id/class/add/extra"
      post "/groups/:group_id/class/add/extra", SchoolCollegeRegisterController, :createExtraClass #verified
      #get class list
      get "/groups/:group_id/get/class/list", SchoolCollegeRegisterController, :getClassListWithSections #verified
      #trail period check
      get "/groups/:group_id/trial/period", SchoolCollegeRegisterController, :getTrailPeriodRemainingDays #verified
      #add medium new
      post "/add/medium/to/db/new", SchoolCollegeRegisterController, :addMediumNew #verified
      ################################################ School-College-Register API's END #######################################################


      ########################################### School-Fees API ############################################################################################
      #get class fess for admin
      get "/groups/:group_id/class/get/fee", SchoolFeeController, :getClassFees #verified
      #pay fees by students and accountant
      post "/groups/:group_id/team/:team_id/student/:user_id/fee/paid", SchoolFeeController, :addFeePaidDetailsByStudent #verified
      #add fine amount to fee after due date
      get "/groups/:group_id/team/:team_id/student/:user_id/fee/due/fine", SchoolFeeController, :addFeeFinesToStudent #verified
      #get total fine amount of the school
      get "/groups/:group_id/total/fee/amount", SchoolFeeController, :getTotalFeeOfSchool #verified
      #fee installments for school
      get "/groups/:group_id/team/:team_id/school/fee/report/get", SchoolFeeController, :getInstallmentSchool #verified
      #fee report get class
      get "/groups/:group_id/class/fee/report", SchoolFeeController, :getClassesFeeReport #verified
      #get sending reminder for students not paid fees
      get "/groups/:group_id/fee/reminder/get", SchoolFeeController, :getFeeReminderList #verified
      #post message of reminder
      post "/groups/:group_id/team/:team_id/fee/reminder/add", SchoolFeeController, :postFeeReminder #verified
      #get due amount from database
      get "/groups/:group_id/team/:team_id/user/:user_id/due/get", SchoolFeeController, :getDue
      ########################################### School-Fees  API's END #############################################################################################

      ######################################## Suggestion-Box API's Start ####################################################################################################
      #add suggestion by parent's
      post "/groups/:group_id/suggestion/add", SuggestionBoxController, :postSuggestionByParents #verified
      #get suggestion post for posted user and all post for admin and canPost = true
      get "/groups/:group_id/suggestion/get", SuggestionBoxController, :getSuggestionToLoginUserAndAdmin #verified
      #get events for suggestion box post get
      get "/groups/:group_id/suggestion/events", SuggestionBoxController, :getEventsForSuggestionBoxPost #verified
      #continuation of notes-videos
      get "/groups/:group_id/team/:team_id/post/:post_id/notes/read", SuggestionBoxController, :getNotesFeed #verified
      #continuation of homeWork
      get "/groups/:group_id/team/:team_id/post/:post_id/homework/read", SuggestionBoxController, :getHomeWorkFeed #verified
      ######################################## Suggestion-Box API's End  #####################################################################################################


      ###################################### Feeder-icon Constituency/School And Reports Api ###############################################################################################
      #get feeder for school and constituency ?type=noticeBoard/homeWork/notesVideos
      get "/groups/:group_id/all/post/get", FeederNotificationController, :getAllPost #verified
      #events api
      get "/groups/:group_id/all/post/get/events", FeederNotificationController, :getAllPostEvent #verified
      #add report list
      post "/gruppie/reports/list/add", FeederNotificationController, :addReportsToDb #verified
      #get report list
      get "/gruppie/reports/list/get", FeederNotificationController, :getReportsListToDb #verified
      #get teams for feeder notification
      get "/groups/:group_id/feeder/teams/get", FeederNotificationController, :getTeamToPost #verified
      #post from feeder
      post "/groups/:group_id/feeder/post/add", FeederNotificationController, :postFromFeeder #verified
      #get language true to select for student
      get "/groups/:group_id/team/:team_id/language/get", FeederNotificationController, :getLanguageList #verified
      #get languages gruppie
      get "/gruppie/languages/get", FeederNotificationController, :getLanguages #verified
      #post language to gruppie
      post "/gruppie/languages/add", FeederNotificationController, :postLanguages #verified
      #append uniquePost id for old post collection
      post "/groups/:group_id/post/uniqueid", FeederNotificationController, :addUniquePostId  #verified
      ##################################### Feeder_icon Constituency/School And Reports Api End ############################################################################################



      ##################################### CALENDAR API'S START ###########################################################################################################################
      #Add events to calendar
      post "/groups/:group_id/calendar/events/add", CalendarController, :addCalendarEvents  #verified
      #get evnets from calendar
      get "/groups/:group_id/calendar/events/get", CalendarController, :getCalendarEvents  #verified
      #calendar edit
      put "/groups/:group_id/calendar/:calendar_id/events/edit", CalendarController, :editCalendarEvents  #verified
      #delete calendar delete
      put "/groups/:group_id/calendar/:calendar_id/events/delete",CalendarController, :deleteCalendarEvents  #verified
      ##################################### CALENDAR APLI's END  ###########################################################################################################################


      #################################### User-Block-And-Admin Change-API's START ##########################################################################################################################
      #block from team query_params
      #"/groups/:group_id/team/:team_id/user/:user_id"?type=block/leaveteam
      post "/groups/:group_id/team/:team_id/user/:user_id", UserBlockController, :blockUser  #verified
      #unBlock from team
      put "/groups/:group_id/team/:team_id/user/:user_id/unblock", UserBlockController, :unblockUser  #verified
      #change Admin
      put "/groups/:group_id/team/:team_id/user/:user_id/change/admin", UserBlockController, :changeAdmin  #verified
      #################################### User-Block-And-Admin Change-API's END ##########################################################################################################################











      ############################## CONSTITUENCY CATEGORY APP ROUTES##################################################################################################################################
      #add booths to constituency by admin/authorized users
      post "/groups/:group_id/constituency/booths/add", ConstituencyController, :addBoothsToConstituency #verified
      #get booths list in booth register
      get "/groups/:group_id/all/booths/get", ConstituencyController, :getAllBoothTeams #verified
      #add members to booth
      post "/groups/:group_id/team/:team_id/user/add/booth", ConstituencyController, :addMembersToBoothTeam #verified
      #update booth member information
      put "/groups/:group_id/team/:team_id/user/:user_id/update/booth/member", ConstituencyController, :updateBoothMemberInformation #verified
      #get booth all members
      get "/groups/:group_id/team/:team_id/booth/members", ConstituencyController, :getBoothTeamMembers #verified ?committeeId=:committeeId //to filter based on committees
      #add family member to constituency voters list
      post "/groups/:group_id/user/:user_id/register/family/voters", ConstituencyController, :addMyFamilyToConstituencyDb #verified
      #get user profile detail in constituency app
      get "/groups/:group_id/user/:user_id/profile/get", ConstituencyController, :getConstituencyUserProfileDetail #verified
      #update profile for user in constituency group
      put "/groups/:group_id/user/:user_id/profile/edit", ConstituencyController, :getConstituencyUserProfileEdit #verified
      #get list of family voters added under userId
      get "/groups/:group_id/user/:user_id/family/voters/get", ConstituencyController, :getFamilyRegisterList #verified
      #get my booth teams in group for booth president
      get "/groups/:group_id/my/booth/teams", ConstituencyController, :getMyBoothTeams #verified
      #get my subbooth teams in group for booth worker/page pramukh
      get "/groups/:group_id/my/subbooth/teams", ConstituencyController, :getMySubBoothTeams #verified
      #get list of teams under booth team members
      get "/groups/:group_id/team/:team_id/booth/members/teams", ConstituencyController, :getBoothMembersTeamList #verified
      #register issues only by admin/authorized user
      post "/groups/:group_id/constituency/issues/register", ConstituencyController, :constituencyIssuesRegister #verified
      #get list of issues registered for constituency
      get "/groups/:group_id/constituency/issues", ConstituencyController, :constituencyIssuesGet #verified
      #register department user and party user to each constituency issues registered
      post "/groups/:group_id/issue/:issue_id/department/user/add", ConstituencyController, :addDepartmentAndPartyUserToConstituencyIssues #verified
      #delete constituency_issue registered
      put "/groups/:group_id/issue/:issue_id/delete", ConstituencyController, :deleteConstituencyIssueRegistered #verified
      #get login user belongs to booths/subBooth teams to select which booth while adding issues ticket
      get "/groups/:group_id/booth/subbooth/teams", ConstituencyController, :getBoothOrSubBoothTeamForLoginUser #verified
      #Select the issue and raise ticket on issue
      post "/groups/:group_id/team/:booth_id/issue/:issue_id/ticket/add", ConstituencyController, :addTicketOnIssueOfConstituency #verified
      #get list of issues for not approved, approved, hold on role: admin, booth president, coordinator, public
      get "/groups/:group_id/issues/tickets/get", ConstituencyController, :getConstituencyIssuesTickets #verified
      #approve issues from party taskforce (?status=approved/denied/notApproved)
      put "/groups/:group_id/issue/post/:issuePost_id/approve", ConstituencyController, :changeStatusOfNotApprovedIssuesTickets #verified
      #approve issues from admin (?status=approved/denied/notApproved)
      put "/groups/:group_id/issue/post/:issuePost_id/admin/approve", ConstituencyController, :changeStatusOfNotApprovedIssuesTicketsByAdmin #verified
      #close/hold/open issues from department taskforce (?status=closed/hold/open)
      put "/groups/:group_id/issue/post/:issuePost_id/taskforce/close", ConstituencyController, :closeOrHoldIssueOnOpenByDepartmentTaskForce #verified
      #remove raised ticket from user
      put "/groups/:group_id/issue/:issuePost_id/remove", ConstituencyController, :removeIssueAddedByLoginUser #verified
      #add coordinator to booths and same coordinator should get added to booth coordinator team along with MLA
      post "/groups/:group_id/team/:team_id/coordinator/add/booth", ConstituencyController, :addCoordinatorsToBoothTeam #verified
      #get list of booth coordinators
      get "/groups/:group_id/team/:team_id/booth/coordinator/get", ConstituencyController, :getListOfBoothCoordinators #verified
      #add comment to issue tickets
      post "/groups/:group_id/issue/post/:issuePost_id/comment/add", ConstituencyController, :addCommentToIssueTickets #verified
      #get comment list for issue tickets
      get "/groups/:group_id/issue/post/:issuePost_id/comments/get", ConstituencyController, :getCommentsOnIssueTickets #verified
      #remove comments added for issue tickets
      put "/groups/:group_id/issue/post/:issuePost_id/comment/:comment_id/remove", ConstituencyController, :removeCommentAddedForIssueTicket #verified
      #add committees to booth teams (Other than default committee team)
      post "/groups/:group_id/booth/team/:team_id/committee/add", ConstituencyController, :addCommitteesToBoothTeam #verified
      #get list of committee for booth team
      get "/groups/:group_id/booth/team/:team_id/committees/get", ConstituencyController, :getCommitteeListForBoothTeam #verified
      #remove committee from booth team
      put "/groups/:group_id/booth/team/:team_id/committee/remove", ConstituencyController, :removeCommitteeFromBoothTeam #verified
      #get admin feeder in home page
      get "/groups/:group_id/constituency/feeder", ConstituencyController, :getAdminFeederInConstituencyGroup #verified
      #add banner image by MLA/Admin
      post "/groups/:group_id/banner/add", ConstituencyController, :addBannerInConstituencyGroup #verified
      #get constituency group banner
      get "/groups/:group_id/banner/get", ConstituencyController, :getConstituencyGroupBanner #verified
      #search user by name, phone and voterId
      get "/groups/:group_id/user/search", ConstituencyController, :searchUserInGroup #verified

      ################################ Election Api's #############################
      #add voters from master election list to booth/subBooth or booth/street team accordingly
      post "/groups/:group_id/team/:team_id/add/voters/masterlist", ConstituencyController, :addVotersToTeamFromMasterList #verified
      #get list of voters as master list from constituency_voters_database
      get "/groups/:group_id/team/:team_id/get/voters/masterlist", ConstituencyController, :getVotersFromMasterList #verified
      #remove voter from master list
      put "/groups/:group_id/team/:team_id/voter/remove", ConstituencyController, :removeVoterFromMasterList #verified
      #allocate voters to booth workers
      put "/groups/:group_id/booth/worker/:user_id/voters/allocate", ConstituencyController, :allocateVotersToBoothWorkers #verified
      #add user will vote for us or not status
      post "/groups/:group_id/user/:user_id/voter/status", ConstituencyController, :addVoterStatus
      #########################################################################################################################################


      ################################### Constituency-Category-List ##########################################################################
      #add category list to gruppie db
      post "/groups/:group_id/constituency/category/list/add", ConstituencyCategoryController, :addCategoriesToDb #verified
      #get category list from gruppie db
      get "/groups/:group_id/constituency/category/list/get", ConstituencyCategoryController, :getCategoriesFromDb #verified
      #add categoryTypes list to gruppie db
      post "/groups/:group_id/constituency/category/types/add", ConstituencyCategoryController, :addCategoriesTypeToDb #verified
      #get categoryTypes List from db
      get "/groups/:group_id/constituency/category/types/get", ConstituencyCategoryController, :getCategoriesTypeFromDb #verified
      #get users based on filter
      get "/groups/:group_id/constituency/category/get", ConstituencyCategoryController, :getUsersBasedOnFilter #verified
      #post add special types to post
      post "/groups/:group_id/constituency/special/post/add", ConstituencyCategoryController, :addSpecialPostBasedOnFilter #verified
      #get post based on filter
      get "/groups/:group_id/constituency/special/post/get", ConstituencyCategoryController, :getSpecialPostBasedOnFilter #verified
      #post add likes  to special post
      post "/groups/:group_id/constituency/special/post/:post_id/like", ConstituencyCategoryController, :addLikesToSpecialPost #verified
      #get saved Special post
      get "/groups/:group_id/constituency/special/save/get", ConstituencyCategoryController, :getSpecialPost #verified
      #delete special post
      put "/groups/:group_id/constituency/special/post/:post_id/delete", ConstituencyCategoryController, :deleteSpecialPost #verified
      #events api
      get "/groups/:group_id/constituency/special/post/events", ConstituencyCategoryController, :getEventsForSpecialPost #verified
      # get voterId and installed users
      get "/groups/:group_id/constituency/install/voter/get", ConstituencyCategoryController, :getInstalledAndVoterUsers #verified
      #add question form to db
      post "/groups/:group_id/constituency/voter/analytics/field", ConstituencyCategoryController, :addProfileExtraFields #verified
      #get the fields from db
      get "/groups/:group_id/constituency/voter/analytics/field/get", ConstituencyCategoryController, :getAnalysisFields #verified
      #search api
      get "/groups/:group_id/constituency/search/list/users", ConstituencyCategoryController, :getSearchListConstituency #verified
      #post searchName
      post "/users/searchname/insert", ConstituencyCategoryController, :addSpecialName #verified
      #get booth teams
      get "/groups/:group_id/constituency/booth/members/get", ConstituencyCategoryController, :getBoothMembersTeam  #verified
      #get booth team user
      get "/groups/:group_id/team/:team_id/constituency/booth/members", ConstituencyCategoryController, :getTeamUsersList  #verified
      #get subBooth team users
      get "/groups/:group_id/team/:team_id/constituency/booth/users", ConstituencyCategoryController, :getBoothTeamUsers  #verified
      ################################### Constituency-Category-List API's END##########################################################################


      ################################## Constituency-Analysis-API's START #############################################################################
      #add panchayat to db
      post "/groups/:group_id/constituency/panchayat/add", ConstituencyAnalysisController, :addZpToConstituency #verified
      #get panchayat from db
      get "/groups/:group_id/constituency/panchayat/get", ConstituencyAnalysisController, :getZpTpConstituency #verified
      #update panchayat
      put "/groups/:group_id/constituency/panchayat/:panchayat_id/edit", ConstituencyAnalysisController, :editZpTpWardConstituency #verified
      #delete panchayat
      put "/groups/:group_id/constituency/panchayat/:panchayat_id/delete", ConstituencyAnalysisController, :deleteZpTpWardConstituency #verified
      #add constituency
      post "/groups/:group_id/constituency/president/citizen/add", ConstituencyAnalysisController, :addPresidentCitizenToConstituency #verified
      #custom api
      post "/groups/:group_id/constituency/team/push", ConstituencyAnalysisController, :pushToTeam #verified
      ################################## Constituency-Analysis-API's END ###############################################################################


      ######################################## Community-category-list API's START ####################################################################
      #Add members to community teams
      post "/groups/:group_id/team/:team_id/user/add/community", CommunityController, :addMembersToBoothTeam #verified
      #Add branches to community
      post "/groups/:group_id/add/branches/community", CommunityController, :addBranchesToCommunity #verified
      #add post to branches
      post "/groups/:group_id/branch/:branch_id/posts/add", CommunityController, :addPostToBranches #verified
      #edit api
      put "/groups/:group_id/branch/:branch_id/edit", CommunityController, :editBranches #verified
      #delete api
      put "/groups/:group_id/branch/:branch_id/delete", CommunityController, :deleteBranches #verified
      #get branchPost
      get "/groups/:group_id/branch/:branch_id/posts/get",  CommunityController, :getBranchPosts #verified
      #default team user add
      post "/groups/:group_id/user/add/community", CommunityController, :addUsersToDefaultTeam #verified
      #kendra admin add
      post "/groups/:group_id/branch/:branch_id/admin/add", CommunityController, :addAdminToTeam #verified
      #get admin List of Kendra
      get "/groups/:group_id/branch/:branch_id/admin/get", CommunityController, :getAdminFromTeam #verified
      #kendra team admin remove
      put "/groups/:group_id/branch/:branch_id/user/:user_id/admin/delete", CommunityController, :deleteAdminFromTeam #verified
      #filter api
      get "/search/filter", CommunityController, :getListBasedOnSearch
      #custom api
      post "/groups/:group_id/community/id/append", CommunityController, :addCommunityIdNo
      #community admin add
      post "/groups/:group_id/admin/add", CommunityController, :makeAdminToApp
      #get community admin
      get "/groups/:group_id/admin/get", CommunityController, :getAppAdmins
      #delete admin
      put "/groups/:group_id/user/:user_id/admin/delete", CommunityController, :deleteAppAdmin
      #public team add
      post "/groups/:group_id/add/public/team", CommunityController, :addPublicTeam
      ######################################## Community-category-list API's END ####################################################################



    end

  end

end
