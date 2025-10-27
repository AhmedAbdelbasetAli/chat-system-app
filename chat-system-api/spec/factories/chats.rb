FactoryBot.define do
  factory :chat do
    association :application
    messages_count { 0 }
    
    # Don't use sequence for number - let model auto-assign
    # number is set automatically by before_create callback
    
    trait :with_messages do
      after(:create) do |chat|
        create_list(:message, 5, chat: chat)
      end
    end
  end
end
