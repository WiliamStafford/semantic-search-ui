export const getCategories = async () => {
    return await axios.get('/api/v1/categories');
};