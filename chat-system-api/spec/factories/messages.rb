FactoryBot.define do
  factory :message do
    association :chat
    body { Faker::Lorem.sentence(word_count: 10) }
    
    # Don't use sequence for number - let model auto-assign
    # number is set automatically by before_create callback
    
    trait :short do
      body { Faker::Lorem.word }
    end
    
    trait :long do
      body { Faker::Lorem.paragraph(sentence_count: 5) }
    end
  end
end
