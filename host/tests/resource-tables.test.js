
// Unit tests for ResourceTable
import assert from 'assert';
import { ResourceManager, ResourceTable } from '../js/resource-tables.js';

async function runTests() {
    console.log("Running ResourceTable tests...");

    // Test 1: ResourceTable CRUD
    {
        const table = new ResourceTable();
        
        // Create (auto-ID)
        const res1 = { name: 'A' };
        const id1 = table.create(res1);
        assert.strictEqual(id1, 1);
        assert.strictEqual(table.get(1), res1);

        // Set (manual ID)
        const res2 = { name: 'B' };
        table.set(99, res2);
        assert.strictEqual(table.get(99), res2);

        // Delete
        const deleted = table.delete(1);
        assert.strictEqual(deleted, res1);
        assert.strictEqual(table.get(1), undefined);

        // Clear
        table.clear();
        assert.strictEqual(table.get(99), undefined);
        // Check ID reset
        const idNew = table.create({ name: 'C' });
        assert.strictEqual(idNew, 1);

        console.log("PASS: ResourceTable CRUD");
    }

    // Test 2: ResourceManager structure
    {
        const mgr = new ResourceManager();
        assert(mgr.buffers instanceof ResourceTable);
        assert(mgr.textures instanceof ResourceTable);
        assert(mgr.programs instanceof ResourceTable);
        console.log("PASS: ResourceManager structure");
    }
}

runTests().catch(e => {
    console.error("FAILED:", e);
    process.exit(1);
});
