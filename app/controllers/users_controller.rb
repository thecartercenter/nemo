# ELMO - Secure, robust, and versatile data collection.
# Copyright 2011 The Carter Center
#
# ELMO is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# ELMO is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with ELMO.  If not, see <http://www.gnu.org/licenses/>.
# 
class UsersController < ApplicationController
  def index
    @users = load_objects_with_subindex(User)
  end
  def new
    @user = User.default
  end
  def edit
    @user = User.find(params[:id])
    @title = "Edit Profile" if @user == current_user
  end
  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      if @user == current_user
        flash[:success] = "Profile updated successfully."
        redirect_to(:action => :edit)
      else
        flash[:success] = "User updated successfully."
        @user.reset_password_if_requested
        handle_printable_instructions
      end
    else
      render(:action => :edit)
    end
  end
  def create
    @user = User.new_with_login_and_password(params[:user])
    if @user.save
      @user.reset_password_if_requested
      flash[:success] = "User created successfully."
      handle_printable_instructions
    else
      render(:action => :new)
    end
  end
  def destroy
    @user = User.find(params[:id])
    begin flash[:success] = @user.destroy && "User deleted successfully." rescue flash[:error] = $!.to_s end
    redirect_to(:action => :index)
  end
  def login_instructions
    @user = User.find(params[:id])
    @title = ""
  end
  def export
    respond_to do |format|
      format.vcf do
        @users = params[:selected] ? load_selected_objects(User) : []
        render(:text => @users.collect{|u| u.to_vcf}.join("\n"))
      end
    end
  end
  
  private
    def handle_printable_instructions
      # if we need to print instructions, redirect there. otherwise redirect to index
      if @user.reset_password_method == "print"
        # save the password in the flash since we won't be able to get it in the next request
        flash[:password] = @user.password
        redirect_to(:action => :login_instructions, :id => @user.id)
      else
        redirect_to(:action => :index)
      end
    end
end
