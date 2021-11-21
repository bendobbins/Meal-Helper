import mysql.connector

from flask import Flask, request, session, jsonify
from flask_session import Session
from tempfile import mkdtemp
from werkzeug.security import generate_password_hash, check_password_hash

from Meal_Helper_Helper import login_required, mealDicBuilder, return_char, queryMaker, yesAndNo

# Create app
app = Flask(__name__)

app.config["TEMPLATES_AUTO_RELOAD"] = True

# Configure app
@app.after_request
def after_request(response):
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Expires"] = 0
    response.headers["Pragma"] = "no-cache"
    return response

# Configure sessions
app.config["SESSION_FILE_DIR"] = mkdtemp()
app.config["SESSION_PERMANENT"] = False
app.config["SESSION_TYPE"] = "filesystem"
Session(app)



@app.route("/register", methods=["POST"])
def register():
    """
    Creates a new user account, creates session id for user, stores unique username and hashed password in mysql users table
    """
    # Connect to database and create cursor
    # These are in every function because the connection would time out if only put once at the top
    db = mysql.connector.connect(
        host="localhost",
        user="mealHelper",
        password="mealPass123!",
        database="Meal_Helper"
    )
    cursor = db.cursor(prepared=True)
    # Receive data from server
    registerInfo = request.get_json()
    # Create new table and unique index on username if they don't exist
    cursor.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER AUTO_INCREMENT, username VARCHAR(255) NOT NULL, hash TEXT NOT NULL, PRIMARY KEY(id))")
    cursor.execute("SELECT COUNT(1) FROM INFORMATION_SCHEMA.STATISTICS WHERE table_schema = 'Meal_Helper' AND table_name = 'users' AND index_name = 'username'")
    index = cursor.fetchall()[0][0]
    if index == 0:
        cursor.execute("CREATE UNIQUE INDEX username ON users (username)")
    username = registerInfo['username']
    password = registerInfo['password']
    confirmation = registerInfo['confirm']
    if password == confirmation:
        # Create password hash
        phash = generate_password_hash(password, method="sha256", salt_length=8)
        values = (username, phash)
        # Error will occur if username to be inserted is taken, return true or false for registered value accordingly
        try:
            cursor.execute("INSERT INTO users (username, hash) VALUES (%s, %s)", values)
            db.commit()
            cursor.execute("SELECT id FROM users WHERE username = %s", (username,))
            session["user_id"] = cursor.fetchall()[0][0]
            registered = {"registered": True}
        except:
            registered = {"registered": False}
    return jsonify(registered)


@app.route("/login", methods=["POST"])
def login():
    """
    Checks username and password for user logging in, returns whether the user exists, and if it does, whether the password is correct
    """
    # Connect to database and create cursor
    db = mysql.connector.connect(
        host="localhost",
        user="mealHelper",
        password="mealPass123!",
        database="Meal_Helper"
    )
    cursor = db.cursor(prepared=True)
    session.clear()
    loginInfo = request.get_json()
    username = loginInfo['username']
    user = (username,)
    password = loginInfo['password']
    cursor.execute("SELECT hash FROM users WHERE username = %s", user)
    phashlist = cursor.fetchall()
    # Check if user exists (because then a password would exist)
    if phashlist:
        phash = phashlist[0][0]
        # If user exists, check if inputted password matches hash, if true return logged in and start session
        if check_password_hash(phash, password):
            loggedIn = {"logged_in": True, "user": True}
            cursor.execute("SELECT id FROM users WHERE username = %s", user)
            session["user_id"] = cursor.fetchall()[0][0]
        # Return if password does not match
        else:
            loggedIn = {"logged_in": False, "user": True}
    # Return if username doesn't exist
    else:
        loggedIn = {"logged_in": False, "user": False}
    return jsonify(loggedIn)


@app.route("/quiz", methods=["GET", "POST"])
@login_required
def quiz():
    """
    Accepts data from a personal information quiz and stores it in a mysql table called personal_data
    """
    # So frontend can check session
    if request.method == "GET":
        return jsonify({"session": True})
    else:
        # Connect to database and create cursor
        db = mysql.connector.connect(
            host="localhost",
            user="mealHelper",
            password="mealPass123!",
            database="Meal_Helper"
        )
        cursor = db.cursor(prepared=True)
        quizInfo = request.get_json()
        # Make sure user entered integers for certain text field values on front end
        try:
            height = int(quizInfo['height'])
            weight = int(quizInfo['weight'])
        except:
            return jsonify({"height/weight": True, "received": False})
        # Create Y and N list from bools
        booleanlist = [quizInfo['vegetarian'], quizInfo['vegan'], quizInfo['glutenFree'], quizInfo['lactose'], quizInfo['nuts']]
        charlist = return_char(booleanlist)
        # For sexSel: 0 = Male, 1 = Female, 2 = Other
        # For weightGoalSel: 0 = Lose weight, 1 = Gain weight, 2 = Remain at current weight
        quizInsert = (quizInfo['sexSel'], weight, height, quizInfo['weightGoalSel'], quizInfo['poundsGoal'], charlist[0], charlist[1], charlist[2], charlist[3], charlist[4], session["user_id"])
        # Create personal_data if it does not exist
        cursor.execute("CREATE TABLE IF NOT EXISTS personal_data (id INTEGER, sex INTEGER, weight INTEGER, height INTEGER, weight_goal INTEGER, pounds_goal INTEGER, original_goal INTEGER, vegetarian CHAR, vegan CHAR, gluten CHAR, lactose CHAR, nuts CHAR, FOREIGN KEY (id) REFERENCES users(id))")
        # Check if user is new or not by seeing if they have previous data in table
        # If they are a new user, original goal must be added
        cursor.execute("SELECT * FROM personal_data WHERE id = %s", (session["user_id"],))
        newUserCheck = cursor.fetchall()
        if newUserCheck:
            # Not new user, insert new values for all except original goal
            cursor.execute("UPDATE personal_data SET sex = %s, weight = %s, height = %s, weight_goal = %s, pounds_goal = %s, vegetarian = %s, vegan = %s, gluten = %s, lactose = %s, nuts = %s WHERE id = %s", quizInsert)
        else:
            # New user, create original goal and insert with other values
            if quizInfo['weightGoalSel'] == 0:
                originalGoal = weight - quizInfo['poundsGoal']
            elif quizInfo['weightGoalSel'] == 1:
                originalGoal = weight + quizInfo['poundsGoal']
            else:
                originalGoal = weight
            quizInsert += (originalGoal,)
            cursor.execute("INSERT INTO personal_data (sex, weight, height, weight_goal, pounds_goal, vegetarian, vegan, gluten, lactose, nuts, id, original_goal) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", quizInsert)
        db.commit()
        return jsonify({"height/weight": False, "received": True})


@app.route("/personal", methods=["GET", "POST"])
@login_required
def personal():
    """
    Display user's personal information by retrieving it from the personal_data table
    """
    # So frontend can check session
    if request.method == "POST":
        return jsonify({"session": True})
    else:
        # Connect to database and create cursor
        db = mysql.connector.connect(
            host="localhost",
            user="mealHelper",
            password="mealPass123!",
            database="Meal_Helper"
        )
        cursor = db.cursor(prepared=True)
        # Select needed values from database
        cursor.execute("SELECT sex, weight, height, weight_goal, pounds_goal, original_goal, vegetarian, vegan, gluten, lactose, nuts, username FROM personal_data JOIN users ON personal_data.id = users.id WHERE personal_data.id = %s", (session["user_id"],))
        info = cursor.fetchall()[0]
        # Create strings from integer values for nicer display on frontend
        if info[0] == 0:
            sex = "Male"
        elif info[0] == 1:
            sex = "Female"
        else:
            sex = "Other"
        if info[3] == 0:
            currentGoal = "Lose " + str(info[4]) + " lbs"
        elif info[3] == 1:
            currentGoal = "Gain " + str(info[4]) + " lbs"
        else:
            currentGoal = "Maintain same weight"
        # Create Yes and No values from Y and N values for personal dietary restrictions
        preferencesChar = [info[6], info[7], info[8], info[9], info[10]]
        preferencesString = yesAndNo(preferencesChar)
        keys = ["Username", "Sex", "Current Weight", "Height", "Current Weight Goal", "Original Weight Goal", "Vegetarian", "Vegan", "Gluten-Free", "Lactose Intolerance", "Nut-Free"]
        values = [info[11], sex, str(info[1]) + " lbs", str(info[2]) + '"', currentGoal, str(info[5]) + " lbs", preferencesString[0], preferencesString[1], preferencesString[2], preferencesString[3], preferencesString[4]]
        infoToSend = []
        # Create a list of dictionaries, each with a category of personal information and the value for that category, then return list
        for i in range(len(keys)):
            dic = {"id": keys[i], "value": values[i]}
            infoToSend.append(dic)
        return jsonify({"info": infoToSend})


@app.route("/recipes", methods=["GET", "POST"])
@login_required
def recipes():
    """
    Selects recipes from recipes table according to user's dietary restrictions, then passes all information about each recipe to frontend
    """
    # I created a table in my database via the terminal called recipes using the command
    # CREATE TABLE recipes (name TINYTEXT, meal_type VARCHAR(15), imageURL TEXT, ingredients TEXT, directions TEXT, prep_time INTEGER, cook_time INTEGER, serving_size TINYINT, calories INTEGER, low_carb CHAR, vegetarian CHAR, vegan CHAR, gluten_free CHAR, dairy_free CHAR, nut_free CHAR);
    # I did this outside of my Python code so that I could preload the table with some recipes that can be used before the users input any
    # I also created non-unique indexes on the following values: low_carb, vegetarian, vegan, gluten_free, dairy_free and nut_free
    if request.method == "POST":
        return jsonify({"session": True})
    else:
        # Connect to database and create cursor
        db = mysql.connector.connect(
            host="localhost",
            user="mealHelper",
            password="mealPass123!",
            database="Meal_Helper"
        )
        cursor = db.cursor(prepared=True)
        # Get restrictions for user so that certain recipes can be excluded
        cursor.execute("SELECT weight_goal, vegetarian, vegan, gluten, lactose, nuts FROM personal_data WHERE id = %s", (session["user_id"],))
        preferences = cursor.fetchall()[0]
        keylist = ["vegetarian", "vegan", "gluten_free", "dairy_free", "nut_free"]
        # Create queries that rule out recipes with a restriction if the user has that restriction
        query = queryMaker(preferences[1:], keylist)
        # Fetch all recipes that work for user
        if preferences[0] == 0:
            cursor.execute("SELECT * FROM recipes WHERE low_carb = 'Y'" + query[0] + query[1] + query[2] + query[3] + query[4])
        elif preferences[0] == 1:
            cursor.execute("SELECT * FROM recipes WHERE low_carb = 'N'" + query[0] + query[1] + query[2] + query[3] + query[4])
        else:
            cursor.execute("SELECT * FROM recipes WHERE calories > 0" + query[0] + query[1] + query[2] + query[3] + query[4])
        meals = cursor.fetchall()
        breakfastid = 0
        lunchid = 0
        dinnerid = 0
        breakfastlist = []
        lunchlist = []
        dinnerlist = []
        # Loop through all recipes
        for meal in meals:
            # Check meal type
            if meal[1] == "breakfast":
                # Create dictionary for meal with all information about that meal, add 1 to id and append dictionary to list for corresponding meal type
                breakfastlist.append(mealDicBuilder(breakfastid, meal))
                breakfastid += 1
            elif meal[1] == "lunch":
                lunchlist.append(mealDicBuilder(lunchid, meal))
                lunchid += 1
            else:
                dinnerlist.append(mealDicBuilder(dinnerid, meal))
                dinnerid += 1
        # Return list of dictionaries for each meal type
        return jsonify({
            "breakfast": breakfastlist,
            "lunch": lunchlist,
            "dinner": dinnerlist
        })


@app.route("/AddRecipe", methods=["GET", "POST"])
@login_required
def AddRecipe():
    """
    Accepts user data for a new recipe, verifies if recipe is valid, then adds to database as a new recipe
    """
    # Check session
    if request.method == "GET":
        return jsonify({"session": True})
    else:
        # Connect to database and create cursor
        db = mysql.connector.connect(
            host="localhost",
            user="mealHelper",
            password="mealPass123!",
            database="Meal_Helper"
        )
        cursor = db.cursor(prepared=True)
        recipe = request.get_json()
        # Make sure calories text field input is an integer
        try:
            calories = int(recipe['calories'])
        except:
            return jsonify({"calories": True, "ingredients": False, "submitted": False})
        # Make a list of Y and N characters to be inserted into table corresponding to boolean values regarding restrictions for meal
        booleanlist = [recipe['low_carb'], recipe['vegetarian'], recipe['vegan'], recipe['gluten_free'], recipe['dairy_free'], recipe['nut_free']]
        charlist = return_char(booleanlist)
        # Get meal type
        if recipe['typeSel'] == 0:
            meal_type = 'breakfast'
        elif recipe['typeSel'] == 1:
            meal_type = 'lunch'
        else:
            meal_type = 'dinner'
        # Check that ingredient list is valid
        checkIngredients = recipe['ingredients'].split(",")
        if len(checkIngredients) == 1:
            return jsonify({"calories": False, "ingredients": True, "submitted": False})
        # Insert new recipe into recipe table
        addedRecipe = (recipe['name'], meal_type, recipe['imageURL'], recipe['ingredients'], recipe['directions'], recipe['prep'], recipe['cook'], recipe['servings'], calories, charlist[0], charlist[1], charlist[2], charlist[3], charlist[4], charlist[5])
        sql = "INSERT INTO recipes (name, meal_type, imageURL, ingredients, directions, prep_time, cook_time, serving_size, calories, low_carb, vegetarian, vegan, gluten_free, dairy_free, nut_free) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        cursor.execute(sql, addedRecipe)
        db.commit()
        return jsonify({"calories": False, "ingredients": False, "submitted": True})


@app.route("/logout")
def logout():
    """
    Logs user out
    """
    # Clear user's session
    session.clear()
    return jsonify({"logged out": True})