
const list<string> GREETINGS = [
    "Hello",        # English
    "你好",         # Chinese
    "Hola",         # Spanish 
    "Kumusta Ka",   # Filipino 
    "Terve",        # Finnish 
    "Bonjour",      # French 
    "Ciao",         # Italian 
    "Hallo",        # German 
    "Tungjatjeta",  # Albanian 
    "Shalom",       # Hebrew 
    "Sveikas",      # Lithuanian 
    "Haa",          # Comanche 
    "Apa Kabar",    # Bahasa Indonesia 
    "Kako Si",      # Croation 
    "Ahoj",         # Czech 
    "Szvervusz",    # Hungarian 
    "Konnichiwa",   # Japanese 
    "Labdien",      # Latvian 
    "Talofa",       # Samoan 
    "Hujambo"       # Swahili
]

service SayHello {
    string hello_to(1:string name)
}

