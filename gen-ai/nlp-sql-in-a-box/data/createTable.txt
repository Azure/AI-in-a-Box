CREATE TABLE ExplorationProduction (
    WellID INT PRIMARY KEY,
    WellName VARCHAR(50),
    Location VARCHAR(100),
    ProductionDate DATE,
    ProductionVolume DECIMAL(10, 2),
    Operator VARCHAR(50),
    FieldName VARCHAR(50),
    Reservoir VARCHAR(50),
    Depth DECIMAL(10, 2),
    APIGravity DECIMAL(5, 2),
    WaterCut DECIMAL(5, 2),
    GasOilRatio DECIMAL(10, 2)
);