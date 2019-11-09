class GetUserTransactions
  include Interactor::Organizer

  organize FilterTransaction, TrackAnalytic
end
