// storage.js - Manejo de almacenamiento local para PsyCase

class PsyCaseStorage {
  constructor() {
    this.dbName = 'PsyCaseDB';
    this.version = 1;
    this.storeName = 'data';
    this.db = null;
  }

  // Inicializar IndexedDB
  async init() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, this.version);

      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        this.db = request.result;
        resolve(this.db);
      };

      request.onupgradeneeded = (event) => {
        const db = event.target.result;
        if (!db.objectStoreNames.contains(this.storeName)) {
          db.createObjectStore(this.storeName);
          console.log('✅ IndexedDB creada:', this.dbName);
        }
      };
    });
  }

  // Guardar datos
  async save(key, value) {
    if (!this.db) await this.init();
    
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([this.storeName], 'readwrite');
      const store = transaction.objectStore(this.storeName);
      const request = store.put(value, key);

      request.onsuccess = () => {
        console.log('✅ Datos guardados:', key);
        resolve(true);
      };
      request.onerror = () => reject(request.error);
    });
  }

  // Leer datos
  async load(key) {
    if (!this.db) await this.init();
    
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([this.storeName], 'readonly');
      const store = transaction.objectStore(this.storeName);
      const request = store.get(key);

      request.onsuccess = () => {
        resolve(request.result);
      };
      request.onerror = () => reject(request.error);
    });
  }

  // Eliminar dato
  async remove(key) {
    if (!this.db) await this.init();
    
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([this.storeName], 'readwrite');
      const store = transaction.objectStore(this.storeName);
      const request = store.delete(key);

      request.onsuccess = () => {
        console.log('🗑️ Dato eliminado:', key);
        resolve(true);
      };
      request.onerror = () => reject(request.error);
    });
  }

  // Debug: ver todo
  async debug() {
    if (!this.db) await this.init();
    
    console.log('🔍 === PSYCASE STORAGE ===');
    const transaction = this.db.transaction([this.storeName], 'readonly');
    const store = transaction.objectStore(this.storeName);
    const request = store.getAll();

    request.onsuccess = () => {
      console.log('Datos guardados:', request.result);
    };
  }
}

// Crear instancia global
window.psyCaseStorage = new PsyCaseStorage();
console.log('✅ PsyCase Storage JS cargado');