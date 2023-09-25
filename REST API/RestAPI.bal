import ballerina/http;
import ballerinax/mysql;
import ballerina/sql;
import ballerinax/mysql.driver as _;

//Records
type Staff record
{
    string staffNumber;
    string officeNumber;
    string staffName;
    string title;
};

type Office record {
    string office_number;
    string location;
    int capcity;
    string lecturer;
};

type Lecturers record {
    string name;
    string course;
    string office_number;
};

type LectureAndCourses record {
    string staffNumber;
    string officeNumber;
    string staffName;
};

final mysql:Client db = check new (
    host = "first-instance.cg4vktva35w7.eu-north-1.rds.amazonaws.com",
    user = "learning", password = "learning-db",
    port = 3306,
    database = "bal_db"
);

isolated service /api on new http:Listener(9000) {
    //Retrieve the details of a specific lecturer by their staff number.(Simeon)
    resource isolated function get lecturers/[string staffNumber]() returns Staff[]|error {
        stream<Staff, sql:Error?> staffs = db->query(`select * from Staff where staffNumber = ${staffNumber}`);
        return from Staff staff in staffs
            select staff;
    }

    // Retrieve all the lecturers that sit in the same office.(Barkias)
    resource isolated function get lecturer/[string office_number]() returns Lecturers[]|error {

        do {
            stream<Lecturers, sql:Error?> lecturer_office = db->query(`SELECT * FROM Staff WHERE  officeNumber = ${office_number}`);
            return from Lecturers offices in lecturer_office
                select offices;
        }
        on fail var e {
            return error(e.message());
        }
    }

    //Retrieve a list of all lecturers withtin the faculty (Patrick)
    resource isolated function get lecturer() returns Staff[]|error {
        stream<Staff, sql:Error?> staffStream = db->query(`SELECT * FROM Staff WHERE title = "lecturer"`);
        return from Staff staff in staffStream
            select staff;
    }

    //Delete Lecturer by staffNumber (Patrick)
    resource isolated function delete lecturer/[string staffNumber]() returns http:NoContent|error
    {
        _ = check db->execute(`DELETE FROM Staff WHERE staffNumber = ${staffNumber}`);
        return http:NO_CONTENT;
    }

    //Retrieve all lecturers that teach a crtain course(Linda)
    resource isolated function get staff/[string staffNumber]() returns LectureAndCourses[]|error {
        stream<LectureAndCourses, sql:Error?> streamName = db->query(`SELECT
        Lecturer_Course.*,
        Staff.*,
        Courses.courseName,
        Courses.NQFLevel
        FROM Lecturer_Course
        INNER JOIN Staff ON Lecturer_Course.staffNumber = Staff.staffNumber
        INNER JOIN Courses ON Lecturer_Course.courseCode = Courses.courseCode
        WHERE
        Lecturer_Course.staffNumber = ${staffNumber}`);

        return from LectureAndCourses staff in streamName
            select staff;
    };

    //addinfg a new lecturer(Linda)
    resource isolated function post lecturer(Staff lecture) returns Staff|error {
        do {
            _ = check db->execute(`insert into Staff(staffNumber, officeNumber, staffName, title)
                            values(${lecture.staffNumber}, ${lecture.officeNumber}, ${lecture.staffName}, ${lecture.title}`);
        } on fail var Linda {
            return error(Linda.message());
        }
        return lecture;
    }

}
