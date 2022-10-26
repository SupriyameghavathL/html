defmodule GruppieWeb.SchoolFees do
    use Ecto.Schema
    import Ecto.Changeset
    import GruppieWeb.Handler.TimeNow

    @fields [ :feeDetails, :totalFee, :dueDates, :addFineAmount, :reminder ]

    #@fee_paid_fields [ :totalFee, :paidDates, :dueDates, :feeDetails ]
    @fee_paid_fields [ :totalFee, :paidDetails, :dueDates, :feeDetails ]

    #@student_fee_paid_fields [:totalFee, :dueAmount, :paidDates]
    @student_fee_paid_fields [:paidDate, :amountPaid, :attachment, :paymentMode, :fineAmount, :addFineAmount, :reminder]

    @primary_key{:id, :binary_id, autogenerate: true}
    schema "school_fees" do
        #field :feeTitle, :string
        field :feeDetails, :map
        field :totalFee, :integer
        field :dueDates, {:array, :map}
        #field :paidDates, {:array, :map}
        field :paidDetails, :map
        field :dueAmount, :integer
        field :paidDate, :string
        field :amountPaid, :integer
        field :attachment, {:array, :string}
        field :paymentMode, :string
        field :addFineAmount, :integer
        field :fineAmount, :integer
        field :reminder, {:array, :integer}
        field :insertedAt, :string
        field :updatedAt, :string
    end


    def changeset_create_fee(struct, params) do
        struct
        |> cast(params, @fields)
        #|> validate_required(:feeTitle, [message: "Title Must Not Be Empty"])
        |> validate_required(:totalFee, [message: "Total Fee Must Not Be Empty"])
        |> put_change(:isActive, true)
        |> set_time
    end


    def changeset_fee_paid(struct, params) do
        struct
        |> cast(params, @fee_paid_fields)
        #|> validate_required(:paidDates, [message: "Must Not Be Empty"])
        |> validate_required(:paidDetails, [message: "Must Not Be Empty"])
        #|> validate_required(:dueDates, [message: "Must Not Be Empty"])
        |> validate_required(:totalFee, [message: "Total Fee Must Not Be Empty"])
    end


    def changeset_student_fee_paid(struct, params) do
        struct
        |> cast(params, @student_fee_paid_fields)
        |> validate_required(:paidDate, [message: "Must Not Be Empty"])
        |> validate_required(:amountPaid, [message: "Must Not Be Empty"])
        # |> validate_required(:attachment, [message: "Must Not Be Empty"])
        |> validate_required(:paymentMode, [message: "Must Not Be Empty"])
    end


    defp set_time(struct) do
        struct
        |> put_change( :insertedAt, bson_time() )
        |> put_change( :updatedAt, bson_time() )
    end
end
