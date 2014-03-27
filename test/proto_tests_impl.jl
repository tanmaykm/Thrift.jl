
function test_hello(name::String)
    num_greetings = length(GREETINGS)
    rand_greeting = int((num_greetings-1)*rand()) + 1
    string(GREETINGS[rand_greeting], " ", name)
end

