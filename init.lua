local boundary = require('boundary')
local pginfo = require('pginfo')
local table = require('table')
local string = require('string')
local timer = require('timer')

-- Default params
local connections = {
[0] = {
	host = "localhost",
	port = 5432,
	user = "postgres",
	password = "123qwe",
	database = "postgres",
	source = "",
	pollInterval = 5000
}}

-- Fetching params
if (boundary.param ~= nil) then
  connections = boundary.param or connections
end

print("_bevent:Boundary LUA Postgres plugin up : version 1.0|t:info|tags:lua,plugin")

local function getStats(conobj, pgcon, source)
	conobj:get_bg_writer_stats(pgcon, function(writer_stats)
		conobj:get_lock_stats_mode(pgcon, function(db_locks)
			conobj:get_database_stats(pgcon, function(db_stats)
							
				--lock stats
				p(string.format("POSTGRESQL_EXCLUSIVE_LOCKS %s %s", db_locks['all']['Exclusive'], source))
				p(string.format("POSTGRESQL_ROW_EXCLUSIVE_LOCKS %s %s", db_locks['all']['RowExclusive'], source))
				p(string.format("POSTGRESQL_SHARE_ROW_EXCLUSIVE_LOCKS %s %s", db_locks['all']['ShareRowExclusive'], source))
				p(string.format("POSTGRESQL_SHARE_UPDATE_EXCLUSIVE_LOCKS %s %s", db_locks['all']['ShareUpdateExclusive'], source))
				p(string.format("POSTGRESQL_SHARE_LOCKS %s %s", db_locks['all']['Share'], source))
				p(string.format("POSTGRESQL_ACCESS_SHARE_LOCKS %s %s", db_locks['all']['AccessShare'], source))
							
				--checkpoint/bgwriter stats
				p(string.format("POSTGRESQL_CHECKPOINT_WRITE_TIME %s %s", writer_stats['checkpoint_write_time'], source))
				p(string.format("POSTGRESQL_CHECKPOINTS_TIMED %s %s", writer_stats['checkpoints_timed'], source))
				p(string.format("POSTGRESQL_BUFFERS_ALLOCATED %s %s", writer_stats['buffers_alloc'], source))
				p(string.format("POSTGRESQL_BUFFERS_CLEAN %s %s", writer_stats['buffers_clean'], source))
				p(string.format("POSTGRESQL_BUFFERS_BACKEND_FSYNC %s %s", writer_stats['buffers_backend_fsync'], source))
				p(string.format("POSTGRESQL_CHECKPOINT_SYNCHRONIZATION_TIME %s %s", writer_stats['checkpoint_sync_time'], source))
				p(string.format("POSTGRESQL_CHECKPOINTS_REQUESTED %s %s", writer_stats['checkpoints_req'], source))
				p(string.format("POSTGRESQL_BUFFERS_BACKEND %s %s", writer_stats['buffers_backend'], source))
				p(string.format("POSTGRESQL_MAXIMUM_WRITTEN_CLEAN %s %s", writer_stats['maxwritten_clean'], source))
				p(string.format("POSTGRESQL_BUFFERS_CHECKPOINT %s %s", writer_stats['buffers_checkpoint'], source))

				--Global DB Stats
				p(string.format("POSTGRESQL_BLOCKS_READ %s %s", db_stats['totals']['blks_read'], source))
				p(string.format("POSTGRESQL_DISK_SIZE %s %s", db_stats['totals']['disk_size'], source))
				p(string.format("POSTGRESQL_TRANSACTIONS_COMMITTED %s %s", db_stats['totals']['xact_commit'], source))
				p(string.format("POSTGRESQL_TUPLES_DELETED %s %s", db_stats['totals']['tup_deleted'], source))
				p(string.format("POSTGRESQL_TRANSACTIONS_ROLLEDBACK %s %s", db_stats['totals']['xact_rollback'], source))
				p(string.format("POSTGRESQL_BLOCKS_HIT %s %s", db_stats['totals']['blks_hit'], source))
				p(string.format("POSTGRESQL_TUPLES_RETURNED %s %s", db_stats['totals']['tup_returned'], source))
				p(string.format("POSTGRESQL_TUPLES_FETCHED %s %s", db_stats['totals']['tup_fetched'], source))
				p(string.format("POSTGRESQL_TUPLES_UPDATED %s %s", db_stats['totals']['tup_updated'], source))
				p(string.format("POSTGRESQL_TUPLES_INSERTED %s %s", db_stats['totals']['tup_inserted'], source))
				p(string.format("POSTGRESQL_TUPLES_FETCHED %s %s", db_stats['totals']['tup_fetched'], source))
				
			end)
		end)
	end)
end

local function poll(connections)
	if table.getn(connections) > 0 then
		local query = connections[1]
		local dbcon = pginfo:new(query.host, query.port, query.user, query.password, query.database, query.source)
		table.remove(connections, 1)

		dbcon:establish(function(connection)
			dbcon:get_databases(connection, function(dbs)
				getStats(connection, query.source)
				timer.setInterval(query.pollInterval, getStats, dbcon, connection, query.source)
				poll(connections)
			end)
		end)
	end
end

poll(connections)
