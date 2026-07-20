import Foundation
import SQLite3

// MARK: - Database Manager
/// SQLite database wrapper for persisting match state and shot history.

public final class DatabaseManager: @unchecked Sendable {
    
    // MARK: - Properties
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    // MARK: - Initialization
    
    public init() {
        let documentsDir = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        self.dbPath = documentsDir
            .appendingPathComponent(AppConstants.databaseFilename)
            .path
        
        openDatabase()
        createTables()
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    // MARK: - Database Lifecycle
    
    private func openDatabase() {
        let result = sqlite3_open(dbPath, &db)
        if result != SQLITE_OK {
            Log.database.error("Failed to open database: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            Log.database.info("Database opened at \(dbPath)")
        }
    }
    
    private func createTables() {
        let createMatchTable = """
            CREATE TABLE IF NOT EXISTS matches (
                id TEXT PRIMARY KEY,
                player_color TEXT NOT NULL,
                current_turn INTEGER NOT NULL DEFAULT 1,
                remaining_player_coins INTEGER NOT NULL DEFAULT 9,
                remaining_opponent_coins INTEGER NOT NULL DEFAULT 9,
                queen_status TEXT NOT NULL DEFAULT 'On Board',
                created_at REAL NOT NULL,
                updated_at REAL NOT NULL
            );
        """
        
        let createShotHistoryTable = """
            CREATE TABLE IF NOT EXISTS shot_history (
                id TEXT PRIMARY KEY,
                match_id TEXT NOT NULL,
                turn INTEGER NOT NULL,
                recommendation_json TEXT NOT NULL,
                timestamp REAL NOT NULL,
                FOREIGN KEY (match_id) REFERENCES matches(id)
            );
        """
        
        executeSQL(createMatchTable)
        executeSQL(createShotHistoryTable)
    }
    
    // MARK: - SQL Execution
    
    @discardableResult
    private func executeSQL(_ sql: String) -> Bool {
        var errMsg: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, sql, nil, nil, &errMsg)
        
        if result != SQLITE_OK {
            let error = errMsg.map { String(cString: $0) } ?? "Unknown error"
            Log.database.error("SQL error: \(error)")
            sqlite3_free(errMsg)
            return false
        }
        return true
    }
    
    // MARK: - Match CRUD
    
    /// Save a new match state.
    public func saveMatch(_ match: MatchState) {
        let sql = """
            INSERT OR REPLACE INTO matches
            (id, player_color, current_turn, remaining_player_coins,
             remaining_opponent_coins, queen_status, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            Log.database.error("Failed to prepare save match statement")
            return
        }
        defer { sqlite3_finalize(stmt) }
        
        sqlite3_bind_text(stmt, 1, (match.id as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (match.playerColor.rawValue as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 3, Int32(match.currentTurn))
        sqlite3_bind_int(stmt, 4, Int32(match.remainingPlayerCoins))
        sqlite3_bind_int(stmt, 5, Int32(match.remainingOpponentCoins))
        sqlite3_bind_text(stmt, 6, (match.queenStatus.rawValue as NSString).utf8String, -1, nil)
        sqlite3_bind_double(stmt, 7, match.createdAt.timeIntervalSince1970)
        sqlite3_bind_double(stmt, 8, match.updatedAt.timeIntervalSince1970)
        
        if sqlite3_step(stmt) != SQLITE_DONE {
            Log.database.error("Failed to save match: \(String(cString: sqlite3_errmsg(db)))")
        }
    }
    
    /// Load the most recent match.
    public func loadLatestMatch() -> MatchState? {
        let sql = "SELECT * FROM matches ORDER BY updated_at DESC LIMIT 1;"
        
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_finalize(stmt) }
        
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        
        let colorStr = String(cString: sqlite3_column_text(stmt, 1))
        guard let color = PlayerColor(rawValue: colorStr) else { return nil }
        
        var match = MatchState(playerColor: color)
        // Note: The ID and timestamps from DB are not restored here since
        // MatchState generates new ones. In production, add a full initializer.
        match.currentTurn = Int(sqlite3_column_int(stmt, 2))
        match.remainingPlayerCoins = Int(sqlite3_column_int(stmt, 3))
        match.remainingOpponentCoins = Int(sqlite3_column_int(stmt, 4))
        
        let queenStr = String(cString: sqlite3_column_text(stmt, 5))
        match.queenStatus = QueenStatus(rawValue: queenStr) ?? .onBoard
        
        return match
    }
    
    /// Delete all matches and history.
    public func clearAll() {
        executeSQL("DELETE FROM shot_history;")
        executeSQL("DELETE FROM matches;")
        Log.database.info("All data cleared")
    }
}
