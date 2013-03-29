class CourtsController < ApplicationController
extend Authorization

  authorize [ :destroy, :index, :create, :update, :edit], "master"

  def create
    @court = Court.new( params[ :court])
    if @court.save
      flash[ :success] = t "court.created", court: @court.name
      redirect_to courts_path
    else
      @courts = Court.all
      @new_court = Court.new
      render :index
    end
  end

  def index
    @courts = Court.all
    @new_court = Court.new :link => nil
  end

  def edit
    @court = Court.find params[ :id]
  end

  def update
    @court = Court.find params[ :id]
    if @court.update_attributes( params[ :court])
      flash.now[ :success] = t "court.changed"
      redirect_to courts_path
    else
      render :edit
    end
  end

  def destroy
    destroyed = Court.find params[ :id]
    destroyed_inspect = destroyed.inspect
    destroyed.destroy
    flash[ :success] = t "court.destroyed", court: destroyed_inspect
    redirect_to courts_path
  end
end

