/**
 * Storage utility for Golf Scramble app
 *
 * This provides a localStorage-based storage system that mimics
 * the window.storage API used in the app. For production use,
 * you can replace this with a real backend (Firebase, Supabase, etc.)
 */

const STORAGE_PREFIX = 'golf-scramble-'

/**
 * Initialize the storage system on window object
 */
export function initStorage() {
  window.storage = {
    /**
     * Get a value from storage
     * @param {string} key - The key to retrieve
     * @param {boolean} _shared - Ignored in localStorage implementation
     * @returns {Promise<{value: string | null}>}
     */
    get: async (key, _shared = false) => {
      try {
        const value = localStorage.getItem(STORAGE_PREFIX + key)
        return { value }
      } catch (error) {
        console.error('Storage get error:', error)
        return { value: null }
      }
    },

    /**
     * Set a value in storage
     * @param {string} key - The key to set
     * @param {string} value - The value to store
     * @param {boolean} _shared - Ignored in localStorage implementation
     * @returns {Promise<void>}
     */
    set: async (key, value, _shared = false) => {
      try {
        localStorage.setItem(STORAGE_PREFIX + key, value)
      } catch (error) {
        console.error('Storage set error:', error)
        // Handle quota exceeded
        if (error.name === 'QuotaExceededError') {
          alert('Storage is full. Some data may not be saved.')
        }
        throw error
      }
    },

    /**
     * Remove a value from storage
     * @param {string} key - The key to remove
     * @returns {Promise<void>}
     */
    remove: async (key) => {
      try {
        localStorage.removeItem(STORAGE_PREFIX + key)
      } catch (error) {
        console.error('Storage remove error:', error)
        throw error
      }
    },

    /**
     * Clear all golf scramble data from storage
     * @returns {Promise<void>}
     */
    clear: async () => {
      try {
        const keysToRemove = []
        for (let i = 0; i < localStorage.length; i++) {
          const key = localStorage.key(i)
          if (key && key.startsWith(STORAGE_PREFIX)) {
            keysToRemove.push(key)
          }
        }
        keysToRemove.forEach(key => localStorage.removeItem(key))
      } catch (error) {
        console.error('Storage clear error:', error)
        throw error
      }
    }
  }
}

export default window.storage
