-- PHASE 1: DATABASE ARCHITECTURE (DDL)
-- Creating the Patients Table
CREATE TABLE Patients (
    PatientID INT PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Gender VARCHAR(10),
    DateOfBirth DATE,
    EnrollmentDate DATE);

--LabResults table
    CREATE TABLE LabResults (
    ResultID INT PRIMARY KEY,
    PatientID INT,
    TestName VARCHAR(100),
    TestValue DECIMAL(10,2),
    Unit VARCHAR(20),
    Status VARCHAR(20),
    OrderTimestamp TIMESTAMP,
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID))
 
--Adding the verification timestamp column to calculate TAT
ALTER TABLE LabResults
ADD VerifiedTimestamp DATETIME;

--droping and adding OrderTimestamp
    alter table LabResults 
    drop column  OrderTimestamp

    alter table LabResults
    add OrderTimestamp datetime

-- PHASE 2: DATA INSERTION & CLEANING (DML)
    -- add values in the labresults table
INSERT INTO LabResults (ResultID, PatientID, TestName, TestValue, Unit, Status) VALUES
(5001, 101, 'Fasting Blood Sugar', 145.20, 'mg/dL', 'Elevated'),
(5002, 101, 'Packed Cell Volume (PCV)', 42.00, '%', 'Normal'),
(5003, 102, 'Malaria Parasite Smear', 0.00, 'per uL', 'Normal'),
(5004, 103, 'Malaria Parasite Smear', 4500.00, 'per uL', 'Critical'),
(5005, 103, 'Packed Cell Volume (PCV)', 24.00, '%', 'Critical'),
(5006, 104, 'Fasting Blood Sugar', 85.00, 'mg/dL', 'Normal')

-- Adding values in the patient table 
INSERT INTO Patients (PatientID, FirstName, LastName, Gender, DateOfBirth, EnrollmentDate) VALUES
(101, 'Chidi', 'Okonkwo', 'Male', '1985-04-12', '2026-01-15'),
(102, 'Aminat', 'Bello', 'Female', '1992-09-23', '2026-02-10'),
(103, 'Emem', 'Bassey', 'Female', '2001-11-05', '2026-03-01'),
(104, 'Tunde', 'Bakare', 'Male', '1978-07-30', '2026-05-12');


UPDATE Patients
SET LastName = 'Bello-Asuquo'
WHERE PatientID = 102;

--Updating the OrderTimestamp times for each test
UPDATE LabResults SET OrderTimestamp = '2026-06-15 08:00:00' WHERE ResultID = 5001;
UPDATE LabResults SET OrderTimestamp = '2026-06-15 08:00:00' WHERE ResultID = 5002;
UPDATE LabResults SET OrderTimestamp = '2026-06-15 09:30:00' WHERE ResultID = 5003;
UPDATE LabResults SET OrderTimestamp = '2026-06-15 10:00:00' WHERE ResultID = 5004;
UPDATE LabResults SET OrderTimestamp = '2026-06-15 10:00:00' WHERE ResultID = 5005;
UPDATE LabResults SET OrderTimestamp = '2026-06-16 07:15:00' WHERE ResultID = 5006;

select * from Patients
select * from LabResults

--Updating the verification times for each test
UPDATE LabResults SET VerifiedTimestamp = '2026-06-15 09:15:00' WHERE ResultID = 5001;
UPDATE LabResults SET VerifiedTimestamp = '2026-06-15 08:45:00' WHERE ResultID = 5002;
UPDATE LabResults SET VerifiedTimestamp = '2026-06-15 10:10:00' WHERE ResultID = 5003;
UPDATE LabResults SET VerifiedTimestamp = '2026-06-15 12:45:00' WHERE ResultID = 5004;
UPDATE LabResults SET VerifiedTimestamp = '2026-06-15 11:15:00' WHERE ResultID = 5005;
UPDATE LabResults SET VerifiedTimestamp = '2026-06-16 11:30:00' WHERE ResultID = 5006;

-- PHASE 3: ANALYTICAL QUERIES
--================================================
-- Query 1: TAT & SLA Performance Matrix

SELECT 
    ResultID, PatientID, TestName, OrderTimestamp, VerifiedTimestamp,
    DATEDIFF(minute, OrderTimestamp, VerifiedTimestamp) AS ProcessingTimeMinutes,
    CASE 
        WHEN DATEDIFF(minute, OrderTimestamp, VerifiedTimestamp) <= 60 THEN 'Within SLA (Efficient)'
        WHEN DATEDIFF(minute, OrderTimestamp, VerifiedTimestamp) BETWEEN 61 AND 120 THEN 'Acceptable'
        ELSE 'SLA Breach (Delayed Bottleneck)'
    END AS PerformanceStatus
FROM LabResults;

-- Query 2: Systematic Delay Identification
--Result that took the longest time to finalize)
SELECT 
    TestName,
    COUNT(ResultID) AS TotalTestsRun,
    AVG(DATEDIFF(minute, OrderTimestamp, VerifiedTimestamp)) AS AvgTAT_Minutes,
    MAX(DATEDIFF(minute, OrderTimestamp, VerifiedTimestamp)) AS MaxTAT_Minutes
FROM LabResults
GROUP BY TestName
ORDER BY AvgTAT_Minutes DESC;

-- Query 3: High-Risk Patient Routing
-- High Risk Patient
SELECT 
    p.PatientID,
    p.FirstName,
    p.LastName,
    l.TestName,
    l.TestValue,
    l.Status
FROM Patients p
INNER JOIN LabResults l ON p.PatientID = l.PatientID
WHERE p.PatientID IN (
    SELECT DISTINCT PatientID 
    FROM LabResults 
    WHERE Status = 'Critical');
