# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

defmodule Patron do
  @moduledoc false
  use Ecto.Schema

  schema "patrons" do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:date_of_birth, :date)
    field(:email_address, :string, redact: true)
    field(:late_fees_balance, :integer)

    has_many(:loans, Loan)
    has_many(:reviews, BookReview)

    timestamps()
  end
end
