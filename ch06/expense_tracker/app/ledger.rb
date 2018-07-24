require_relative '../config/sequel'

module ExpenseTracker
  RecordResult = Struct.new(:success?, :expense_id, :error_message)

  class Ledger
    
    def record(expense)
      unless expense.key? ('payee')
        return invalid_response('payee')
      end

      unless expense.key? ('amount')
        return invalid_response('amount')
      end

      unless expense.key? ('date')
        return invalid_response('date')
      end
      
      DB[:expenses].insert(expense)
      id = DB[:expenses].max(:id)
      RecordResult.new(true, id, nil)
    end

    def expenses_on(date)
      DB[:expenses].where(date: date).all
    end

    private

    def invalid_response(str)
      message = "Invalid expense: `#{str}` is required"
      return RecordResult.new(false, nil, message)
    end

  end
end
