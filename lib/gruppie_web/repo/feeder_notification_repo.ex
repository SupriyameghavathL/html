defmodule GruppieWeb.Repo.FeederNotificationRepo do
  import GruppieWeb.Handler.TimeNow

  @conn :mongo

  @post_coll "posts"

  @view_subject_post_topic_col "VW_SUBJECT_POST_TOPICS"

  @school_assignment_col "school_assignment"

  @teams_coll "teams"

  @subject_staff_coll "subject_staff_database"

  @staff_coll "staff_database"

  @reports_col "report_database"

  @group_teams_member_col "group_team_members"

  @subject_staff_database_coll "subject_staff_database"

  @language_coll "language_db"


  def getAllPostForAdmin(groupObjectId, params) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => %{"$in" => ["groupPost", "teamPost"]},
      "isActive" => true,
    }
    # to get pageCount
    {:ok, pageCount} = pageCountAllPostAdmin(groupObjectId)
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 15
      list = Mongo.find(@conn, @post_coll, filter, [sort: %{"_id" => -1} , skip: skip, limit: 15 ])
      |> Enum.to_list()
      [ %{"pageCount" => pageCount} | list ]
    else
      list = Mongo.find(@conn, @post_coll, filter)
      |> Enum.to_list()
      [ %{"pageCount" => pageCount} | list ]
    end
  end


  defp pageCountAllPostAdmin(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @post_coll, filter, [projection: project])
  end


  def getAllPostBasedOnAllTypesALL(groupObjectId, loginUser, params, teamIds, teamObjectIds) do
    filter = %{
      "groupId" => groupObjectId,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "specialPost",
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
        },
        %{"type" => "teamPost",
          "teamId" => %{
            "$in" => teamObjectIds
          }
        }
      ],
      "isActive" => true,
    }
    {:ok, pageCount} = pageCountAllPostAll(groupObjectId, teamIds, teamObjectIds, loginUser)
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 15
      list = Mongo.find(@conn, @post_coll, filter, [sort: %{"_id" => -1} , skip: skip, limit: 15])
      |> Enum.to_list()
      [ %{"pageCount" => pageCount} | list ]
    else
      list = Mongo.find(@conn, @post_coll, filter, [sort: %{"_id" => -1}])
      |> Enum.to_list()
      [ %{"pageCount" => pageCount} | list ]
    end
  end



  defp pageCountAllPostAll(groupObjectId, teamIds, teamObjectIds, loginUser) do
    filter = %{
      "groupId" => groupObjectId,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "specialPost",
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
        },
        %{"type" => "teamPost",
          "teamId" => %{
            "$in" => teamObjectIds
          }
        }
      ],
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @post_coll, filter, [projection: project])
  end



  def getAllPostBasedOnAllTypesAllPresident(groupObjectId, loginUser, params, teamIds, teamObjectIds) do
    filter = %{
      "groupId" => groupObjectId,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "specialPost",
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
          ]
        },
        %{"type" => "teamPost",
          "teamId" => %{
            "$in" => teamObjectIds
          }
        }
      ],
      "isActive" => true,
    }
    {:ok, pageCount} = pageCountAllPostAllPresident(groupObjectId, teamIds, teamObjectIds, loginUser)
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 15
      list = Mongo.find(@conn, @post_coll, filter, [sort: %{"_id" => -1} , skip: skip, limit: 15])
      |> Enum.to_list()
      [ %{"pageCount" => pageCount} | list ]
    else
      list = Mongo.find(@conn, @post_coll, filter, [sort: %{"_id" => -1}])
      |> Enum.to_list()
      [ %{"pageCount" => pageCount} | list ]
    end
  end


  defp pageCountAllPostAllPresident(groupObjectId, teamIds, teamObjectIds, loginUser) do
    filter = %{
      "groupId" => groupObjectId,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "specialPost",
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
        },
        %{"type" => "teamPost",
          "teamId" => %{
            "$in" => teamObjectIds
          }
        }
      ],
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @post_coll, filter, [projection: project])
  end



  def getAllPostBasedOnAllTypesAllBoothWorker(groupObjectId, loginUser, params, teamIds, teamObjectIds) do
    filter = %{
      "groupId" => groupObjectId,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "specialPost",
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
        },
        %{"type" => "teamPost",
          "teamId" => %{
            "$in" => teamObjectIds
          }
        }
      ],
      "isActive" => true,
    }
    {:ok, pageCount} = pageCountAllPostAllWorker(groupObjectId, teamIds, teamObjectIds, loginUser)
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 15
      list = Mongo.find(@conn, @post_coll, filter, [sort: %{"_id" => -1} , skip: skip, limit: 15])
      |> Enum.to_list()
      [ %{"pageCount" => pageCount} | list ]
    else
      list = Mongo.find(@conn, @post_coll, filter, [sort: %{"_id" => -1}])
      |> Enum.to_list()
      [ %{"pageCount" => pageCount} | list ]
    end
  end


  defp pageCountAllPostAllWorker(groupObjectId, teamIds, teamObjectIds, loginUser) do
    filter = %{
      "groupId" => groupObjectId,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "specialPost",
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
        },
        %{"type" => "teamPost",
          "teamId" => %{
            "$in" => teamObjectIds
          }
        }
      ],
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @post_coll, filter, [projection: project])
  end


  def getAllPostBasedOnAllTypesAllCitizen(groupObjectId, loginUser, params, teamIds, teamObjectIds) do
    filter = %{
      "groupId" => groupObjectId,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "specialPost",
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
        },
        %{"type" => "teamPost",
          "teamId" => %{
            "$in" => teamObjectIds
          }
        }
      ],
      "isActive" => true,
    }
    {:ok, pageCount} = pageCountAllPostAllCitizen(groupObjectId, teamIds, teamObjectIds, loginUser)
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 15
      list = Mongo.find(@conn, @post_coll, filter, [sort: %{"_id" => -1} , skip: skip, limit: 15 ])
      |> Enum.to_list()
      [ %{"pageCount" => pageCount} | list ]
    else
      list = Mongo.find(@conn, @post_coll, filter, [sort: %{"_id" => -1}])
      |> Enum.to_list()
      [ %{"pageCount" => pageCount} | list ]
    end
  end


  defp pageCountAllPostAllCitizen(groupObjectId, teamIds, teamObjectIds, loginUser) do
    filter = %{
      "groupId" => groupObjectId,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "specialPost",
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
        },
        %{"type" => "teamPost",
          "teamId" => %{
            "$in" => teamObjectIds
          }
        }
      ],
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @post_coll, filter, [projection: project])
  end


  def getAllPostForAdminSchool(groupObjectId, params) do
    filter = %{
      "groupId" => groupObjectId,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "teamPost"},
        %{"type" => "suggestionPost"}
      ],
      "isActive" => true,
    }
    {:ok, pageCount} = pageCountAllPostAllAdmin(groupObjectId)
    list = if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 15
      Mongo.find(@conn, @post_coll, filter, [sort: %{"_id" => -1} , skip: skip, limit: 15 ])
      |> Enum.to_list()
    else
      Mongo.find(@conn, @post_coll, filter, [sort: %{"_id" => -1}])
      |> Enum.to_list()
    end
    [ %{"pageCount" => pageCount} | list ]
  end


  defp pageCountAllPostAllAdmin(groupObjectId)  do
    filter = %{
      "groupId" => groupObjectId,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "teamPost"},
        %{"type" => "suggestionPost"},
      ],
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @post_coll, filter, [projection: project])
  end


  def getAllHomeWorkPostAdmin(groupObjectId, params) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    {:ok, pageCount} = pageCountAllHomeWorkPostAllAdmin(groupObjectId)
    list = if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 15
      Mongo.find(@conn, @school_assignment_col, filter, [sort: %{"_id" => -1} , skip: skip, limit: 15 ])
      |> Enum.to_list()
    else
      Mongo.find(@conn, @school_assignment_col, filter, [sort: %{"_id" => -1}])
      |> Enum.to_list()
    end
    [ %{"pageCount" => pageCount} | list ]
  end


  defp pageCountAllHomeWorkPostAllAdmin(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @school_assignment_col, filter, [projection: project])
  end


  def getAllNotesAndVideosPostAdmin(groupObjectId, params) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    {:ok, pageCount} = getAllNotesAndVideosPostAdmin(groupObjectId)
    list = if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 15
      pipeline = [%{"$match" => filter}, %{"$sort" => %{"_id" => -1}}, %{"$skip" => skip}, %{"$limit" => 15}]
      Mongo.aggregate(@conn, @view_subject_post_topic_col, pipeline)
      |> Enum.to_list()
    else
      pipeline = [%{"$match" => filter}, %{"$sort" => %{"_id" => -1}}]
      Mongo.find(@conn, @view_subject_post_topic_col, pipeline)
      |> Enum.to_list()
    end
    [ %{"pageCount" => pageCount} | list ]
  end


  defp getAllNotesAndVideosPostAdmin(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => -1
    }
    Mongo.count(@conn, @view_subject_post_topic_col, filter, [projection: project])
  end


  def getAllPostForUserSchool(groupObjectId, teamObjectIds, params, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "teamPost", "teamId" => %{ "$in" => teamObjectIds}},
        %{"type" => "feePost", "userId" => %{"$eq" => userObjectId}}
      ]
    }
    {:ok, pageCount} = getAllPostUserCount(groupObjectId, teamObjectIds)
    list = if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 15
      Mongo.find(@conn, @post_coll, filter, [sort: %{"_id" => -1}, limit: 15, skip: skip])
      |> Enum.to_list()
    else
      Mongo.find(@conn, @post_coll, filter)
      |> Enum.to_list()
    end
    [ %{"pageCount" => pageCount} | list ]
  end


  defp getAllPostUserCount(groupObjectId, teamObjectIds) do
    filter = %{
      "groupId" => groupObjectId,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "teamPost", "teamId" => %{ "$in" => teamObjectIds}}
      ],
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @post_coll, filter, [projection: project])
  end


  def getAllHomeWorkPostUser(groupObjectId, teamObjectIds, params) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "teamId" => %{
        "$in" => teamObjectIds
      }
    }
    {:ok, pageCount} = getAllHomeWorkPostUserCount(groupObjectId, teamObjectIds)
    list = if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 15
      Mongo.find(@conn, @school_assignment_col, filter, [sort: %{"_id" => -1}, limit: 15, skip: skip])
      |> Enum.to_list()
    else
      Mongo.find(@conn, @school_assignment_col, filter)
      |> Enum.to_list()
    end
    [ %{"pageCount" => pageCount} | list ]
  end


  defp getAllHomeWorkPostUserCount(groupObjectId, teamObjectIds)  do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "teamId" => %{
        "$in" => teamObjectIds
      }
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @school_assignment_col, filter, [projection: project])
  end


  def getAllNotesAndVideosPostUser(groupObjectId, teamObjectIds, params) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "teamId" => %{
        "$in" => teamObjectIds
      }
    }
    {:ok, pageCount} = getAllNotesAndVideosPostUserCount(groupObjectId, teamObjectIds)
    list = if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 15
      pipeline = [%{"$match" => filter }, %{"$sort" => %{"_id" => -1 }}, %{"$limit" => 15 }, %{"$skip" => skip }]
      Mongo.aggregate(@conn, @view_subject_post_topic_col, pipeline)
      |> Enum.to_list()
    else
      pipeline = [%{"$match" => filter }]
      Mongo.aggregate(@conn, @view_subject_post_topic_col, pipeline)
      |> Enum.to_list()
    end
    [ %{"pageCount" => pageCount} | list ]
  end


  defp getAllNotesAndVideosPostUserCount(groupObjectId, teamObjectIds) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "teamId" => %{
        "$in" => teamObjectIds
      }
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @view_subject_post_topic_col, filter, [projection: project])
  end


  def getTeamName(groupObjectId, teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 0,
      "name" => 1,
    }
    Mongo.find_one(@conn, @teams_coll, filter, [projection: project])
  end


  def getSubjectName(groupObjectId, subjectObjectId) do
    filter = %{
      "_id" => subjectObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 0,
      "subjectName" => 1,
    }
    Mongo.find_one(@conn, @subject_staff_coll, filter, [projection: project])
  end


  def getUserNameAndImage(userObjectId) do
    filter = %{
      "userId" => userObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 0,
      "name" => 1,
    }
    Mongo.find_one(@conn, @staff_coll, filter, [projection: project])
  end


  def getTeamDetails(teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "isActive" => true,
    }
    # IO.puts "#{filter}"
    Mongo.find_one(@conn, @teams_coll, filter)
  end


  #events api functions

  def getAllPostForAdminEvents(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "updatedAt" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @post_coll, filter, [projection: project, sort: %{"updatedAt" => -1}, limit: 1])
    |> Enum.to_list()
  end


  def getAllPostBasedOnAllTypesALLEvent(groupObjectId, loginUser, teamIds, teamObjectIds) do
    filter = %{
      "groupId" => groupObjectId,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "specialPost",
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
        },
        %{"type" => "teamPost",
          "teamId" => %{
            "$in" => teamObjectIds
          }
        }
      ],
      "isActive" => true,
    }
    project = %{
      "updatedAt" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @post_coll, filter, [projection: project, sort: %{"updatedAt" => -1}, limit: 1])
    |> Enum.to_list()
  end


  def getAllPostBasedOnAllTypesAllPresidentEvents(groupObjectId, loginUser, teamIds, teamObjectIds) do
    filter = %{
      "groupId" => groupObjectId,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "specialPost",
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
          ]
        },
        %{"type" => "teamPost",
          "teamId" => %{
            "$in" => teamObjectIds
          }
        }
      ],
      "isActive" => true,
    }
    project = %{
      "updatedAt" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @post_coll, filter, [projection: project, sort: %{"updatedAt" => -1}, limit: 1])
    |> Enum.to_list()
  end


  def getAllPostBasedOnAllTypesAllBoothWorkerEvents(groupObjectId, loginUser, teamIds, teamObjectIds) do
    filter = %{
      "groupId" => groupObjectId,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "specialPost",
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
        },
        %{"type" => "teamPost",
          "teamId" => %{
            "$in" => teamObjectIds
          }
        }
      ],
      "isActive" => true,
    }
    project = %{
      "updatedAt" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @post_coll, filter, [projection: project, sort: %{"updatedAt" => -1}, limit: 1])
    |> Enum.to_list()
  end


  def getAllPostBasedOnAllTypesAllCitizenEvents(groupObjectId, loginUser, teamIds, teamObjectIds) do
    filter = %{
      "groupId" => groupObjectId,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "specialPost",
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
        },
        %{"type" => "teamPost",
          "teamId" => %{
            "$in" => teamObjectIds
          }
        }
      ],
      "isActive" => true,
    }
    project = %{
      "updatedAt" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @post_coll, filter, [projection: project, sort: %{"updatedAt" => -1}, limit: 1])
    |> Enum.to_list()
  end


  def getAllPostForAdminSchoolEvents(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "teamPost"},
        %{"type" => "suggestionPost"}
      ],
      "isActive" => true,
    }
    project = %{
      "updatedAt" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @post_coll, filter, [projection: project, sort: %{"updatedAt" => -1}, limit: 1])
    |> Enum.to_list()
  end


  def getAllHomeWorkPostAdminEvents(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "updatedAt" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @school_assignment_col, filter, [projection: project, sort: %{"updatedAt" => -1}, limit: 1])
    |> Enum.to_list()
  end


  def getAllNotesAndVideosPostAdminEvents(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "updatedAt" => 1,
      "_id" => 0,
    }
    pipeline = [%{"$match" => filter }, %{"$project" => project}, %{"$sort": %{"updatedAt" => -1}}, %{"$limit" => 1}]
    Mongo.aggregate(@conn, @view_subject_post_topic_col, pipeline)
    |> Enum.to_list()
  end


  def getAllPostForUserSchoolEvents(groupObjectId, teamObjectIds) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "teamPost", "teamId" => %{ "$in" => teamObjectIds}}
      ]
    }
    project = %{
      "updatedAt" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @post_coll, filter, [projection: project, sort: %{"updatedAt" => -1}, limit: 1])
    |> Enum.to_list()
  end


  def getAllHomeWorkPostUserEvents(groupObjectId, teamObjectIds) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "teamId" => %{
        "$in" => teamObjectIds
      }
    }
    project = %{
      "updatedAt" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @school_assignment_col, filter, [projection: project, sort: %{"updatedAt" => -1}, limit: 1])
    |> Enum.to_list()
  end


  def getAllNotesAndVideosPostUserEvents(groupObjectId, teamObjectIds) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "teamId" => %{
        "$in" => teamObjectIds
      }
    }
    project = %{
      "updatedAt" => 1,
      "_id" => 0,
    }
    pipeline = [%{"$match" => filter }, %{"$project" => project}, %{"$sort": %{"updatedAt" => -1}}, %{"$limit" => 1}]
    Mongo.aggregate(@conn, @view_subject_post_topic_col, pipeline)
    |> Enum.to_list()
  end


  def addReportsListToDb(reports) do
    filter = %{
    }
    map = Mongo.find_one(@conn, @reports_col, filter)
    if !map do
      insertDoc = %{
        "reports" => reports
      }
      Mongo.insert_one(@conn, @reports_col, insertDoc)
    else
      update = %{
        "$push" => %{
          "reports" => %{
            "$each" => reports
         }
        }
      }
      Mongo.update_one(@conn, @reports_col, filter, update)
    end
  end


  def getReportsListToDb() do
    Mongo.find_one(@conn, @reports_col, %{})
  end


  def getTeamsArray(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 0,
      "teams" => 1,
    }
    Mongo.find_one(@conn, @group_teams_member_col, filter, [projection: project])
  end


  def getTeamsConstituencyAdmin(groupObjectId, teamIdList, params) do
    filter = %{
      "_id" => %{
        "$in" => teamIdList
      },
      "groupId" => groupObjectId,
      "isActive" => true,
      "category" => %{
        "$ne" => ["booth", "subBooth"]
      }
    }
    project = %{
      "_id" => 1,
      "name" => 1,
      "image" => 1,
    }
    if !is_nil(params["page"]) do
      # pageNo = String.to_integer(params["page"])
      # skip = (pageNo - 1) * 15
      # list = Mongo.find(@conn, @teams_coll, filter, [projection: project, limit: 15, skip: skip, sort: %{"name" => 1}])
      # |> Enum.to_list()
      # #getting count of teams from above query and appending to list has no of pages count
      # {:ok, pageCount} = getTeamsConstituencyAdminCount(groupObjectId, teamIdList)
      # list = [%{"pageCount" => pageCount}] ++ list
      Mongo.find(@conn, @teams_coll, filter, [projection: project, sort: %{"name" => 1}])
      |> Enum.to_list()
    else
      []
    end
  end


  # defp getTeamsConstituencyAdminCount(groupObjectId, teamIdList) do
  #   filter = %{
  #     "_id" => %{
  #       "$in" => teamIdList
  #     },
  #     "groupId" => groupObjectId,
  #     "isActive" => true,
  #     "category" => %{
  #       "$ne" => ["booth", "subBooth"]
  #     }
  #   }
  #   project = %{
  #     "_id" => 1,
  #   }
  #   Mongo.count(@conn, @teams_coll, filter, [projection: project])
  # end


  def getTeamsUserId(groupObjectId, teamIdList, params) do
    filter = %{
      "_id" => %{
        "$in" => teamIdList
      },
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
      "name" => 1,
      "image" => 1,
    }
    if !is_nil(params["page"]) do
      # pageNo = String.to_integer(params["page"])
      # skip = (pageNo - 1) * 15
      # list = Mongo.find(@conn, @teams_coll, filter, [projection: project, limit: 15, skip: skip, sort: %{"name" => 1}])
      # |> Enum.to_list()
      # #getting count of teams from above query and appending to list has no of pages count
      # {:ok, pageCount} = getTeamsUserCount(groupObjectId, teamIdList)
      # list = [%{"pageCount" => pageCount}] ++ list
      Mongo.find(@conn, @teams_coll, filter, [projection: project, sort: %{"name" => 1}])
      |> Enum.to_list()
    else
      []
    end
  end


  # defp getTeamsUserCount(groupObjectId, teamIdList) do
  #   filter = %{
  #     "_id" => %{
  #       "$in" => teamIdList
  #     },
  #     "groupId" => groupObjectId,
  #     "isActive" => true,
  #   }
  #   project = %{
  #     "_id" => 1,
  #   }
  #   Mongo.count(@conn, @teams_coll, filter, [projection: project])
  # end


  def getTeamsSchoolAdmin(groupObjectId, teamIdList, params) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "$and" => [
        %{
          "$or" => [
            %{
              "_id" => %{
                "$in" => teamIdList
              },
            }
          ]
        },
        %{
          "$or" => [
            %{
             "class" => true,
            }
          ]
        }
      ]
    }
    project = %{
      "_id" => 1,
      "name" => 1,
      "image" => 1,
    }
    if !is_nil(params["page"]) do
      # pageNo = String.to_integer(params["page"])
      # skip = (pageNo - 1) * 15
      # list = Mongo.find(@conn, @teams_coll, filter, [projection: project, limit: 15, skip: skip, sort: %{"name" => 1}])
      # |> Enum.to_list()
      # #getting count of teams from above query and appending to list has no of pages count
      # {:ok, pageCount} = getTeamsSchoolAdminCount(groupObjectId, teamIdList)
      # list = [%{"pageCount" => pageCount}] ++ list
      Mongo.find(@conn, @teams_coll, filter, [projection: project, sort: %{"name" => 1}])
      |> Enum.to_list()
    else
      []
    end
  end


  # defp getTeamsSchoolAdminCount(groupObjectId, teamIdList) do
  #   filter = %{
  #     "groupId" => groupObjectId,
  #     "isActive" => true,
  #     "$and" => [
  #       %{
  #         "$or" => [
  #           %{
  #             "_id" => %{
  #               "$in" => teamIdList
  #             },
  #           }
  #         ]
  #       },
  #       %{
  #         "$or" => [
  #           %{
  #            "class" => true,
  #           }
  #         ]
  #       }
  #     ]
  #   }
  #   project = %{
  #     "_id" => 1,
  #   }
  #   Mongo.count(@conn, @teams_coll, filter, [projection: project])
  # end


  def getTeamsArrayCommunityAdmin(groupObjectId, teamIdList, params) do
    filter = %{
      "_id" => %{
        "$in" => teamIdList
      },
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
      "name" => 1,
      "image" => 1,
    }
    if !is_nil(params["page"]) do
      # pageNo = String.to_integer(params["page"])
      # skip = (pageNo - 1) * 15
      # list = Mongo.find(@conn, @teams_coll, filter, [projection: project, limit: 15, skip: skip, sort: %{"name" => 1}])
      # |> Enum.to_list()
      # #getting count of teams from above query and appending to list has no of pages count
      # {:ok, pageCount} = getTeamsCommunityAdminCount(groupObjectId, teamIdList)
      # list = [%{"pageCount" => pageCount}] ++ list
      Mongo.find(@conn, @teams_coll, filter, [projection: project, sort: %{"name" => 1}])
      |> Enum.to_list()
    else
      []
    end
  end


  # defp getTeamsCommunityAdminCount(groupObjectId, teamIdList) do
  #   filter = %{
  #     "_id" => %{
  #       "$in" => teamIdList
  #     },
  #     "groupId" => groupObjectId,
  #     "isActive" => true,
  #   }
  #   project = %{
  #     "_id" => 1,
  #   }
  #   Mongo.count(@conn, @teams_coll, filter, [projection: project])
  # end


  def  getPostDetails(postObjectId) do
    filter = %{
      "_id" => postObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 0,
    }
    Mongo.find_one(@conn, @post_coll, filter, [projection: project])
  end


  def getLanguageListClass(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true,
      "isLanguage" => true,
    }
    project = %{
      "_id" => 1,
      "subjectName" => 1,
      "subjectPriority" => 1,
    }
    Mongo.find(@conn, @subject_staff_database_coll, filter, [projection: project])
  end


  def getLanguages() do
    Mongo.find_one(@conn, @language_coll, %{}, [projection: %{"languages" => 1,}])
  end


  def postLanguages(languages) do
    filter = %{}
    project = %{
      "_id" => 1,
    }
    map = Mongo.find_one(@conn, @language_coll, filter, [projection: project])
    if map do
      update = %{
        "$push" => %{
          "languages" => %{
            "$each" => languages
          }
        }
      }
      Mongo.update_one(@conn, @language_coll, %{}, update)
    else
      insertDoc = %{
        "isActive" => true,
        "insertedAt" => bson_time(),
        "updatedAt" => bson_time(),
        "languages" => languages
      }
      Mongo.insert_one(@conn, @language_coll, insertDoc)
    end
  end


  def getPostForUniqueId(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "uniquePostId" => %{
        "$exists" => false
      },
      "$and" => [
        %{
          "$or" => [
            %{"type" => "teamPost"},
            %{"type" => "groupPost"},
            %{"type" => "specialPost"},
            %{"type" => "suggestionPost"}
          ]
        },
      ],
      "isActive" => true,
    }
    Mongo.find(@conn, @post_coll, filter)
    |> Enum.to_list()
  end


  def updatePost(groupObjectId, post, postObjectId) do
    filter = %{
      "_id" => postObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => post
    }
    Mongo.update_one(@conn, @post_coll, filter, update)
  end
end
