import { describe, test, expect, beforeEach, afterEach } from "vitest";
import { join } from "path";
import { writeFile, readFile } from "fs/promises";
import {
  createTestWorkspace,
  type TestWorkspace,
  createFixtureFile,
  runCli,
} from "./integrationTestUtils";

describe("Integration Tests - Edge Cases", () => {
  let workspace: TestWorkspace;

  beforeEach(async () => {
    workspace = await createTestWorkspace();
  });

  afterEach(async () => {
    await workspace.cleanup();
  });

  test("handles empty files", async () => {
    const fileName = "empty.md";
    const filePath = join(workspace.path, fileName);
    await writeFile(filePath, "");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);
    const content = await readFile(filePath, "utf-8");
    expect(content).toBe(""); // Should remain empty
  });

  test("handles files with only whitespace", async () => {
    const fileName = "whitespace.md";
    const filePath = join(workspace.path, fileName);
    await writeFile(filePath, "   \n\n\t\n   ");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);
    const content = await readFile(filePath, "utf-8");
    expect(content).toBe("   \n\n\t\n   "); // Should remain unchanged
  });

  test("handles very long metadata values", async () => {
    await createFixtureFile(workspace.path, "edge-very-long-metadata.md");
    const filePath = join(workspace.path, "edge-very-long-metadata.md");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);
    const content = await readFile(filePath, "utf-8");
    expect(content).toContain("---\n");
    expect(content).toContain("This is an extremely long description");
  });

  test("handles special characters in metadata", async () => {
    await createFixtureFile(workspace.path, "legacy-special-chars.md");
    const filePath = join(workspace.path, "legacy-special-chars.md");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);
    const content = await readFile(filePath, "utf-8");
    expect(content).toContain("Special chars: @#$%^&*()");
    expect(content).toContain("Quotes: \"test\" and 'test'");
  });

  test("handles CRLF line endings", async () => {
    await createFixtureFile(workspace.path, "edge-crlf-endings.md");
    const filePath = join(workspace.path, "edge-crlf-endings.md");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);
    const content = await readFile(filePath, "utf-8");
    expect(content).toContain("---\n");
    // Should preserve CRLF in content but use LF in YAML
    expect(content).toMatch(/\r\n.*# Legacy Metadata with CRLF/);
  });

  test("handles UTF-8 with BOM", async () => {
    const fileName = "utf8-bom.md";
    const filePath = join(workspace.path, fileName);
    // UTF-8 BOM
    const content = "\uFEFF---\nid: test\ntype: binding\n---\n\n# Test";
    await writeFile(filePath, content);

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);
    const newContent = await readFile(filePath, "utf-8");
    expect(newContent).toContain("---\n");
    expect(newContent).toContain("id: test");
  });

  test("handles files with no extension", async () => {
    const fileName = "README";
    const filePath = join(workspace.path, fileName);
    await writeFile(filePath, "# Just a README\n\nNo metadata here.");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);
    const content = await readFile(filePath, "utf-8");
    expect(content).toBe("# Just a README\n\nNo metadata here."); // Unchanged
  });

  test("handles nested directory structures", async () => {
    // Create deeply nested structure
    const deepPath = join(workspace.path, "a", "b", "c", "d", "e");
    await workspace.mkdir(deepPath);
    await createFixtureFile(deepPath, "legacy-basic-binding.md");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);
    expect(result.stdout).toContain("1 file");

    const filePath = join(deepPath, "legacy-basic-binding.md");
    const content = await readFile(filePath, "utf-8");
    expect(content).toContain("---\n");
  });

  test("handles mixed metadata formats in same directory", async () => {
    // Create files with different metadata formats
    await createFixtureFile(workspace.path, "yaml-basic-binding.md");
    await createFixtureFile(workspace.path, "legacy-basic-binding.md");
    await createFixtureFile(workspace.path, "no-metadata-plain.md");

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);

    // Check each file
    const yamlContent = await readFile(join(workspace.path, "yaml-basic-binding.md"), "utf-8");
    expect(yamlContent).toContain("---\n"); // Already had YAML

    const legacyContent = await readFile(join(workspace.path, "legacy-basic-binding.md"), "utf-8");
    expect(legacyContent).toContain("---\n"); // Converted from legacy

    const plainContent = await readFile(join(workspace.path, "no-metadata-plain.md"), "utf-8");
    expect(plainContent).not.toContain("---\n"); // No metadata, unchanged
  });

  test("handles files with multiple horizontal rules", async () => {
    const fileName = "multiple-hr.md";
    const filePath = join(workspace.path, fileName);
    const content = `---
id: test-hr
type: binding
---

# Test

Some content here.

---

More content after HR.

---

Even more content.
`;
    await writeFile(filePath, content);

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);
    const newContent = await readFile(filePath, "utf-8");
    // Should not modify content HRs, only the metadata
    expect(newContent.match(/---/g)?.length).toBeGreaterThan(2);
  });

  test("handles files with code blocks containing dashes", async () => {
    const fileName = "code-with-dashes.md";
    const filePath = join(workspace.path, fileName);
    const content = `---
id: test
type: tenet

# Test

\`\`\`yaml
---
example: yaml
---
\`\`\`

Some text

\`\`\`
// Code with --- comment
function test() {
  // --- separator ---
  return true;
}
\`\`\`
`;
    await writeFile(filePath, content);

    const result = await runCli([workspace.path], workspace);

    expect(result.exitCode).toBe(0);
    const newContent = await readFile(filePath, "utf-8");
    expect(newContent).toContain("```yaml");
    expect(newContent).toContain("// --- separator ---");
  });
});
