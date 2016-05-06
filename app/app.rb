ENV['RACK_ENV'] ||= 'development'

require 'sinatra/base'
require_relative 'data_mapper_setup'
require 'sinatra/flash'


class BookmarkManager < Sinatra::Base
  enable :sessions
  set :session_secret, 'super secret'
  register Sinatra::Flash

  helpers do
    def current_user
      @current_user ||= User.get(session[:user_id])
    end
  end

  get '/' do
    redirect '/links'
  end


  get '/links' do
    @links = Link.all
    erb :'links/index'
  end

  get '/links/new' do
    erb :'links/new'
  end

  post '/links' do
    link = Link.new(url:params[:url], title:params[:title])
    params[:tags].split(', ').each do |tag|
      link.tags << Tag.create(name: tag)
    end
    link.save
    redirect '/links'
  end

  get '/tags/:name' do
    tag = Tag.all(name: params[:name])
    @links = tag ? tag.links : []
    erb :'links/index'
  end

  get '/users/new' do
    @user = User.new
    erb :'users/new'
  end

  post '/users' do
    @user = User.new(password:params[:password], password_confirmation:params[:password_confirmation], email:params[:email])
    if @user.save
      redirect '/sessions/new'
    else
      #alternatively set flash[:errors] to @user.errors.full_messages
      flash.now[:errors] = []
      @user.errors.each do |error|
        flash.now[:errors] << error
      end
      erb :'users/new'
    end
  end

  get '/sessions/new' do
    erb :'sessions/new'
  end

  post '/sessions' do
  # @user = User.first(email:params[:email])
  # if @user.authenticated?(params[:password])
  #   session[:user_id] = @user.id
  #   redirect to('/links')
  # else
  #   flash.now[:errors] = ['The email or password is incorrect']
  #   erb :'sessions/new'
  # end
  user = User.authenticate(params[:email], params[:password])
    if user
      session[:user_id] = user.id
      redirect to('/links')
    else
      flash.now[:errors] = [['The email or password is incorrect']]
      erb :'sessions/new'
    end
  end
  # start the server if ruby file executed directly
  run! if app_file == $0
end
