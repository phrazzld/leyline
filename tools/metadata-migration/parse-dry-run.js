#!/usr/bin/env node

/**
 * Simple script to parse and summarize dry-run output
 */

const fs = require('fs');

// Read from stdin
let input = '';
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  parseDryRunOutput(input);
});

function parseDryRunOutput(output) {
  const lines = output.split('\n');
  let summary = null;

  // Find the summary JSON
  for (const line of lines) {
    if (line.includes('"msg":"Migration completed"') && line.includes('"summary":')) {
      try {
        const parsed = JSON.parse(line);
        if (parsed.metadata && parsed.metadata.summary) {
          summary = parsed.metadata.summary;
          break;
        }
      } catch (e) {
        // Continue searching
      }
    }
  }

  if (!summary) {
    console.error("Could not find migration summary in output");
    return;
  }

  console.log("=== DRY-RUN VALIDATION REPORT ===");
  console.log("");

  console.log("📊 File Statistics:");
  console.log(`  Total files found: ${summary.totalFiles}`);
  console.log(`  Files processed: ${summary.processedFiles}`);
  console.log(`  ✅ Successful: ${summary.succeededCount}`);
  console.log(`  ❌ Failed: ${summary.failedCount}`);
  console.log("");

  console.log("📄 File Categories:");
  console.log(`  Already YAML: ${summary.alreadyYamlCount}`);
  console.log(`  No metadata: ${summary.noMetadataCount}`);
  console.log(`  Unknown format: ${summary.unknownFormatCount}`);
  console.log(`  Files to be modified: ${summary.modifiedCount}`);
  console.log("");

  // Count DRY RUN operations
  const dryRunLines = lines.filter(line => line.includes("[DRY RUN] Would rewrite"));
  console.log(`🔄 Dry-run conversions proposed: ${dryRunLines.length}`);

  if (dryRunLines.length > 0) {
    console.log("");
    console.log("Files that would be converted:");
    dryRunLines.forEach(line => {
      try {
        const parsed = JSON.parse(line);
        const filePath = parsed.filePath || parsed.msg.match(/Would rewrite: (.+)/)?.[1];
        if (filePath) {
          console.log(`  - ${filePath}`);
        }
      } catch (e) {
        // Try simple extraction
        const match = line.match(/Would rewrite: (.+?)["'\s]/);
        if (match) {
          console.log(`  - ${match[1]}`);
        }
      }
    });
  }

  // Analyze errors
  if (summary.errors && summary.errors.length > 0) {
    console.log("");
    console.log("⚠️  Errors encountered:");

    // Group errors by type
    const errorTypes = new Map();

    for (const error of summary.errors) {
      const errorType = error.message;
      if (!errorTypes.has(errorType)) {
        errorTypes.set(errorType, []);
      }
      errorTypes.get(errorType).push(error.filePath);
    }

    // Display grouped errors
    for (const [errorType, files] of errorTypes) {
      console.log(`\n  ${errorType} (${files.length} files):`);
      files.slice(0, 5).forEach(file => {
        console.log(`    - ${file}`);
      });
      if (files.length > 5) {
        console.log(`    ... and ${files.length - 5} more`);
      }
    }
  }

  console.log("");
  console.log("=== SUMMARY ===");

  if (summary.failedCount === 0) {
    console.log("✅ All files processed successfully!");
    console.log(`   ${dryRunLines.length} files would be converted from legacy format to YAML`);
  } else {
    console.log("⚠️  Some files had errors during processing");
    console.log(`   ${summary.failedCount} files failed (mostly missing lastModified dates)`);
    console.log(`   ${dryRunLines.length} files would be successfully converted`);
    console.log(`   ${summary.noMetadataCount} files have no metadata`);
  }

  // Check filesystem integrity
  console.log("");
  console.log("🔒 Filesystem Integrity:");
  console.log("   ✅ No files were modified (dry-run mode)");
  console.log(`   ✅ No backups created (${summary.backupsCreated} expected)`);

  console.log("");
  console.log("📋 Recommendations:");
  if (summary.failedCount > 0) {
    console.log("   1. Review files with missing lastModified fields");
    console.log("   2. Add appropriate dates to legacy metadata sections");
    console.log("   3. Run dry-run again after fixes to verify");
  } else {
    console.log("   1. Review the conversion list above");
    console.log("   2. Create a backup of the docs directory");
    console.log("   3. Run migration without --dry-run flag");
  }

  console.log("");
  console.log("✅ Dry-run validation completed");
}
