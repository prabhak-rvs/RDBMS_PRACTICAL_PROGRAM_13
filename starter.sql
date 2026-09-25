-- Assignment 13
-- Normalize Student table up to Third Normal Form (3NF)

-- Original table:
-- Student(StudentID, StudentName, CourseName, FacultyName, DepartmentName)

-- Create the normalized tables:
--
-- Department(DepartmentID, DepartmentName)
-- Faculty(FacultyID, FacultyName, DepartmentID)
-- Course(CourseID, CourseName, FacultyID)
-- Student(StudentID, StudentName, CourseID)

-- Write your CREATE TABLE statements below.
