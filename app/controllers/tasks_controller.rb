#==
# RailsCollab
# Copyright (C) 2007 - 2008 James S Urquhart
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class TasksController < ApplicationController

  layout 'project_website'
  helper 'project_items'

  before_filter :process_session
  before_filter :grab_list
  after_filter  :user_track, :only => [:index, :show]
  
  # GET /tasks
  # GET /tasks.xml
  def index
    include_private = @logged_user.member_of_owner?

    respond_to do |format|
      format.html {
        @open_task_lists = @active_project.project_task_lists.open(include_private)
        @completed_task_lists = @active_project.project_task_lists.completed(include_private)
        @content_for_sidebar = 'task_lists/index_sidebar'
      }
      format.xml  {
        @tasks = @task_list.project_tasks.find(:all)
        render :xml => @tasks.to_xml(:root => 'tasks')
      }
    end
  end

  # GET /tasks/1
  # GET /tasks/1.xml
  def show
    begin
      @task = @task_list.project_tasks.find(params[:id])
    rescue
      return error_status(true, :invalid_task)
    end

    respond_to do |format|
      format.html { }
      format.js
      format.xml  { render :xml => @task.to_xml(:root => 'task') }
    end
  end

  # GET /tasks/new
  # GET /tasks/new.xml
  def new
    return error_status(true, :insufficient_permissions) unless (ProjectTask.can_be_created_by(@logged_user, @task_list))
    
    @page_actions = []
    if ProjectTaskList.can_be_created_by(@logged_user, @active_project)
      @page_actions << {:title => :add_task_list, :url=> new_task_list_path}
    end
    
    @task = @task_list.project_tasks.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @task.to_xml(:root => 'task') }
    end
  end

  # GET /tasks/1/edit
  def edit
    @page_actions = []
    if ProjectTaskList.can_be_created_by(@logged_user, @active_project)
      @page_actions << {:title => :add_task_list, :url=> new_task_list_path}
    end
    
    begin
      @task = @task_list.project_tasks.find(params[:id])
    rescue
      return error_status(true, :invalid_task)
    end
    
    return error_status(true, :insufficient_permissions) unless (@task.can_be_edited_by(@logged_user))
  end

  # POST /tasks
  # POST /tasks.xml
  def create
    return error_status(true, :insufficient_permissions) unless (ProjectTask.can_be_created_by(@logged_user, @task_list))
    
    @task = @task_list.project_tasks.build(params[:task])
    @task.created_by = @logged_user

    respond_to do |format|
      if @task.save
        Notifier.deliver_task(@task.user, @task) if params[:send_notification] and @task.user
        flash[:notice] = 'ListItem was successfully created.'
        format.html { redirect_back_or_default(task_lists_path) }
        format.js
        format.xml  { render :xml => @task.to_xml(:root => 'task'), :status => :created, :location => @task }
      else
        format.html { render :action => "new" }
        format.js
        format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tasks/1
  # PUT /tasks/1.xml
  def update
    begin
      @task = @task_list.project_tasks.find(params[:id])
    rescue
      return error_status(true, :invalid_task)
    end
    
    return error_status(true, :cannot_edit_listitem) unless (@task.can_be_edited_by(@logged_user))
    
    @task.updated_by = @logged_user

    respond_to do |format|
      if @task.update_attributes(params[:task])
        Notifier.deliver_task(@task.user, @task) if params[:send_notification] and @task.user
        flash[:notice] = 'ListItem was successfully updated.'
        format.html { redirect_back_or_default(task_lists_path) }
        format.js
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.js
        format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tasks/1
  # DELETE /tasks/1.xml
  def destroy
    begin
      @task = @task_list.project_tasks.find(params[:id])
    rescue
      return error_status(true, :invalid_task)
    end
    
    return error_status(true, :insufficient_permissions) unless (@task.can_be_deleted_by(@logged_user))
    
    @task.updated_by = @logged_user
    @task.destroy

    respond_to do |format|
      format.html { redirect_back_or_default(task_lists_url) }
      format.js
      format.xml  { head :ok }
    end
  end

  # PUT /tasks/1/status
  # PUT /tasks/1/status.xml
  def status
    begin
      @task = @task_list.project_tasks.find(params[:id])
    rescue
      return error_status(true, :invalid_task)
    end
  
    return error_status(true, :insufficient_permissions) unless (@task.can_be_completed_by(@logged_user))
    
    @task.set_completed(params[:task][:completed] == 'true', @logged_user)
    @task.order = @task_list.project_tasks.length
    @task.save

    respond_to do |format|
      format.html { redirect_back_or_default(task_lists_url) }
      format.js
      format.xml  { head :ok }
    end

  end

protected

  def grab_list
    begin
      @task_list = @active_project.project_task_lists.find(params[:task_list_id])
      unless @task_list.can_be_seen_by(@logged_user)
        error_status(true, :insufficient_permissions)
        return false
      end
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_task)
      return false
    end
    
    true
  end
end
