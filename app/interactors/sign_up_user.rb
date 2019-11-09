class SignUpUser
  include Interactor::Organizer

  organize CreateUser, SendWelcomeEmail, TrackAnalytic
end
