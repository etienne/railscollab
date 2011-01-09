class ToolsController < ApplicationController

  before_filter :process_session
  before_filter :user_track

  def index
    @tools = AdministrationTool.admin_list
  end

end
