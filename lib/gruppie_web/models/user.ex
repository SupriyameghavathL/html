defmodule GruppieWeb.User do
  use Ecto.Schema
  import Ecto.Changeset



  # @update_fields [ :name, :email, :gender, :dob, :image, :occupation, :qualification, :address, :voterId, :aadharNumber, :education,
                  #  :caste, :religion, :bloodGroup, :designation, :subcaste, :category, :roleOnConstituency ]

  # @verify_otp_fields [:countryCode, :phone, :otp]

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
  end


  def changeset_user_exist(struct, params \\%{}) do
    struct
    |> cast(params, [:countryCode, :phone])
    |> validate_required(:phone, [message: "Phone Number Must Not Be Empty"])
    |> validate_required(:countryCode, [message: "countryCode Must Not Be Empty"])
    #|> validate_length(:phone, is: 10)
    |> valid_phone_number
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
end
