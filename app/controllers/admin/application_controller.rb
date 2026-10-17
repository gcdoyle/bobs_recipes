# All Administrate controllers inherit from this
# `Administrate::ApplicationController`, making it the ideal place to put
# authentication logic or other before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    # Administrate's controllers come from its engine, so the app's helpers
    # aren't included automatically. The recipe ingredients field uses format_qty.
    helper RecipesHelper

    before_action :authenticate_user!
    before_action :authenticate_admin

    # Index pages sort by name unless a controller says otherwise.
    def default_sorting_attribute
      :name
    end

    def default_sorting_direction
      :asc
    end

    def authenticate_admin
      if current_user.admin
        return
     else
        redirect_to root_url # or whatever
     end
    end

    # Override this value to specify the number of elements to display at a time
    # on index pages. Defaults to 20.
    # def records_per_page
    #   params[:per_page] || 20
    # end
  end
end
