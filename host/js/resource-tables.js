// Resource tables

export class ResourceTable {
    constructor() {
        this.resources = new Map();
        this.nextId = 1;
    }

    create(resource) {
        const id = this.nextId++;
        this.resources.set(id, resource);
        return id;
    }

    get(id) {
        return this.resources.get(id);
    }

    set(id, resource) {
        this.resources.set(id, resource);
    }

    delete(id) {
        const resource = this.resources.get(id);
        if (resource) {
            this.resources.delete(id);
            return resource;
        }
        return null;
    }

    clear() {
        this.resources.clear();
        this.nextId = 1;
    }
}

export class ResourceManager {
    constructor() {
        this.buffers = new ResourceTable();
        this.textures = new ResourceTable();
        this.programs = new ResourceTable();
    }
}
