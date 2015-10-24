
function hello_to(name::AbstractString)
    num_greetings = length(GREETINGS)
    rand_greeting = round(Int, (num_greetings-1)*rand()) + 1
    string(GREETINGS[rand_greeting], " ", name)
end

