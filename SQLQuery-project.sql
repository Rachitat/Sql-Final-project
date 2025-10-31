-- Create Database
CREATE DATABASE StudentResultDB;
GO
USE StudentResultDB;
GO

-- Students Table
CREATE TABLE Students (
    StudentID INT PRIMARY KEY IDENTITY(1,1),
    StudentName VARCHAR(100),
    Department VARCHAR(50)
);

-- Courses Table
CREATE TABLE Courses (
    CourseID INT PRIMARY KEY IDENTITY(1,1),
    CourseName VARCHAR(100),
    Credits INT
);

-- Semesters Table
CREATE TABLE Semesters (
    SemesterID INT PRIMARY KEY IDENTITY(1,1),
    SemesterName VARCHAR(50)
);

-- Grades Table
CREATE TABLE Grades (
    GradeID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT FOREIGN KEY REFERENCES Students(StudentID),
    CourseID INT FOREIGN KEY REFERENCES Courses(CourseID),
    SemesterID INT FOREIGN KEY REFERENCES Semesters(SemesterID),
    Marks INT,
    Grade CHAR(2)
);

-- GPA Table
CREATE TABLE GPA (
    GPAID INT PRIMARY KEY IDENTITY(1,1),
    StudentID INT FOREIGN KEY REFERENCES Students(StudentID),
    SemesterID INT FOREIGN KEY REFERENCES Semesters(SemesterID),
    GPA DECIMAL(3,2)
);


INSERT INTO Students (StudentName, Department) VALUES
('Amit Sharma', 'Computer Science'),
('Riya Singh', 'IT'),
('Rahul Verma', 'Electronics');

INSERT INTO Courses (CourseName, Credits) VALUES
('Database Systems', 3),
('Data Structures', 4),
('Operating Systems', 3);

INSERT INTO Semesters (SemesterName) VALUES
('Semester 1'), ('Semester 2');

INSERT INTO Grades (StudentID, CourseID, SemesterID, Marks, Grade) VALUES
(1, 1, 1, 85, 'A'),
(1, 2, 1, 78, 'B'),
(2, 1, 1, 92, 'A'),
(2, 3, 1, 80, 'B'),
(3, 2, 1, 67, 'C');



CREATE TRIGGER trg_CalculateGPA
ON Grades
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO GPA (StudentID, SemesterID, GPA)
    SELECT 
        g.StudentID,
        g.SemesterID,
        ROUND(AVG(
            CASE 
                WHEN g.Grade = 'A' THEN 4.0
                WHEN g.Grade = 'B' THEN 3.0
                WHEN g.Grade = 'C' THEN 2.0
                WHEN g.Grade = 'D' THEN 1.0
                ELSE 0.0
            END
        ), 2)
    FROM Grades g
    GROUP BY g.StudentID, g.SemesterID;
END;
GO


SELECT 
    s.StudentName,
    sem.SemesterName,
    gpa.GPA
FROM GPA gpa
JOIN Students s ON gpa.StudentID = s.StudentID
JOIN Semesters sem ON gpa.SemesterID = sem.SemesterID;

SELECT 
    s.StudentName,
    sem.SemesterName,
    vw.GPA
FROM vw_SemesterSummary vw
JOIN Students s ON vw.StudentName = s.StudentName
JOIN Semesters sem ON vw.SemesterName = sem.SemesterName;






SELECT 
    s.StudentName,
    gpa.SemesterID,
    gpa.GPA,
    RANK() OVER (PARTITION BY gpa.SemesterID ORDER BY gpa.GPA DESC) AS RankPosition
FROM GPA gpa
JOIN Students s ON gpa.StudentID = s.StudentID;


SELECT 
    StudentName,
    SemesterID,
    GPA,
    RANK() OVER (PARTITION BY SemesterID ORDER BY GPA DESC) AS RankPosition
FROM (
    SELECT 
        s.StudentID,
        s.StudentName,
        g.SemesterID,
        ROUND(AVG(
            CASE 
                WHEN g.Grade = 'A' THEN 4.0
                WHEN g.Grade = 'B' THEN 3.0
                WHEN g.Grade = 'C' THEN 2.0
                ELSE 0.0
            END
        ), 2) AS GPA
    FROM Grades g
    JOIN Students s ON g.StudentID = s.StudentID
    GROUP BY s.StudentID, s.StudentName, g.SemesterID
) AS GPAData
ORDER BY SemesterID, RankPosition;




SELECT 
    s.StudentName,
    g.SemesterID,
    COUNT(CASE WHEN g.Grade IN ('A','B','C') THEN 1 END) AS PassedSubjects,
    COUNT(CASE WHEN g.Grade IN ('D','F') THEN 1 END) AS FailedSubjects
FROM Grades g
JOIN Students s ON g.StudentID = s.StudentID
GROUP BY s.StudentName, g.SemesterID;





CREATE VIEW vw_SemesterSummary AS
SELECT 
    s.StudentName,
    sem.SemesterName,
    ROUND(AVG(
        CASE 
            WHEN g.Grade = 'A' THEN 4.0
            WHEN g.Grade = 'B' THEN 3.0
            WHEN g.Grade = 'C' THEN 2.0
            ELSE 0.0
        END
    ), 2) AS GPA
FROM Grades g
JOIN Students s ON g.StudentID = s.StudentID
JOIN Semesters sem ON g.SemesterID = sem.SemesterID
GROUP BY s.StudentName, sem.SemesterName;


CREATE VIEW vw_WeeklyGPASummary AS
SELECT
    s.StudentID,
    s.StudentName,
    sem.SemesterID,
    sem.SemesterName,
    ROUND(AVG(
        CASE 
            WHEN g.Grade = 'A' THEN 4.0
            WHEN g.Grade = 'B' THEN 3.0
            WHEN g.Grade = 'C' THEN 2.0
            ELSE 0.0
        END
    ), 2) AS GPA,
    RANK() OVER (PARTITION BY sem.SemesterID ORDER BY AVG(
        CASE 
            WHEN g.Grade = 'A' THEN 4.0
            WHEN g.Grade = 'B' THEN 3.0
            WHEN g.Grade = 'C' THEN 2.0
            ELSE 0.0
        END
    ) DESC) AS RankInSemester
FROM Grades g
JOIN Students s ON g.StudentID = s.StudentID
JOIN Semesters sem ON g.SemesterID = sem.SemesterID
GROUP BY s.StudentID, s.StudentName, sem.SemesterID, sem.SemesterName;



SELECT * FROM vw_WeeklyGPASummary;

SELECT * FROM vw_SemesterSummary;



