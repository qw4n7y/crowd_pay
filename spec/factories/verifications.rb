FactoryGirl.define do
  factory :verification, class: CrowdPay::Verification do |v|
    v.firstName 'Investor First'
    v.lastName 'Investor Middle'
    v.address 'my address'
    v.city 'atlanta'
    v.state 'GA'
    v.zip '53665'
    v.taxpayerId '112223333'
    v.birthMonth 2
    v.birthDay 19
    v.birthYear 1989
    v.created_by_ip_address '182.156.77.154'
  end

  trait :pass do
    id '1254778630'
    key 'id.success'
    message 'Pass'
  end

  trait :fail do
    id '1211436364'
    key 'id.failure'
    message 'FAIL'
    request_data { { taxpayerId: '112223333' }.to_s }
    qualifiers [
      {
        'Key' => 'resultcode.mob.does.not.match',
        'Message' => 'MOB Does Not Match'
      }
    ]
  end

  trait :hard_fail do
    fail
  end

  trait :soft_fail do
    fail

    questions [
      {
        'Prompt' => 'In which county have you lived?',
        'Type' => 'current.county.b',
        'Choices' => [
          { 'Text' => 'GUERNSEY' },
          { 'Text' => 'FULTON' },
          { 'Text' => 'ALCONA' },
          { 'Text' => 'None of the above' },
          { 'Text' => 'Skip Question' }
        ]
      },
      {
        'Prompt' => 'From whom did you purchase the property at 222333 PEACHTREE PLACE?',
        'Type' => 'purchased.property.from',
        'Choices' => [
          { 'Text' => 'JOE ANDERSON' },
          { 'Text' => 'ERIC WALTORS' },
          { 'Text' => 'A VIRAY' },
          { 'Text' => 'None of the above' },
          { 'Text' => 'Skip Question' }
        ]
      },
      {
        'Prompt' => 'In which city is ANY STREET?',
        'Type' => 'city.of.residence',
        'Choices' => [
          { 'Text' => 'ATLANTA' },
          { 'Text' => 'ALMO' },
          { 'Text' => 'PAULDING' },
          { 'Text' => 'None of the above' },
          { 'Text' => 'Skip Question' }
        ]
      },
      {
        'Prompt' => 'Between 1979 and 1980, in which State did you live?',
        'Type' => 'prior.residence.state.multiyear',
        'Choices' => [
          { 'Text' => 'KENTUCKY' },
          { 'Text' => 'NEW YORK' },
          { 'Text' => 'MARYLAND' },
          { 'Text' => 'None of the above' },
          { 'Text' => 'Skip Question' }
        ]
      }
    ]
  end

  trait :answers_pass do
    id '1265185524'
    key 'result.questions.0.incorrect'
    message 'All answers correct'
    summary 'pass'
    request_data { { id: '1234567890', answers: [] }.to_s }
  end

  trait :answers_fail do
    id '1265411516'
    key 'result.questions.3.incorrect'
    message 'Three Incorrect Answers'
    summary 'fail'
    request_data { { id: '1234567890', answers: [] }.to_s }
    end
end
