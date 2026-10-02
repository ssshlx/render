// request.js - Polyfill para funciones HTTP en ejecutores

const request = {
    get: async (url, options = {}) => {
        const {
            headers = {},
            timeout = 10000
        } = options;
        
        try {
            // Intentar con getgenv()
            const axios = getgenv("axios");
            
            if (axios) {
                const response = await axios.get(url, {
                    headers: headers,
                    timeout: timeout
                });
                return response;
            }
            
            // Fallback: intentar con fetch global
            const response = await fetch(url, {
                method: "GET",
                headers: headers,
                signal: AbortSignal.timeout(timeout)
            });
            
            return {
                status: response.status,
                ok: response.ok,
                headers: response.headers,
                json: async () => response.json(),
                text: async () => response.text(),
                arrayBuffer: async () => await response.arrayBuffer()
            };
        } catch (error) {
            const errorMsg = error.message || error;
            console.error("Error en request.get:", errorMsg);
            throw new Error(errorMsg);
        }
    },
    
    post: async (url, body, options = {}) => {
        const {
            headers = {},
            timeout = 10000
        } = options;
        
        try {
            // Intentar con getgenv()
            const axios = getgenv("axios");
            
            if (axios) {
                const response = await axios.post(url, body, {
                    headers: headers,
                    timeout: timeout
                });
                return response;
            }
            
            // Fallback: intentar con fetch global
            const response = await fetch(url, {
                method: "POST",
                headers: headers,
                body: typeof body === "string" ? body : JSON.stringify(body),
                signal: AbortSignal.timeout(timeout)
            });
            
            return {
                status: response.status,
                ok: response.ok,
                headers: response.headers,
                json: async () => response.json(),
                text: async () => response.text()
            };
        } catch (error) {
            const errorMsg = error.message || error;
            console.error("Error en request.post:", errorMsg);
            throw new Error(errorMsg);
        }
    },
    
    put: async (url, body, options = {}) => {
        return await this.post(url, body, options);
    },
    
    patch: async (url, body, options = {}) => {
        return await this.post(url, body, options);
    },
    
    delete: async (url, options = {}) => {
        return await this.get(url, options);
    }
};

module.exports = request;
