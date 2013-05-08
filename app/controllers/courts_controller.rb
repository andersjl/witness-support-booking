class CourtsController < ApplicationController
extend Authorization

  authorize [ :destroy, :index, :create, :update, :edit], "master"

  def create
    court = Court.new
    court.massign params[ :court], :name, :link
    if court.save
      flash[ :success] = t( "court.created", court: court.name) if court
      redirect_to courts_path
    else
      @courts = Court.all
      @new_court = court
      render :index
    end
  end

  def index
    @courts = Court.all
    @new_court = Court.new
  end

  def edit
    @court = Court.find params[ :id]
  end

  def update
    @court = Court.find params[ :id]
    if @court
      @court.massign params[ :court], :name, :link
      if @court.save
        flash.now[ :success] = t( "court.changed")
        redirect_to courts_path
      else
        render :edit
      end
    else
      redirect_to courts_path
    end
  end

  def destroy
    destroyed = Court.find params[ :id]
    if destroyed
      destroyed_inspect = destroyed.inspect
      destroyed.destroy
      flash[ :success] = t( "court.destroyed", court: destroyed_inspect)
    end
    redirect_to courts_path
  end
end

