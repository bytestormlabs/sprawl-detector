class SchedulesController < ApplicationController
  def index
    render json: [
      {
        id: 1,
        name: "Business Hours Only",
        description: "Availability during core business hours of 8am EST to 5pm EST Monday through Friday."
      },
      {
        id: 2,
        name: "Extended Business Hours",
        description: "Availability during core business hours of 8am EST to 8pm EST Monday through Friday."
      },
      {
        id: 3,
        name: "Week Days Only",
        description: "Availability during the business week Monday through Friday."
      },
    ]
  end
end
