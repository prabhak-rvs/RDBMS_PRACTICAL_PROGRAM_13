#!/bin/bash

set -u

MYSQL="mysql --protocol=TCP -h 127.0.0.1 -u root -p${MYSQL_ROOT_PASSWORD} -N -B"
DB="autograding_db"

PASS=0
FAIL=0

echo "======================================"
echo "Assignment 13 - 3NF Autograding"
echo "======================================"

# Check MySQL connection
if ! $MYSQL -e "SELECT 1" >/dev/null 2>&1; then
    echo "ERROR: Cannot connect to MySQL"
    exit 1
fi

# Create clean database
$MYSQL -e "DROP DATABASE IF EXISTS $DB"
$MYSQL -e "CREATE DATABASE $DB"

# Check student file
if [ ! -f "./Assignment_13/answers.sql" ]; then
    echo "FAIL: Assignment_13/answers.sql not found"
    exit 1
fi

# Reject database-level commands
if grep -Eiq '^[[:space:]]*(DROP[[:space:]]+DATABASE|CREATE[[:space:]]+DATABASE|USE)[[:space:]]' "./Assignment_13/answers.sql"; then
    echo "FAIL: Do not use DROP DATABASE, CREATE DATABASE, or USE."
    exit 1
fi

# Execute student SQL
if ! $MYSQL "$DB" < "./Assignment_13/answers.sql" > /tmp/sql_output.txt 2>&1; then
    echo "FAIL: SQL execution failed"
    cat /tmp/sql_output.txt
    exit 1
fi

table_exists() {
    TABLE="$1"

    COUNT=$($MYSQL "$DB" -e "
        SELECT COUNT(*)
        FROM information_schema.tables
        WHERE table_schema='$DB'
        AND table_name='$TABLE';
    ")

    [ "$COUNT" = "1" ]
}

column_exists() {
    TABLE="$1"
    COLUMN="$2"

    COUNT=$($MYSQL "$DB" -e "
        SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_schema='$DB'
        AND table_name='$TABLE'
        AND column_name='$COLUMN';
    ")

    [ "$COUNT" = "1" ]
}

primary_key_exists() {
    TABLE="$1"
    COLUMN="$2"

    COUNT=$($MYSQL "$DB" -e "
        SELECT COUNT(*)
        FROM information_schema.key_column_usage
        WHERE table_schema='$DB'
        AND table_name='$TABLE'
        AND column_name='$COLUMN'
        AND constraint_name='PRIMARY';
    ")

    [ "$COUNT" = "1" ]
}

foreign_key_exists() {
    TABLE="$1"
    COLUMN="$2"
    REF_TABLE="$3"
    REF_COLUMN="$4"

    COUNT=$($MYSQL "$DB" -e "
        SELECT COUNT(*)
        FROM information_schema.key_column_usage
        WHERE table_schema='$DB'
        AND table_name='$TABLE'
        AND column_name='$COLUMN'
        AND referenced_table_name='$REF_TABLE'
        AND referenced_column_name='$REF_COLUMN';
    ")

    [ "$COUNT" = "1" ]
}

check() {
    NAME="$1"
    RESULT="$2"

    if [ "$RESULT" = "0" ]; then
        echo "PASS: $NAME"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $NAME"
        FAIL=$((FAIL + 1))
    fi
}

echo
echo "Checking tables..."

table_exists Department
check "Department table exists" $?

table_exists Faculty
check "Faculty table exists" $?

table_exists Course
check "Course table exists" $?

table_exists Student
check "Student table exists" $?

echo
echo "Checking columns..."

column_exists Department DepartmentID
check "DepartmentID exists in Department" $?

column_exists Department DepartmentName
check "DepartmentName exists in Department" $?

column_exists Faculty FacultyID
check "FacultyID exists in Faculty" $?

column_exists Faculty FacultyName
check "FacultyName exists in Faculty" $?

column_exists Faculty DepartmentID
check "DepartmentID exists in Faculty" $?

column_exists Course CourseID
check "CourseID exists in Course" $?

column_exists Course CourseName
check "CourseName exists in Course" $?

column_exists Course FacultyID
check "FacultyID exists in Course" $?

column_exists Student StudentID
check "StudentID exists in Student" $?

column_exists Student StudentName
check "StudentName exists in Student" $?

column_exists Student CourseID
check "CourseID exists in Student" $?

echo
echo "Checking primary keys..."

primary_key_exists Department DepartmentID
check "DepartmentID is primary key" $?

primary_key_exists Faculty FacultyID
check "FacultyID is primary key" $?

primary_key_exists Course CourseID
check "CourseID is primary key" $?

primary_key_exists Student StudentID
check "StudentID is primary key" $?

echo
echo "Checking foreign keys..."

foreign_key_exists Faculty DepartmentID Department DepartmentID
check "Faculty.DepartmentID -> Department.DepartmentID" $?

foreign_key_exists Course FacultyID Faculty FacultyID
check "Course.FacultyID -> Faculty.FacultyID" $?

foreign_key_exists Student CourseID Course CourseID
check "Student.CourseID -> Course.CourseID" $?

echo
echo "Checking Student table for denormalized columns..."

for COLUMN in CourseName FacultyName DepartmentName
do
    COUNT=$($MYSQL "$DB" -e "
        SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_schema='$DB'
        AND table_name='Student'
        AND column_name='$COLUMN';
    ")

    if [ "$COUNT" = "0" ]; then
        echo "PASS: Student does not contain $COLUMN"
        PASS=$((PASS + 1))
    else
        echo "FAIL: Student should not contain $COLUMN"
        FAIL=$((FAIL + 1))
    fi
done

echo
echo "======================================"
echo "AUTOGRADING RESULT"
echo "======================================"
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "======================================"

if [ "$FAIL" -eq 0 ]; then
    echo "RESULT: PASS"
    exit 0
else
    echo "RESULT: FAIL"
    exit 1
fi
