require 'pry'
require_relative '../../../app/api'
require 'rack/test'

module ExpenseTracker

  RSpec.describe API do
    include Rack::Test::Methods

    let(:ledger) { instance_double('ExpenseTracker::Ledger') }
    let(:expense) { { 'some' => 'data' } } 

    def app
      API.new(ledger: ledger)
    end

    describe 'POST /expenses' do
    
      def check_body(last_response, content)
        parsed = JSON.parse(last_response.body)
        expect(parsed).to include(content)
      end

      def check_status(last_response, code)
        expect(last_response.status).to eq(code)
      end

      context 'when the expense is successfully recorded' do
      
        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(true, 417, nil))
        end
       
        it 'returns the expense id' do
          post '/expenses', JSON.generate(expense)
          check_body(last_response, 'expense_id' => 417)
        end

        it 'responds with a 200 (OK)' do
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
          post '/expenses', JSON.generate(expense)
          check_body(last_response, 'error' => 'Expense incomplete')
        end

        it ' respond with a 422 (Unprocessable entity)' do
          post 'expenses', JSON.generate(expense)
          check_status(last_response, 422)
        end
      end
    end

    describe 'GET /expenses/:date' do

      def check_status(last_response, expected)
        expect(last_response.status).to eq(expected) 
      end
      
      def check_body(last_response, expected)
        parsed = JSON.parse(last_response.body)
        expect(parsed).to eq(expected)
      end

      context 'when expenses exist on the given date' do

        before do
          allow(ledger).to receive(:expenses_on)
            .with('2017-06-12')
            .and_return(['expense_1', 'expense_2'])
        end

        it 'returns the expense records as JSON' do 
          get '/expenses/2017-06-12'
          check_body(last_response, ['expense_1', 'expense_2'])
        end
        it 'responds with a 200 (OK)' do
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
          get '/expenses/2017-06-08'
          check_body(last_response, [])  
        end

        it 'responds with a 200 (OK)' do
          get '/expenses/2017-06-08'
          check_status(last_response, 200)
        end
      end
    end

  end
end

