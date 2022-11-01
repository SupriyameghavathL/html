defmodule GruppieWeb.Repo.SchoolFeeRepo do
  import GruppieWeb.Handler.TimeNow
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Handler.SchoolFeeHandler

  @conn :mongo

  @teams_col "teams"

  @group_team_members_col "group_team_members"

  @school_fee_db_col "school_fees_database"

  @student_db_col "student_database"

  @view_school_fee_paid_details "VW_SCHOOL_FEE_PAID_DETAILS"

  @view_school_fee_due_dates "VW_SCHOOL_FEE_DB_DUE_DATES"

  @user_col "users"

  # @school_class_fee "school_class_fees"

  @notification_token "notification_tokens"

  @post_coll "posts"

  def getClassFees(groupObjectId) do
    filter = %{
       "groupId" => groupObjectId,
       "class" => true,
       "isActive" => true,
       "gruppieClassName" => %{
        "$exists" => true,
       },
    }
    project = %{
      "name" => 1,
      "image" => 1,
      "_id" => 1,
    }
    Mongo.find(@conn, @teams_col, filter, [projection: project])
    |> Enum.to_list()
  end


  def getClassFeesStudent(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{
      "teams.teamId" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @group_team_members_col, filter, [projection: project])
  end


  def getTeamsClassForParents(groupObjectId, teamObjectIds) do
    filter = %{
      "_id" => %{
        "$in" => teamObjectIds,
      },
      "groupId" => groupObjectId,
      "gruppieClassName" => %{
        "$exists" => true,
      },
      "isActive" => true
    }
    project = %{
      "name" => 1,
      "image" => 1,
      "_id" => 1,
    }
    Mongo.find(@conn, @teams_col, filter, [projection: project])
    |> Enum.to_list()
  end


  def canPostTrue(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "canPost" => true,
      "isActive" => true
    }
    project = %{
      "userId" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @group_team_members_col, filter, [projection: project])
  end


  def getStudentDbDetailById(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{"attendance" => 0}
    Mongo.find_one(@conn, @student_db_col, filter, [projection: project])
    #|> Enum.to_list
    #|> hd
  end


  def addFeePaidDetailsByStudent(changeset, groupObjectId, team, studentDb, params) do
    paymentMode = String.downcase(changeset.paymentMode)
    if paymentMode == "cheque" do
      if String.length(params["chequeNo"]) == 6 do
        changeset = changeset
        |> Map.put_new(:studentName, studentDb["name"])
        |> Map.put_new(:className, team["name"])
        |> Map.put_new(:paymentId, encode_object_id(new_object_id()))
        |> Map.put_new(:status, "notApproved")
        |> Map.put_new(:paidAtTime, bson_time())
        |> Map.put_new(:paidUserId, encode_object_id(studentDb["userId"]))
        |> Map.put_new(:bankName, params["bankName"])
        |> Map.put_new(:bankBranch, params["bankBranch"])
        |> Map.put_new(:chequeNo, params["chequeNo"])
        |> Map.put_new(:date, params["date"])
        |> Map.put(:paymentMode, paymentMode)
        |> Map.delete(changeset.paymentMode)
        successStudent(changeset, groupObjectId, team, studentDb)
      else
       {:invalidCheque, "invalid ChequeNo"}
      end
    else
      changeset = changeset
      |> Map.put_new(:studentName, studentDb["name"])
      |> Map.put_new(:className, team["name"])
      |> Map.put_new(:paymentId, encode_object_id(new_object_id()))
      |> Map.put_new(:status, "notApproved")
      |> Map.put_new(:paidAtTime, bson_time())
      |> Map.put_new(:paidUserId, encode_object_id(studentDb["userId"]))
      |> Map.put(:paymentMode, paymentMode)
      |> Map.delete(changeset.paymentMode)
      successStudent(changeset, groupObjectId, team, studentDb)
    end
  end


  def addFeePaidDetailsByAccountant(changeset, groupObjectId, team, studentDb, userObjectId, params, accountantName) do
    paymentMode = String.downcase(changeset.paymentMode)
    if paymentMode == "cheque" do
      if String.length(params["chequeNo"]) == 6 do
        changeset = changeset
        |> Map.put_new(:studentName, studentDb["name"])
        |> Map.put_new(:className, team["name"])
        |> Map.put_new(:paymentId, encode_object_id(new_object_id()))
        |> Map.put_new(:status, "notApproved")
        |> Map.put_new(:paidAtTime, bson_time())
        |> Map.put_new(:paidUserId, encode_object_id(userObjectId))
        |> Map.put_new(:bankName, params["bankName"])
        |> Map.put_new(:bankBranch, params["bankBranch"])
        |> Map.put_new(:chequeNo, params["chequeNo"])
        |> Map.put_new(:date, params["date"])
        |> Map.put_new(:approvedUserId, encode_object_id(userObjectId))
        |> Map.put_new(:approvedTime, bson_time())
        |> Map.put_new(:approverName, accountantName)
        |> Map.put(:paymentMode, paymentMode)
        |> Map.delete(changeset.paymentMode)
        success(changeset, groupObjectId, team, studentDb, userObjectId)
      else
       {:invalidCheque, "invalid ChequeNo"}
      end
    else
      changeset = changeset
      |> Map.put_new(:studentName, studentDb["name"])
      |> Map.put_new(:className, team["name"])
      |> Map.put_new(:paymentId, encode_object_id(new_object_id()))
      |> Map.put_new(:status, "notApproved")
      |> Map.put_new(:paidAtTime, bson_time())
      |> Map.put_new(:paidUserId, encode_object_id(userObjectId))
      |> Map.put_new(:approvedUserId, encode_object_id(userObjectId))
      |> Map.put_new(:approvedTime, bson_time())
      |> Map.put_new(:approverName, accountantName)
      |> Map.put(:paymentMode, paymentMode)
      |> Map.delete(changeset.paymentMode)
      success(changeset, groupObjectId, team, studentDb, userObjectId)
    end
  end

  def checkThisPaymentIsAlreadyApproved(groupObjectId, teamObjectId, userObjectId, payment_id) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "feePaidDetails.paymentId" => payment_id,
      "feePaidDetails.status" => "approved",
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_school_fee_paid_details, filter, [projection: project])
  end


  def getIndividualStudentFeeDetailsByPaymentId(groupObjectId, teamObjectId, userObjectId, payment_id) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "feePaidDetails.paymentId" => payment_id,
      "isActive" => true
    }
    pipeline = [%{"$match" => filter}]
    Mongo.aggregate(@conn, @view_school_fee_paid_details, pipeline)
    |> Enum.to_list
    |> hd
  end


  def pushPaymentDetails(groupObjectId, teamObjectId, userObjectId, installmentList) do
    #update status "completed" for dueDatesCompleted
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    update = %{
      "$push" => %{
        "installmentPaymentDetails" => %{
          "$each" => installmentList
        }
      }
    }
    Mongo.update_one(@conn, @school_fee_db_col, filter, update)
  end


  def updateBalanceAmount(groupObjectId, teamObjectId, userObjectId, date, balance) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "dueDates.date" => date,
      "isActive" => true
    }
    update = %{
      "$set" => %{
        "dueDates.$.balance" => balance
      }
    }
    Mongo.update_one(@conn, @school_fee_db_col, filter, update)
  end


  def dueDateStatusUpdate(groupObjectId, teamObjectId, userObjectId, dueDate, paidDate, status, fineAmount) do
    #update status "completed" for dueDatesCompleted
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "dueDates.date" => dueDate,
      "isActive" => true
    }
    update = if status == "completed" do
      %{"$set" => %{"dueDates.$.status" => "completed", "dueDates.$.paidDate" => paidDate, "dueDates.$.fineAmount" => fineAmount}}
    else
      %{"$unset" => %{"dueDates.$.status" => "completed"}}
    end
    Mongo.update_one(@conn, @school_fee_db_col, filter, update)
  end


  def approveFeePaidByStudent(groupObjectId, teamObjectId, userObjectId, payment_id, totalAmountPaid, totalBalance) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "feePaidDetails.paymentId" => payment_id,
      "isActive" => true
    }
    updateChangeset =  %{
      "$set" =>  %{
        "totalAmountPaid" => totalAmountPaid,
        "totalBalance" => totalBalance,
        "feePaidDetails.$.status" => "approved",
        "isActive" => true
      }}
    Mongo.update_one(@conn, @school_fee_db_col, filter, updateChangeset)
  end


  defp success(changeset, groupObjectId, team, studentDb, _userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => team["_id"],
      "userId" => studentDb["userId"],
      "isActive" => true,
    }
    update = %{
      "$push" => %{
        "feePaidDetails" => changeset,
      }
    }
    Mongo.update_one(@conn, @school_fee_db_col, filter, update)
    SchoolFeeHandler.approveFeePaidByAdmin(groupObjectId, team["_id"], studentDb["userId"], changeset.paymentId)
  end


  defp successStudent(changeset, groupObjectId, team, studentDb) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => team["_id"],
      "userId" => studentDb["userId"],
      "isActive" => true,
    }
    update = %{
      "$push" => %{
        "feePaidDetails" => changeset,
      }
    }
    Mongo.update_one(@conn, @school_fee_db_col, filter, update)
  end


  def checkReverseDate(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "dueDates.dateReverse" => %{
        "$exists" => false,
      }
    }
    project = %{
      "_id" => 0,
      "dueDates" => 1,
      "addFineAmount" => 1,
    }
    Mongo.find_one(@conn, @school_fee_db_col, filter, [projection: project])
  end


  def getDueDateForFine(groupObjectId, teamObjectId, userObjectId, date) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true,
      "dueDates.dateReverse" => %{
        "$lte" => date,
      },
      "dueDates.status" => %{
        "$exists" => false,
      }
    }
    project = %{
      "dueDates" => 1,
      "addFineAmount" => 1,
      "_id" => 0,
    }
    pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$limit" => 1}]
    Mongo.aggregate(@conn, @view_school_fee_due_dates, pipeline)
    |> Enum.to_list()
  end


  def getTeamIds(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "class" => true,
    }
    project = %{
     "_id" => 1,
     "name" => 1,
    }
    Mongo.find(@conn, @teams_col, filter, [projection: project])
    |>Enum.to_list()
  end


  def getTotalFeeAmountAndPaidTeam(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "totalFee" => 1,
      "totalAmountPaid" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @school_fee_db_col, filter, [projection: project])
    |>Enum.to_list()
  end


  def getIsActiveUserId(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "userId" => 1,
      "_id" => 0,
    }
    list = Mongo.find(@conn, @student_db_col, filter, [projection: project])
    |> Enum.to_list()
    userObjectIds = for userId <- list do
      userId["userId"]
    end
    getTotalFeeOfTheTeam(groupObjectId, teamObjectId, userObjectIds)
  end


  defp getTotalFeeOfTheTeam(groupObjectId, teamObjectId, userObjectIds) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{
        "$in" => userObjectIds
      },
      "isActive" => true,
    }
    project = %{
      "totalFee" => 1,
      "totalAmountPaid" => 1,
      "dueDates" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @school_fee_db_col, filter, [projection: project])
    |>Enum.to_list()
  end


  def getStudentIds(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId"=> teamObjectId,
      "isActive" => true,
    }
    project = %{
      "userId" => 1,
      "name" => 1,
      "fatherName" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @student_db_col, filter, [projection: project])
    |> Enum.to_list()
  end


  def getClassStudentFee(groupObjectId, teamObjectId, userObjectIds) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{
        "$in" => userObjectIds
      },
      "isActive" => true,
    }
    project = %{
      "dueDates" => 1,
      "totalAmountPaid" => 1,
      "totalFee" => 1,
      "_id" => 0,
      "userId" => 1,
    }
    Mongo.find(@conn, @school_fee_db_col, filter, [projection: project])
    |> Enum.to_list()
  end


  def getPhoneList(userObjectIds) do
    filter = %{
      "_id" => %{
        "$in" => userObjectIds
      }
    }
    project = %{
      "userId" => "$$CURRENT._id",
      "phone" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @user_col, filter, [projection: project])
    |> Enum.to_list()
  end


  # def getInstallmentOfClass(groupObjectId, teamObjectId) do
  #   filter = %{
  #     "groupId" => groupObjectId,
  #     "teamId" => teamObjectId,
  #     "isActive" => true,
  #   }
  #   project = %{
  #     "_id" => 0,
  #     "dueDates" => 1,
  #   }
  #   Mongo.find_one(@conn, @school_class_fee, filter, [projection: project])
  # end


  def getStudentsListForReminder123(groupObjectId, teamObjectId, userObjectIds, date) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{
        "$in" => userObjectIds
      },
      "isActive" => true,
      "dueDates.dateReverse" => %{
        "$lte" => date,
      },
      "dueDates.status" => %{
        "$exists" => false,
      }
    }
    # IO.puts "#{filter}"
    project = %{
      "_id" => 0,
      "userId" => 1,
      "dueDates.minimumAmount" => 1,
      "totalAmountPaid" => 1,
    }
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    Mongo.aggregate(@conn, @view_school_fee_due_dates, pipeline)
    |> Enum.to_list()
  end



  def getStudentsListForReminder(groupObjectId, teamObjectId, userObjectId, date) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true,
      "dueDates.dateReverse" => %{
        "$lte" => date,
      },
      "dueDates.status" => %{
        "$exists" => false,
      }
    }
    project = %{
      "_id" => 0,
      "userId" => 1,
      "dueDates.minimumAmount" => 1,
      "totalAmountPaid" => 1,
    }
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    Mongo.aggregate(@conn, @view_school_fee_due_dates, pipeline)
    |> Enum.to_list()
  end


  def getStudentsReminderList(groupObjectId, teamObjectId, userObjectIds, reverseDateString) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{
        "$in" => userObjectIds
      },
      "isActive" => true,
      "dueDates.dateReverse" => %{
        "$gte" => reverseDateString,
      },
      "dueDates.status" => %{
        "$exists" => false,
      }
    }
    project = %{
      "_id" => 0,
      "userId" => 1,
    }
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    Mongo.aggregate(@conn, @view_school_fee_due_dates, pipeline)
    |> Enum.to_list()
  end


  def getDeviceTokenId(userObjectIds) do
    filter = %{
      "userId" => %{
        "$in" => userObjectIds
      },
      "category" => "school",
    }
    project = %{
      "deviceToken" => 1,
      "deviceType" => 1,
      "userId" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @notification_token, filter, [projection: project])
    |> Enum.to_list()
  end


  # def getDeviceTokenId(userObjectId) do
  #   filter = %{
  #     "userId" => userObjectId,
  #     "category" => "school",
  #   }
  #   project = %{
  #     "deviceToken" => 1,
  #     "deviceType" => 1,
  #     "userId" => 1,
  #     "_id" => 0,
  #   }
  #   Mongo.find(@conn, @notification_token, filter, [projection: project])
  #   |> Enum.to_list()
  # end


  def postFeeReminder(feePostList) do
    Mongo.insert_many(@conn, @post_coll, feePostList)
  end


  def feeRevert(groupObjectId, teamObjectId, userObjectId, paymentId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "feePaidDetails.paymentId" => paymentId
    }
    project = %{
      "feePaidDetails.$" => 1,
      "totalAmountPaid" => 1,
      "totalBalance" => 1,
      "installmentPaymentDetails" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @school_fee_db_col, filter, [projection: project])
  end


  def revertInstallment(groupObjectId, teamObjectId, userObjectId, paymentId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "installmentPaymentDetails.transactionId" => paymentId
    }
    project = %{
      "installmentPaymentDetails.$" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @school_fee_db_col, filter, [projection: project])
  end


  def revertFeesAndInstallment(groupObjectId, teamObjectId, userObjectId, paymentId, totalBalanceMap, balance, date) do
    revertFees(groupObjectId, teamObjectId, userObjectId, paymentId, totalBalanceMap)
    #reverting insatllment
    installmentRevert(groupObjectId, teamObjectId, userObjectId, paymentId, balance, date)
  end

  def installmentRevert(groupObjectId, teamObjectId, userObjectId, paymentId, balance, date) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "dueDates.date" => date
    }
    update = %{
      "$set" => %{
        "dueDates.$.balance" => balance,
      },
      "$unset" => %{
        "dueDates.$.status" => "completed"
      }
    }
    Mongo.update_one(@conn, @school_fee_db_col, filter, update)
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "installmentPaymentDetails.transactionId" => paymentId
    }
    update = %{
      "$set" => %{
        "installmentPaymentDetails.$.revert" => true
      }
    }
    Mongo.update_one(@conn, @school_fee_db_col, filter, update)
  end

  def revertFees(groupObjectId, teamObjectId, userObjectId, paymentId, totalBalanceMap) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "feePaidDetails.paymentId" => paymentId
    }
    update = %{
      "$set" => %{
        "totalAmountPaid" => totalBalanceMap["totalAmountPaid"],
        "totalBalance" => totalBalanceMap["totalBalance"],
        "feePaidDetails.$.revert" => true
      }
    }
    Mongo.update_one(@conn, @school_fee_db_col, filter, update)
  end
end
