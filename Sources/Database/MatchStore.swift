import Foundation

// MARK: - Match Store
/// High-level interface for match state persistence using DatabaseManager.

public final class MatchStore: @unchecked Sendable {
    
    private let database: DatabaseManager
    
    public init(database: DatabaseManager = DatabaseManager()) {
        self.database = database
    }
    
    /// Save the current match state.
    public func save(_ match: MatchState) {
        database.saveMatch(match)
        Log.matchState.info("Match saved: turn \(match.currentTurn)")
    }
    
    /// Load the most recent match, if any.
    public func loadLatest() -> MatchState? {
        let match = database.loadLatestMatch()
        if let match = match {
            Log.matchState.info("Loaded match: \(match.playerColor.rawValue), turn \(match.currentTurn)")
        }
        return match
    }
    
    /// Start a new match with the given player color.
    public func startNewMatch(playerColor: PlayerColor) -> MatchState {
        let match = MatchState(playerColor: playerColor)
        save(match)
        Log.matchState.info("New match started: \(playerColor.rawValue)")
        return match
    }
    
    /// Clear all stored matches.
    public func clearAll() {
        database.clearAll()
    }
}
