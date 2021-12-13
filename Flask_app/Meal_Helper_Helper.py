import json
import mysql.connector

from flask import session, jsonify
from functools import wraps


def login_required(protected_function):
    """
    Wrapper for all pages that require login to access.
    """
    @wraps(protected_function)
    def decorated_function(*args, **kwargs):
        # Check user session
        if session.get("user_id") is None:
            # Return false if no session, allow connection to route if session
            return jsonify({"session": False})
        return protected_function(*args, **kwargs)
    return decorated_function



def return_char(booleanlist):
    """
    Function changes a list of boolean values into a list of Y and N values.
    """
    charlist = []

    for boolean in booleanlist:
        if boolean:
            charlist.append("Y")
        else:
            charlist.append("N")

    return charlist


def queryMaker(characterlist, columnlist):
    """
    Function takes a list of Y and N chars corresponding to a list of mysql values and creates a mysql query for each value if the char is Y.
    Also appends an empty string if char is N to avoid bounds errors when using returned list to create queries.
    """
    query = []

    for i in range(len(columnlist)):
        if characterlist[i] == "Y":
            query.append(" AND " + columnlist[i] + " = 'Y'")
        else:
            query.append("")

    return query


def restrictions_helper(meal):
    """
    Function creates a list of restrictions from data passed in about a recipe in a tuple.
    """
    restrictions = []
    
    if meal[10] == "Y":
        restrictions.append("v")
    if meal[11] == "Y":
        restrictions.append("V")
    if meal[12] == "N":
        restrictions.append("G")
    if meal[13] == "N":
        restrictions.append("D")
    if meal[14] == "N":
        restrictions.append("N")

    return restrictions


def yesAndNo(chars):
    """
    Function takes a list of Y and N values as input and returns a list with corresponding Yes and No strings.
    """
    wordList = []

    for char in chars:
        if char == "Y":
            wordList.append("Yes")
        else:
            wordList.append("No")

    return wordList


def mealDicBuilder(mealid, meal):
    """
    Function creates a dictionary to be jsonified and used in frontend based on recipe tuple from mysql query.
    """
    # Change ingredients from comma-separated list to python list
    ingredientList = meal[3].split(",")
    for i in range(len(ingredientList)):
        # Clean up strings
        ingredient = ingredientList[i].strip()
        ingredient = ingredient.strip("\n")

        # Capitalize first letter of string if not a number
        try:
            int(ingredient[0])
        except:
            ingredient = ingredient[0].upper() + ingredient[1:]

        ingredientList.pop(i)
        ingredientList.insert(i, ingredient)

    # Get yes and no values for restrictions from mysql Y and N values
    valueList = ["Low_Carb", "Vegetarian", "Vegan", "Gluten_Free", "Dairy_Free", "Nut_Free"]
    charList = [meal[9], meal[10], meal[11], meal[12], meal[13], meal[14]]
    DisplayRestrictions = yesAndNo(charList)

    # Build dictionary
    mealDic = {}
    mealDic["Name"] = meal[0]
    mealDic["Restrictions"] = restrictions_helper(meal)
    mealDic["Ingredients"] = ingredientList
    mealDic["Directions"] = meal[4]

    # Change ints to strings to be displayed on frontend
    if meal[5] != 1:
        mealDic["Prep"] = str(meal[5]) + " mins"
    else:
        mealDic["Prep"] = str(meal[5]) + " min"
    if meal[6] != 1:
        mealDic["Cook"] = str(meal[6]) + " mins"
    else:
        mealDic["Cook"] = str(meal[6]) + " min"

    mealDic["Servings"] = str(meal[7])
    mealDic["Calories"] = str(meal[8])

    # Add yes and no values for each restriction
    for j in range(len(valueList)):
        mealDic[valueList[j]] = DisplayRestrictions[j]

    mealDic["Image"] = meal[2]
    mealDic["id"] = mealid

    return mealDic
    

def preloadRecipes():
    """
    Function preloads recipes into database from a preconfigured json file. Uses the same method and json formatting that is used
    for Meal_Helper.py AddRecipe() function. Only called when this program is run by itself.
    """
    # Connect to database
    db = mysql.connector.connect(
            host="localhost",
            user="mealHelper",
            password="mealPass123!",
            database="Meal_Helper"
        )
    cursor = db.cursor(prepared=True)

    # Open json file
    with open("~/project/Flask_app/recipePreload.json") as jsonFile:

        # Load json as python object
        recipeList = json.load(jsonFile)

        # recipeList is list of dictionaries format
        for recipe in recipeList:

            # Same code as in AddRecipe()
            booleanlist = [recipe['low_carb'], recipe['vegetarian'], recipe['vegan'], recipe['gluten_free'], recipe['dairy_free'], recipe['nut_free']]
            charlist = return_char(booleanlist)

            if recipe['typeSel'] == 0:
                meal_type = 'breakfast'
            elif recipe['typeSel'] == 1:
                meal_type = 'lunch'
            else:
                meal_type = 'dinner'

            addedRecipe = (recipe['name'], meal_type, recipe['imageURL'], recipe['ingredients'], recipe['directions'], recipe['prep'], recipe['cook'], recipe['servings'], recipe['calories'], charlist[0], charlist[1], charlist[2], charlist[3], charlist[4], charlist[5])
            sql = "INSERT INTO recipes (name, meal_type, imageURL, ingredients, directions, prep_time, cook_time, serving_size, calories, low_carb, vegetarian, vegan, gluten_free, dairy_free, nut_free) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
            cursor.execute(sql, addedRecipe)

        db.commit()


# Call preload when program is run
if __name__ == '__main__':
    preloadRecipes()