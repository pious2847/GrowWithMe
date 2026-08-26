import json
import random
import re

# 1. Slot Definitions for Combinatorial Generation
NAMES = [
    # Northern Ghana / Dagbon / Mamprugu
    "Amina", "Abdul", "Fatima", "Yakubu", "Fuseini", "Alhassan", "Mariama",
    "Zainab", "Sulemana", "Adam", "Iddrisu", "Issah", "Mubarak", "Murtala",
    "Haruna", "Ibrahim", "Mustapha", "Salifu", "Seidu", "Sani", "Alhaji",
    "Hafiz", "Nuhu", "Sumaila", "Abubakar", "Nasiru", "Fati", "Rahina", 
    "Ramatu", "Hajara", "Hawa", "Safia", "Rukaya", "Maimuna", "Bintu", 
    "Kadija", "Adiza", "Aisha",

    # Dagbani / Northern local names
    "Naa", "Naba", "Fatawu", "Mahama", "Ndebugri", "Ziblim", "Wumpini", 
    "Mahamadu", "Abdul-Rahman",

    # Akan / Ashanti / Fante
    "Kofi", "Kwame", "Kwaku", "Yaw", "Kojo", "Kwadwo", "Kwabena",
    "Akwasi", "Kweku", "Fiifi", "Kobina", "Ebo", "Ekow", "Ato",
    "Ama", "Akosua", "Adwoa", "Abena", "Yaa", "Afia", "Esi",
    "Akua", "Araba", "Mansa", "Maame", "Nana", "Nhyira",

    # Ewe
    "Koku", "Kafui", "Komla", "Selorm", "Sena", "Seli",
    "Eyram", "Elikem", "Mawuli", "Dzifa", "Dela", "Mawusi", "Yawa",

    # Ga
    "Nii", "Tetteh", "Nartey", "Lamptey", "Quaye", "Lartey",
    "Odoi", "Adjei", "Armah", "Dede", "Momo", "Afi",

    # Common Ghanaian names
    "Saviour", "Blessing", "Precious", "Gift", "Divine", "Favour",
    "Prince", "Princess", "Michael", "Daniel", "Samuel", "Emmanuel",
    "Isaac", "Jonathan", "David", "Joseph", "John", "Mary", "Grace",
    "Esther", "Ruth", "Rebecca", "Elizabeth", "Joyce", "Patience",
    "Mercy", "Gloria", "Priscilla", "Christiana", "Victoria"
]

CITIES = [
    # Northern Region
    "Tamale", "Savelugu", "Yendi", "Walewale", "Pong-Tamale", "Tolon",
    "Kumbungu", "Karaga", "Gushegu", "Saboba", "Bimbilla", "Gushiegu",
    "Zabzugu", "Tatale", "Wulensi", "Mion", "Nanton", "Kpandai",
    "Sang", "Daboya", "Salaga", "Damongo", "Bole", "Sawla", "Larabanga",
    "Mole", "Fufulso", "Garu", "Pusiga",

    # Upper East
    "Bolgatanga", "Navrongo", "Bawku", "Zebilla", "Paga", "Sandema",
    "Fumbisi", "Bongo", "Zuarungu", "Tongo", "Binduri",

    # Upper West
    "Wa", "Lawra", "Jirapa", "Nandom", "Tumu", "Nadowli", "Daffiama",
    "Hamile", "Funsi", "Gwollu", "Kaleo",

    # Ashanti
    "Kumasi", "Obuasi", "Ejisu", "Konongo", "Mampong", "Bekwai",
    "Tarkwa", "Offinso", "Asante Mampong", "Agogo", "Juaben",

    # Greater Accra
    "Accra", "Tema", "Madina", "Adenta", "Legon", "Dansoman",
    "Kaneshie", "Nungua", "Teshie", "Labadi", "Spintex", "Kasoa",
    "Ashaley Botwe", "East Legon", "Dodowa", "Prampram",

    # Eastern
    "Koforidua", "Nkawkaw", "Akropong", "Aburi", "Nsawam", "Suhum",
    "Akim Oda", "Akim Swedru", "Begoro", "Mpraeso",

    # Central
    "Cape Coast", "Kasoa", "Winneba", "Mankessim", "Elmina",
    "Saltpond", "Swedru", "Agona Swedru", "Dunkwa", "Assin Fosu",

    # Western
    "Takoradi", "Sekondi", "Tarkwa", "Axim", "Elubo", "Prestea",
    "Bogoso", "Agona Nkwanta", "Wassa Akropong",

    # Volta / Oti
    "Ho", "Hohoe", "Kpando", "Aflao", "Keta", "Anloga", "Sogakope",
    "Denu", "Kete Krachi", "Nkwanta", "Dambai"
]

FOODS = [
    # Northern Ghana
    "TZ", "tubani", "tuo zaafi", "ayoyo soup", "ayoyo", "alefu", "dawadawa",
    "groundnut soup", "groundnut paste", "meat stew", "green leaf soup",
    "bean stew", "rice", "waakye", "yam", "boiled yam", "fried yam",
    "yam porridge", "sweet potato", "cocoyam", "maize", "millet",
    "millet porridge", "maize porridge", "koko", "tom brown", "weanimix",
    "soybeans", "beans", "black-eyed beans", "bambara beans",

    # Common Ghanaian foods
    "banku", "kenkey", "fufu", "ampesi", "red red", "plantain", "fried plantain",
    "boiled plantain", "rice and stew", "jollof", "fried rice", "plain rice",
    "gari", "gari soakings", "gari fortor", "kokonte", "aprapransa", "eto",
    "ɔmo tuo", "omotuo", "light soup", "palm nut soup", "palm nut", "kontomire",
    "kontomire stew", "garden egg stew", "okra soup", "okra", "beans stew",

    # Protein / affordable foods
    "egg", "boiled egg", "fried egg", "fish", "smoked fish", "sardine",
    "tuna", "chicken", "meat", "goat meat", "beef", "soy", "milk",
    "powdered milk", "groundnuts", "peanuts",

    # Fruits
    "banana", "mango", "papaya", "pawpaw", "orange", "watermelon",
    "pineapple", "avocado", "guava",

    # Vegetables / local ingredients
    "moringa leaves", "cassava", "carrot", "tomato", "onion", "pepper",
    "garden eggs", "cabbage", "cocoyam leaves"
]

SYMPTOMS_CHILD = [
    # Fever
    "fever", "hot body", "body dey hot", "body dey burn", "very hot",
    "temperature high", "head dey hot",

    # Convulsions
    "convulsions", "fits", "shaking", "jerking", "body dey shake",
    "e dey shake", "hands dey shake", "legs dey shake", "eyes dey turn",
    "body stiff", "child suddenly collapsed",

    # Vomiting
    "vomiting", "vomiting everything", "e dey vomit", "vomit plenty",
    "cannot keep food down", "cannot keep water down",

    # Diarrhea
    "running stomach", "toilet plenty", "watery stool", "loose stool",
    "diarrhea", "stooling plenty", "e dey stool plenty", "blood in the stool",
    "blood dey come from the stool", "stool has blood",

    # Breathing
    "coughing bad", "bad cough", "fast breathing", "breathing fast",
    "difficulty breathing", "struggling to breathe", "chest dey pull in",
    "chest is pulling inside", "e dey breathe hard", "breath no dey come well",
    "breathing is not normal",

    # Feeding
    "refusing breast", "won't take breast", "not sucking", "not breastfeeding",
    "e no dey suck", "e no want breast", "not eating", "not drinking",

    # General danger signs
    "very weak", "sleeping too much", "difficult to wake", "not responding",
    "child collapsed", "child is unconscious", "very sleepy", "eyes are sinking",
    "mouth is dry", "not passing urine", "crying without tears", "swollen body",
    "rash", "yellow eyes", "yellow body", "severe pain", "stomach swollen",
    "belly swollen"
]

SYMPTOMS_PREG = [
    "bleeding", "spotting blood", "blood dey come", "blood is coming",
    "bleeding from my private part", "severe headache", "headache plenty",
    "very bad headache", "blurred vision", "seeing double", "eyes dey blur",
    "I cannot see well", "swollen feet", "my feet are swollen",
    "my face and hands swell", "face dey swell", "hands dey swell",
    "baby not moving", "baby stopped kicking", "baby no dey move",
    "I cannot feel the baby", "baby movement has reduced", "strong belly pain",
    "severe abdominal pain", "belle dey pain me", "stomach dey pain me",
    "water broke early", "water dey come", "water has broken", "fever and chills",
    "high fever", "convulsions", "fits", "difficulty breathing",
    "breathing is difficult", "chest pain", "fainting", "I collapsed",
    "very weak", "dizziness", "I feel dizzy", "vomiting plenty",
    "vomiting everything", "cannot eat", "cannot drink", "severe back pain"
]

TIME_TAILS = [
    "", " since morning", " since yesterday", " since last night", " since afternoon",
    " since evening", " since this morning", "since yesterday morning",
    " since yesterday evening", " for two days now", " for three days",
    " for one week", " for some hours", " for a few hours", " for some time",
    " since last week", " since Monday", " since Tuesday", " since weighing day",
    " since we came from the hospital", " just now", " right now", " this morning",
    " today", " tonight", " oo", " oo since morning"
]

PREFIXES = [
    "", "please ", "abeg ", "I beg ", "nana ", "madam ", "mummy ", "mama ",
    "sister ", "brother ", "charley ", "chale ", "boss ", "sorry oo ",
    "please oo ", "I beg you ", "good morning nana ", "good afternoon nana ",
    "good evening nana ", "please help me ", "mummy please ", "madam please "
]

HEALTH_PLACES = [
    "hospital", "clinic", "health centre", "CHPS compound", "CHPS",
    "community health centre", "district hospital", "regional hospital",
    "Tamale Teaching Hospital", "health post", "maternity ward",
    "children's ward", "polyclinic", "CHPS zone"
]

# 2. Intent templates mapped to Nana's JSON actions
INTENT_TEMPLATES = {
    "start_health_check_child": {
        "queries": [
            "{child} is having {symptom}{time}",
            "{child} get {symptom}{time}, what do I do",
            "my baby {child} dey feel {symptom}, abeg help me",
            "{child} body dey hot and e get {symptom}",
            "body of {child} dey burn and e dey {symptom}",
            "{child} body dey hot{time}",
            "my baby {child} dey vomit plenty{time}",
            "{child} no dey breastfeed{time}",
            "please, {child} dey breathe fast{time}",
            "my pikin {child} get running stomach{time}",
            "the baby {child} dey shake{time}",
            "my child {child} no dey eat and e dey sleep too much",
            "should I take {child} to the {health_place} for {symptom}{time}",
            "I want to check my child {child} health, e has {symptom}",
            "please my baby {child} {symptom}{time}, should I go {health_place}"
        ],
        "say": "I hear you. {symptom} can be a critical danger sign for {child}. Let us start the health check right away to verify if we need to visit the clinic.",
        "action": {"name": "start_health_check", "params": {"subject": "child", "childName": "{child}"}}
    },
    "start_health_check_preg": {
        "queries": [
            "I am pregnant and I have {symptom}{time}",
            "I get belle and I dey feel {symptom}{time}",
            "spotting {symptom} since yesterday, help me",
            "my belly dey pain me and I get {symptom}",
            "I am expecting and get severe {symptom}",
            "I get belle and baby no dey move{time}",
            "I am pregnant and blood dey come{time}",
            "my feet and face dey swell{time}",
            "belle dey pain me badly{time}",
            "water break and I never reach hospital",
            "should I go {health_place} for this {symptom}{time}",
            "water broke early and I get severe {symptom}",
            "my head dey pain me bad, I am expecting{time}",
            "spotting blood and I am pregnant{time}",
            "is {symptom} serious in pregnancy, what should I do",
            "I have severe {symptom}{time}, should I visit the {health_place}"
        ],
        "say": "Please listen carefully. {symptom} during pregnancy is a warning sign. Let us run a check-in right now to see if we must go to the health facility.",
        "action": {"name": "start_health_check", "params": {"subject": "pregnancy"}}
    },
    "add_child": {
        "queries": [
            "register my new baby {child} born on {date}",
            "add my child {child}, a {sex} born {date}",
            "I delivered a baby {sex} named {child} on {date}",
            "put my baby {child} inside the app, born {date}",
            "I delivered a new baby {sex} {child} on {date}",
            "add my {sex} child {child} born on {date}",
            "register my kid {child} born {date}"
        ],
        "say": "Medaase! I will register baby {child} on the app so we can track their growth and vaccine schedule.",
        "action": {"name": "add_child", "params": {"name": "{child}", "sex": "{sex}", "dateOfBirth": "{date}"}}
    },
    "plan_diet": {
        "queries": [
            "what should I cook with {food1} and {food2}",
            "plan meals for my baby, I have {food1}",
            "chop money no dey, what can we eat with {food1}",
            "what foods are good for a child in {city}",
            "meal plan for a pregnant woman using {food1}",
            "is {food1} good for my baby",
            "can I feed the child with {food1}",
            "how to cook {food1} and {food2} for a toddler",
            "I have {food1} at home, what meal can we make",
            "what can we eat with {food1} today"
        ],
        "say": "I will open the diet planner so we can design healthy, affordable meals using {food1} and other local ingredients.",
        "action": {"name": "plan_diet", "params": {}}
    }
}

# 3. SMS Typo Generator to inject realistic training noise
def add_sms_noise(text):
    subs = {"please": "pls", "what": "wat", "should": "shud", "you": "u", "your": "ur", "and": "nd", "the": "de"}
    words = text.split()
    out = []
    for w in words:
        lw = w.lower()
        if lw in subs and random.random() < 0.4:
            out.append(subs[lw])
        elif len(w) > 4 and random.random() < 0.1:
            # Drop a random middle letter
            i = random.randrange(1, len(w) - 1)
            out.append(w[:i] + w[i+1:])
        else:
            out.append(w)
    return " ".join(out)

# 4. Generate Dataset
def generate_dataset(num_samples=55000):
    dataset = []
    
    for i in range(num_samples):
        # Pick a random template type
        intent_key = random.choice(list(INTENT_TEMPLATES.keys()))
        tpl = INTENT_TEMPLATES[intent_key]
        
        # Select slots
        child = random.choice(NAMES)
        city = random.choice(CITIES)
        symptom = random.choice(SYMPTOMS_CHILD if "child" in intent_key else SYMPTOMS_PREG)
        time = random.choice(TIME_TAILS)
        prefix = random.choice(PREFIXES)
        food1 = random.choice(FOODS)
        food2 = random.choice([f for f in FOODS if f != food1])
        sex = random.choice(["male", "female"])
        year = random.choice(["2025", "2026"])
        month = f"{random.randint(1, 12):02d}"
        day = f"{random.randint(1, 28):02d}"
        date = f"{year}-{month}-{day}"
        health_place = random.choice(HEALTH_PLACES)
        
        # Populate queries
        raw_query = random.choice(tpl["queries"]).format(
            child=child, symptom=symptom, time=time, food1=food1, food2=food2, sex=sex, date=date, city=city, health_place=health_place
        )
        query = (prefix + raw_query).strip()
        
        # Inject SMS typos/noise
        if random.random() < 0.35:
            query = add_sms_noise(query)
            
        # Format response
        say = tpl["say"].format(child=child, symptom=symptom, food1=food1)
        
        # Format action parameters
        action = None
        if tpl["action"]:
            action_name = tpl["action"]["name"]
            action_params = {}
            for k, v in tpl["action"]["params"].items():
                if isinstance(v, str):
                    action_params[k] = v.format(child=child, sex=sex, date=date)
                else:
                    action_params[k] = v
            action = {"name": action_name, "params": action_params}
            
        response_json = json.dumps({"say": say, "action": action})
        
        # Structure as training data
        messages = [
            {"role": "system", "content": "You are Nana, a warm maternal care helper. Always output a JSON object containing 'say' and 'action'."},
            {"role": "user", "content": query},
            {"role": "assistant", "content": response_json}
        ]
        
        dataset.append({"messages": messages})
        
    return dataset

if __name__ == "__main__":
    SAMPLES_COUNT = 55000
    print(f"Generating {SAMPLES_COUNT} diverse training turns...")
    data = generate_dataset(SAMPLES_COUNT)
    
    # Save as JSONL (Standard format for SFTTrainer / Hugging Face datasets)
    output_file = "nana_dataset_55k.jsonl"
    with open(output_file, "w", encoding="utf-8") as f:
        for item in data:
            f.write(json.dumps(item) + "\n")
            
    print(f"Dataset successfully created and saved as: {output_file} ({len(data)} rows)")
