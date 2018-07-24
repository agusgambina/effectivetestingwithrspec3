require 'pry'
require_relative '../../../app/api'
require 'rack/test'
require 'ox'

module ExpenseTracker
  RSpec.describe API do
    include Rack::Test::Methods

    let(:ledger) { instance_double('ExpenseTracker::Ledger') }

    def app
      API.new(ledger: ledger)
    end

    def check_body_json(last_response, content)
      parsed = JSON.parse(last_response.body)
      expect(parsed).to include(content)
    end

    def check_status(last_response, code)
      expect(last_response.status).to eq(code)
    end
      
    describe 'POST /expenses' do
      let(:expense) { { 'some' => 'data' } } 
      
      context 'when the expense is successfully recorded' do
        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(true, 417, nil))
        end

        it 'returns the expense id' do
          header 'Content-Type', 'application/json'
          post '/expenses', JSON.generate(expense)
          check_body_json(last_response, 'expense_id' => 417)
        end

        it 'responds with a 200 (OK)' do
          header 'Content-Type', 'application/json'
          post '/expenses', JSON.generate(expense)
          check_status(last_response, 200)
        end
      end
      
      context 'when the expense fails validation' do
        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(false, 417, 'Expense incomplete'))
        end
        
        it 'returns an error message' do
          header 'Content-Type', 'application/json'
          post '/expenses', JSON.generate(expense)
          check_body_json(last_response, 'error' => 'Expense incomplete')
        end

        it ' respond with a 422 (Unprocessable entity)' do
          header 'Content-Type', 'application/json'
          post 'expenses', JSON.generate(expense)
          check_status(last_response, 422)
        end
      end

      context 'when the expense, submitted with xml format, is successfully recorded' do
        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(true, 417, nil))
        end
        
        it 'returns the expense id' do
          header 'Content-Type', 'text/xml'
          post '/expenses', Ox.dump(expense)

          check_body_json(last_response, 'expense_id' => 417)
        end

        it 'responds with a 200 (OK)' do
          header 'Content-Type', 'text/xml'
          post '/expenses', Ox.dump(expense)
          
          check_status(last_response, 200)
        end
      end

      context 'when the expense has an unsupported format' do
        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(false, 415, 'Unsupported Media Type'))
        end

        it 'returns an error message' do
          header 'Content-Type', 'text/plain'
          post '/expenses', "some plain data"

          parsed = JSON.parse(last_response.body)
          expect(parsed).to eq('error' => 'Unsupported Media Type')
        end

        it 'responds with a 415 (Unsupported Media Type)' do
          header 'Content-Type', 'text/plain'
          post '/expenses', "some plain data"

          check_status(last_response, 415)
        end
      end

      context 'when the expense format does not match the advertised format' do
        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(false, 409, 'The expense format does not match the advertised'))
        end

        it 'returns an error message' do
          header 'Content-Type', 'application/json'
          post '/expenses', Ox.dump(expense)

          parsed = JSON.parse(last_response.body)
          expect(parsed).to eq('error' => 'The expense format does not match the advertised')
        end

        it 'responds with a 409 (Conflict)' do
          header 'Content-Type', 'application/json'
          post '/expenses', Ox.dump(expense)

          check_status(last_response, 409)
        end
      end

    end

    describe 'GET /expenses/:date' do
      expense_1 = { :payee => 'Starbucks', :amount =>  5.12, :date => '2017-07-12' }
      expense_2 = { :payee => 'Tickets', :amount => 15, :date => '2017-07-10' }

      context 'when expenses exist on the given date' do
        before do
          allow(ledger).to receive(:expenses_on)
            .with('2017-06-12')
            .and_return(to_json([expense_1, expense_2]))
        end
        
        it 'returns the expense records as JSON' do 
          header 'Accept', 'application/json'
          get '/expenses/2017-06-12'
          parsed = JSON.parse(last_response.body)
          expect(parsed).to eq(to_json([expense_1, expense_2]))
        end

        it 'responds with a 200 (OK)' do
          header 'Accept', 'application/json'
          get '/expenses/2017-06-12'
          check_status(last_response, 200)
        end
      end

      context 'when there are no expenses on the given date' do
        before do
          allow(ledger).to receive(:expenses_on)
            .and_return([])
        end

        it 'returns an empty array as JSON' do
          header 'Accept', 'application/json'
          get '/expenses/2017-06-08'
          parsed = JSON.parse(last_response.body)
          expect(parsed).to eq([])
        end

        it 'responds with a 200 (OK)' do
          get '/expenses/2017-06-08'
          check_status(last_response, 200)
        end
      end

      context 'when expenses exists on the given date and are required in xml format' do
        before do
          allow(ledger).to receive(:expenses_on)
            .and_return(Ox.dump([expense_1, expense_2]))
        end

        it 'returns records as XML' do
          header 'Accept', 'text/xml'
          get '/expenses/2017-06-12'

          # TODO this code needs to be fixed, the and_return method is retrieving something that should be parsed before Ox
          parsed = Ox.parse_obj(Ox.parse_obj(last_response.body))
          expect(parsed).to eq([expense_1, expense_2])
        end

        it 'responds with a 200 (OK)' do
          header 'Accept', 'text/xml'
          get '/expenses/2017-06-12'

          check_status(last_response, 200)
        end

      end

      context 'when expenses are required in an unsupported format' do
        before do
          allow(ledger).to receive(:expenses_on)
            .and_return(RecordResult.new(false, 415, 'Unsupported Media Type'))
        end

        it 'returns an error message' do
          header 'Accept', 'text/plain'
          get '/expenses/2017-06-12'

          parsed = JSON.parse(last_response.body)
          expect(parsed).to eq('error' => 'Unsupported Media Type')
        end

        it 'responds with a 415 (Unsupported Media Type)' do
          header 'Accept', 'text/plain'
          get '/expenses/2017-06-12'

          check_status(last_response, 415)
        end
        
      end 

    end

  end
end

