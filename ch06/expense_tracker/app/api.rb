require 'sinatra/base'
require 'json'
require 'ox'
require_relative 'ledger'
require 'pry'

module ExpenseTracker
  class API < Sinatra::Base
    def initialize(ledger: Ledger.new)
      @ledger = ledger
      super()
    end

    get '/expenses/:date' do
      date = params['date']
      if request.accept? 'application/json'
        JSON.generate(@ledger.expenses_on(date))
      elsif request.accept? 'text/xml'
        Ox.dump(@ledger.expenses_on(date))
      else
        status 415
        return JSON.generate('error' => 'Unsupported Media Type')
      end
    end

    post '/expenses' do
      media_type = request.media_type
      if media_type == 'application/json'
        begin
          expense = JSON.parse request.body.read
        rescue
          return return_conflict
        end
      elsif  media_type == 'text/xml'
        begin
          expense = Ox.parse_obj(request.body.read)
        rescue
          return return_conflict
        end
      else
        status 415
        return JSON.generate('error' => 'Unsupported Media Type')
      end
      result = @ledger.record(expense)
      if result.success?
        JSON.generate('expense_id' => result.expense_id)
      else
        status 422
        JSON.generate('error' => result.error_message)
      end
    end

    private

    def return_conflict
      status 409
      return JSON.generate('error' => 'The expense format does not match the advertised')
    end

  end
end

