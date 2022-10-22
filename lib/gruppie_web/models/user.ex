defmodule GruppieWeb.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias GruppieWeb.Repo.SecurityRepo
  import GruppieWeb.Handler.TimeNow



  # @update_fields [ :name, :email, :gender, :dob, :image, :occupation, :qualification, :address, :voterId, :aadharNumber, :education,
                  #  :caste, :religion, :bloodGroup, :designation, :subcaste, :category, :roleOnConstituency ]

  @verify_otp_fields [:countryCode, :phone, :otp]

  @primary_key{:id, :binary_id, autogenerate: true}
  schema "users" do
    field :name, :string
    field :email, :string
    field :countryCode, :string
    field :phone, :string
    field :password_hash, :string
    field :gender, :string
    field :dob, :string
    field :image, :string
    field :occupation, :string
    field :qualification, :string
    field :inserted_at, :string
    field :updated_at, :string
    field :otp, :string
    field :voterId, :string
    ###school category group###
    field :studentId, :string
    field :admissionNumber, :string
    field :rollNumber, :string
    field :class, :string
    field :section, :string
    field :doj, :string
    field :fatherName, :string
    field :motherName, :string
    field :fatherNumber, :string
    field :motherNumber, :string
    field :address, :string
    field :aadharNumber, :string
    field :bloodGroup, :string
    field :religion, :string
    field :caste, :string
    field :staffId, :string
    field :designation, :string
    field :education, :string
    field :subcaste, :string
    field :category, :string
    field :roleOnConstituency, :string
    ##Staff db register
    field :uanNumber, :string
    field :panNumber, :string
    field :bankAccountNumber, :string
    field :bankName, :string
    field :bankIfscCode, :string
    field :staffType, :string
    field :profession, :string
    field :insertedAt, :string
    field :updatedAt, :string
  end


  def changeset_user_exist(struct, params \\%{}) do
    struct
    |> cast(params, [:countryCode, :phone])
    |> validate_required(:phone, [message: "Phone Number Must Not Be Empty"])
    |> validate_required(:countryCode, [message: "countryCode Must Not Be Empty"])
    #|> validate_length(:phone, is: 10)
    |> valid_phone_number
  end


  #struct returned here is an elixir changeset not a user struct
  def changeset_user_register(struct, params \\%{}) do
    struct
    |> cast(params, [:name, :email, :countryCode, :phone, :religion, :caste, :subcaste, :category, :designation, :education, :image, :dob]) #{param : struct [basically user struct [%User{}], param2 : parama, param3 : list od colums ned to update ]
    |> validate_required(:phone, [message: "Phone Number Must Not Be Empty"])
    |> validate_required(:countryCode, [message: "Country Code Must Not Be Empty"])
    |> validate_required(:name, [message: "Name Must Not Be Empty"])
    |> email_validation
    |> validate_format(:email, ~r/@/, [message: "Invalid Email Address"])
    |> valid_phone_number
    |> valid_unique_number_on_register
    |> set_time
  end


  #check phone is valid or not
  defp valid_phone_number(struct) do
    if struct.valid? do
      countryCode = get_field(struct, :countryCode) #get_field used to get values from struct
      phone = get_field(struct, :phone)
      case ExPhoneNumber.parse(phone, countryCode) do
        {:ok, phone_number} ->
          e164_number = ExPhoneNumber.format(phone_number, :e164)
          struct
          |> delete_change(:countryCode)
          |> put_change(:phone, e164_number)
        {:error, _}->
          add_error(struct, :phone, "Invalid CountryCode/Phone Given")
      end
    else
      struct
    end
  end


  def email_validation(struct) do
    countryCode = get_field(struct, :countryCode)
    email = get_field(struct, :email)
    if countryCode != "IN" do
      if is_nil(email) do
        add_error(struct, :email, "Email Is Mandatory")
      else
        struct
      end
    else
      struct
    end
  end

  #struct returned here is an elixir changeset not a user struct
  def changeset_user_register_individual(struct, params \\%{}) do
    struct
    |> cast(params, [:name, :email, :countryCode, :phone, :religion, :caste, :subcaste, :category, :designation, :education, :image, :dob]) #{param : struct [basically user struct [%User{}], param2 : parama, param3 : list od colums ned to update ]
    |> validate_required(:phone, [message: "Phone Number Must Not Be Empty"])
    |> validate_required(:countryCode, [message: "Country Code Must Not Be Empty"])
    |> validate_required(:name, [message: "Name Must Not Be Empty"])
    |> email_validation
    |> validate_format(:email, ~r/@/, [message: "Invalid Email Address"])
    |> valid_phone_number
    |> set_time
  end

  def changeset_verify_otp_individual(struct, params) do
    struct
    |> cast(params, @verify_otp_fields)
    |> validate_required( :otp, [message: "Otp Must Not Be Empty"] )
    |> validate_required( :phone, [message: "Phone Number Must Not Be Empty"] )
    |> validate_required( :countryCode, [message: "Country Code Must Not Be Empty"] )
    |> valid_phone_number
  end




  #check phone number already exists or not in database on registration
  defp valid_unique_number_on_register(struct) do
    if struct.valid? do
      countryCode = get_field(struct, :countryCode) #get required valuen from struct
      phone = get_field(struct, :phone)
      case ExPhoneNumber.parse(phone, countryCode) do
        {:ok, phone_number} ->
          e164_number = ExPhoneNumber.format(phone_number, :e164)
          case SecurityRepo.findUserExistByPhoneNumber(e164_number) do
            {:ok, result} ->
              if result > 0 do
                add_error(struct, :phone, "Phone Number Already Exists")
              else
                struct
                |> delete_change(:countryCode)
                |> put_change(:phone, e164_number)
              end
          end
        {:error, _}->
          add_error(struct, :phone, "Invalid CountryCode/Phone Given")
      end
    else
      struct
    end
  end


  defp set_time(struct) do
    struct
    |> put_change(:insertedAt, bson_time())
    |> put_change(:updatedAt, bson_time())
  end





end
