require "sinatra"
require "sinatra/activerecord"

# require "./aes_crypt"
# https://gist.github.com/subwindow/728456
require 'openssl'

module AESCrypt
  # def AESCrypt.decrypt(encrypted_data, key, iv, cipher_type)
    def AESCrypt.decrypt(encrypted_data, key, iv, cipher_type)
    aes = OpenSSL::Cipher::Cipher.new(cipher_type)
    aes.decrypt
    aes.key = key
    aes.iv = iv if iv != nil
    aes.update([encrypted_data].pack("H*")) + aes.final
    end

    # def AESCrypt.encrypt(data, key, iv, cipher_type)
  def AESCrypt.encrypt(data, key, iv, cipher_type)
    aes = OpenSSL::Cipher::Cipher.new(cipher_type)
    aes.encrypt
    aes.key = key
    aes.iv = iv if iv != nil
    (aes.update(data) + aes.final).unpack("H*")[0]
  end
end

set :database, {adapter: "sqlite3", database: "foo.sqlite3"}

class MyApplication < Sinatra::Base
  register Sinatra::ActiveRecordExtension
end

class Messages < ActiveRecord::Base
  validates_presence_of :message
end

get '/' do
  p 'Hello!'
end

get '/messages' do
  @messages = Messages.all
  erb :index
end

get '/messages/' do
    redirect '/messages'
end

get '/messages/new' do
  @message = Messages.new
  erb :new
end

post '/messages' do
  a = params[:message]
  b = a.to_a
  # k = OpenSSL::Digest::SHA256.new(1234.to_s).digest
  c = AESCrypt.encrypt(b[0][1], OpenSSL::Digest::SHA256.new(1234.to_s).digest, nil, "AES-256-CBC")
  @message = Messages.new("message"=>"#{c}")
  if @message.save
    redirect "/messages/#{@message.id}"
  else
    erb :new
  end
end

get '/messages/:id' do
  a = Messages.find(params[:id])
  @message = AESCrypt.decrypt(a.message, OpenSSL::Digest::SHA256.new(1234.to_s).digest, nil, "AES-256-CBC")

  erb :show
end

post '/messages/:id' do
  @message = Messages.find(params[:id]).destroy
  # @message.delete
  redirect '/'
end


# require 'pry'; binding.pry;