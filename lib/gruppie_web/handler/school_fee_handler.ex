defmodule GruppieWeb.Handler.SchoolFeeHandler do
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.SchoolFeeRepo
  alias GruppieWeb.Repo.TeamRepo
  alias GruppieWeb.Repo.ConstituencyRepo


  def getClassFees(groupObjectId) do
    SchoolFeeRepo.getClassFees(groupObjectId)
  end


  def getClassFeesStudent(groupObjectId, userObjectId) do
    teamsList = SchoolFeeRepo.getClassFeesStudent(groupObjectId, userObjectId)
    teamObjectIds = for teamIds <- teamsList["teams"] do
      teamIds["teamId"]
    end
    SchoolFeeRepo.getTeamsClassForParents(groupObjectId, teamObjectIds)
  end


  def canPostTrue(groupObjectId, userObjectId) do
    SchoolFeeRepo.canPostTrue(groupObjectId, userObjectId)
  end


  def addFeePaidDetailsByAccountant(changeset, groupObjectId, team_id, userObjectId, studentObjectId, params, accountantName) do
    team = TeamRepo.get(team_id)
    #get student detail by userId in studentRegister
    student = SchoolFeeRepo.getStudentDbDetailById(groupObjectId, team["_id"], studentObjectId)
    changeset = if Map.has_key?(changeset, :fineAmount) do
      changeset
      |> Map.put(:amountPaidWithFine, changeset.amountPaid + changeset.fineAmount)
      |> Map.put(:amountPaid, changeset.amountPaid)
    else
      changeset
    end
    SchoolFeeRepo.addFeePaidDetailsByAccountant(changeset, groupObjectId, team, student, userObjectId, params, accountantName)
  end


  def addFeePaidDetailsByStudent(changeset, groupObjectId, team_id, userObjectId, params) do
    team = TeamRepo.get(team_id)
    #get student detail by userId in studentRegister
    student = SchoolFeeRepo.getStudentDbDetailById(groupObjectId, team["_id"], userObjectId)
    SchoolFeeRepo.addFeePaidDetailsByStudent(changeset, groupObjectId, team, student, params)
  end


  def approveFeePaidByAdmin(groupObjectId, teamObjectId, userObjectId, payment_id) do
    #check this paymentId is already approved
    {:ok, checkAlreadyApproved} = SchoolFeeRepo.checkThisPaymentIsAlreadyApproved(groupObjectId, teamObjectId, userObjectId, payment_id)
    if checkAlreadyApproved == 0 do
      #get this student payment details to approve
      studentPaymentDetail = SchoolFeeRepo.getIndividualStudentFeeDetailsByPaymentId(groupObjectId, teamObjectId, userObjectId, payment_id)
      amountPaidNow = studentPaymentDetail["feePaidDetails"]["amountPaid"]
      totalBalance = studentPaymentDetail["totalBalance"] - amountPaidNow #totalBalance - amountPaidNow
      totalAmountPaid = studentPaymentDetail["totalAmountPaid"] + amountPaidNow #totalAmountPaid + amountPaidNow
      paidDate = studentPaymentDetail["feePaidDetails"]["paidDate"]
      fineAmount = studentPaymentDetail["feePaidDetails"]["fineAmount"]
      #to add previous due amount to current
      {list, _} = Enum.reduce(studentPaymentDetail["dueDates"], {[], 0}, fn %{"minimumAmount" => ma_str} = x, {l, sum} ->
        new_sum = sum + String.to_integer(ma_str)
        {[%{x | "minimumAmount" => to_string(new_sum)} | l], new_sum}
      end)  #Here i will get due amount with previous sum in list
      #check if due minimum amount is less than amount paid to send status = completed
      Enum.reduce(list, [], fn k, _acc ->
        if totalAmountPaid >= String.to_integer(k["minimumAmount"]) do
          #update status = completed for this date
          if !Map.has_key?(k, "paidDate") do
            SchoolFeeRepo.dueDateStatusUpdate(groupObjectId, teamObjectId, userObjectId, k["date"], paidDate, "completed", fineAmount)
          end
        else
          #unset status=completed if exist for this date
          SchoolFeeRepo.dueDateStatusUpdate(groupObjectId, teamObjectId, userObjectId, k["date"], "", "notCompleted", "")
        end
      end)
      SchoolFeeRepo.approveFeePaidByStudent(groupObjectId, teamObjectId, userObjectId, payment_id, totalAmountPaid, totalBalance)
    else
      {:ok, "already approved"}
    end
  end


  def approveFeePaidByAdmin123(groupObjectId, teamObjectId, userObjectId, payment_id) do
    #check this paymentId is already approved
    {:ok, checkAlreadyApproved} = SchoolFeeRepo.checkThisPaymentIsAlreadyApproved(groupObjectId, teamObjectId, userObjectId, payment_id)
    if checkAlreadyApproved == 0 do
      #get this student payment details to approve
      studentPaymentDetail = SchoolFeeRepo.getIndividualStudentFeeDetailsByPaymentId(groupObjectId, teamObjectId, userObjectId, payment_id)
      amountPaidNow = studentPaymentDetail["feePaidDetails"]["amountPaid"]
      totalBalance = studentPaymentDetail["totalBalance"] - amountPaidNow #totalBalance - amountPaidNow
      totalAmountPaid = studentPaymentDetail["totalAmountPaid"] + amountPaidNow #totalAmountPaid + amountPaidNow
      paidDate = studentPaymentDetail["feePaidDetails"]["paidDate"]
      fineAmount = studentPaymentDetail["feePaidDetails"]["fineAmount"]
      #to add previous due amount to current
      {list, _} = Enum.reduce(studentPaymentDetail["dueDates"], {[], 0}, fn %{"minimumAmount" => ma_str} = x, {l, sum} ->
        new_sum = sum + String.to_integer(ma_str)
        {[%{x | "minimumAmount" => to_string(new_sum)} | l], new_sum}
      end)  #Here i will get due amount with previous sum in list
      #check if due minimum amount is less than amount paid to send status = completed
      Enum.reduce(list, [], fn k, _acc ->
        if totalAmountPaid >= String.to_integer(k["minimumAmount"]) do
          #update status = completed for this date
          SchoolFeeRepo.dueDateStatusUpdate(groupObjectId, teamObjectId, userObjectId, k["date"], paidDate, "completed", fineAmount)
        else
          #unset status=completed if exist for this date
          SchoolFeeRepo.dueDateStatusUpdate(groupObjectId, teamObjectId, userObjectId, k["date"], paidDate, "notCompleted", "")
        end
      end)
      #installment details update logics
      installmentLogics(studentPaymentDetail, paidDate, fineAmount, totalAmountPaid, groupObjectId, teamObjectId, userObjectId)
      SchoolFeeRepo.approveFeePaidByStudent(groupObjectId, teamObjectId, userObjectId, payment_id, totalAmountPaid, totalBalance)
    else
      {:ok, "already approved"}
    end
  end


  #installment details update logics
  defp installmentLogics(studentPaymentDetail, paidDate, fineAmount, totalAmountPaid, groupObjectId, teamObjectId, userObjectId) do
    installmentList = Enum.reduce(studentPaymentDetail["dueDates"], %{totalAmountPaid: totalAmountPaid, list: []}, fn k, acc ->
      accMap = if !Map.has_key?(k , "status") do
        if acc.totalAmountPaid >= String.to_integer(k["minimumAmount"]) do
          k = k
          |> Map.put("fineAmount", fineAmount)
          |> Map.put("paidDate", paidDate)
          |> Map.put("paidAmount", k["balance"])
          |> Map.put("balance", 0)
          |> Map.delete("reminderDateList")
          SchoolFeeRepo.updateBalanceAmount(groupObjectId, teamObjectId, userObjectId, k["date"], String.to_integer(k["minimumAmount"]) - acc.totalAmountPaid)
          %{totalAmountPaid: acc.totalAmountPaid - String.to_integer(k["minimumAmount"]), list: acc.list ++ [k]}
        else
          if acc.totalAmountPaid > 0 do
            k = k
            |> Map.put("fineAmount", fineAmount)
            |> Map.put("paidDate", paidDate)
            |> Map.put("balance", String.to_integer(k["minimumAmount"]) - acc.totalAmountPaid)
            |> Map.put("paidAmount", k["balance"] - (String.to_integer(k["minimumAmount"]) - acc.totalAmountPaid))
            |> Map.delete("reminderDateList")
            #balance amount
            SchoolFeeRepo.updateBalanceAmount(groupObjectId, teamObjectId, userObjectId, k["date"], String.to_integer(k["minimumAmount"]) - acc.totalAmountPaid)
            %{totalAmountPaid: acc.totalAmountPaid - String.to_integer(k["minimumAmount"]),list: acc.list ++ [k]}
          else
            %{totalAmountPaid: acc.totalAmountPaid, list: acc.list}
          end
        end
      else
        %{totalAmountPaid: acc.totalAmountPaid - String.to_integer(k["minimumAmount"]), list: acc.list}
      end
      accMap
    end)
    SchoolFeeRepo.pushPaymentDetails(groupObjectId, teamObjectId, userObjectId, installmentList.list)
  end


 def addFeeFinesToStudent(groupObjectId, teamObjectId, userObjectId, date) do
    #checking whether reverse date exists or not
    checkReverseDate = SchoolFeeRepo.checkReverseDate(groupObjectId, teamObjectId, userObjectId)
    if checkReverseDate do
      dueDateList = for dueDate <- checkReverseDate["dueDates"] do
        if !Map.has_key?(dueDate, "status") do
          dueDate
        end
      end
      dueDateList = dueDateList
      |> Enum.reject(&is_nil/1)
      if dueDateList != [] do
        dueDateMap = hd(dueDateList)
        #to convert date to reverse
        dueDateArray = String.split(dueDateMap["date"],"-")
        reverseDate = Enum.at(dueDateArray, 2)<>"-"<>Enum.at(dueDateArray, 1)<>"-"<>Enum.at(dueDateArray, 0)
        {:ok, date1 } = DateTimeParser.parse_datetime(reverseDate , assume_time: true)
        {:ok, date2 } = DateTimeParser.parse_datetime(date, assume_time: true)
        dateInSec = NaiveDateTime.diff(date2, date1)
        if Map.has_key?(checkReverseDate, "addFineAmount") do
          amount = Kernel.trunc((dateInSec/86400) * checkReverseDate["addFineAmount"])
          if amount < 0 do
            0
          else
            amount
          end
        else
          0
        end
      else
        0
      end
    else
      dueDateList = SchoolFeeRepo.getDueDateForFine(groupObjectId, teamObjectId, userObjectId, date)
      if dueDateList != [] do
        dueDate = hd(dueDateList)
        {:ok, date1 } = DateTimeParser.parse_datetime(dueDate["dueDates"]["dateReverse"] , assume_time: true)
        {:ok, date2 } = DateTimeParser.parse_datetime(date, assume_time: true)
        dateInSec = NaiveDateTime.diff(date2, date1)
        if Map.has_key?(dueDate, "addFineAmount") do
          Kernel.trunc((dateInSec/86400) * dueDate["addFineAmount"])
        else
          0
        end
      else
        0
      end
    end
  end


  def getTotalFeeAmountAndPaid(groupObjectId) do
    #get class true team ids
    teamIds = SchoolFeeRepo.getTeamIds(groupObjectId)
    list = for teamId <- teamIds do
      #get userIds isActive = true
      activeUserFees = SchoolFeeRepo.getIsActiveUserId(groupObjectId, teamId["_id"])
      Enum.reduce(activeUserFees, %{totalFeeSchool: 0, totalAmountReceived: 0}, fn k, acc ->
        %{totalFeeSchool: acc.totalFeeSchool + k["totalFee"], totalAmountReceived: acc.totalAmountReceived + k["totalAmountPaid"] }
      end)
    end
    Enum.reduce(list, %{totalFeeSchool: 0, totalAmountReceived: 0}, fn k, acc ->
      %{totalFeeSchool: acc.totalFeeSchool + k.totalFeeSchool, totalAmountReceived: acc.totalAmountReceived + k.totalAmountReceived}
    end)
  end


  def getTotalFeeAmountClassWise(groupObjectId, teamObjectId) do
    activeUserFees = SchoolFeeRepo.getIsActiveUserId(groupObjectId, teamObjectId)
    Enum.reduce(activeUserFees, %{totalFeeSchool: 0, totalAmountReceived: 0}, fn k, acc ->
      %{totalFeeSchool: acc.totalFeeSchool + k["totalFee"], totalAmountReceived: acc.totalAmountReceived + k["totalAmountPaid"]}
    end)
  end


  def getClassStudentFee(groupObjectId, teamObjectId) do
    #get student ids and details
    studentUserId = SchoolFeeRepo.getStudentIds(groupObjectId, teamObjectId)
    userObjectIds = for userId <- studentUserId do
      userId["userId"]
    end
    studentsList = SchoolFeeRepo.getClassStudentFee(groupObjectId, teamObjectId, userObjectIds)
    if studentsList != [] do
      list = Enum.reduce(studentsList, [], fn k, acc ->
        list1 = Enum.reduce(k["dueDates"], %{"list" => [], "rem" => 0, "inc" => 1 }, fn v, acc1 ->
          map = %{"totalAmount" => k["totalAmountPaid"] - acc1["rem"]}
          dueDatesMap = if map["totalAmount"] >= String.to_integer(v["minimumAmount"]) do
            %{
              "dueDate" => v["date"],
              "minimumAmount" => v["minimumAmount"],
              "paidAmount" => v["minimumAmount"],
              "balance" => 0,
              "installmentNo" => acc1["inc"],
            }
          else
            if  map["totalAmount"] > 0  do
              %{
                "dueDate" => v["date"],
                "minimumAmount" => v["minimumAmount"],
                "paidAmount" =>   Integer.to_string(map["totalAmount"]),
                "balance" =>  String.to_integer(v["minimumAmount"]) - map["totalAmount"],
                "installmentNo" => acc1["inc"],
              }
            else
              if map["totalAmount"] == 0 do
                %{
                  "dueDate" => v["date"],
                  "minimumAmount" => v["minimumAmount"],
                  "paidAmount" => "0",
                  "balance" =>  String.to_integer(v["minimumAmount"]) - map["totalAmount"],
                  "installmentNo" => acc1["inc"],
                }
              else
                %{
                  "dueDate" => v["date"],
                  "minimumAmount" => v["minimumAmount"],
                  "paidAmount" => "0",
                  "balance" =>  String.to_integer(v["minimumAmount"]),
                  "installmentNo" => acc1["inc"],
                }
              end
            end
          end
          dueDatesMap = if Map.has_key?(v, "paidDate") do
            dueDatesMap
            |> Map.put("paidDate", v["paidDate"])
          else
            dueDatesMap
          end
          dueDatesMap = if Map.has_key?(v, "paidDate") do
            dueDatesMap
            |> Map.put("fineAmount", v["fineAmount"])
          else
            dueDatesMap
          end
         %{"list" => acc1["list"] ++ [dueDatesMap], "rem" => acc1["rem"] + String.to_integer(v["minimumAmount"]), "inc" => acc1["inc"] + 1}
        end)
        k = k
        |> Map.put("dueWisePayment", list1["list"])
        |> Map.put("lengthOfInstallment", length(list1["list"]))
        |> Map.delete("dueDates")
        acc ++ [k]
      end)
      list =  Enum.map(studentUserId, fn k ->
        studentDetails = Enum.find(list, fn v -> v["userId"] == k["userId"] end)
        if studentDetails do
          Map.merge(k, studentDetails)
        end
      end)
      list =list
      |> Enum.reject(&is_nil/1)
      #getting installment totalAmount and receivedAmount
      list = Enum.sort_by(list, & (&1["lengthOfInstallment"]), &>=/2)
      length = hd(list)["lengthOfInstallment"]
      installmentList = for installmentNo <- 1..length do
        installMentDetails = Enum.reduce(list, %{"totalAmount" => 0, "totalAmountReceived"=> 0}, fn k, acc ->
          list = Enum.reduce(k["dueWisePayment"], %{"totalAmount" => 0, "totalAmountReceived" => 0},fn k1, acc1 ->
            if k1["installmentNo"] == installmentNo do
              %{
                "totalAmount" => acc1["totalAmount"] + String.to_integer(k1["minimumAmount"]),
                "totalAmountReceived" => acc1["totalAmountReceived"] + String.to_integer(k1["paidAmount"])
              }
            else
              acc1
            end
          end)
          %{
            "totalAmount" => acc["totalAmount"] + list["totalAmount"],
            "totalAmountReceived" => acc["totalAmountReceived"] + list["totalAmountReceived"]
          }
        end)
        installMentDetails
        |> Map.put("installmentNo", installmentNo)
        |> Map.put("balanceAmount", installMentDetails["totalAmount"] -  installMentDetails["totalAmountReceived"])
      end
      installmentMap = %{
        "installmentsReport" => installmentList
      }
      [installmentMap | list ]
    else
      []
    end
  end


  def getClassFeeReportList(groupObjectId) do
    #get class true team ids
    teamIds = SchoolFeeRepo.getTeamIds(groupObjectId)
    Enum.reduce(teamIds, [], fn k,  acc ->
      #get userIds isActive = true
      activeUserFees = SchoolFeeRepo.getIsActiveUserId(groupObjectId, k["_id"])
      totalClassFeeList = Enum.reduce(activeUserFees, %{totalFeeClass: 0, totalAmountReceivedClass: 0}, fn k, acc1 ->
        %{totalFeeClass: acc1.totalFeeClass + k["totalFee"], totalAmountReceivedClass: acc1.totalAmountReceivedClass + k["totalAmountPaid"]}
      end)
      map = %{
        "name" => k["name"],
        "teamId" => encode_object_id(k["_id"]),
        "totalFeeClass" => totalClassFeeList.totalFeeClass,
        "totalAmountReceivedClass" => totalClassFeeList.totalAmountReceivedClass,
        "totalBalanceAmount" => totalClassFeeList.totalFeeClass - totalClassFeeList.totalAmountReceivedClass
      }
      acc ++ [map]
    end)
  end


  # def getInstallmentOfClass(groupObjectId) do
  #   SchoolFeeRepo.getInstallmentOfClass(groupObjectId, teamObjectId)
  # end


  def getStudentsListForReminder123(groupObjectId, teamObjectId, date) do
    studentList = SchoolFeeRepo.getStudentIds(groupObjectId, teamObjectId)
    userObjectIds = for userId <- studentList do
      userId["userId"]
    end
    dueStudent = SchoolFeeRepo.getStudentsListForReminder(groupObjectId, teamObjectId, userObjectIds, date)
    list = Enum.reduce(studentList, [], fn k, acc ->
      dueStudentMap = Enum.reduce(dueStudent, %{"minimumAmount" =>  0}, fn k1, acc1 ->
        if k["userId"] == k1["userId"] do
          acc1 = %{"minimumAmount" => acc1["minimumAmount"] + String.to_integer(k1["dueDates"]["minimumAmount"])}
          Map.put(k, "minimumAmount", acc1["minimumAmount"])
        else
          acc1
        end
      end)
      if dueStudentMap["minimumAmount"] > 0 do
        acc ++ [dueStudentMap]
      else
        acc
      end
    end)
    feeDueUsersList = for userId <- list do
      userId["userId"]
    end
    #getting device token for the due userList from notification collection
    deviceTokenList = SchoolFeeRepo.getDeviceTokenId(feeDueUsersList)
    #looping the deviceToken List and apppending to user // enum.Map not used because only 1 matching document is found 2 documents may exists
    userReminderWithDeviceToken = Enum.reduce(deviceTokenList, [], fn k, acc ->
      userWithDeviceTokenList = Enum.reduce(list, [], fn k1, acc1 ->
        if k["userId"] == k1["userId"] do
          if Map.has_key?(k1, "pushToken") do
            k1["pushToken"] ++ [%{
              "deviceToken" => k["deviceToken"],
              "deviceType" => k["deviceType"]
            }]
          else
            Map.put(k1, "pushToken", [%{
              "deviceToken" => k["deviceToken"],
              "deviceType" => k["deviceType"]
              }]
            )
          end
        end
        acc1 ++ [k1]
      end)
      userWithDeviceTokenList = userWithDeviceTokenList
      |> Enum.reject(&is_nil/1)
      acc ++ [userWithDeviceTokenList]
    end)
    if userReminderWithDeviceToken != [] do
      hd(userReminderWithDeviceToken)
    else
      []
    end
  end


  def getStudentsListForReminder123(groupObjectId, date) do
    #get class true team ids
    teamIds = SchoolFeeRepo.getTeamIds(groupObjectId)
    Enum.reduce(teamIds, [], fn k,  acc ->
      #get userIds isActive = true
      studentList = SchoolFeeRepo.getStudentIds(groupObjectId, k["_id"])
      userObjectIds = for userId <- studentList do
        userId["userId"]
      end
      dueStudent = SchoolFeeRepo.getStudentsListForReminder(groupObjectId, k["_id"], userObjectIds, date)
      list = Enum.reduce(studentList, [], fn k, acc ->
        dueStudentMap = Enum.reduce(dueStudent, %{"minimumAmount" =>  0}, fn k1, acc1 ->
          if k["userId"] == k1["userId"] do
            acc1 = %{"minimumAmount" => acc1["minimumAmount"] + String.to_integer(k1["dueDates"]["minimumAmount"])}
            Map.put(k, "minimumAmount", acc1["minimumAmount"])
          else
            acc1
          end
        end)
        if dueStudentMap["minimumAmount"] > 0 do
          acc ++ [dueStudentMap]
        else
          acc
        end
      end)
      feeDueUsersList = for userId <- list do
        userId["userId"]
      end
      #getting device token for the due userList from notification collection
      deviceTokenList = SchoolFeeRepo.getDeviceTokenId(feeDueUsersList)
      userDueList = if deviceTokenList != [] do
        #looping the deviceToken List and apppending to user // enum.Map not used because only 1 matching document is found 2 documents may exists
        userReminderWithDeviceToken = Enum.reduce(deviceTokenList, [], fn k, acc ->
          userWithDeviceTokenList = Enum.reduce(list, [], fn k1, acc1 ->
            if k["userId"] == k1["userId"] do
              if Map.has_key?(k1, "pushToken") do
                k1["pushToken"] ++ [%{
                  "deviceToken" => k["deviceToken"],
                  "deviceType" => k["deviceType"]
                }]
              else
                Map.put(k1, "pushToken", [%{
                  "deviceToken" => k["deviceToken"],
                  "deviceType" => k["deviceType"]
                  }]
                )
              end
            end
            acc1 ++ [k1]
          end)
          userWithDeviceTokenList = userWithDeviceTokenList
          |> Enum.reject(&is_nil/1)
          acc ++ [userWithDeviceTokenList]
        end)
        if userReminderWithDeviceToken != [] do
          hd(userReminderWithDeviceToken)
        else
          []
        end
      else
        list
      end
      acc ++ userDueList
    end)
  end


  def getStudentsListForReminder(groupObjectId, date) do
    #get class true team ids
    teamIds = SchoolFeeRepo.getTeamIds(groupObjectId)
    Enum.reduce(teamIds, [], fn k,  acc ->
      #get userIds isActive = true
      studentList = SchoolFeeRepo.getStudentIds(groupObjectId, k["_id"])
      userOverDueList = Enum.reduce(studentList, [], fn k1, acc1 ->
        dueStudent = SchoolFeeRepo.getStudentsListForReminder(groupObjectId, k["_id"], k1["userId"], date)
        dueMap = Enum.reduce(dueStudent, %{ minimumAmount: 0 }, fn k2, acc2 ->
          %{
            minimumAmount: acc2.minimumAmount + String.to_integer(k2["dueDates"]["minimumAmount"])
          }
        end)
        deviceTokenList = ConstituencyRepo.getUserNotificationPushToken(k1["userId"])
        if deviceTokenList != [] do
          tokenList = Enum.reduce(deviceTokenList, [], fn k3, acc3 ->
            tokenMap = %{
              "deviceToken" => k3["deviceToken"],
              "deviceType" => k3["deviceType"]
            }
            acc3 ++ [tokenMap]
          end)
          k1 = k1
          |> Map.put("dueAmount", dueMap.minimumAmount)
          |> Map.put("pushToken", tokenList)
          acc1 ++ [k1]
        else
          k1 = k1
          |> Map.put("dueAmount", dueMap.minimumAmount)
          acc1 ++ [k1]
        end
      end)
      if userOverDueList != [] do
        #sending reminder post to users
        postFeeReminder(groupObjectId, k["_id"], userOverDueList)
      end
      acc ++ userOverDueList
    end)
  end


  def postFeeReminder(groupObjectId, teamObjectId, userIdsList) do
    feePostList = for userId <- userIdsList do
      %{
        "title" => "Fee Reminder",
        "text" => ~s"Dear Parents,\n\tThis is a gentle reminder that your child’s fee payment(#{userId["dueAmount"]}) is due.Please attend to this matter as soon as possible. Thank you.",
        "isActive" => true,
        "groupId" => groupObjectId,
        "teamId" => teamObjectId,
        "userId" => userId["userId"],
        "type" => "feePost",
        "uniquePostId" => encode_object_id(new_object_id())
      }
    end
    SchoolFeeRepo.postFeeReminder(feePostList)
  end


  def getDue(groupObjectId, teamObjectId, userObjectId, date) do
    reverseDateArray = String.split(date, "-")
    reverseDateString = Enum.at(reverseDateArray, 2)<>"-"<>Enum.at(reverseDateArray, 1)<>"-"<>Enum.at(reverseDateArray, 0)
    dueDateList = SchoolFeeRepo.getStudentsListForReminder(groupObjectId, teamObjectId, userObjectId, reverseDateString)
    list = if dueDateList != [] do
      Enum.reduce(dueDateList, %{dueAmount: 0, totalAmountPaid: 0}, fn k, acc ->
        if Map.has_key?(k, "dueDates") do
          if acc.totalAmountPaid == 0 do
            %{dueAmount: acc.dueAmount + String.to_integer(k["dueDates"]["minimumAmount"]), totalAmountPaid: acc.totalAmountPaid + k["totalAmountPaid"]}
          else
            %{dueAmount: acc.dueAmount + String.to_integer(k["dueDates"]["minimumAmount"]), totalAmountPaid: acc.totalAmountPaid}
          end
        else
          0
        end
      end)
    else
      %{dueAmount: 0, totalAmountPaid: 0}
    end
    %{
      "dueAmount" => list.dueAmount - list.totalAmountPaid
    }
  end


  def feeRevert(groupObjectId, teamObjectId, userObjectId, payment_id) do
    feeDetails = SchoolFeeRepo.feeRevert(groupObjectId, teamObjectId, userObjectId, payment_id)
    totalBalanceMap = if feeDetails do
      %{
        "totalAmountPaid" =>  feeDetails["totalAmountPaid"] - hd(feeDetails["feePaidDetails"])["amountPaid"],
        "totalBalance" => hd(feeDetails["feePaidDetails"])["amountPaid"] + feeDetails["totalBalance"]
      }
    else
      {:ok, "success"}
    end
    SchoolFeeRepo.revertFees(groupObjectId, teamObjectId, userObjectId, payment_id, totalBalanceMap)
  end
end
