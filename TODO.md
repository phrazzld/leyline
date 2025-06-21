# Leyline Cache Implementation TODO

*Make it fast. Ship it. No excuses.*

## Phase 1: Basic Cache (Ship This Week)

### Core Implementation
- [x] Create `lib/leyline/cache/` directory structure
- [x] Create `lib/leyline/cache/file_cache.rb` with class skeleton
- [x] Add `require 'digest'` and `require 'fileutils'`
- [x] Implement `ensure_directories` private method
- [x] Add instance variables: `@cache_dir`, `@content_dir`, `@max_cache_size`
- [x] Implement `content_file_path(hash)` for git-style sharding
- [x] Implement `put(content)` that returns SHA256 hash and stores file
- [x] Implement `get(hash)` that returns content or nil
- [x] Add basic `File.exist?` check before reading

### Wire It Up
- [x] Modify FileSyncer to check cache before copying
- [x] Cache files after successful sync
- [x] Add `--no-cache` flag to CLI

### Ship It
- [x] Manual test: sync twice, verify second sync is faster
- [x] Commit and push

## Phase 2: Make It Robust (Only If Needed)

### Size Management
- [ ] Add `cache_size` method using Dir.glob
- [ ] Delete oldest files when > 50MB
- [ ] Add `clear_cache` command

### Error Handling
- [ ] Handle corrupted files (return nil, log error)
- [ ] Clean up failed writes

## Phase 3: Optimize (Only If Still Slow)

### Measure First
- [ ] Add simple timing output in verbose mode
- [ ] Identify actual bottlenecks

### Then Fix
- [ ] Parallel file operations (if needed)
- [ ] Better cache keys (if needed)
- [ ] Version awareness (if needed)

---

*Remember: Working code > Perfect plan. Ship the minimum that makes sync fast.*
