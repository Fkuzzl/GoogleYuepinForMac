import Foundation
import SQLite3

public actor CandidateCache {
    public enum CacheError: Error {
        case openFailed(String)
        case prepareFailed(String)
        case writeFailed(String)
    }

    private let database: OpaquePointer
    private let lifetime: TimeInterval

    public init(path: URL, lifetime: TimeInterval = 30 * 24 * 60 * 60) throws {
        self.lifetime = lifetime
        try FileManager.default.createDirectory(
            at: path.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        var databasePointer: OpaquePointer?
        guard sqlite3_open(path.path, &databasePointer) == SQLITE_OK, let databasePointer else {
            let message = databasePointer.map { String(cString: sqlite3_errmsg($0)) } ?? "Unknown SQLite error"
            sqlite3_close(databasePointer)
            throw CacheError.openFailed(message)
        }
        database = databasePointer
        let schema = """
        CREATE TABLE IF NOT EXISTS candidate_cache (
            query TEXT PRIMARY KEY NOT NULL,
            payload BLOB NOT NULL,
            created_at REAL NOT NULL,
            last_accessed_at REAL NOT NULL
        );
        """
        guard sqlite3_exec(database, schema, nil, nil, nil) == SQLITE_OK else {
            let message = String(cString: sqlite3_errmsg(database))
            sqlite3_close(database)
            throw CacheError.openFailed(message)
        }
    }

    deinit {
        sqlite3_close(database)
    }

    public func candidates(for query: String, allowExpired: Bool = false, now: Date = Date()) throws -> [Candidate]? {
        let sql = "SELECT payload, created_at FROM candidate_cache WHERE query = ? LIMIT 1;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw CacheError.prepareFailed(String(cString: sqlite3_errmsg(database)))
        }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, query, -1, Self.transientDestructor)

        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        let createdAt = sqlite3_column_double(statement, 1)
        guard allowExpired || now.timeIntervalSince1970 - createdAt <= lifetime else { return nil }
        guard let bytes = sqlite3_column_blob(statement, 0) else { return nil }
        let count = Int(sqlite3_column_bytes(statement, 0))
        let data = Data(bytes: bytes, count: count)
        let candidates = try JSONDecoder().decode([Candidate].self, from: data)
        try touch(query: query, now: now)
        return candidates
    }

    public func store(_ candidates: [Candidate], for query: String, now: Date = Date()) throws {
        let data = try JSONEncoder().encode(candidates)
        let sql = """
        INSERT INTO candidate_cache(query, payload, created_at, last_accessed_at)
        VALUES(?, ?, ?, ?)
        ON CONFLICT(query) DO UPDATE SET
            payload = excluded.payload,
            created_at = excluded.created_at,
            last_accessed_at = excluded.last_accessed_at;
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw CacheError.prepareFailed(String(cString: sqlite3_errmsg(database)))
        }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, query, -1, Self.transientDestructor)
        data.withUnsafeBytes { bytes in
            sqlite3_bind_blob(statement, 2, bytes.baseAddress, Int32(data.count), Self.transientDestructor)
        }
        sqlite3_bind_double(statement, 3, now.timeIntervalSince1970)
        sqlite3_bind_double(statement, 4, now.timeIntervalSince1970)
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw CacheError.writeFailed(String(cString: sqlite3_errmsg(database)))
        }
    }

    public func removeExpired(now: Date = Date()) throws {
        let cutoff = now.timeIntervalSince1970 - lifetime
        let sql = "DELETE FROM candidate_cache WHERE created_at < ?;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw CacheError.prepareFailed(String(cString: sqlite3_errmsg(database)))
        }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_double(statement, 1, cutoff)
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw CacheError.writeFailed(String(cString: sqlite3_errmsg(database)))
        }
    }

    private func touch(query: String, now: Date) throws {
        let sql = "UPDATE candidate_cache SET last_accessed_at = ? WHERE query = ?;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw CacheError.prepareFailed(String(cString: sqlite3_errmsg(database)))
        }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_double(statement, 1, now.timeIntervalSince1970)
        sqlite3_bind_text(statement, 2, query, -1, Self.transientDestructor)
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw CacheError.writeFailed(String(cString: sqlite3_errmsg(database)))
        }
    }

    private static let transientDestructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
}
