import axios from 'axios';

// Azure App Service API (health: https://WebApplicationNestVet.azurewebsites.net/health)
const API_BASE_URL = 'https://webapplicationnestvet.azurewebsites.net/api/v1';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  withCredentials: true,
});

api.interceptors.response.use(
    (response) => response,
    (error) => {
        console.error('API Error:', error.response ? error.response.data : error.message);
        return Promise.reject(error);
    }
);

export default api;
