const API_BASE_URL = 'http://localhost:8081/api/products';

const productForm = document.getElementById('productForm');
const productIdInput = document.getElementById('productId');
const nameInput = document.getElementById('name');
const descriptionInput = document.getElementById('description');
const priceInput = document.getElementById('price');
const submitButton = document.getElementById('submitButton');
const cancelEditButton = document.getElementById('cancelEditButton');
const formTitle = document.getElementById('form-title');
const productTableBody = document.getElementById('productTableBody');
const messageBox = document.getElementById('messageBox');
const messageText = document.getElementById('messageText');

// Function to display messages to the user
function showMessage(message, type = 'success') {
    messageText.textContent = message;
    messageBox.classList.remove('hidden', 'bg-red-100', 'border-red-400', 'text-red-700', 'bg-green-100', 'border-green-400', 'text-green-700');
    if (type === 'success') {
        messageBox.classList.add('bg-green-100', 'border-green-400', 'text-green-700');
    } else if (type === 'error') {
        messageBox.classList.add('bg-red-100', 'border-red-400', 'text-red-700');
    }
    messageBox.classList.remove('hidden');
    // Hide message after 5 seconds
    setTimeout(() => {
        messageBox.classList.add('hidden');
    }, 5000);
}

// Function to fetch all products from the backend
async function fetchProducts() {
    try {
        const response = await fetch(API_BASE_URL, {
            method: 'GET',
            headers: { 'Content-Type': 'application/json' }
        });
        ;
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        const products = await response.json();
        renderProducts(products);
    } catch (error) {
        console.error('Error fetching products:', error);
        showMessage('Failed to load products. Please ensure the backend is running.', 'error');
    }
}

// Function to render products in the table
function renderProducts(products) {
    productTableBody.innerHTML = ''; // Clear existing rows
    if (products.length === 0) {
        productTableBody.innerHTML = `<tr><td colspan="5" class="px-6 py-4 whitespace-nowrap text-center text-gray-500">No products found. Add one above!</td></tr>`;
        return;
    }
    products.forEach(product => {
        const row = `
            <tr class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">${product.id}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">${product.name}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${product.description}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">$${product.price.toFixed(2)}</td>
                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-2">
                    <button onclick="editProduct(${product.id})"
                            class="px-4 py-2 bg-blue-500 text-white rounded-md shadow-sm hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition duration-150 ease-in-out">
                        Edit
                    </button>
                    <button onclick="deleteProduct(${product.id})"
                            class="px-4 py-2 bg-red-500 text-white rounded-md shadow-sm hover:bg-red-600 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition duration-150 ease-in-out">
                        Delete
                    </button>
                </td>
            </tr>
        `;
        productTableBody.innerHTML += row;
    });
}

// Function to handle form submission (Add or Update)
productForm.addEventListener('submit', async (event) => {
    event.preventDefault(); // Prevent default form submission

    const id = productIdInput.value;
    const name = nameInput.value;
    const description = descriptionInput.value;
    const price = parseFloat(priceInput.value);

    const productData = { name, description, price };

    try {
        let response;
        if (id) {
            // Update existing product
            response = await fetch(`${API_BASE_URL}/${id}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(productData)
            });
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            showMessage('Product updated successfully!', 'success');
        } else {
            // Add new product
            response = await fetch(API_BASE_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(productData)
            });
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            showMessage('Product added successfully!', 'success');
        }
        productForm.reset(); // Clear the form
        resetFormForAdd(); // Reset form state
        fetchProducts(); // Refresh the product list
    } catch (error) {
        console.error('Error saving product:', error);
        showMessage(`Failed to save product: ${error.message}`, 'error');
    }
});

// Function to populate the form for editing
async function editProduct(id) {
    try {
        const response = await fetch(`${API_BASE_URL}/${id}`);
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        const product = await response.json();
        productIdInput.value = product.id;
        nameInput.value = product.name;
        descriptionInput.value = product.description;
        priceInput.value = product.price;

        formTitle.textContent = 'Edit Product';
        submitButton.textContent = 'Update Product';
        cancelEditButton.classList.remove('hidden');
    } catch (error) {
        console.error('Error fetching product for edit:', error);
        showMessage('Failed to load product for editing.', 'error');
    }
}

// Function to delete a product
async function deleteProduct(id) {
    if (!confirm('Are you sure you want to delete this product?')) { // Using confirm for simplicity, but a custom modal is recommended for production
        return;
    }
    try {
        const response = await fetch(`${API_BASE_URL}/${id}`, {
            method: 'DELETE'
        });
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        showMessage('Product deleted successfully!', 'success');
        fetchProducts(); // Refresh the product list
    } catch (error) {
        console.error('Error deleting product:', error);
        showMessage('Failed to delete product.', 'error');
    }
}

// Function to reset the form to "Add New Product" state
function resetFormForAdd() {
    productIdInput.value = '';
    productForm.reset();
    formTitle.textContent = 'Add New Product';
    submitButton.textContent = 'Add Product';
    cancelEditButton.classList.add('hidden');
}

// Event listener for the Cancel Edit button
cancelEditButton.addEventListener('click', resetFormForAdd);

// Initial fetch of products when the page loads
document.addEventListener('DOMContentLoaded', fetchProducts);
