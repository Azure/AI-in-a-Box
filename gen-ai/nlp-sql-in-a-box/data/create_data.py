import pyodbc
from faker import Faker
import configparser

# Read the config.ini file
config = configparser.ConfigParser()
config.read('data/config.ini')

# Connect to the SQL Server database
server_name = config.get('database', 'server_name')
database_name = config.get('database', 'database_name')
username = config.get('database', 'username')
password = config.get('database', 'password')

# Connect to the SQL Server database
conn = pyodbc.connect('DRIVER={driver};SERVER={server_name};DATABASE={database_name};UID={username};PWD={password}'.format(driver="ODBC Driver 18 for SQL Server",server_name=server_name, database_name=database_name, username=username, password=password))

# Create a cursor object to execute SQL queries
cursor = conn.cursor()

# Create Faker object
fake = Faker()

# Generate and insert 100 fake records
for id in range(100):
    well_id = id + 1
    well_name = fake.word() + ' Well'
    location = fake.city() + ', ' + fake.country()
    production_date = fake.date_between(start_date='-1y', end_date='today')
    production_volume = fake.pydecimal(left_digits=6, right_digits=2, positive=True)
    operator = fake.company()
    field_name = fake.word() + ' Field'
    reservoir = fake.word() + ' Reservoir'
    depth = fake.pydecimal(left_digits=5, right_digits=2, positive=True)
    api_gravity = fake.pydecimal(left_digits=2, right_digits=2, positive=True)
    water_cut = fake.pydecimal(left_digits=2, right_digits=2)
    gas_oil_ratio = fake.pydecimal(left_digits=4, right_digits=2)
    print(well_name + " added to the database.")
    # Insert record into the ExplorationProduction table
    cursor.execute("INSERT INTO ExplorationProduction (WellID, WellName, Location, ProductionDate, ProductionVolume, Operator, FieldName, Reservoir, Depth, APIGravity, WaterCut, GasOilRatio) VALUES (?,?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                   well_id,well_name, location, production_date, production_volume, operator, field_name, reservoir, depth, api_gravity, water_cut, gas_oil_ratio)

# Commit the changes and close the connection
conn.commit()
conn.close()
