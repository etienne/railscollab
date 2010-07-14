#==
# RailsCollab
# Copyright (C) 2007 - 2009 James S Urquhart
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

module FoldersHelper
  def page_title
    case action_name
      when 'files' then :folder_name.l_with_args(:folder => @current_folder.name)
      when 'new', 'create' then :add_folder.l
      when 'edit', 'update' then :edit_folder.l
      else super
    end
  end

  def current_tab
    :files
  end

  def current_crumb
    case action_name
      when 'show' then @folder.nil? ? :files : @folder.name
      when 'new', 'create' then :add_folder
      when 'edit', 'update' then :edit_folder
      else super
    end
  end

  def extra_crumbs
    crumbs = []
    crumbs << {:title => :files, :url => files_path(@active_project.id)}
    crumbs << {:title => @folder.name, :url => @folder.object_url} unless @folder.nil? or @folder.new_record?
    crumbs
  end

  def additional_stylesheets
    ['project/files']
  end
end
