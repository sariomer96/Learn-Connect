import SQLite3
import Foundation

final class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?

    private init() {
        openDatabase()
        createTables()
    }

    private func openDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("LearnConnectDB.sqlite")

        
        print(fileURL.path)
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database")
        } else
        {
            print("connected")
        }
    }
      

    private func createTables() {
        let createUsersTable = """
        CREATE TABLE IF NOT EXISTS Users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE,
            password TEXT,
            name TEXT,
            surname TEXT
        );
        """

        let createCoursesTable = """
        CREATE TABLE IF NOT EXISTS Courses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            category TEXT
        );
        """

        let createUserCoursesTable = """
        CREATE TABLE IF NOT EXISTS UserCourses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            course_id INTEGER,
            FOREIGN KEY(user_id) REFERENCES Users(id),
            FOREIGN KEY(course_id) REFERENCES Courses(id)
        );
        """

        let createVideosTable = """
        CREATE TABLE IF NOT EXISTS Videos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            course_id INTEGER,
            title TEXT,
            url TEXT,
            FOREIGN KEY(course_id) REFERENCES Courses(id)
        );
        """

        let createUserVideoProgressTable = """
        CREATE TABLE IF NOT EXISTS UserVideoProgress (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            video_id INTEGER,
            progress REAL,
            FOREIGN KEY(user_id) REFERENCES Users(id),
            FOREIGN KEY(video_id) REFERENCES Videos(id)
        );
        """

        executeQuery(createUsersTable)
        executeQuery(createCoursesTable)
        executeQuery(createUserCoursesTable)
        executeQuery(createVideosTable)
        executeQuery(createUserVideoProgressTable)
    }

    private func executeQuery(_ query: String) {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Query executed successfully: \(query)")
            } else {
                print("Error executing query: \(query)")
            }
        } else {
            print("Error preparing query: \(query)")
        }
        sqlite3_finalize(statement)
    }
 

    func insertUser(email: String, password: String, name: String, surname: String, isSuccess: (Bool) -> ()) {
        
        print(type(of: email))
        let query = "INSERT INTO Users (email, password, name, surname) VALUES (?, ?, ?, ?);"
        var statement: OpaquePointer?

        // Hazırlama işlemi
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error preparing insert statement: \(errorMessage)")
            isSuccess(false)
            return
        }
        sqlite3_bind_text(statement, 1, (email as NSString).utf8String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 2, (password as NSString).utf8String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 3, (name as NSString).utf8String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 4, (surname as NSString).utf8String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))


        // SQL ifadesini yürütme
        if sqlite3_step(statement) == SQLITE_DONE {
            print("User inserted successfully.")
            isSuccess(true)
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error inserting user: \(errorMessage)")
            isSuccess(false)
        }

        // Belleği serbest bırakma
        sqlite3_finalize(statement)
    }

    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }

    func loginUser(email: String, password: String, isSuccess: @escaping (Bool) -> ()) {
        let query = "SELECT * FROM Users WHERE email = ? AND password = ?;"
        var statement: OpaquePointer?

        // Hazırlama işlemi
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error preparing login statement: \(errorMessage)")
            isSuccess(false)
            return
        }

        // Parametreleri bağlama
        sqlite3_bind_text(statement, 1, (email as NSString).utf8String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(statement, 2, (password as NSString).utf8String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        // Sorguyu çalıştırma
        if sqlite3_step(statement) == SQLITE_ROW {
            // Kullanıcı bulundu
            print("Login successful!")
            isSuccess(true)
        } else {
            // Kullanıcı bulunamadı veya şifre yanlış
            print("Invalid email or password.")
            isSuccess(false)
        }

        // Belleği serbest bırakma
        sqlite3_finalize(statement)
    }

    func fetchAllUsers() -> [(id: Int, email: String, name: String, surname: String)] {
        let query = "SELECT id, email, name, surname FROM Users;"
        var statement: OpaquePointer?
        var users: [(id: Int, email: String, name: String, surname: String)] = []

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let email = String(cString: sqlite3_column_text(statement, 1))
                let name = String(cString: sqlite3_column_text(statement, 2))
                let surname = String(cString: sqlite3_column_text(statement, 3))

                users.append((id: id, email: email, name: name, surname: surname))
            }
        } else {
            print("Error preparing fetch statement.")
        }
        sqlite3_finalize(statement)
        return users
    }
}
