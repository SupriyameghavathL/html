defmodule GruppieWeb.Repo.ConstituencyCategoryRepo do
  import GruppieWeb.Handler.TimeNow
  import GruppieWeb.Repo.RepoHelper


  @conn :mongo

  @category_list_constituency "constituency_category_db"

  @category_types_col "constituency_category_types_db"

  @teams_col "teams"

  @user_col "users"

  @group_team_member_col "group_team_members"

  @saved_post_col "posts"

  @user_category_app_col "user_category_apps"

  @voters_analytics_field "voter_analysis_db"

  @view_teams_details_col "VW_TEAMS_DETAILS"


  def addCategoriesToDb(groupObjectId, categories) do
    filter = %{
      "groupId" => groupObjectId,
    }
    {:ok, category_count} = Mongo.count(@conn, @category_list_constituency, filter)
    if category_count == 0 do
      #insert newly
      insertDoc = %{"categories" => categories,"groupId" => groupObjectId}
      Mongo.insert_one(@conn, @category_list_constituency, insertDoc)
    else
      #update profession to existing
      update = %{"$push" => %{"categories" => %{"$each" => categories}}}
      Mongo.update_one(@conn, @category_list_constituency, filter, update)
    end
  end


  def getCategoriesFromDb(_groupObjectId) do
    # filter = %{
    #   "groupId" => groupObjectId,
    # }
    project = %{
      "_id" => 0,
      "groupId" => 0,
    }
    Mongo.find_one(@conn, @category_list_constituency, %{}, [projection: project])
  end


  def addCategoriesTypeToDb(groupObjectId, categoryTypes) do
    filter = %{
      "groupId" => groupObjectId,
    }
    {:ok, categoryTypes_count} = Mongo.count(@conn, @category_types_col, filter)
    if categoryTypes_count == 0 do
      #insert newly
      insertDoc = %{"categoryTypes" => categoryTypes, "groupId" => groupObjectId}
      Mongo.insert_one(@conn, @category_types_col, insertDoc)
    else
      #update profession to existing
      update = %{"$push" => %{"categoryTypes" => %{"$each" => categoryTypes}}}
      Mongo.update_one(@conn, @category_types_col, filter, update)
    end
  end


  def getCategoriesTypeFromDb(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
    }
    project = %{
      "_id" => 0,
      "groupId" => 0,
    }
    Mongo.find_one(@conn, @category_types_col, filter, [projection: project])
  end


  def getIdsBoothPresident(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "category" => "booth",
      "isActive" => true,
    }
    project = %{
      "adminId" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @teams_col, filter, [projection: project])
    |> Enum.to_list()
  end


  def getIdsBoothWorkers(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "category" => "subBooth",
      "isActive" => true,
    }
    project = %{
      "adminId" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @teams_col, filter, [projection: project])
    |> Enum.to_list()
  end



  def getUserListBasedOnFilter(params, userIds) do
    #booth president and worker filter
    filter = if params["categoryType"] == "1" || params["categoryType"] == "2" do
      cond do
        params["category"] == "CASTE"  ->
          %{
            "_id" => %{
              "$in" => userIds,
            },
            "caste" => params["categorySelection"]
          }
        params["category"] == "PROFESSION" ->
          %{
            "_id" => %{
              "$in" => userIds,
            },
            "designation" => params["categorySelection"]
          }
        params["category"] == "EDUCATION" ->
          %{
            "_id" => %{
              "$in" => userIds,
            },
            "qualification" => params["categorySelection"]
          }
        params["category"] == "GENDER" ->
          %{
            "_id" => %{
              "$in" => userIds,
            },
            "gender" =>  params["categorySelection"]
          }
      end
      #citizen filter
    else
      cond do
        params["category"] == "CASTE"  ->
          %{
            "caste" => params["categorySelection"]
          }
        params["category"] == "PROFESSION" ->
          %{
            "designation" => params["categorySelection"]
          }
        params["category"] == "EDUCATION" ->
          %{
            "qualification" => params["categorySelection"]
          }
        params["category"] == "GENDER" ->
          %{
            "gender" =>  params["categorySelection"]
          }
      end
    end
    {:ok, pageCount } = if params["categoryType"] == "1" || params["categoryType"] == "2" do
      getPageCountFilter(userIds, params)
    else
      getPageCountFilter("", params)
    end
    project = %{
      "_id" => 1,
      "name" => 1,
      "phone" => 1,
      "image" => 1,
    }
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 50
      list = Mongo.find(@conn, @user_col, filter, [projection: project, skip: skip, limit: 50])
      |> Enum.to_list()
      [%{"pageCount" => pageCount } | list]
    else
      list = Mongo.find(@conn, @user_col, filter, [projection: project])
      |> Enum.to_list()
      [%{"pageCount" => pageCount } | list]
    end
  end


  def getPageCountFilter(userIds, params) do
    filter = if params["categoryType"] == "1" || params["categoryType"] == "2" do
      cond do
        params["category"] == "CASTE"  ->
          %{
            "_id" => %{
              "$in" => userIds,
            },
            "caste" => params["categorySelection"]
          }
        params["category"] == "PROFESSION" ->
          %{
            "_id" => %{
              "$in" => userIds,
            },
            "designation" => params["categorySelection"]
          }
        params["category"] == "EDUCATION" ->
          %{
            "_id" => %{
              "$in" => userIds,
            },
            "qualification" => params["categorySelection"]
          }
        params["category"] == "GENDER" ->
          %{
            "_id" => %{
              "$in" => userIds,
            },
            "gender" =>  params["categorySelection"]
          }
      end
    else
      cond do
        params["category"] == "CASTE"  ->
          %{
            "caste" => params["categorySelection"]
          }
        params["category"] == "PROFESSION" ->
          %{
            "designation" => params["categorySelection"]
          }
        params["category"] == "EDUCATION" ->
          %{
            "qualification" => params["categorySelection"]
          }
        params["category"] == "GENDER" ->
          %{
            "gender" =>  params["categorySelection"]
          }
      end
    end
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @user_col, filter, [projection: project])
  end


  def addSpecialPostBasedOnFilter(changeset, groupObjectId, userObjectId) do
    changeset = changeset
    |> Map.put(:groupId, groupObjectId)
    |> Map.put(:userId, userObjectId)
    |> Map.put(:type, "specialPost")
    |> Map.put(:uniquePostId, encode_object_id(new_object_id()))
    Mongo.insert_one(@conn, @saved_post_col, changeset)
  end


  def checkBoothPresident(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => userObjectId,
      "category" => "booth",
      "isActive" => true
    }
    project = %{
      "_id" => 1,
    }
    Mongo.find_one(@conn, @teams_col, filter, [projection: project])
  end


  def checkBoothWorker(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => userObjectId,
      "category" => "subBooth",
      "isActive" => true
    }
    project = %{
      "_id" => 1,
    }
    Mongo.find_one(@conn, @teams_col, filter, [projection: project])
  end


  def checkCitizen(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.find_one(@conn, @group_team_member_col, filter, [projection: project])
  end

  def checkCanPost(groupObjectId, userObjectId) do
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


  def getSpecialPostBasedForAdmin(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "type" => "specialPost"
    }
    Mongo.find(@conn, @saved_post_col, filter, [sort: %{"_id" => -1}])
    |> Enum.to_list()
  end


  def getSpecialPostBasedOnAllTypesALL(groupObjectId, loginUser, params, teamIds) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => "specialPost",
      "$and" => [
        %{"$or" =>
          [
            %{"categoryType" => "1"},
            %{"categoryType" => "2"},
            %{"categoryType" => "3"},
          ]
        },
        %{"$or" =>
          [
            %{"$and" => [%{"teamIds" => %{"$exists" => true }}, %{"teamIds" => %{ "$in" => teamIds}}]},
            %{"teamIds" => %{"$exists" => false}}
          ]
        },
        %{"$or" =>
          [
            %{"categorySelection" => loginUser["qualification"]},
            %{"categorySelection" => loginUser["designation"]},
            %{"categorySelection" => loginUser["gender"]},
            %{"categorySelection" => loginUser["caste"]},
          ],
        }
      ],
      "isActive" => true,
    }
    project = %{
      "isActive" => 0,
      "groupId" => 0,
      "categoryType" => 0,
      "category" => 0,
      "categorySelection" => 0,
    }
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 15
      Mongo.find(@conn, @saved_post_col, filter, [projection: project, sort: %{"_id" => -1} , skip: skip, limit: 15])
      |> Enum.to_list()
    else
      Mongo.find(@conn, @saved_post_col, filter, [projection: project, sort: %{"_id" => -1}])
      |> Enum.to_list()
    end
  end


  def getSpecialPostBasedOnAllTypesAllPresident(groupObjectId, loginUser, params, teamIds) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => "specialPost",
      "$and" => [
        %{"$or" =>
          [
            %{"categoryType" => "1"},
            %{"categoryType" => "3"},
          ]
        },
        %{"$or" =>
          [
            %{"$and" => [%{"teamIds" => %{"$exists" => true }}, %{"teamIds" => %{ "$in" => teamIds}}]},
            %{"teamIds" => %{"$exists" => false}}
          ]
        },
        %{"$or" =>
          [
            %{"categorySelection" => loginUser["qualification"]},
            %{"categorySelection" => loginUser["designation"]},
            %{"categorySelection" => loginUser["gender"]},
            %{"categorySelection" => loginUser["caste"]},
          ],
        }
      ],
      "isActive" => true,
    }
    project = %{
      "isActive" => 0,
      "groupId" => 0,
      "categoryType" => 0,
      "category" => 0,
      "categorySelection" => 0,
    }
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 15
      Mongo.find(@conn, @saved_post_col, filter, [projection: project, sort: %{"_id" => -1} , skip: skip, limit: 15])
      |> Enum.to_list()
    else
      Mongo.find(@conn, @saved_post_col, filter, [projection: project, sort: %{"_id" => -1}])
      |> Enum.to_list()
    end
  end


  def getSpecialPostBasedOnAllTypesAllBoothWorker(groupObjectId, loginUser, params, teamIds) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => "specialPost",
      "$and" => [
        %{"$or" =>
          [
            %{"categoryType" => "2"},
            %{"categoryType" => "3"},
          ]
        },
        %{"$or" =>
          [
            %{"$and" => [%{"teamIds" => %{"$exists" => true }}, %{"teamIds" => %{ "$in" => teamIds}}]},
            %{"teamIds" => %{"$exists" => false}}
          ]
        },
        %{"$or" =>
          [
            %{"categorySelection" => loginUser["qualification"]},
            %{"categorySelection" => loginUser["designation"]},
            %{"categorySelection" => loginUser["gender"]},
            %{"categorySelection" => loginUser["caste"]},
          ],
        }
      ],
      "isActive" => true,
    }
    # IO.puts "#{filter}"
    project = %{
      "isActive" => 0,
      "groupId" => 0,
      "categoryType" => 0,
      "category" => 0,
      "categorySelection" => 0,
    }
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 15
      Mongo.find(@conn, @saved_post_col, filter, [projection: project, sort: %{"_id" => -1} , skip: skip, limit: 15])
      |> Enum.to_list()
    else
      Mongo.find(@conn, @saved_post_col, filter, [projection: project, sort: %{"_id" => -1}])
      |> Enum.to_list()
    end
  end


  def getSpecialPostBasedOnAllTypesAllCitizen(groupObjectId, loginUser, params, teamIds) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => "specialPost",
      "$and" => [
        %{"$or" =>
          [
            %{"categoryType" => "3"},
          ]
        },
        %{"$or" =>
          [
            %{"$and" => [%{"teamIds" => %{"$exists" => true }}, %{"teamIds" => %{ "$in" => teamIds}}]},
            %{"teamIds" => %{"$exists" => false}}
          ]
        },
        %{"$or" =>
          [
            %{"categorySelection" => loginUser["qualification"]},
            %{"categorySelection" => loginUser["designation"]},
            %{"categorySelection" => loginUser["gender"]},
            %{"categorySelection" => loginUser["caste"]},
          ],
        }
      ],
      "isActive" => true,
    }
    project = %{
      "isActive" => 0,
      "groupId" => 0,
      "categoryType" => 0,
      "category" => 0,
      "categorySelection" => 0,
    }
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 15
      Mongo.find(@conn, @saved_post_col, filter, [projection: project, sort: %{"_id" => -1} , skip: skip, limit: 15 ])
      |> Enum.to_list()
    else
      Mongo.find(@conn, @saved_post_col, filter, [projection: project, sort: %{"_id" => -1}])
      |> Enum.to_list()
    end
  end


  def getTeamIds(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
    }
    project = %{
      "teams.teamId" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @group_team_member_col, filter, [projection: project])
  end


  def getTotalSpecialPostCount(groupObjectId, loginUser, canEdit) do
    filter = if canEdit do
      %{
        "groupId" => groupObjectId,
        "type" => "specialPost",
        "isActive" => true,
      }
    else
      %{
        "groupId" => groupObjectId,
        "type" => "specialPost",
        "$and" => [
          %{"$or" =>
            [
              %{"categoryType" => "1"},
              %{"categoryType" => "2"},
              %{"categoryType" => "3"},
            ]
          },
          %{"$or" =>
            [
              %{"categorySelection" => loginUser["qualification"]},
              %{"categorySelection" => loginUser["designation"]},
              %{"categorySelection" => loginUser["gender"]},
              %{"categorySelection" => loginUser["caste"]},
            ],
          }
        ],
        "isActive" => true,
      }
    end
    project = %{"_id" => 1}
    Mongo.count(@conn, @saved_post_col, filter, [projection: project])
  end


  def getUserLikeThePost(groupObjectId, postObjectId, userObjectId) do
    filter = %{
      "_id" => postObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
      "likedUsers.userId" => userObjectId,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @saved_post_col, filter, [projection: project])
  end


  def addLikesToSpecialPost(groupObjectId, postObjectId, _userObjectId, likedUserDoc) do
    filter = %{
      "_id" => postObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "likes" => 1,
      },
      "$push" => %{
        "likedUsers" => likedUserDoc,
      }
    }
    Mongo.update_one(@conn, @saved_post_col, filter, update)
  end


  def addDisLikeToSpecialPost(groupObjectId, postObjectId, userObjectId) do
    filter = %{
      "_id" => postObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "likes" => -1,
      },
      "$pull" => %{
        "likedUsers" => %{
          "userId" => userObjectId
        },
      }
    }
    Mongo.update_one(@conn, @saved_post_col, filter, update)
  end

  def findPostIsLiked(userObjectId, groupObjectId, postObjectId) do
    filter = %{
      "_id" => postObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
      "likedUsers" => userObjectId,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @saved_post_col, filter, [projection: project])
  end


  def deleteSpecialPost(groupObjectId, postObjectId) do
    filter = %{
      "_id" => postObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "updatedAt" => bson_time(),
        "isActive" => false,
      }
    }
    Mongo.update_one(@conn, @saved_post_col, filter, update)
  end


  def getUserNameAndImage(userObjectId) do
    filter = %{
      "_id" => userObjectId,
    }
    project = %{
      "name" => 1,
      "image" => 1,
      "phone" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @user_col, filter, [projection: project])
  end


  #events api queries
  def getSpecialPostBasedForAdminEvents(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => "specialPost",
      "isActive" => true,
    }
    project = %{
      "updatedAt" => 1,
      "_id" => 0,
    }
    list = Mongo.find(@conn, @saved_post_col, filter, [sort: %{"updatedAt" => -1}, projection: project, limit: 1])
    |> Enum.to_list()
    if list != [] do
      hd(list)
    else
      []
    end
  end


  def getSpecialPostBasedOnAllTypesALLEvents(groupObjectId, loginUser, teamIds) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => "specialPost",
      "$and" => [
        %{"$or" =>
          [
            %{"categoryType" => "1"},
            %{"categoryType" => "2"},
            %{"categoryType" => "3"},
          ]
        },
        %{"$or" =>
          [
            %{"$and" => [%{"teamIds" => %{"$exists" => true }}, %{"teamIds" => %{ "$in" => teamIds}}]},
            %{"teamIds" => %{"$exists" => false}}
          ]
        },
        %{"$or" =>
          [
            %{"categorySelection" => loginUser["qualification"]},
            %{"categorySelection" => loginUser["designation"]},
            %{"categorySelection" => loginUser["gender"]},
            %{"categorySelection" => loginUser["caste"]},
          ],
        }
      ],
      "isActive" => true,
    }
    project = %{
      "_id" => 0,
      "updatedAt" => 1,
    }
    list =Mongo.find(@conn, @saved_post_col, filter, [projection: project, sort: %{"updatedAt" => -1}, limit: 1])
    |> Enum.to_list()
    if list != [] do
      hd(list)
    else
      []
    end
  end


  def getSpecialPostBasedOnAllTypesAllPresidentEvents(groupObjectId, loginUser, teamIds) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => "specialPost",
      "$and" => [
        %{"$or" =>
          [
            %{"categoryType" => "1"},
            %{"categoryType" => "3"},
          ]
        },
        %{"$or" =>
          [
            %{"$and" => [%{"teamIds" => %{"$exists" => true }}, %{"teamIds" => %{ "$in" => teamIds}}]},
            %{"teamIds" => %{"$exists" => false}}
          ]
        },
        %{"$or" =>
          [
            %{"categorySelection" => loginUser["qualification"]},
            %{"categorySelection" => loginUser["designation"]},
            %{"categorySelection" => loginUser["gender"]},
            %{"categorySelection" => loginUser["caste"]},
          ],
        }
      ],
      "isActive" => true,
    }
    project = %{
      "_id" => 0,
      "updatedAt" => 1,
    }
    list = Mongo.find(@conn, @saved_post_col, filter, [projection: project, sort: %{"updatedAt" => -1}, limit: 1])
    |> Enum.to_list()
    if list != [] do
      hd(list)
    else
      []
    end
  end


  def getSpecialPostBasedOnAllTypesAllBoothWorkerEvents(groupObjectId, loginUser, teamIds) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => "specialPost",
      "$and" => [
        %{"$or" =>
          [
            %{"categoryType" => "2"},
            %{"categoryType" => "3"},
          ]
        },
        %{"$or" =>
          [
            %{"$and" => [%{"teamIds" => %{"$exists" => true }}, %{"teamIds" => %{ "$in" => teamIds}}]},
            %{"teamIds" => %{"$exists" => false}}
          ]
        },
        %{"$or" =>
          [
            %{"categorySelection" => loginUser["qualification"]},
            %{"categorySelection" => loginUser["designation"]},
            %{"categorySelection" => loginUser["gender"]},
            %{"categorySelection" => loginUser["caste"]},
          ],
        }
      ],
      "isActive" => true,
    }
    # IO.puts "#{filter}"
    project = %{
      "_id" => 0,
      "updatedAt" => 1,
    }
    list = Mongo.find(@conn, @saved_post_col, filter, [projection: project, sort: %{"updatedAt" => -1}, limit: 1])
    |> Enum.to_list()
    if list != [] do
      hd(list)
    else
      []
    end
  end


  def getSpecialPostBasedOnAllTypesAllCitizenEvents(groupObjectId, loginUser, teamIds) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => "specialPost",
      "$and" => [
        %{"$or" =>
          [
            %{"categoryType" => "3"},
          ]
        },
        %{"$or" =>
          [
            %{"$and" => [%{"teamIds" => %{"$exists" => true }}, %{"teamIds" => %{ "$in" => teamIds}}]},
            %{"teamIds" => %{"$exists" => false}}
          ]
        },
        %{"$or" =>
          [
            %{"categorySelection" => loginUser["qualification"]},
            %{"categorySelection" => loginUser["designation"]},
            %{"categorySelection" => loginUser["gender"]},
            %{"categorySelection" => loginUser["caste"]},
          ],
        }
      ],
      "isActive" => true,
    }
    project = %{
      "_id" => 0,
      "updatedAt" => 1,
    }
    list = Mongo.find(@conn, @saved_post_col, filter, [projection: project, sort: %{"updatedAt" => -1}, limit: 1])
    |> Enum.to_list()
    if list != [] do
      hd(list)
    else
      []
    end
  end


  def getTotalUsersInstalledApp() do
    filter = %{
      "constituencyName" => %{
        "$exists" => true,
      },
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @user_category_app_col, filter, [projection: project])
  end


  def getTotalVoters() do
    filter = %{
      "voterId" => %{
        "$nin" => ["", nil]
      }
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @user_col, filter, [projection: project])
  end


  def checkExtraFieldCreated(groupObject) do
    filter = %{
      "groupId" => groupObject,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @voters_analytics_field, filter, [projection: project])
  end


  def insertDocToDb(insertDoc) do
    Mongo.insert_one(@conn, @voters_analytics_field, insertDoc)
  end


  def pushToExistingArray(groupObjectId, voterAnalysisFields) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$push" => %{
        "voterAnalysisFields" => %{
          "$each" => voterAnalysisFields
        }
      }
    }
    Mongo.update_one(@conn, @voters_analytics_field, filter, update)
  end


  def getAnalysisFields(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "voterAnalysisFields" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @voters_analytics_field, filter, [projection: project])
  end


 #searchFilter
 def getUserListBasedOnSearch(params, userIds) do
    searchFilter = String.downcase(params["filter"])
    regexMap = %{ "$regex" => searchFilter }
    filter = if params["category"] && params["categorySelection"] do
      if params["categoryType"] == "1" ||  params["categoryType"] == "2"  do
        cond do
          params["category"] == "GENDER" ->
            %{
              "_id" => %{
                "$in" => userIds,
              },
              "searchName" => regexMap,
              "gender" => params["categorySelection"],
            }
          params["category"] == "EDUCATION" ->
            %{
              "_id" => %{
                "$in" => userIds,
              },
              "searchName" => regexMap,
              "qualification" => params["categorySelection"],
            }
          params["category"] == "PROFESSION" ->
            %{
              "_id" => %{
                "$in" => userIds,
              },
              "searchName" => regexMap,
              "designation" => params["categorySelection"],
            }
          params["category"] == "CASTE" ->
            %{
              "_id" => %{
                "$in" => userIds,
              },
              "searchName" => regexMap,
              "caste" => params["categorySelection"],
            }
        end
      else
        cond do
          params["category"] == "GENDER" ->
            %{
              "searchName" => regexMap,
              "gender" => params["categorySelection"],
            }
          params["category"] == "EDUCATION" ->
            %{
              "searchName" => regexMap,
              "qualification" => params["categorySelection"],
            }
          params["category"] == "PROFESSION" ->
            %{
              "searchName" => regexMap,
              "designation" => params["categorySelection"],
            }
          params["category"] == "CASTE" ->
            %{
              "searchName" => regexMap,
              "caste" => params["categorySelection"],
            }
        end
      end
    else
      %{
        "searchName" => regexMap,
      }
    end
    project = %{
      "name" => 1,
      "_id" => 1,
    }
    # {:ok, pageCount } = if params["categoryType"] == "1" ||  params["categoryType"] == "2"  do
    #   pageCountForPresidentAndBooth(params, userIds, regexMap)
    # else
    #   pageCountForCitizen(params, regexMap)
    # end
    {:ok, pageCount} = cond do
      params["categoryType"] == "1" ||  params["categoryType"] == "2" ->
        pageCountForPresidentAndBooth(params, userIds, regexMap)
      params["categoryType"] == "3" ->
        pageCountForCitizen(params, regexMap)
      true ->
        pageCountForUsers(regexMap)
    end
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 30
      list = Mongo.find(@conn, @user_col, filter, [projection: project, skip: skip, limit: 30])
      |> Enum.to_list()
      [ %{"pageCount" => pageCount["n"]} | list ]
    else
      list = Mongo.find(@conn, @user_col, filter, [projection: project])
      |> Enum.to_list()
      [ %{"pageCount" => pageCount["n"]} | list ]
    end
  end



  defp  pageCountForPresidentAndBooth(params, userIds, regexMap) do
    filter = cond do
      params["category"] == "GENDER" ->
        %{
          "_id" => %{
            "$in" => userIds,
          },
          "searchName" => regexMap,
          "gender" => params["categorySelection"],
        }
      params["category"] == "EDUCATION" ->
        %{
          "_id" => %{
            "$in" => userIds,
          },
          "searchName" => regexMap,
          "qualification" => params["categorySelection"],
        }
      params["category"] == "PROFESSION" ->
        %{
          "_id" => %{
            "$in" => userIds,
          },
          "searchName" => regexMap,
          "designation" => params["categorySelection"],
        }
      params["category"] == "CASTE" ->
        %{
          "_id" => %{
            "$in" => userIds,
          },
          "searchName" => regexMap,
          "caste" => params["categorySelection"],
        }
    end
    # project = %{
    #   "_id" => 1,
    # }
    Mongo.command(@conn, %{ count: @user_col, query: filter })
  end


  defp pageCountForCitizen(params, regexMap) do
    filter = cond do
      params["category"] == "GENDER" ->
        %{
          "searchName" => regexMap,
          "gender" => params["categorySelection"],
        }
      params["category"] == "EDUCATION" ->

        %{
          "searchName" => regexMap,
          "qualification" => params["categorySelection"],
        }
      params["category"] == "PROFESSION" ->
        %{
          "searchName" => regexMap,
          "designation" => params["categorySelection"],

        }
      params["category"] == "CASTE" ->
        %{
          "searchName" => regexMap,
          "caste" => params["categorySelection"],
        }
    end
    # project = %{
    #   "_id" => 1,
    # }
    Mongo.command(@conn, %{ count: @user_col, query: filter })
  end


  defp  pageCountForUsers(regexMap) do
    filter = %{
      "searchName" => regexMap,
    }
    # project = %{
    #   "_id" => 1,
    # }
    Mongo.command(@conn, %{ count: @user_col, query: filter })
  end


  def getActiveUsers(groupObjectId, userIdsList) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => %{
        "$in" => userIdsList,
      },
      "isActive" => true,
      "teams.0" => %{
        "$exists" => true
      }
      }
    project = %{
      "userId" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @group_team_member_col, filter, [projection: project])
    |> Enum.to_list()
  end


  def getUserList() do
    Mongo.find(@conn, @user_col, %{}, [projection: %{ "_id" => 1, "name" => 1}, limit: 3000])
    |> Enum.to_list()
  end


  def updateNames(name) do
    filter = %{
      "_id" => name["_id"]
    }
    update = %{
      "$set" => %{
        "searchName" => name["searchName"]
      }
    }
    Mongo.update_one(@conn, @user_col, filter, update)
  end


  def getBoothMembersTeams(groupObjectId, params) do
    filter = %{
      "groupId" => groupObjectId,
      "category" => "booth",
      "isActive" => true,
    }
    project = %{
       "name" => 1,
       "image" => 1,
       "category" => 1,
       "zoomKey" => 1,
       "zoomSecret" => 1,
       "adminId" => 1,
       "boothCommittees" => 1,
       "usersCount" => 1,
       "workersCount" => 1,
       "downloadedUserCount" => 1,
       "adminName" => "$$CURRENT.userDetails.name",
       "phone" => "$$CURRENT.userDetails.phone",
       "userImage" => "$$CURRENT.userDetails.image",
       "userId" => "$$CURRENT.userDetails._id",
      }
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      # skip = (pageNo - 1) * 50
      skip = (pageNo - 1) * 15
      pipeline = [%{"$match" => filter}, %{"$sort" => %{ "userDetails.name" => 1}}, %{"$skip" => skip}, %{"$limit" => 15},  %{"$project" => project}]
      Mongo.aggregate(@conn, @view_teams_details_col, pipeline)
      |>Enum.to_list()
    # else
    #   Mongo.find(@conn, @VW_TEAMS_DETAILS, filter, [projection: project])
    #   |>Enum.to_list()
    end
  end


  def getPageCountBooths(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "category" => "booth",
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @view_teams_details_col, filter, [projection: project])
  end


  # def getUserListOfConstituency(params) do
  #   filter = %{

  #   }
  #   project = %{
  #     "name" => 1,
  #     "image" => 1,
  #     "phone" => 1,
  #     "_id" => 1,
  #   }
  #   if !is_nil(params["page"]) do
  #     pageNo = String.to_integer(params["page"])
  #     skip = (pageNo - 1) * 50
  #     Mongo.find(@conn, @user_col, filter, [projection: project, skip: skip, limit: 50 ])
  #     |> Enum.to_list()
  #   else
  #     Mongo.find(@conn, @user_col, filter, [projection: project])
  #     |> Enum.to_list()
  #   end
  # end


  def getUserListPagesCount() do
    filter = %{

    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @user_col, filter, [projection: project])
  end


  def checkVoterFieldUpdate(userObjectId) do
    filter = %{
      "_id" => userObjectId,
      "$or" => [
        %{
          "voterId" => %{
            "$in" => ["", nil]
          }
        },
        %{
          "voterId" => %{
            "$exists" => false
          }
        }
      ]
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @user_col, filter, [projection: project])
  end


  def appendWorkerCount(teamObjectId, groupObjectId) do
    filter = %{
      "boothTeamId" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    {:ok, workersCount} = Mongo.count(@conn, @teams_col, filter, [projection: project])
    appendToTeamsCollectionWorkersCount(teamObjectId, groupObjectId, workersCount)
  end


  defp appendToTeamsCollectionWorkersCount(teamObjectId, groupObjectId, workersCount) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "workersCount" => workersCount
      }
    }
    Mongo.update_one(@conn, @teams_col, filter, update)
  end


  def appendUserCount(teamObjectId, groupObjectId) do
    filter = %{
      "boothTeamId" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    list = Mongo.find(@conn, @teams_col, filter, [projection: project])
    |> Enum.to_list
    teamIds = for teamId <- list do
      teamId["_id"]
    end
    filter2 = %{
      "groupId" => groupObjectId,
      "teams.teamId" => %{
        "$in" => teamIds
      },
      "isActive" => true,
    }
    project1 = %{
      "_id" => 1,
    }
    {:ok, usersCount} = Mongo.count(@conn, @group_team_member_col, filter2, [projection: project1])
    appendToTeamsCollectionUsersCount(teamObjectId, groupObjectId, usersCount)
  end


  defp appendToTeamsCollectionUsersCount(teamObjectId, groupObjectId, usersCount) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "usersCount" => usersCount
      }
    }
    Mongo.update_one(@conn, @teams_col, filter, update)
  end


  def downloadedUserCount(teamObjectId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "boothTeamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    list = Mongo.find(@conn, @teams_col, filter, [projection: project])
    |> Enum.to_list()
    getUserIds(list, groupObjectId, teamObjectId)
  end


  defp getUserIds(list, groupObjectId, teamObjectId) do
    teamIds = for teamId <- list do
      teamId["_id"]
    end
    filter = %{
      "groupId" => groupObjectId,
      "teams.teamId" => %{
        "$in" => teamIds,
      },
      "isActive" => true,
    }
    project = %{
      "userId" => 1,
      "_id" => 0,
    }
    list = Mongo.find(@conn, @group_team_member_col, filter, [projection: project])
    |> Enum.to_list()
    getCountOfUserDownloaded(groupObjectId, list, teamObjectId)
  end


  defp getCountOfUserDownloaded(groupObjectId, list, teamObjectId)  do
    userIds = for userId <- list do
      userId["userId"]
    end
    filter = %{
      "userId" => %{
        "$in" => userIds,
      },
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    {:ok, userDownloadedCount } = Mongo.count(@conn, @user_category_app_col, filter, [projection: project])
    filter1 = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "downloadedUserCount" => userDownloadedCount,
      }
    }
    Mongo.update_one(@conn, @teams_col, filter1, update)
  end


  def getTeamUsersList(groupObjectId, teamObjectId, params) do
    filter = %{
      "groupId" => groupObjectId,
      "boothTeamId" => teamObjectId,
      "category" => "subBooth",
      "isActive" => true
    }
    project = %{
      "name" => 1,
      "image" => 1,
      "category" => 1,
      "adminName" => "$$CURRENT.userDetails.name",
      "phone" => "$$CURRENT.userDetails.phone",
      "userImage" => "$$CURRENT.userDetails.image",
      "userId" => "$$CURRENT.userDetails._id",
      "subjectId" => 1,
      "ebookId" => 1,
      "zoomKey" => 1,
      "zoomSecret" => 1,
      "membersCount" => 1,
      "downloadedUserCount" => 1,
    }
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      # skip = (pageNo - 1) * 50
      skip = (pageNo - 1) * 15
      pipeline = [%{ "$match" => filter }, %{ "$project" => project }, %{ "$sort" => %{ "name" => 1 }}, %{"$limit" => 15}, %{"$skip" => skip}]
      Mongo.aggregate(@conn, @view_teams_details_col, pipeline)
      |> Enum.to_list()
    else
      pipeline = [%{ "$match" => filter }, %{ "$project" => project }, %{ "$sort" => %{ "name" => 1 } }]
      Mongo.aggregate(@conn, @view_teams_details_col, pipeline)
      |> Enum.to_list()
    end
  end


  def getPageCountMembers(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "boothTeamId" => teamObjectId,
      "category" => "subBooth",
      "isActive" => true
    }
    # IO.puts "#{filter}"
    Mongo.count(@conn, @view_teams_details_col, filter)
  end


  def getMembersCount(teamObjectId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teams.teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    {:ok, count} = Mongo.count(@conn, @group_team_member_col, filter, [projection: project])
    #appending  user count  in team to team table
    appendToTeamDocument(teamObjectId, groupObjectId, count)
  end


  defp  appendToTeamDocument(teamObjectId, groupObjectId, count) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "membersCount" => count
      }
    }
    Mongo.update_one(@conn, @teams_col, filter, update)
  end

  def getDownloadedMembersCount(teamObjectId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teams.teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "userId" => 1,
      "_id" => 0,
    }
    userIdList = Mongo.find(@conn, @group_team_member_col, filter, [projection: project])
    |> Enum.to_list()
    #to get user downloaded app from user category table
    getDownloadedUserCount(teamObjectId, userIdList, groupObjectId)
  end


  defp  getDownloadedUserCount(teamObjectId, userIdList, groupObjectId) do
    userIds = for userId <- userIdList do
      userId["userId"]
    end
    filter = %{
      "userId" => %{
        "$in" => userIds
      },
      "constituencyName" => %{
        "$exists" => true,
      },
      "isActive" => true,
    }
    project = %{
      "_id" => 1
    }
    {:ok, userDownloadedCount } = Mongo.count(@conn, @user_category_app_col, filter, [projection: project])
    #appending downloaded user count to team table
    appendDownloadedUserCountToDocument(teamObjectId, userDownloadedCount, groupObjectId)
  end


  defp appendDownloadedUserCountToDocument(teamObjectId, userDownloadedCount, groupObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "downloadedUserCount" => userDownloadedCount
      }
    }
    Mongo.update_one(@conn, @teams_col, filter, update)
  end

  #get userId belongs to team from group_team_mem col
  def getTeamUsersListGroup(groupObjectId, teamObjectId, params) do
    filter = %{
      "groupId" => groupObjectId,
      "teams.teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 0,
      "userId" => 1,
      "teams.teamId.$" => 1,
      "teams.allowedToAddUser" => 1,
      "teams.allowedToAddPost" => 1,
      "teams.allowedToAddComment" => 1
    }
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      # skip = (pageNo - 1) * 50
      skip = (pageNo - 1) * 15
      Mongo.find(@conn, @group_team_member_col, filter, [projection: project, limit: 15, skip: skip])
      |> Enum.to_list
    else
      Mongo.find(@conn, @group_team_member_col, filter, [projection: project])
      |> Enum.to_list
    end
  end


  def getDownloadedUserIds(userObjectId) do
    filter = %{
      "userId" => userObjectId,
      "isActive" => true,
      "constituencyName" => %{
        "$exists" => true,
      },
    }
    project = %{
      "userId" => 1,
      "_id" => 0,
    }
    Mongo.count(@conn, @user_category_app_col, filter, [projection: project])
  end


  def getTotalPageCount(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teams.teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @group_team_member_col, filter, [projection: project])
  end


  def getTeamUsersListByCommitteeIdList(groupObjectId, teamObjectId, params) do
    filter = %{
      "groupId" => groupObjectId,
      "$and" => [
        %{"teams.teamId" => teamObjectId},
        %{"teams.committeeIds" => params["committeeId"]}
      ],
      "isActive" => true,
    }
    project = %{
      "_id" => 0,
      "userId" => 1,
      "teams.teamId.$" => 1,
      "teams.allowedToAddUser" => 1,
      "teams.allowedToAddPost" => 1,
      "teams.allowedToAddComment" => 1
    }
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      # skip = (pageNo - 1) * 50
      skip = (pageNo - 1) * 15
      Mongo.find(@conn, @group_team_member_col, filter, [projection: project, limit: 15, skip: skip])
      |> Enum.to_list
    else
      Mongo.find(@conn, @group_team_member_col, filter, [projection: project])
      |> Enum.to_list
    end
  end


  def pageCountCommittee(groupObjectId, teamObjectId, params) do
    filter = %{
      "groupId" => groupObjectId,
      "$and" => [
        %{"teams.teamId" => teamObjectId},
        %{"teams.committeeIds" => params["committeeId"]}
      ],
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @group_team_member_col, filter, [projection: project])
  end
end
