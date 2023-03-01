class SchedulesController < ApplicationController
  def index
    render json: [
      {
        id: 1,
        name: "Business Hours Only",
        description: "Availability during core business hours of 8am EST to 5pm EST Monday through Friday.",
        up_schedule: "0 8 ? * MON-FRI *",
        down_schedule: "0 17 ? * MON-FRI *"
      },
      {
        id: 2,
        name: "Extended Business Hours",
        description: "Availability during core business hours of 8am EST to 8pm EST Monday through Friday.",
        up_schedule: "0 8 ? * MON-FRI *",
        down_schedule: "0 20 ? * MON-FRI *"
      },
      {
        id: 3,
        name: "Week Days Only",
        description: "Availability during the business week Monday through Friday.",
        up_schedule: "0 0 ? * MON *",
        down_schedule: "0 23 ? * FRI *"
      },
      {
        id: 4,
        name: "Testing",
        description: "Availability during the business week Monday through Friday.",
        up_schedule: "5 13 ? * MON-FRI *",
        down_schedule: "48 12 ? * MON-FRI *"
      },
    ]
  end
end
